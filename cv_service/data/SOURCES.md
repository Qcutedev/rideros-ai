# Data Sources — road photo classifier

This file is the only thing under `cv_service/data/` that is committed. Every image, zip and derived
file stays local (`.gitignore`). Nothing here is redistributed, and the trained weights
(`cv_service/artifacts/`) are not committed either.

The license review was done on 2026-11-12 (Phase 5, P5c), before any training. Its result is below.

## Summary

| Dataset | Used for | License (where checked) | Result |
|---|---|---|---|
| RDD2022 | `road_damage`, and plain roads for `other` | **CC BY 4.0** (figshare API, official record) | Pass |
| AlleyFloodNet | `flooding` and `other` (non-flooding alleys) | **CC BY 4.0** (Kaggle dataset page / API) | Pass, see the provenance note |
| Flood10k | `flooding` (the "flooded" folder only) | **CC BY-NC 4.0** (Mendeley Data + its README) | Pass for this non-commercial project, see the provenance note |
| torchvision | model code | BSD-3-Clause | Pass |
| MobileNetV3-Large ImageNet-1k weights (`IMAGENET1K_V2`) | starting weights | No license of their own. They are trained on ImageNet, whose terms allow non-commercial research and education only | Pass, because this project is non-commercial (it already depends on CC BY-NC Meituan data) |

**Consequence:** the classifier is treated as **non-commercial**, the same as the Pickup model.
Commercial use would need Flood10k removed, weights not derived from ImageNet, and a fresh license review.

## 1. RDD2022 (used)

| Item | Value |
|---|---|
| Title | RDD2022 – The multi-national Road Damage Dataset released through CRDDC'2022 |
| Record | figshare article 21431547, version 1, DOI `10.6084/m9.figshare.21431547.v1` |
| License | CC BY 4.0 (`license` field of `https://api.figshare.com/v2/articles/21431547`) |
| Paper | Arya et al., *RDD2022: A multi-national image dataset for automatic Road Damage Detection*, arXiv:2209.08538 |
| Who took the photos | The dataset authors' teams, with smartphones mounted on vehicles or motorbikes (and a drone for China_Drone) |
| Used | `China_MotorBike`, `Czech`, `India`, `United_States`, **train** folders only (the test folders have no labels) |
| Not used | `China_Drone` (aerial view) and `Norway` (10.6 GB of wide, high-resolution frames) |

The figshare file is one 13.3 GB zip that stores one zip per country without compression.
`python -m training download` reads the outer zip's central directory through HTTP Range requests and
downloads only the four country zips (about 1.4 GB). It checks each one against the CRC-32 in that
directory and against the SHA-256 pin below.

Labels: an image with at least one `D00`/`D10`/`D20`/`D40` box (longitudinal, transverse and alligator
cracks, and potholes) is `road_damage`. An image with no box is `other` (a plain road). An image that
only has other box types (for example `Repair`, or India's `D44`) is not used.

| File (local name) | Bytes | SHA-256 |
|---|---|---|
| `RDD2022_China_MotorBike.zip` | 192,030,116 | `2acdc8b8527c9b36cce4ba97dfdd5be9090be32f588c31b769a08c1a41c0c274` |
| `RDD2022_Czech.zip` | 257,117,218 | `94c65a4e6cfed187b193ba967f0a2b16bd4287dfe313d0962f3711afce75bf1d` |
| `RDD2022_India.zip` | 526,709,145 | `28eab0aa85638855e1907e63b175be2305a0accd018c54603037d3fb8cab963a` |
| `RDD2022_United_States.zip` | 444,335,958 | `597e8bcf1ffbe80d6c8295fbf99ebab5651c9e4efe961f9d38a9ed4ad10b957e` |

Attribution: D. Arya, H. Maeda, S. K. Ghosh, D. Toshniwal, Y. Sekimoto, *RDD2022*, figshare, CC BY 4.0.
Changes made: images were re-encoded and resized for training.

## 2. AlleyFloodNet (used)

| Item | Value |
|---|---|
| Page | https://www.kaggle.com/datasets/seonyseony/alleyfloodnet (version 1, 67 MB) |
| License | CC BY 4.0 ("Attribution 4.0 International", Kaggle dataset metadata) |
| Paper | O. Lee, H. Joo, *AlleyFloodNet: A Ground-Level Image Dataset for Rapid Flood Detection in Economically and Flood-Vulnerable Areas*, Electronics 14(10), 2082 (2025), DOI `10.3390/electronics14102082` (the paper is also CC BY 4.0) |
| Content | 1,110 ground-level photos: flooding and non-flooding alleys and low-lying streets. The published split is train 468/380, val 79/90, test 133/129 (flooding/non-flooding) |
| How to get it | Kaggle requires signing in, so the zip is downloaded by hand and passed to `python -m training download --alley <zip>` |

The published train/val/test split is kept as it is.

**Provenance note:** the paper says the images were "collected from diverse regions worldwide". It does not
say who took each photo. The CC BY 4.0 grant comes from the dataset publisher. Rights in individual
photos the publisher did not take may sit with third parties.

## 3. Flood10k (used: flooded images only)

| Item | Value |
|---|---|
| Record | Mendeley Data `4sgcd7zdsp`, version 1, DOI `10.17632/4sgcd7zdsp.1` |
| License | CC BY-NC 4.0 (Mendeley page and README) |
| Authors | A. Odebode, A. Bennett Milburn (2025) |
| Content | 10,419 images: 5,093 flooded and 5,326 normal. Only `flooded` is used (the user's decision, 2026-11-12) |
| File | `Flood10k.zip`, 747,365,154 bytes, SHA-256 `304474a533c8b78a7fe9bd1caa03f15ae0465decd8ad89d8bd3ac8b920aee706` (the hash Mendeley publishes; it matches the download) |

**Provenance note:** the README says the flooded images were aggregated from CrisisMMD (Twitter), the
Twitter Flood Dataset and FloodIMG (Kaggle). The CC BY-NC license covers the compilation. The individual
photos come from social media and the web, so their authors keep their rights. The README asks users
to also cite the original sources:

- F. Alam, F. Ofli, M. Imran, *CrisisMMD: Multimodal Twitter Datasets from Natural Disasters*, ICWSM 2018.
- B. Barz et al., *Finding Relevant Flood Images on Twitter Using Content-Based Filters*, ICPR 2021.
- R. Karanjit, R. Pally, V. Samadi, *FloodIMG: Flood Image DataBase System*, Kaggle (2022), DOI `10.34740/KAGGLE/DS/1864149`.

## 4. Dependencies in the service image (D6, third part)

These were listed from package metadata inside `rideros-cv` (built 2026-11-12, CPU torch). All are
permissive. There is no GPL or AGPL package, and no Ultralytics.

| Package | Version | License |
|---|---|---|
| torch (CPU) | 2.15.0+cpu | Apache-2.0 AND Apache-2.0 WITH LLVM-exception AND BSD-2-Clause AND BSD-3-Clause AND BSL-1.0 AND ISC AND MIT AND Zlib |
| torchvision (CPU) | 0.29.2+cpu | BSD-3-Clause |
| numpy | 2.5.4 | BSD-3-Clause AND 0BSD AND MIT AND Zlib AND CC0-1.0 |
| pillow | 13.0.0 | MIT-CMU |
| fastapi / starlette / uvicorn | 0.162.5 / 1.10.0 / 0.54.0 | MIT / BSD-3-Clause / BSD-3-Clause |
| pydantic, pydantic-core, pydantic-settings | 2.14.3, 2.50.4, 2.16.2 | MIT |
| python-multipart | 0.0.33 | Apache-2.0 |
| sympy, mpmath, networkx, jinja2, markupsafe, filelock, fsspec (torch dependencies) | — | BSD / MIT |
| anyio, h11, idna, click, annotated-types, annotated-doc, typing-extensions, typing-inspection, python-dotenv, setuptools, opentelemetry-api | — | MIT / BSD-3-Clause / PSF-2.0 / Apache-2.0 |

## What follows from the provenance notes

- No image and no derived image is committed, published or shipped. The service image contains code only.
- The model is used in the app only as a suggestion with a confidence and an "estimate" label (HANDOFF §4.11, decision 10).
- None of the three datasets contains photos from Thailand. The domain shift is stated in the model card.
