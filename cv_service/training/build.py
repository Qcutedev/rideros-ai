"""Turn the raw zips into one labelled, de-duplicated, split image set under data/interim/.

Classes (decision 8, HANDOFF §4.11):
  flooding     AlleyFloodNet "flooding" + Flood10k "flooded"
  road_damage  RDD2022 train images with at least one D00/D10/D20/D40 box
  other        RDD2022 train images with no box (plain road) + AlleyFloodNet "non-flooding"

Leakage guards:
  * RDD2022 images are numbered frames from vehicle/motorbike runs, so neighbours look alike. Images are
    grouped in blocks of `RDD_GROUP` consecutive numbers and a whole block goes to one split.
  * Near-duplicates (64-bit dHash within 3 bits) are kept once; a photo seen under two labels is dropped.
  * AlleyFloodNet keeps the train/test split its authors published. The Kaggle v1 zip has no val folder,
    so val is carved out of its train images (deterministic per image, `alley_val`).
Images are never extracted under their archive names: each kept image is re-encoded to
data/interim/images/<id>.jpg (shorter side 256 px), and manifest.csv records where it came from.
"""

from __future__ import annotations

import csv
import hashlib
import io
import json
import random
import re
import xml.etree.ElementTree as ET
import zipfile
from collections import Counter, defaultdict
from collections.abc import Iterator
from dataclasses import asdict, dataclass
from pathlib import Path, PurePosixPath

from PIL import Image, ImageOps

from training import sources
from training.paths import INTERIM, RAW

CLASSES: tuple[str, ...] = ("flooding", "road_damage", "other")
SPLITS: tuple[str, ...] = ("train", "val", "test")
SEED = 42
RDD_GROUP = 25
SHORT_SIDE = 256
# Split shares for sources without a published split (by group, not by image).
SPLIT_SHARES = {"train": 0.70, "val": 0.15}
# Per-class cap so no class dominates; inside a class each source gets an even share (fair_quotas).
CLASS_CAP = 3000
# Test photos kept at upload size (data/interim/bench) for the CPU latency measurement.
BENCH_PER_CLASS = 20
_IMAGE_EXT = (".jpg", ".jpeg", ".png", ".webp", ".bmp")


@dataclass
class Item:
    source: str  # rdd2022/<country> | flood10k | alleyfloodnet
    zip_name: str
    member: str
    label: str
    group: str
    split: str | None = None  # set by the source when it publishes a split
    id: str = ""
    dhash: str = ""


# ---------------------------------------------------------------- sources


def _rdd_items(country: str) -> Iterator[Item]:
    zip_name = f"RDD2022_{country}.zip"
    with zipfile.ZipFile(RAW / zip_name) as zf:
        names = zf.namelist()
        xmls = {
            PurePosixPath(n).stem: n for n in names if "/train/annotations/xmls/" in n and n.endswith(".xml")
        }
        for name in names:
            path = PurePosixPath(name)
            if "/train/images/" not in name or path.suffix.lower() not in _IMAGE_EXT:
                continue
            xml_name = xmls.get(path.stem)
            if xml_name is None:
                continue  # unlabelled image: we cannot tell damage from no damage
            boxes = {
                obj.findtext("name", "").strip() for obj in ET.fromstring(zf.read(xml_name)).iter("object")
            }
            if boxes & sources.RDD_DAMAGE_CLASSES:
                label = "road_damage"
            elif not boxes:
                label = "other"
            else:
                continue  # only other box types (e.g. repairs): neither damage nor a clean road
            number = re.search(r"(\d+)$", path.stem)
            block = int(number.group(1)) // RDD_GROUP if number else path.stem
            yield Item(f"rdd2022/{country}", zip_name, name, label, f"rdd2022/{country}/{block}")


def _flood10k_items() -> Iterator[Item]:
    with zipfile.ZipFile(RAW / "Flood10k.zip") as zf:
        for name in zf.namelist():
            path = PurePosixPath(name)
            if name.startswith("__MACOSX/") or path.suffix.lower() not in _IMAGE_EXT:
                continue
            if path.parent.name == "flooded":  # "normal" images are not used (user decision, 2026-11-12)
                yield Item("flood10k", "Flood10k.zip", name, "flooding", f"flood10k/{path.name}")


def _alley_label(parts: tuple[str, ...]) -> str | None:
    """Label from the leaf folder only: Kaggle v1 also has `flood_train_/` above it, which says nothing."""
    if not parts:
        return None
    leaf = re.sub(r"[^a-z]+", "-", parts[-1].lower()).strip("-")
    if leaf in ("flood", "flooded", "flooding"):
        return "flooding"
    if leaf in (
        "non-flood",
        "non-flooded",
        "non-flooding",
        "nonflooded",
        "nonflooding",
        "no-flood",
        "not-flooded",
    ):
        return "other"
    return None


def _alley_split(parts: tuple[str, ...]) -> str | None:
    """Split from any folder name token, e.g. `flood_train_` -> train, `Validation` -> val."""
    for part in parts:
        for token in re.split(r"[^a-z]+", part.lower()):
            if token in ("train", "training"):
                return "train"
            if token in ("val", "valid", "validation"):
                return "val"
            if token in ("test", "testing"):
                return "test"
    return None


def alley_val(member: str) -> bool:
    """True for the train images moved to val when the zip publishes no val split.

    Same share of train+val as the other sources (15 of 85) and the same hash on every run."""
    share = SPLIT_SHARES["val"] / (SPLIT_SHARES["train"] + SPLIT_SHARES["val"])
    u = int(hashlib.sha256(f"{SEED}:alley-val:{member}".encode()).hexdigest()[:8], 16) / 0xFFFFFFFF
    return u < share


def _alley_items() -> Iterator[Item]:
    items: list[Item] = []
    with zipfile.ZipFile(RAW / "alleyfloodnet.zip") as zf:
        for name in zf.namelist():
            path = PurePosixPath(name)
            if name.startswith("__MACOSX/") or path.suffix.lower() not in _IMAGE_EXT:
                continue
            parts = path.parent.parts
            label, split = _alley_label(parts), _alley_split(parts)
            if label is None or split is None:
                raise ValueError(f"unexpected AlleyFloodNet layout: {name}")
            items.append(
                Item("alleyfloodnet", "alleyfloodnet.zip", name, label, f"alley/{name}", split=split)
            )
    if not any(i.split == "val" for i in items):
        for item in items:
            if item.split == "train" and alley_val(item.member):
                item.split = "val"
    yield from items


# ---------------------------------------------------------------- helpers


def dhash(image: Image.Image) -> str:
    """64-bit difference hash: robust to re-encoding and resizing, catches re-posted copies."""
    small = image.convert("L").resize((9, 8), Image.Resampling.LANCZOS)
    px = small.tobytes()  # mode "L": one byte per pixel, row-major
    bits = 0
    for row in range(8):
        for col in range(8):
            bits = (bits << 1) | (px[row * 9 + col] > px[row * 9 + col + 1])
    return f"{bits:016x}"


class NearDuplicateIndex:
    """Finds a kept image whose dHash is within `max_bits` (Hamming) of a new one.

    A JPEG re-save or a re-post flips a bit or two, so exact matching is not enough. With max_bits=3,
    two hashes that close share at least one of their four 16-bit quarters exactly (pigeonhole), so
    only images in the same quarter buckets are compared."""

    def __init__(self, max_bits: int = 3) -> None:
        assert max_bits < 4, "the 4-quarter bucketing only guarantees recall below 4 bits"
        self.max_bits = max_bits
        self._buckets: dict[tuple[int, int], list[tuple[int, Item]]] = defaultdict(list)

    @staticmethod
    def _quarters(value: int) -> list[tuple[int, int]]:
        return [(q, (value >> (16 * q)) & 0xFFFF) for q in range(4)]

    def find(self, hex_hash: str) -> Item | None:
        value = int(hex_hash, 16)
        for key in self._quarters(value):
            for other, item in self._buckets.get(key, ()):
                if (value ^ other).bit_count() <= self.max_bits:
                    return item
        return None

    def add(self, item: Item) -> None:
        value = int(item.dhash, 16)
        for key in self._quarters(value):
            self._buckets[key].append((value, item))


def group_split(group: str) -> str:
    """Deterministic split for a group (same group -> same split on every run)."""
    u = int(hashlib.sha256(f"{SEED}:{group}".encode()).hexdigest()[:8], 16) / 0xFFFFFFFF
    if u < SPLIT_SHARES["train"]:
        return "train"
    return "val" if u < SPLIT_SHARES["train"] + SPLIT_SHARES["val"] else "test"


def load_image(data: bytes) -> Image.Image:
    image = Image.open(io.BytesIO(data))
    image = ImageOps.exif_transpose(image)
    return image.convert("RGB")


def shrink(image: Image.Image, short_side: int = SHORT_SIDE) -> Image.Image:
    w, h = image.size
    scale = short_side / min(w, h)
    if scale >= 1:
        return image
    return image.resize((round(w * scale), round(h * scale)), Image.Resampling.LANCZOS)


def fair_quotas(sizes: dict[str, int], cap: int) -> dict[str, int]:
    """Split `cap` evenly across sources; a source smaller than its share gives the rest to the others.

    Even shares keep one country's camera from standing in for a class (RDD2022 United_States and
    China_MotorBike have damage images only)."""
    quotas: dict[str, int] = {}
    left, remaining = cap, dict(sizes)
    while remaining:
        share = left // len(remaining)
        small = {s: n for s, n in remaining.items() if n <= share}
        if not small:
            for i, s in enumerate(sorted(remaining)):
                quotas[s] = share + (1 if i < left - share * len(remaining) else 0)
            break
        for s, n in small.items():
            quotas[s] = n
            left -= n
            del remaining[s]
    return quotas


def sample_groups(pool: list[Item], quota: int, rng: random.Random) -> list[Item]:
    """About `quota` images taken as whole groups (a group never straddles the cut)."""
    if len(pool) <= quota:
        return list(pool)
    groups: dict[str, list[Item]] = defaultdict(list)
    for item in pool:
        groups[item.group].append(item)
    order = sorted(groups)
    rng.shuffle(order)
    taken: list[Item] = []
    for g in order:
        if len(taken) >= quota:
            break
        taken += groups[g]
    return taken


def cap_class(pool: list[Item], cap: int, rng: random.Random) -> list[Item]:
    """At most ~`cap` images of one class, shared evenly across its sources."""
    by_source: dict[str, list[Item]] = defaultdict(list)
    for item in pool:
        by_source[item.source].append(item)
    quotas = fair_quotas({s: len(v) for s, v in by_source.items()}, cap)
    kept: list[Item] = []
    for source in sorted(by_source):
        kept += sample_groups(by_source[source], quotas[source], rng)
    return kept


# ---------------------------------------------------------------- build


def collect() -> list[Item]:
    items: list[Item] = []
    for country in sources.RDD_COUNTRIES:
        items += _rdd_items(country)
    items += _flood10k_items()
    items += _alley_items()
    return items


def build(*, cap: int = CLASS_CAP) -> dict:
    rng = random.Random(SEED)
    items = collect()
    raw_counts = Counter((i.source, i.label) for i in items)
    # AlleyFloodNet is small and closest to what riders photograph: never capped away.
    alley = [i for i in items if i.source == "alleyfloodnet"]
    rest = [i for i in items if i.source != "alleyfloodnet"]
    alley_per_class = Counter(i.label for i in alley)
    capped: list[Item] = list(alley)
    for label in CLASSES:
        pool = [i for i in rest if i.label == label]
        capped += cap_class(pool, max(cap - alley_per_class[label], 0), rng)

    out_dir = INTERIM / "images"
    bench_dir = INTERIM / "bench"
    for d in (out_dir, bench_dir):
        if d.exists():
            for old in d.glob("*.jpg"):
                old.unlink()
        d.mkdir(parents=True, exist_ok=True)
    bench_left = Counter(dict.fromkeys(CLASSES, BENCH_PER_CLASS))
    seen = NearDuplicateIndex()
    conflicts: set[str] = set()  # ids of kept images that a copy with another label collided with
    kept: list[Item] = []
    dropped = Counter()
    # Alley first so its copy wins when another source re-posted the same photo.
    capped.sort(key=lambda i: (i.source != "alleyfloodnet", i.source, i.member))
    open_zips: dict[str, zipfile.ZipFile] = {}
    try:
        for item in capped:
            if item.zip_name not in open_zips:
                open_zips[item.zip_name] = zipfile.ZipFile(RAW / item.zip_name)
            try:
                image = load_image(open_zips[item.zip_name].read(item.member))
            except Exception:  # noqa: BLE001 - a broken file is skipped and counted, not fatal
                dropped["unreadable"] += 1
                continue
            item.dhash = dhash(image)
            item.id = hashlib.sha256(f"{item.zip_name}:{item.member}".encode()).hexdigest()[:16]
            prior = seen.find(item.dhash)
            if prior is not None:
                if prior.label != item.label:
                    conflicts.add(prior.id)
                dropped["duplicate"] += 1
                continue
            seen.add(item)
            if item.split is None:
                item.split = group_split(item.group)
            shrink(image).save(out_dir / f"{item.id}.jpg", "JPEG", quality=90)
            if item.split == "test" and bench_left[item.label] > 0 and rng.random() < 0.1:
                # Latency set: the photo as the backend would forward it (JPEG, longest side <= 1600).
                bench = image.copy()
                bench.thumbnail((1600, 1600), Image.Resampling.LANCZOS)
                bench.save(bench_dir / f"{item.id}.jpg", "JPEG", quality=85)
                bench_left[item.label] -= 1
            kept.append(item)
    finally:
        for zf in open_zips.values():
            zf.close()
    if conflicts:
        for item in kept:
            if item.id in conflicts:
                dropped["label_conflict"] += 1
                (out_dir / f"{item.id}.jpg").unlink(missing_ok=True)
                (bench_dir / f"{item.id}.jpg").unlink(missing_ok=True)
        kept = [i for i in kept if i.id not in conflicts]

    with (INTERIM / "manifest.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(asdict(kept[0]).keys()))
        writer.writeheader()
        writer.writerows(asdict(i) for i in sorted(kept, key=lambda i: i.id))
    summary = {
        "seed": SEED,
        "class_cap": cap,
        "rdd_group": RDD_GROUP,
        "raw_counts": {f"{s}|{label}": n for (s, label), n in sorted(raw_counts.items())},
        "dropped": dict(dropped),
        "kept": {
            split: {label: sum(1 for i in kept if i.split == split and i.label == label) for label in CLASSES}
            for split in SPLITS
        },
        "kept_by_source": {
            f"{s}|{label}|{split}": n
            for (s, label, split), n in sorted(Counter((i.source, i.label, i.split) for i in kept).items())
        },
    }
    (INTERIM / "build_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return summary


def read_manifest(path: Path | None = None) -> list[dict[str, str]]:
    with (path or INTERIM / "manifest.csv").open(encoding="utf-8") as f:
        return list(csv.DictReader(f))
