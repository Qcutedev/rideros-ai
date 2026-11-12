from __future__ import annotations

import io
import random

import pytest
from PIL import Image, ImageDraw

from training import download, sources
from training.build import (
    Item,
    NearDuplicateIndex,
    _alley_label,
    _alley_split,
    alley_val,
    cap_class,
    dhash,
    fair_quotas,
    group_split,
    sample_groups,
)
from training.evaluate import confusion, per_class
from training.train import macro_f1


def _scene(seed: int) -> Image.Image:
    rng = random.Random(seed)
    image = Image.new("RGB", (400, 300), (rng.randrange(256), rng.randrange(256), rng.randrange(256)))
    draw = ImageDraw.Draw(image)
    for _ in range(12):
        x, y = rng.randrange(400), rng.randrange(300)
        draw.rectangle(
            (x, y, x + 60, y + 40), fill=(rng.randrange(256), rng.randrange(256), rng.randrange(256))
        )
    return image


def _bits(a: str, b: str) -> int:
    return (int(a, 16) ^ int(b, 16)).bit_count()


def _recompressed(image: Image.Image) -> Image.Image:
    buf = io.BytesIO()
    image.save(buf, "JPEG", quality=70)
    return Image.open(buf)


def test_dhash_is_close_for_a_recompressed_copy_and_far_for_another_photo():
    a = _scene(1)
    assert _bits(dhash(a), dhash(_recompressed(a))) <= 3
    assert _bits(dhash(a), dhash(_scene(2))) > 12


def _item(name: str, image: Image.Image, label: str = "flooding") -> Item:
    item = Item("s", "z", name, label, name, id=name)
    item.dhash = dhash(image)
    return item


def test_near_duplicate_index_finds_copies_only():
    index = NearDuplicateIndex()
    original = _item("a", _scene(1))
    index.add(original)
    assert index.find(_item("b", _recompressed(_scene(1))).dhash) is original
    assert index.find(_item("c", _scene(2)).dhash) is None


def test_near_duplicate_index_respects_the_bit_limit():
    index = NearDuplicateIndex(max_bits=3)
    base = Item("s", "z", "a", "other", "a", dhash=f"{0:016x}")
    index.add(base)
    # Three flipped bits spread over three quarters: still a copy. Four: not.
    assert index.find(f"{(1 << 0) | (1 << 20) | (1 << 40):016x}") is base
    assert index.find(f"{(1 << 0) | (1 << 20) | (1 << 40) | (1 << 60):016x}") is None


def test_group_split_is_deterministic_and_roughly_70_15_15():
    groups = [f"rdd2022/Czech/{i}" for i in range(3000)]
    first = [group_split(g) for g in groups]
    assert first == [group_split(g) for g in groups]
    share = {s: first.count(s) / len(first) for s in ("train", "val", "test")}
    assert share["train"] == pytest.approx(0.70, abs=0.03)
    assert share["val"] == pytest.approx(0.15, abs=0.03)


def test_fair_quotas_give_leftovers_to_larger_sources():
    assert fair_quotas({"a": 100, "b": 5000, "c": 5000}, 1000) == {"a": 100, "b": 450, "c": 450}
    assert sum(fair_quotas({"a": 10, "b": 20}, 1000).values()) == 30
    assert fair_quotas({"a": 999, "b": 999}, 1001) == {"a": 501, "b": 500}


def _items(source: str, n: int, group_size: int) -> list[Item]:
    return [
        Item(source, "z", f"{source}/{i}", "road_damage", f"{source}/{i // group_size}") for i in range(n)
    ]


def test_sample_groups_keeps_whole_groups():
    taken = sample_groups(_items("s", 100, 10), 35, random.Random(0))
    groups = {i.group for i in taken}
    assert len(taken) == 10 * len(groups)
    assert 35 <= len(taken) <= 45


def test_cap_class_shares_the_cap_across_sources():
    pool = _items("us", 1000, 25) + _items("czech", 1000, 25) + _items("china", 40, 1)
    kept = cap_class(pool, 300, random.Random(0))
    counts = {s: sum(1 for i in kept if i.source == s) for s in ("us", "czech", "china")}
    assert counts["china"] == 40
    assert 130 <= counts["us"] <= 155 and 130 <= counts["czech"] <= 155


@pytest.mark.parametrize(
    ("parts", "label", "split"),
    [
        (("AlleyFloodNet", "train", "flooding"), "flooding", "train"),
        (("AlleyFloodNet", "Validation", "non-flooding"), "other", "val"),
        (("test", "Non_Flooding"), "other", "test"),
        (("test", "readme"), None, "test"),
        # Kaggle v1 layout: the label is the leaf folder, the split hides in "flood_train_".
        (("AlleyFloodNet", "flood_train_", "flooded"), "flooding", "train"),
        (("AlleyFloodNet", "flood_train_", "non_flooded"), "other", "train"),
        (("AlleyFloodNet", "flood_test_", "non_flooded"), "other", "test"),
        (("AlleyFloodNet", "flood_test_"), None, "test"),
    ],
)
def test_alley_folder_names(parts, label, split):
    assert _alley_label(parts) == label
    assert _alley_split(parts) == split


def test_alley_val_is_stable_and_about_15_of_85():
    members = [f"AlleyFloodNet/flood_train_/flooded/{i}.jpg" for i in range(4000)]
    picked = [m for m in members if alley_val(m)]
    assert picked == [m for m in members if alley_val(m)]
    assert 0.15 < len(picked) / len(members) < 0.21


def test_metrics_helpers():
    t = ["flooding", "flooding", "other", "road_damage"]
    p = ["flooding", "other", "other", "road_damage"]
    pc = per_class(t, p)
    assert pc["flooding"] == {"precision": 1.0, "recall": 0.5, "f1": 0.6667, "support": 2}
    assert confusion(t, p) == [[1, 0, 1], [0, 1, 0], [0, 0, 1]]
    assert macro_f1([0, 0, 2, 1], [0, 2, 2, 1], 3) == pytest.approx((2 / 3 + 1 + 2 / 3) / 3)


def test_unpinned_or_changed_files_fail_closed(tmp_path, monkeypatch):
    f = tmp_path / "Flood10k.zip"
    f.write_bytes(b"not the real zip")
    with pytest.raises(download.IntegrityError, match="hash mismatch"):
        download.verify_pin(f)
    other = tmp_path / "unknown.zip"
    other.write_bytes(b"x")
    with pytest.raises(download.IntegrityError, match="no SHA-256 pin"):
        download.verify_pin(other)
    monkeypatch.setitem(
        sources.PINS, "unknown.zip", sources.Pin("unknown.zip", download.sha256_file(other), 2)
    )
    with pytest.raises(download.IntegrityError, match="size mismatch"):
        download.verify_pin(other)
