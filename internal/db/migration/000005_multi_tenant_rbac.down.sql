-- Revert Option Templates
ALTER TABLE "option_templates" DROP COLUMN IF EXISTS "store_id";

-- Revert Categories
DROP INDEX IF EXISTS "categories_store_slug_idx";
ALTER TABLE "categories" ADD CONSTRAINT "categories_slug_key" UNIQUE ("slug");
ALTER TABLE "categories" DROP COLUMN IF EXISTS "store_id";

-- Revert Products
DROP INDEX IF EXISTS "products_store_slug_idx";
ALTER TABLE "products" ADD CONSTRAINT "products_slug_key" UNIQUE ("slug");
ALTER TABLE "products" DROP COLUMN IF EXISTS "store_id";

-- Revert Users
ALTER TABLE "users" DROP COLUMN IF EXISTS "is_saas_admin";

-- Drop New Tables
DROP TABLE IF EXISTS "user_saas_roles";
DROP TABLE IF EXISTS "user_store_roles";
DROP TABLE IF EXISTS "roles";
DROP TABLE IF EXISTS "stores";
DROP TABLE IF EXISTS "tenants";

DROP TYPE IF EXISTS "role_scope";
