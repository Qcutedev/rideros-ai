"""The three image datasets, their licenses (checked 2026-11-12) and SHA-256 pins.

A file with no pin, or whose hash differs from its pin, fails closed (`IntegrityError`). Pins are filled
in by hand after the first download has been reviewed. See cv_service/data/SOURCES.md for the license
review and the provenance caveats.
"""

from __future__ import annotations

from dataclasses import dataclass

# ---- RDD2022 (CC BY 4.0, figshare record 21431547 v1) ----
# One 13.3 GB zip that stores (no compression) one zip per country. Only the ground-level countries below
# are fetched, each as one HTTP range of the outer zip. China_Drone (aerial) and Norway (10.6 GB) are not.
RDD_URL = "https://ndownloader.figshare.com/files/38030910"
RDD_DOI = "10.6084/m9.figshare.21431547.v1"
RDD_COUNTRIES: tuple[str, ...] = ("China_MotorBike", "Czech", "India", "United_States")
# Pascal VOC object names counted as road damage: longitudinal (D00), transverse (D10), alligator (D20)
# cracks and potholes (D40), the four classes RDD2022 defines.
RDD_DAMAGE_CLASSES = frozenset({"D00", "D10", "D20", "D40"})

# ---- Flood10k (CC BY-NC 4.0, Mendeley Data 4sgcd7zdsp v1) ----
FLOOD10K_URL = (
    "https://data.mendeley.com/public-files/datasets/4sgcd7zdsp/files/"
    "d527906d-8c2a-4a1e-9e31-91e19452042a/file_downloaded"
)
FLOOD10K_DOI = "10.17632/4sgcd7zdsp.1"

# ---- AlleyFloodNet (CC BY 4.0, Kaggle seonyseony/alleyfloodnet v1) ----
# Kaggle needs a signed-in account, so the zip is downloaded by hand and passed to `download --alley`.
ALLEY_PAGE = "https://www.kaggle.com/datasets/seonyseony/alleyfloodnet"
ALLEY_DOI = "10.3390/electronics14102082"


@dataclass(frozen=True)
class Pin:
    filename: str
    sha256: str | None
    bytes: int | None = None


PINS: dict[str, Pin] = {
    # Hash and size as published by the Mendeley Data file API.
    "Flood10k.zip": Pin(
        "Flood10k.zip", "304474a533c8b78a7fe9bd1caa03f15ae0465decd8ad89d8bd3ac8b920aee706", 747_365_154
    ),
    # Kaggle v1 zip ("archive.zip"), downloaded by hand on 2026-11-12 and reviewed (flood_train_/flood_test_).
    "alleyfloodnet.zip": Pin(
        "alleyfloodnet.zip", "4378b0abe3f6e04937501675cbf608f243ef46298f38ee9f69c0c0520f5cb0d1", 67_114_993
    ),
    # Country zips cut out of the figshare zip on 2026-11-12; CRC-32 matched its central directory.
    "RDD2022_China_MotorBike.zip": Pin(
        "RDD2022_China_MotorBike.zip",
        "2acdc8b8527c9b36cce4ba97dfdd5be9090be32f588c31b769a08c1a41c0c274",
        192_030_116,
    ),
    "RDD2022_Czech.zip": Pin(
        "RDD2022_Czech.zip", "94c65a4e6cfed187b193ba967f0a2b16bd4287dfe313d0962f3711afce75bf1d", 257_117_218
    ),
    "RDD2022_India.zip": Pin(
        "RDD2022_India.zip", "28eab0aa85638855e1907e63b175be2305a0accd018c54603037d3fb8cab963a", 526_709_145
    ),
    "RDD2022_United_States.zip": Pin(
        "RDD2022_United_States.zip",
        "597e8bcf1ffbe80d6c8295fbf99ebab5651c9e4efe961f9d38a9ed4ad10b957e",
        444_335_958,
    ),
}
