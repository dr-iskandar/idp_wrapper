# PVS IDP — AI Document Verification Wrapper

WKT Verify adalah **model-agnostic AI document verification layer** untuk banking dan enterprise workflow. Produk ini bukan sekadar OCR: AI dipakai untuk memahami dan mengekstrak dokumen, sementara normalisasi, rule validation, cross-document comparison, human review, provenance, audit, dan verified output dikontrol oleh WKT Verify.

## Fitur utama

- UI baru berbasis **Tailwind CSS + Manrope** dengan identitas visual PVS (white / charcoal / blue-cyan).\n- **Comparison Lab**: custom reference field + value → Table Viewer → compare dengan file upload.\n- **File A vs File B**: extract dua dokumen lalu tampilkan similarity percentage per field + overall similarity.\n- Similarity dihitung oleh engine deterministik setelah extraction: fuzzy text/name, normalized identifier/date, dan relative numeric/currency comparison.\n- Multi-provider **AI Gateway** dengan provider dropdown + model dropdown + custom model ID.
- BYOK (Bring Your Own Key) untuk OpenAI, Google Gemini, Alibaba Qwen, Kimi/Moonshot, DeepSeek, serta endpoint OpenAI-compatible lain.
- **Ollama Local** untuk menjalankan model lokal/on-premise tanpa mengirim dokumen ke cloud.
- Routing provider + model per document type: KTP, NPWP, Bank Statement, Salary Slip, Loan Application, Invoice, dan Unknown.
- Custom model ID jika model terbaru belum ada di dropdown.
- Schema Builder untuk mendefinisikan field per document type.
- Rule Builder untuk cross-document comparison dan required-field validation.
- Review Queue untuk mismatch, missing field/document, dan low-confidence extraction.
- Evidence/provenance per field: provider, model, page, evidence text, confidence, dan bounding box jika tersedia.
- Audit trail, human correction/verification, export JSON/CSV.
- SQLite runtime database dan reference schema PostgreSQL.
- API key provider disimpan terenkripsi AES-256-GCM dan tidak pernah dikirim kembali ke browser.

---

# 1. Requirements

Minimal:

- **Node.js 22.5+** (Node 22 LTS atau lebih baru direkomendasikan)
- npm

Opsional:

- **Ollama** jika ingin memakai local model
- API key OpenAI / Gemini / Qwen / Kimi / DeepSeek jika ingin memakai cloud model

Aplikasi ini tidak memiliki dependency npm runtime tambahan. Database memakai built-in `node:sqlite`.

Cek versi Node:

```bash
node -v
npm -v
```

Jika Node masih di bawah 22.5, upgrade terlebih dahulu.

---

# 2. Clone dan start aplikasi

```bash
git clone https://github.com/dr-iskandar/idp_wrapper.git
cd idp_wrapper
cp .env.example .env.local
npm start
```

Buka browser:

```text
http://localhost:3000
```

Untuk development mode saat ini:

```bash
npm run dev
```

`npm start` dan `npm run dev` saat ini sama-sama menjalankan `server.mjs`.

---

# 3. Environment configuration

File template tersedia di:

```text
.env.example
```

Copy menjadi:

```bash
cp .env.example .env.local
```

Contoh:

```env
OPENAI_API_KEY=
OPENAI_MODEL=gpt-6-luna

APP_MASTER_KEY=

OLLAMA_BASE_URL=http://localhost:11434
PORT=3000
```

## OPENAI_API_KEY

Opsional. Bisa diisi melalui `.env.local` sebagai fallback, atau dimasukkan dari halaman **AI Gateway**.

## APP_MASTER_KEY

Digunakan untuk mengenkripsi API key provider di database.

Untuk local development, jika kosong aplikasi otomatis membuat:

```text
data/.master.key
```

File tersebut masuk `.gitignore` dan **jangan pernah di-commit**.

Untuk server/staging/production, set `APP_MASTER_KEY` dari secret manager/deployment environment agar key tetap stabil di setiap restart/deployment.

## OLLAMA_BASE_URL

Default:

```text
http://localhost:11434
```

## PORT

Default aplikasi:

```text
3000
```

---

# 4. Database — langsung siap pakai

Runtime database menggunakan **SQLite**.

Saat aplikasi pertama kali dijalankan:

1. folder `data/` diperiksa;
2. aplikasi membuat `data/wkt-verify.sqlite` jika belum ada;
3. schema database dibuat otomatis;
4. 5 synthetic demo cases dibuat otomatis dari `seed.mjs`;
5. sesudah itu aplikasi membaca dan menulis data melalui SQLite.

Jadi tidak perlu menjalankan MySQL/PostgreSQL/Docker untuk local MVP.

Runtime database:

```text
data/wkt-verify.sqlite
```

File SQLite tidak di-commit ke GitHub karena merupakan runtime state.

Tabel utama:

```text
providers
routes
schemas
rules
cases
documents
extracted_fields
validations
audit_logs
meta
```

### Reset database local

Stop aplikasi, lalu:

```bash
rm -f data/wkt-verify.sqlite data/wkt-verify.sqlite-shm data/wkt-verify.sqlite-wal
npm start
```

Aplikasi akan membuat ulang database dan 5 synthetic demo cases dari `seed.mjs`.

Jika juga ingin mereset encryption master key local:

```bash
rm -f data/.master.key
```

> Jangan hapus `data/.master.key` pada environment yang sudah menyimpan API key provider, karena API key lama tidak akan bisa didekripsi dengan master key baru.

### PostgreSQL

Reference schema tersedia di:

```text
database-postgres-schema.sql
```

File ini adalah baseline untuk migrasi production. MVP saat ini tetap menggunakan SQLite agar setup demo cepat.

---

# 5. Menjalankan dengan OpenAI

Ada dua cara.

### Cara A — Environment variable

Isi `.env.local`:

```env
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-6-luna
```

Restart aplikasi:

```bash
npm start
```

### Cara B — AI Gateway

1. Buka **AI Gateway**.
2. Pilih provider **OpenAI**.
3. Masukkan API key.
4. Klik **Test & Refresh Models**.
5. Pilih model dari dropdown atau `Custom model...`.
6. Save configuration.
7. Atur routing document type ke OpenAI/model yang diinginkan.

API key disimpan encrypted di SQLite. API konfigurasi hanya mengembalikan status `keyConfigured`, bukan nilai key asli.

---

# 6. Gemini, Qwen, Kimi dan DeepSeek

Masuk ke **AI Gateway** lalu pilih provider yang diinginkan.

Untuk setiap provider:

1. aktifkan provider;
2. isi Base URL bila perlu;
3. masukkan API key;
4. klik **Test & Refresh Models**;
5. pilih model dari dropdown;
6. jika model belum muncul, pilih `Custom model...` dan masukkan model ID;
7. Save Configuration;
8. pilih provider/model tersebut pada **Document Routing**.

Provider cloud generic menggunakan adapter OpenAI-compatible pada MVP ini. Base URL sengaja editable supaya dapat disesuaikan jika vendor/enterprise gateway menggunakan endpoint berbeda.

---

# 7. Ollama local / on-premise

Install Ollama terlebih dahulu, lalu jalankan:

```bash
ollama serve
```

Di terminal lain:

```bash
ollama list
```

Pastikan ada model vision-capable jika ingin memproses gambar dokumen.

Contoh alur:

```text
Document image
  ↓
WKT Verify
  ↓
Ollama @ localhost:11434
  ↓
Local vision model
  ↓
Structured extraction
  ↓
WKT validation / review / audit
```

Di aplikasi:

1. buka **AI Gateway**;
2. pilih **Ollama Local**;
3. Base URL: `http://localhost:11434`;
4. klik **Discover local models**;
5. pilih model dari dropdown;
6. Save Configuration;
7. pada Document Routing, contoh:
   - KTP → Ollama → local vision model
   - NPWP → Ollama → local vision model
   - Bank Statement → OpenAI/Qwen/Gemini

Dengan skenario ini, dokumen yang diroute ke Ollama diproses oleh model lokal, bukan provider cloud.

---

# 8. Model routing

Ada dua level konfigurasi model:

### Provider default model

Contoh:

```text
OpenAI → gpt-6-luna
Gemini → default Gemini model
Qwen → selected Qwen model
Ollama → selected local model
```

### Per-document routing

Contoh:

```text
KTP              → Ollama → Local Vision Model
NPWP             → Gemini → Gemini model
BANK_STATEMENT   → Qwen → Qwen VL model
SALARY_SLIP      → OpenAI → GPT model
LOAN_APPLICATION → OpenAI → GPT model
```

Setiap model control memiliki dropdown dan opsi **Custom model...**.

---

# 9. Cara mencoba end-to-end

## A. Demo data

Saat database baru dibuat, dashboard sudah memiliki synthetic/sample banking cases.

Buka:

```text
Dashboard → Cases
```

Gunakan sample cases untuk melihat:

- match;
- mismatch;
- low confidence;
- missing document;
- review queue;
- audit trail.

## B. Upload case baru

1. Buka **New Case**.
2. Isi customer/case information.
3. Upload PDF/PNG/JPG/JPEG.
4. Simpan case.
5. Buka detail case.
6. Process document dengan AI.
7. Sistem memilih provider/model berdasarkan routing.
8. Extraction disimpan ke database.
9. Validation engine menjalankan rules.
10. Jika mismatch atau confidence rendah, case masuk Review Queue.
11. Reviewer mengoreksi/approve field.
12. Validation dijalankan ulang.
13. Case bisa di-approve.
14. Export hasil sebagai JSON/CSV.

---

# 10. Schema Builder

Schema menentukan field yang ingin diekstrak dari setiap document type.

Contoh KTP:

```text
nik
name
birth_place
birth_date
gender
address
```

Schema dapat diubah dari UI tanpa mengubah provider AI.

Artinya workflow tetap sama walaupun model di belakangnya diganti dari OpenAI ke Ollama/Gemini/Qwen.

---

# 11. Rule Builder

Rule engine menjalankan validasi deterministic setelah extraction.

Contoh:

```text
KTP.name == NPWP.name
KTP.nik == LOAN_APPLICATION.nik
KTP.name == SALARY_SLIP.employee_name
BANK_STATEMENT.account_holder == KTP.name
NPWP.npwp is required
```

Model AI tidak menentukan final banking decision. AI menghasilkan candidate data; WKT Verify melakukan rules, exception handling, dan human review.

---

# 12. Test

Jalankan:

```bash
npm test
```

Test suite mencakup:

- normalization;
- mismatch detection;
- Ollama model discovery;
- Ollama structured vision extraction;
- OpenAI-compatible model discovery;
- OpenAI-compatible multimodal extraction;
- SQLite initialization;
- encrypted provider secret persistence.

---

# 13. Folder structure

```text
.
├── server.mjs
├── db.mjs
├── lib.mjs
├── providers/
│   ├── openai.mjs
│   ├── compatible.mjs
│   └── ollama.mjs
├── public/
│   └── index.html
├── storage/
│   └── uploads/
├── data/
│   └── .gitkeep
├── seed.mjs
├── tests/
├── database-postgres-schema.sql
├── .env.example
└── package.json
```

Runtime-only files seperti `.env.local`, `data/.master.key`, `data/*.sqlite`, dan uploaded customer documents tidak boleh di-commit. Demo case fresh-install dibuat oleh `seed.mjs`, jadi repository tidak perlu menyimpan database binary.

---

# 14. Security note

Ini masih **MVP / product demonstration**, belum merupakan klaim banking compliance.

Sebelum production deployment tambahkan/harden:

- PostgreSQL HA / managed database;
- enterprise SSO / MFA;
- full RBAC dan maker-checker;
- KMS/HSM/Vault-backed secret management;
- encrypted object storage;
- malware scanning;
- network allowlist/private endpoints;
- PII masking / selective page-region transmission;
- retention & deletion policies;
- immutable audit retention;
- async queue/workers, retry, dead-letter queue;
- observability, token/cost telemetry, rate limit dan circuit breaker;
- model evaluation, golden dataset dan shadow testing;
- provider-neutral PDF page rendering untuk full local/on-prem processing.

---

# 15. Recommended production architecture

```text
Bank / Enterprise System
        │
        ▼
    WKT Verify API
        │
        ├── Workflow / Schema / Rule Engine
        ├── Review & Audit
        ├── Model Router
        │      ├── OpenAI
        │      ├── Gemini
        │      ├── Qwen
        │      ├── Kimi
        │      ├── DeepSeek
        │      └── Ollama / Private Model
        │
        ├── PostgreSQL
        ├── Object Storage
        └── Async Worker / Queue
```

Prinsip produk:

> **AI proposes. WKT Verify validates. Human decides.**
