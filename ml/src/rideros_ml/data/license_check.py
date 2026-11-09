"""License gate (Decision D1): the pipeline refuses to run if the dataset license text changed.

The SHA-256 pin of License.txt is enforced by download.verify_pin; this module additionally checks
that the clauses our usage depends on are present verbatim, so a silent license change cannot slip through.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

REQUIRED_CLAUSES: dict[str, str] = {
    "license_cc_by_nc_4": "Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)",
    "no_redistribution": "the distribution of this dataset to third parties is not allowed",
    "non_commercial_only": "this dataset is intended for non-commercial use only",
    "acknowledgement": "This research was supported by data provided by Meituan.",
}

ACKNOWLEDGEMENT = REQUIRED_CLAUSES["acknowledgement"]


@dataclass(frozen=True)
class LicenseCheck:
    clause: str
    present: bool


def check_license_text(text: str) -> list[LicenseCheck]:
    normalized = " ".join(text.split())
    return [LicenseCheck(name, phrase in normalized) for name, phrase in REQUIRED_CLAUSES.items()]


def check_license_file(path: Path) -> list[LicenseCheck]:
    return check_license_text(path.read_text(encoding="utf-8"))
