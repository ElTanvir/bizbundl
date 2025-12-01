-- #############################################################################
-- ## DIGITAL INVENTORY MIGRATION
-- #############################################################################

-- -----------------------------------------------------------------------------
-- -- Product Keys (Digital Inventory)
-- -----------------------------------------------------------------------------
-- Stores unique codes, license keys, or account credentials that are "consumed"
-- upon purchase.
CREATE TABLE "product_keys" (
    "id"            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "variant_id"    UUID NOT NULL REFERENCES "product_variants"("id") ON DELETE CASCADE,
    "key_value"     TEXT NOT NULL, -- The actual key, code, or account details
    "is_used"       BOOLEAN NOT NULL DEFAULT FALSE,
    "order_id"      UUID, -- Reference to the order that consumed this key (nullable for now)
    "used_at"       TIMESTAMPTZ,
    "created_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index for finding available keys quickly. This is CRITICAL for performance
-- when assigning keys during checkout.
CREATE INDEX ON "product_keys" ("variant_id") WHERE "is_used" = FALSE;

-- Trigger for updated_at
CREATE TRIGGER update_product_keys_updated_at
BEFORE UPDATE ON "product_keys"
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
