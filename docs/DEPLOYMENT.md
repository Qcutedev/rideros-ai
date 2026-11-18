# Deployment — RiderOS AI (Phase 7)

- การตัดสินใจ: HANDOFF §4.15 (Oracle Cloud Always Free ARM · `sslip.io` + Caddy · Build บน Server · 2 Workers + Valkey · Backup รายวัน 7 ชุด · Release keystore นอก Repo)
- ไฟล์: `deploy/compose.prod.yml`, `deploy/Caddyfile`, `deploy/db/Dockerfile`, `deploy/prod.env.example`, `deploy/backup.sh`, `deploy/restore_test.sh`, `deploy/restore.sh`, `deploy/smoke_test.py`
- สถานะ: P7a ทดสอบทั้ง Stack ในเครื่อง (Docker Desktop, `API_DOMAIN=localhost`) และ Build arm64 ผ่านแล้ว · P7b = Deploy จริงตามเอกสารนี้ แล้วเติมผลใน §8

## 1. ภาพรวม

```
Internet ──443/80──► caddy (172.30.0.10, TLS อัตโนมัติ, HSTS, เปิดเฉพาะ /api/v1/*)
                       │  edge network
                       ▼
                    backend (uvicorn 2 workers, ENV=production, เชื่อ X-Forwarded-For จาก Caddy เท่านั้น)
                       │  internal network (ไม่มีทางออก Internet)
          ┌────────────┼──────────────┐
          ▼            ▼              ▼
     db (PostGIS)  valkey (rate limit) cv (photo classifier)
```

- มีแค่ Caddy ที่เปิด Port · DB, Valkey, CV ไม่มี Port ออกนอก Docker
- Model artifacts ส่งด้วย `scp` และ Mount แบบอ่านอย่างเดียว ไม่อยู่ใน Repo, Image หรือ Registry (D4)
- Flood10k (CC BY-NC 4.0) ในโมเดลจัดประเภทรูป → ระบบนี้ใช้แบบไม่แสวงหากำไรเท่านั้น: ไม่มีโฆษณา ไม่มีส่วนที่เก็บเงิน

| Service | Image | หมายเหตุ |
|---|---|---|
| caddy | `caddy:2.10.2-alpine` | IP คงที่ `172.30.0.10` (ใช้ใน `FORWARDED_ALLOW_IPS`) |
| backend | Build จาก `backend/Dockerfile` | `WEB_CONCURRENCY=2` · `RATE_LIMIT_STORAGE_URL=redis://valkey:6379/0` · Settings ไม่ยอมให้หลาย Worker กับ `memory://` |
| db | Build จาก `deploy/db/Dockerfile` (`postgres:18.7-trixie` + PGDG PostGIS 3) | `postgis/postgis` มีแค่ amd64 · PGDG มีแค่ PostGIS ตัวล่าสุด (3.7.0) ส่วน Dev ใช้ 3.6.4 (Dump 3.6 Restore ลง 3.7 ได้) |
| valkey | `valkey/valkey:8.1.4-alpine` (BSD-3) | ไม่เก็บลง Disk · `maxmemory 64mb` |
| cv | Build จาก `cv_service/Dockerfile` | `CV_THREADS=2` |

## 2. เตรียม Server (ครั้งเดียว)

ผู้ใช้สมัคร Oracle Cloud เอง (ต้องใช้บัตรยืนยันตัวตน) แล้วสร้าง VM:

1. Compute → Instance: Shape **VM.Standard.A1.Flex** (Ampere ARM) 4 OCPU / 24 GB · Image **Ubuntu 24.04** · ใส่ SSH public key · Boot volume 50 GB ขึ้นไป
   - ถ้าขึ้น "Out of capacity" ให้ลอง Availability domain อื่นหรือลองใหม่ภายหลัง · ทางสำรอง: VPS x86 (Hetzner ~€4–5/เดือน) ใช้ไฟล์ชุดเดียวกันได้
2. Networking → VCN → Security list: เพิ่ม Ingress TCP 80 และ 443 จาก `0.0.0.0/0` (22 มีอยู่แล้ว)
3. Image ของ Oracle มี iptables ที่ปิดทุก Port ยกเว้น 22 → เปิด 80/443 บนเครื่องด้วย:
   ```sh
   sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
   sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
   sudo iptables -I INPUT 6 -m state --state NEW -p udp --dport 443 -j ACCEPT
   sudo netfilter-persistent save
   ```
4. ติดตั้ง Docker Engine + Compose plugin ตามเอกสาร Docker สำหรับ Ubuntu แล้ว `sudo usermod -aG docker $USER` (Logout/Login ใหม่)
5. อัปเดตความปลอดภัยอัตโนมัติ: `sudo apt install unattended-upgrades` · SSH ใช้ Key อย่างเดียว (`PasswordAuthentication no`)

## 3. Deploy ครั้งแรก

```sh
# บน Server
sudo mkdir -p /opt/rideros && sudo chown $USER /opt/rideros
ssh-keygen -t ed25519 -f ~/.ssh/rideros_deploy -N ""      # แล้วใส่ .pub เป็น Deploy key (Read-only) ของ GitHub Repo
GIT_SSH_COMMAND="ssh -i ~/.ssh/rideros_deploy" git clone git@github.com:<owner>/<repo>.git /opt/rideros/app
mkdir -p /opt/rideros/artifacts/cv /opt/rideros/backups
```

```powershell
# บนเครื่อง Dev (PowerShell): ส่ง Artifact ไปตรงๆ ห้ามผ่าน Git
scp -r "C:\dev\RiderOS AI\cv_service\artifacts\road_cv" <user>@<ip>:/opt/rideros/artifacts/cv/
```

```sh
# บน Server
cd /opt/rideros/app
cp deploy/prod.env.example deploy/.env && chmod 600 deploy/.env
#   API_DOMAIN=api.<ip แบบขีด>.sslip.io เช่น 203.0.113.7 → api.203-0-113-7.sslip.io
#   POSTGRES_PASSWORD / JWT_SECRET: python3 -c "import secrets; print(secrets.token_urlsafe(48))"
docker compose -f deploy/compose.prod.yml up -d --build --wait
python3 deploy/smoke_test.py https://$API_DOMAIN       # ต้องได้ SMOKE TEST PASSED
```

- Backend รัน Migration เองทุกครั้งที่เริ่ม (`backend/scripts/entrypoint.sh`)
- Caddy ขอใบรับรอง Let's Encrypt ตอนมี Request แรก (Port 80 ต้องเปิดจาก Internet)

## 4. อัปเดตเวอร์ชัน

```sh
cd /opt/rideros/app
GIT_SSH_COMMAND="ssh -i ~/.ssh/rideros_deploy" git pull --ff-only
sh deploy/backup.sh                                       # Backup ก่อนทุกครั้งที่มี Migration
docker compose -f deploy/compose.prod.yml up -d --build --wait
python3 deploy/smoke_test.py https://$API_DOMAIN
```

## 5. Backup

- `deploy/backup.sh`: `pg_dump --format=custom` + tar ของรูป RoadContext → `BACKUP_DIR` (ค่าเริ่มต้น `/opt/rideros/backups`) · เก็บใหม่สุด `BACKUP_KEEP` ชุด (7) · เขียนเป็น `.part` ก่อนแล้วค่อยเปลี่ยนชื่อ จึงไม่มีไฟล์ที่ดูครบแต่เสีย · ไฟล์ Mode 600 (มีข้อมูลส่วนบุคคล)
- Cron รายวัน (`crontab -e`):
  ```
  15 3 * * * /opt/rideros/app/deploy/backup.sh >> /opt/rideros/backups/backup.log 2>&1
  ```
- Backup อยู่บน Disk เดียวกับ DB → ป้องกันความผิดพลาดของข้อมูล แต่ไม่ป้องกัน VM หาย · ดึงสำเนาลงเครื่องตัวเองเป็นระยะ: `scp <user>@<ip>:/opt/rideros/backups/db-*.dump .`

## 6. Restore

**ทดสอบ Backup (ไม่แตะระบบจริง):**
```sh
sh deploy/restore_test.sh /opt/rideros/backups/db-<ts>.dump /opt/rideros/backups/images-<ts>.tar.gz
```
Restore ลง Container ชั่วคราว (`--network none`) จาก Image ของ db ตัวเดียวกัน แล้วเทียบกับ DB จริง: จำนวนแถวทุกตาราง, Migration revision, PostGIS version, จำนวนไฟล์รูป → `RESTORE TEST PASSED` / Exit 0 · ควรรันทันทีหลัง Backup (แถวที่เขียนระหว่างนั้นจะขึ้นเป็นความต่าง)

**กู้ระบบจริง (ลบข้อมูลปัจจุบัน):**
```sh
sh deploy/restore.sh --yes /opt/rideros/backups/db-<ts>.dump /opt/rideros/backups/images-<ts>.tar.gz
```
หยุด Backend → DROP + CREATE Database → `pg_restore` → แทนที่รูป → เปิด Backend จน Healthy

## 7. Release APK

- Keystore: `%USERPROFILE%\.rideros\rideros-upload.jks` (PKCS12, RSA 4096, Alias `upload`, อายุ 10,000 วัน) · รหัสผ่านอยู่ใน `mobile/android/key.properties` (gitignored)
- **ต้อง Backup ทั้ง 2 ไฟล์ไว้นอกเครื่อง** (เช่น Password manager + Drive ส่วนตัว): ถ้าหาย จะออกเวอร์ชันใหม่ทับแอปเดิมไม่ได้
- ไม่มี `key.properties` → Release build ไม่ถูกเซ็น (Gradle เตือน) ติดตั้งไม่ได้ แทนการแอบใช้ Debug key
- Build (arm64 ตัวเดียว · Release บังคับ https):
  ```powershell
  cd "C:\dev\RiderOS AI\mobile"
  flutter build apk --release --target-platform android-arm64 --dart-define=API_BASE_URL=https://<API_DOMAIN>/api/v1
  & "$env:LOCALAPPDATA\Android\Sdk\build-tools\<version>\apksigner.bat" verify --print-certs build\app\outputs\flutter-apk\app-release.apk
  ```
- Certificate ปัจจุบัน: DN `CN=RiderOS AI, O=RiderOS AI` · SHA-256 `46e29e8947528c758034f9f675cf7c04ab1f7efcf5727c6d869cfc2bd89e4ab3`

## 8. ผลทดสอบ

### 8.1 P7a — ในเครื่อง (2026-11-15, Docker Desktop, `API_DOMAIN=localhost` → Caddy ใช้ CA ภายใน)

| ตรวจ | ผล |
|---|---|
| `up -d --build --wait` | ทุก Service healthy · Backend 2 Worker (`Started server process` ×2, `rate_limit_storage: redis`) |
| `/api/v1/ready` ผ่าน Caddy | `database ok`, `model ok (pickup_o2p/1.0.0)`, `rate_limit ok` |
| Production switches | `/docs`, `/openapi.json`, `/` → 404 · HTTP → 308 HTTPS · มี HSTS, `nosniff` |
| `X-Forwarded-For` ปลอม | Login 7 ครั้งด้วย XFF ต่างกัน → 401 ×5 แล้ว 429 ×2 · Key ใน Valkey เป็น IP จริงของ Peer ไม่ใช่ค่าปลอม · นับรวมทั้ง 2 Worker |
| `deploy/smoke_test.py` | **15/15 PASSED** (รวม Pickup prediction ด้วยโมเดลจริง และรูปที่ CV จัดประเภทเสร็จ) · ผลตอนนั้น: Pickup ถูกเอาออกเมื่อ 2026-11-18 (§4.20 ใน HANDOFF) Smoke test เหลือ 13 ข้อ และ `/ready` ไม่มี `model` แล้ว |
| `backup.sh` | Dump 1.49 MB + รูป · `BACKUP_KEEP=2` เหลือ 2 ชุดถูกต้อง |
| `restore_test.sh` | **PASSED** 17 ตาราง + Migration `0004` + PostGIS 3.7.0 + รูป 1 ไฟล์ · Restore 1 s · ทดสอบกลับด้าน: เพิ่ม 1 แถวใน DB จริง → FAILED ชี้ `income_records 6 vs 5` |
| Disaster drill | ลบ Volume DB + รูป → `restore.sh --yes` → Login บัญชีเดิมได้, รายได้ 5 รายการ, รูปเปิดได้ (`image/jpeg`), AI label ยังอยู่ |
| arm64 (`docker buildx --platform linux/arm64`, QEMU) | Backend: import xgboost 3.4.1 / sklearn 1.9.1 ได้ · CV: torch 2.15.0+cpu คำนวณได้ · db: PostgreSQL 18.7 + PostGIS 3.7.0 + `pg_trgm` + `btree_gist` |

- บน Windows Git Bash ต้องตั้ง `MSYS_NO_PATHCONV=1` ก่อนรัน `backup.sh`/`restore_test.sh` (ไม่งั้น `/data/...` ถูกแปลงเป็น `C:/Program Files/Git/data/...`) · บน Linux ไม่ต้อง
- Docker Desktop ส่ง Peer เป็น Gateway (`172.30.0.1`) ไม่ใช่ IP ของ Client · บน Linux (iptables DNAT) ต้องเห็น IP จริงของ Client → ตรวจใน P7b

### 8.2 P7b — Server จริง

(ยังไม่ทำ)
