-- #############################################################################
-- ## PRODUCT SCHEMA MIGRATION
-- #############################################################################

-- -----------------------------------------------------------------------------
-- -- Categories Table
-- -----------------------------------------------------------------------------
CREATE TABLE "categories" (
    "id"            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "parent_id"     UUID REFERENCES "categories"("id") ON DELETE SET NULL,
    "name"          VARCHAR(255) NOT NULL,
    "slug"          VARCHAR(255) UNIQUE NOT NULL,
    "description"   TEXT,
    "is_active"     BOOLEAN NOT NULL DEFAULT TRUE,
    "created_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ON "categories" ("parent_id");
CREATE INDEX ON "categories" ("slug");

-- Trigger for updated_at
CREATE TRIGGER update_categories_updated_at
BEFORE UPDATE ON "categories"
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- -- Products Table
-- -----------------------------------------------------------------------------
CREATE TABLE "products" (
    "id"            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "name"          VARCHAR(255) NOT NULL,
    "slug"          VARCHAR(255) UNIQUE NOT NULL,
    "description"   TEXT,
    "is_active"     BOOLEAN NOT NULL DEFAULT TRUE,
    "is_digital"    BOOLEAN NOT NULL DEFAULT FALSE,
    "created_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at"    TIMESTAMPTZ
);

CREATE INDEX ON "products" ("slug");
CREATE INDEX ON "products" ("deleted_at") WHERE "deleted_at" IS NULL;
-- GIN indexes for search
CREATE INDEX ON "products" USING GIN ("name" gin_trgm_ops);
CREATE INDEX ON "products" USING GIN ("description" gin_trgm_ops);

-- Trigger for updated_at
CREATE TRIGGER update_products_updated_at
BEFORE UPDATE ON "products"
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- -- Product Categories (Many-to-Many)
-- -----------------------------------------------------------------------------
CREATE TABLE "product_categories" (
    "product_id"    UUID REFERENCES "products"("id") ON DELETE CASCADE,
    "category_id"   UUID REFERENCES "categories"("id") ON DELETE CASCADE,
    PRIMARY KEY ("product_id", "category_id")
);

CREATE INDEX ON "product_categories" ("category_id");

-- -----------------------------------------------------------------------------
-- -- Product Options (e.g., Color, Size)
-- -----------------------------------------------------------------------------
CREATE TABLE "product_options" (
    "id"            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "product_id"    UUID NOT NULL REFERENCES "products"("id") ON DELETE CASCADE,
    "name"          VARCHAR(100) NOT NULL, -- e.g., "Color"
    "position"      INT NOT NULL DEFAULT 0
);

CREATE INDEX ON "product_options" ("product_id");

-- -----------------------------------------------------------------------------
-- -- Product Option Values (e.g., Red, Blue, Large)
-- -----------------------------------------------------------------------------
CREATE TABLE "product_option_values" (
    "id"            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "option_id"     UUID NOT NULL REFERENCES "product_options"("id") ON DELETE CASCADE,
    "value"         VARCHAR(100) NOT NULL, -- e.g., "Red"
    "position"      INT NOT NULL DEFAULT 0
);

CREATE INDEX ON "product_option_values" ("option_id");

-- -----------------------------------------------------------------------------
-- -- Product Variants (SKUs)
-- -----------------------------------------------------------------------------
CREATE TABLE "product_variants" (
    "id"             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "product_id"     UUID NOT NULL REFERENCES "products"("id") ON DELETE CASCADE,
    "sku"            VARCHAR(100) UNIQUE,
    "price"          DECIMAL(10, 2) NOT NULL, -- Specific price for this variant
    "stock_quantity" INT NOT NULL DEFAULT 0,
    "is_active"      BOOLEAN NOT NULL DEFAULT TRUE,
    "created_at"     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at"     TIMESTAMPTZ
);

CREATE INDEX ON "product_variants" ("product_id");
CREATE INDEX ON "product_variants" ("sku");
CREATE INDEX ON "product_variants" ("deleted_at") WHERE "deleted_at" IS NULL;

-- Trigger for updated_at
CREATE TRIGGER update_product_variants_updated_at
BEFORE UPDATE ON "product_variants"
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- -- Variant Option Values (Junction for Variant -> Option Values)
-- -----------------------------------------------------------------------------
-- Links a variant to specific values (e.g., Variant A is linked to "Red" and "Large")
CREATE TABLE "variant_option_values" (
    "variant_id"      UUID REFERENCES "product_variants"("id") ON DELETE CASCADE,
    "option_value_id" UUID REFERENCES "product_option_values"("id") ON DELETE CASCADE,
    PRIMARY KEY ("variant_id", "option_value_id")
);

-- -----------------------------------------------------------------------------
-- -- Digital Assets (for Digital Products)
-- -----------------------------------------------------------------------------
CREATE TABLE "digital_assets" (
    "id"             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "variant_id"     UUID NOT NULL REFERENCES "product_variants"("id") ON DELETE CASCADE,
    "name"           VARCHAR(255) NOT NULL,
    "file_path"      VARCHAR(512) NOT NULL, -- Path to file in storage (S3, local, etc.)
    "file_size"      BIGINT, -- Size in bytes
    "content_type"   VARCHAR(100), -- MIME type
    "download_count" INT NOT NULL DEFAULT 0,
    "created_at"     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ON "digital_assets" ("variant_id");

-- Trigger for updated_at
CREATE TRIGGER update_digital_assets_updated_at
BEFORE UPDATE ON "digital_assets"
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
