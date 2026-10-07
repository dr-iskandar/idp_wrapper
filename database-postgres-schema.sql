-- Production-oriented PostgreSQL schema matching the MVP domain model.
-- API keys should be stored using a secrets manager / KMS in production, not in this table.
CREATE TABLE providers (
  id text PRIMARY KEY,
  name text NOT NULL,
  kind text NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  base_url text,
  default_model text,
  models jsonb NOT NULL DEFAULT '[]'::jsonb,
  secret_ref text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE routes (document_type text PRIMARY KEY, provider_id text NOT NULL REFERENCES providers(id), model text NOT NULL DEFAULT '');
CREATE TABLE document_schemas (id text PRIMARY KEY, label text NOT NULL, enabled boolean NOT NULL DEFAULT true, fields jsonb NOT NULL DEFAULT '[]'::jsonb);
CREATE TABLE validation_rules (id text PRIMARY KEY, definition jsonb NOT NULL);
CREATE TABLE cases (id text PRIMARY KEY, case_number text UNIQUE NOT NULL, case_type text NOT NULL, customer_name text, reference_number text, status text NOT NULL, created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL);
CREATE TABLE documents (id text PRIMARY KEY, case_id text NOT NULL REFERENCES cases(id) ON DELETE CASCADE, filename text, document_type text, mime_type text, processing_status text, storage_path text, checksum text, ai_provider text, ai_model text, ai_usage jsonb, ai_latency_ms integer, uploaded_at timestamptz);
CREATE TABLE extracted_fields (id text PRIMARY KEY, document_id text NOT NULL REFERENCES documents(id) ON DELETE CASCADE, field_name text NOT NULL, raw_value text, normalized_value text, verified_value text, confidence numeric, source_page integer, evidence_text text, bbox jsonb, needs_review boolean, verification_status text, provenance jsonb);
CREATE TABLE validation_results (id text PRIMARY KEY, case_id text NOT NULL REFERENCES cases(id) ON DELETE CASCADE, rule_id text, result jsonb NOT NULL);
CREATE TABLE audit_logs (id text PRIMARY KEY, case_id text NOT NULL REFERENCES cases(id) ON DELETE CASCADE, actor text, action text NOT NULL, entity_type text, entity_id text, metadata jsonb, created_at timestamptz NOT NULL DEFAULT now());
CREATE INDEX idx_documents_case ON documents(case_id);
CREATE INDEX idx_fields_document ON extracted_fields(document_id);
CREATE INDEX idx_audit_case_created ON audit_logs(case_id, created_at DESC);
