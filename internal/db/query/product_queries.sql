-- #############################################################################
-- ## CATEGORIES
-- #############################################################################

-- name: CreateCategory :one
INSERT INTO categories (
    parent_id, name, slug, description, is_active
) VALUES (
    $1, $2, $3, $4, $5
) RETURNING *;

-- name: GetCategory :one
SELECT * FROM categories
WHERE id = $1 LIMIT 1;

-- name: GetCategoryBySlug :one
SELECT * FROM categories
WHERE slug = $1 LIMIT 1;

-- name: ListCategories :many
SELECT * FROM categories
ORDER BY name ASC;

-- name: UpdateCategory :one
UPDATE categories
SET 
    parent_id = COALESCE(sqlc.narg('parent_id'), parent_id),
    name = COALESCE(sqlc.narg('name'), name),
    slug = COALESCE(sqlc.narg('slug'), slug),
    description = COALESCE(sqlc.narg('description'), description),
    is_active = COALESCE(sqlc.narg('is_active'), is_active)
WHERE id = $1
RETURNING *;

-- name: DeleteCategory :exec
DELETE FROM categories
WHERE id = $1;

-- #############################################################################
-- ## PRODUCTS
-- #############################################################################

-- name: CreateProduct :one
INSERT INTO products (
    name, slug, description, is_active, is_digital
) VALUES (
    $1, $2, $3, $4, $5
) RETURNING *;

-- name: GetProduct :one
SELECT * FROM products
WHERE id = $1 LIMIT 1;

-- name: GetProductBySlug :one
SELECT * FROM products
WHERE slug = $1 LIMIT 1;

-- name: ListProducts :many
SELECT p.* FROM products p
LEFT JOIN product_categories pc ON p.id = pc.product_id
WHERE 
    (sqlc.narg('category_id')::uuid IS NULL OR pc.category_id = sqlc.narg('category_id'))
    AND (sqlc.narg('search')::text IS NULL OR 
         p.name ILIKE '%' || sqlc.narg('search') || '%' OR 
         p.description ILIKE '%' || sqlc.narg('search') || '%')
    AND (sqlc.narg('is_active')::boolean IS NULL OR p.is_active = sqlc.narg('is_active'))
ORDER BY p.created_at DESC
LIMIT $1 OFFSET $2;

-- name: UpdateProduct :one
UPDATE products
SET 
    name = COALESCE(sqlc.narg('name'), name),
    slug = COALESCE(sqlc.narg('slug'), slug),
    description = COALESCE(sqlc.narg('description'), description),
    is_active = COALESCE(sqlc.narg('is_active'), is_active),
    is_digital = COALESCE(sqlc.narg('is_digital'), is_digital)
WHERE id = $1
RETURNING *;

-- name: DeleteProduct :exec
UPDATE products
SET deleted_at = now()
WHERE id = $1;

-- name: AssignCategoryToProduct :exec
INSERT INTO product_categories (product_id, category_id)
VALUES ($1, $2)
ON CONFLICT DO NOTHING;

-- name: RemoveCategoryFromProduct :exec
DELETE FROM product_categories
WHERE product_id = $1 AND category_id = $2;

-- #############################################################################
-- ## OPTIONS & VARIANTS
-- #############################################################################

-- name: CreateProductOption :one
INSERT INTO product_options (product_id, name, position)
VALUES ($1, $2, $3)
RETURNING *;

-- name: CreateProductOptionValue :one
INSERT INTO product_option_values (option_id, value, position)
VALUES ($1, $2, $3)
RETURNING *;

-- name: CreateProductVariant :one
INSERT INTO product_variants (
    product_id, sku, price, stock_quantity, is_active
) VALUES (
    $1, $2, $3, $4, $5
) RETURNING *;

-- name: ListProductVariants :many
SELECT * FROM product_variants
WHERE product_id = $1
ORDER BY created_at ASC;

-- name: GetVariant :one
SELECT * FROM product_variants
WHERE id = $1 LIMIT 1;

-- name: AssignOptionValueToVariant :exec
INSERT INTO variant_option_values (variant_id, option_value_id)
VALUES ($1, $2)
ON CONFLICT DO NOTHING;

-- #############################################################################
-- ## OPTION TEMPLATES
-- #############################################################################

-- name: CreateOptionTemplate :one
INSERT INTO option_templates (name, template_data)
VALUES ($1, $2)
RETURNING *;

-- name: GetOptionTemplate :one
SELECT * FROM option_templates
WHERE id = $1 LIMIT 1;

-- name: ListOptionTemplates :many
SELECT * FROM option_templates
ORDER BY name ASC;

-- name: DeleteOptionTemplate :exec
DELETE FROM option_templates
WHERE id = $1;

-- #############################################################################
-- ## DIGITAL INVENTORY
-- #############################################################################

-- name: CreateProductKey :one
INSERT INTO product_keys (variant_id, key_value)
VALUES ($1, $2)
RETURNING *;

-- name: GetAvailableKey :one
-- Retrieves an available key for a variant and locks the row
-- to prevent race conditions during checkout.
SELECT * FROM product_keys
WHERE variant_id = $1 AND is_used = FALSE
LIMIT 1
FOR UPDATE SKIP LOCKED;

-- name: MarkKeyAsUsed :one
UPDATE product_keys
SET 
    is_used = TRUE,
    used_at = now(),
    order_id = $2
WHERE id = $1
RETURNING *;
