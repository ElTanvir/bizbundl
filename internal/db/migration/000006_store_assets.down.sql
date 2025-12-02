-- Drop Pages Table
DROP TABLE IF EXISTS "pages";

-- Revert Stores Table
ALTER TABLE "stores"
DROP COLUMN IF EXISTS "compiled_css_url",
DROP COLUMN IF EXISTS "custom_js_body",
DROP COLUMN IF EXISTS "custom_js_head",
DROP COLUMN IF EXISTS "custom_css",
DROP COLUMN IF EXISTS "config";
