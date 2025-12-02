-- #############################################################################
-- ## OPTION TEMPLATES MIGRATION
-- #############################################################################

-- -----------------------------------------------------------------------------
-- -- Option Templates
-- -----------------------------------------------------------------------------
-- Stores reusable sets of product options (e.g., "Standard T-Shirt Sizes")
-- that can be applied to new products to speed up creation.
CREATE TABLE "option_templates" (
    "id"            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "name"          VARCHAR(255) NOT NULL,
    "template_data" JSONB NOT NULL, -- Stores the structure: [{"name": "Size", "values": ["S", "M"]}]
    "created_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ON "option_templates" ("name");
-- GIN index allows for efficient querying within the JSON structure if needed later
CREATE INDEX ON "option_templates" USING GIN ("template_data");

-- Trigger for updated_at
CREATE TRIGGER update_option_templates_updated_at
BEFORE UPDATE ON "option_templates"
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
