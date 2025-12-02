-- #############################################################################
-- ## STORE ASSETS & PAGES MIGRATION
-- #############################################################################

-- -----------------------------------------------------------------------------
-- -- Update Stores Table
-- -----------------------------------------------------------------------------
ALTER TABLE "stores" 
ADD COLUMN "config" JSONB NOT NULL DEFAULT '{"modules": {"gsap": false, "alpine_intersect": false, "alpine_persist": false}}',
ADD COLUMN "custom_css" TEXT,
ADD COLUMN "custom_js_head" TEXT,
ADD COLUMN "custom_js_body" TEXT,
ADD COLUMN "compiled_css_url" VARCHAR(512); -- URL to the generated static CSS file

-- -----------------------------------------------------------------------------
-- -- Create Pages Table (Landing Pages)
-- -----------------------------------------------------------------------------
CREATE TABLE "pages" (
    "id"            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "store_id"      UUID NOT NULL REFERENCES "stores"("id") ON DELETE CASCADE,
    "name"          VARCHAR(255) NOT NULL,
    "slug"          VARCHAR(255) NOT NULL,
    "content"       JSONB, -- Published content structure
    "draft_content" JSONB, -- Draft content (Real-time editor state)
    "is_published"  BOOLEAN NOT NULL DEFAULT FALSE,
    "type"          VARCHAR(50) NOT NULL DEFAULT 'general', -- 'general', 'landing', 'product_override'
    
    -- Page-specific assets
    "custom_css"    TEXT,
    "custom_js_head" TEXT,
    "custom_js_body" TEXT,
    
    "created_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ON "pages" ("store_id");
CREATE UNIQUE INDEX "pages_store_slug_idx" ON "pages" ("store_id", "slug");

CREATE TRIGGER update_pages_updated_at BEFORE UPDATE ON "pages" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
