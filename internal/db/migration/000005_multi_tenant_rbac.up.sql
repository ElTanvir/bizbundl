-- #############################################################################
-- ## MULTI-TENANT & RBAC MIGRATION
-- #############################################################################

CREATE TYPE "role_scope" AS ENUM ('saas', 'store');

-- -----------------------------------------------------------------------------
-- -- Tenants (The Paying Entity)
-- -----------------------------------------------------------------------------
CREATE TABLE "tenants" (
    "id"            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "name"          VARCHAR(255) NOT NULL,
    "billing_email" VARCHAR(255),
    "status"        VARCHAR(50) NOT NULL DEFAULT 'active',
    "created_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON "tenants" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- -- Stores (The Shopfronts)
-- -----------------------------------------------------------------------------
CREATE TABLE "stores" (
    "id"            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "tenant_id"     UUID NOT NULL REFERENCES "tenants"("id") ON DELETE CASCADE,
    "name"          VARCHAR(255) NOT NULL,
    "slug"          VARCHAR(255) UNIQUE NOT NULL, -- Globally unique (subdomain)
    "domain"        VARCHAR(255) UNIQUE, -- Custom domain
    "settings"      JSONB NOT NULL DEFAULT '{}',
    "created_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ON "stores" ("tenant_id");
CREATE TRIGGER update_stores_updated_at BEFORE UPDATE ON "stores" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- -- Roles (RBAC)
-- -----------------------------------------------------------------------------
CREATE TABLE "roles" (
    "id"            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "tenant_id"     UUID REFERENCES "tenants"("id") ON DELETE CASCADE, -- NULL for System Roles
    "name"          VARCHAR(255) NOT NULL,
    "description"   TEXT,
    "scope"         role_scope NOT NULL,
    "permissions"   TEXT[] NOT NULL DEFAULT '{}', -- Native Postgres Array for max performance
    "is_template"   BOOLEAN NOT NULL DEFAULT FALSE, -- Exportable templates
    "created_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ON "roles" ("tenant_id");
-- GIN index on the array allows for super-fast containment queries: WHERE permissions @> ARRAY['product:read']
CREATE INDEX ON "roles" USING GIN ("permissions");
CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON "roles" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- -- User Roles Mapping
-- -----------------------------------------------------------------------------
CREATE TABLE "user_store_roles" (
    "user_id"       UUID NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
    "store_id"      UUID NOT NULL REFERENCES "stores"("id") ON DELETE CASCADE,
    "role_id"       UUID NOT NULL REFERENCES "roles"("id") ON DELETE CASCADE,
    PRIMARY KEY ("user_id", "store_id", "role_id")
);

CREATE TABLE "user_saas_roles" (
    "user_id"       UUID NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
    "role_id"       UUID NOT NULL REFERENCES "roles"("id") ON DELETE CASCADE,
    PRIMARY KEY ("user_id", "role_id")
);

-- -----------------------------------------------------------------------------
-- -- Update Users Table
-- -----------------------------------------------------------------------------
ALTER TABLE "users" ADD COLUMN "is_saas_admin" BOOLEAN NOT NULL DEFAULT FALSE;

-- -----------------------------------------------------------------------------
-- -- Refactor Existing Tables for Multi-Store
-- -----------------------------------------------------------------------------

-- Products
-- Note: In a production migration, we would need to migrate data. 
-- Here we assume it's safe to add nullable columns or we'd truncate.
-- We'll make it nullable for now to avoid errors on existing data, 
-- but application logic should enforce it.
ALTER TABLE "products" ADD COLUMN "store_id" UUID REFERENCES "stores"("id") ON DELETE CASCADE;
CREATE INDEX ON "products" ("store_id");

-- Drop global slug uniqueness and make it unique per store
ALTER TABLE "products" DROP CONSTRAINT IF EXISTS "products_slug_key";
CREATE UNIQUE INDEX "products_store_slug_idx" ON "products" ("store_id", "slug");

-- Categories
ALTER TABLE "categories" ADD COLUMN "store_id" UUID REFERENCES "stores"("id") ON DELETE CASCADE;
CREATE INDEX ON "categories" ("store_id");

ALTER TABLE "categories" DROP CONSTRAINT IF EXISTS "categories_slug_key";
CREATE UNIQUE INDEX "categories_store_slug_idx" ON "categories" ("store_id", "slug");

-- Option Templates
ALTER TABLE "option_templates" ADD COLUMN "store_id" UUID REFERENCES "stores"("id") ON DELETE CASCADE;
CREATE INDEX ON "option_templates" ("store_id");
