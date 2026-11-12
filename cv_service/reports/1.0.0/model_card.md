# Model Card - road_cv 1.0.0

## Intended use
Portfolio / educational demo. The classifier looks at **one photo attached to a RoadContext report** and
suggests a category: `flooding`, `road_damage` or `other`. The app shows it as
"AI แนะนำ: <หมวด> (xx%)" with the `ค่าประมาณ` badge, or "AI ไม่แน่ใจ" below 0.6 confidence.

It does **not** decide where a road is flooded or blocked. Location, status and "มีผู้รายงานหลายคน" come
from rider reports only. The suggestion never changes a report's category or status, and it is never
shown as "ยืนยันแล้ว".

Not for commercial use (Flood10k is CC BY-NC 4.0 and the starting weights come from ImageNet). The weights
in `cv_service/artifacts/` and the datasets are not redistributed.

## Model
- MobileNetV3-Large, torchvision `IMAGENET1K_V2` weights, new 3-class head.
- Training: 3 epochs head only (lr 1e-3), then the whole network (lr 3e-4, cosine), AdamW, weight decay
  1e-4, label smoothing 0.1, batch 64, seed 42. Early stop after 4 epochs without a validation gain.
- Kept: fine-tune epoch 6 (best validation macro-F1 0.8831). Trained in 278 s on an RTX 3060 Laptop GPU.
- Input: shorter side resized to 256, centre crop 224, ImageNet mean/std.
- Weights SHA-256 `e2e3da1bb36da3ecb7d5c6115c3574945ae5a4d476793f73dcdb726eb352c56d`
  (torch 2.15.0, torchvision 0.29.2). `git_commit` in the metadata is `528477e-dirty`: training ran
  on the uncommitted AlleyFloodNet layout fix that was committed after it.

## Data
Licenses and SHA-256 pins: `cv_service/data/SOURCES.md`. Build: `cv_service/data/interim/build_summary.json`.

| Class | Sources |
|---|---|
| `flooding` | AlleyFloodNet `flooded` (ground-level alleys), Flood10k `flooded` (web photos) |
| `road_damage` | RDD2022 images with at least one D00/D10/D20/D40 box: China_MotorBike, Czech, India, United_States |
| `other` | RDD2022 images with no box (Czech, India), AlleyFloodNet `non_flooded` |

| Split | flooding | road_damage | other | Total |
|---|---|---|---|---|
| train | 2,008 | 2,072 | 2,026 | 6,106 |
| val | 405 | 516 | 419 | 1,340 |
| test | 485 | 375 | 520 | 1,380 |

- Each class is capped at 3,000 images, shared evenly across its sources. AlleyFloodNet is never capped.
- Near-duplicates (dHash within 3 bits) are kept once: 189 dropped. 6 images whose copy had another
  label were dropped.
- Leakage guards: RDD2022 frames go to a split in blocks of 25 consecutive numbers. AlleyFloodNet keeps
  its published train/test split; its Kaggle zip has no val folder, so ~15/85 of its train images moved to
  val by a fixed hash. Flood10k is split per image after de-duplication.

## Results (test split, read once by `python -m training evaluate`)

| Metric | Value |
|---|---|
| Accuracy | **0.8804** (n = 1,380) |
| Macro-F1 | **0.8755** |
| Baseline: always the majority train class (`road_damage`) | accuracy 0.2717 |

| Class | Precision | Recall | F1 | Support |
|---|---|---|---|---|
| flooding | 0.9717 | 0.9897 | 0.9806 | 485 |
| road_damage | 0.7969 | 0.8160 | 0.8063 | 375 |
| other | 0.8546 | 0.8250 | 0.8395 | 520 |

Confusion matrix (rows = true, columns = predicted), also in `confusion_matrix.png`:

| | flooding | road_damage | other |
|---|---|---|---|
| **flooding** | 480 | 1 | 4 |
| **road_damage** | 0 | 306 | 69 |
| **other** | 14 | 77 | 429 |

Accuracy by source (test):

| Source and true class | Accuracy | n |
|---|---|---|
| AlleyFloodNet flooding | 0.9839 | 124 |
| AlleyFloodNet other (dry alleys) | 0.8624 | 109 |
| Flood10k flooding | 0.9917 | 361 |
| RDD2022 China_MotorBike road_damage | 1.0000 | 47 |
| RDD2022 United_States road_damage | 1.0000 | 125 |
| RDD2022 India road_damage | 0.7778 | 72 |
| RDD2022 India other | 0.8108 | 222 |
| RDD2022 Czech road_damage | 0.5954 | 131 |
| RDD2022 Czech other | 0.8201 | 189 |

**UI threshold 0.6:** 91.4% of test photos reach it (shown as "AI แนะนำ"). Their accuracy is 0.9136. The
other 8.6% are shown as "AI ไม่แน่ใจ".

**Latency:** median 19.4 ms, p95 24.9 ms per photo on the host CPU, 1 thread, 60 test photos at upload
size (longest side 1,600 px), decode and preprocessing included. In the `cv` docker container (CPU torch,
1 thread, same 60 photos, `Classifier.classify`): median 16.5 ms, p95 22.8 ms. Both on the dev laptop
(12 logical CPUs); a small cloud VM will be slower.

**End to end (2026-11-12):** a report with a photo sent through the backend API came back with
`ai_status = done`, `ai_label = flooding`, `ai_confidence = 0.917`, and a `model_versions` row
`road_cv/1.0.0`. The app showed "AI แนะนำ: น้ำท่วม (92%)" with the `ค่าประมาณ` badge on the emulator.

## Limitations
- **No photos from Thailand.** Thai sois, monsoon flooding and Thai road surfaces are not in the data, so
  real-world accuracy for RiderOS users is unknown and is likely lower than the test numbers.
- **Shortcut risk on road damage.** RDD2022 United_States and China_MotorBike have damage images only, so
  the camera and scene of those countries alone predict `road_damage`. Their 100% test accuracy reflects
  this, not crack detection. The fair view is Czech and India, where both classes come from the same
  cameras: 0.60 and 0.78 on damage. Small cracks are the main error (`road_damage` vs `other`).
- **Flooding is easier than it looks.** Flood10k photos are web images (news, social media) that differ in
  style from street-level road photos. AlleyFloodNet, the source closest to rider photos, is the better
  guide: 0.98 on flooded alleys and 0.86 on dry ones. Across all sources, 14 of the 520 `other` test
  photos were called `flooding`, a false flood suggestion rate of 2.7%.
- **Three classes only.** Accidents, closed roads and obstacles have no training data. They are predicted
  as one of the three classes, usually `other`.
- Provenance: AlleyFloodNet and Flood10k contain photos their publishers did not take (see SOURCES.md).
- One training run, one seed. No confidence calibration beyond label smoothing.
