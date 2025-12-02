-- #############################################################################
-- ## TENANTS
-- #############################################################################

-- name: CreateTenant :one
INSERT INTO tenants (name, billing_email, status)
VALUES ($1, $2, $3)
RETURNING *;

-- name: GetTenant :one
SELECT * FROM tenants
WHERE id = $1 LIMIT 1;

-- name: ListTenants :many
SELECT * FROM tenants
ORDER BY created_at DESC;

-- #############################################################################
-- ## STORES
-- #############################################################################

-- name: CreateStore :one
INSERT INTO stores (
    tenant_id, name, slug, domain, settings,
    config, custom_css, custom_js_head, custom_js_body
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9
) RETURNING *;

-- name: UpdateStore :one
UPDATE stores
SET 
    name = COALESCE(sqlc.narg('name'), name),
    slug = COALESCE(sqlc.narg('slug'), slug),
    domain = COALESCE(sqlc.narg('domain'), domain),
    settings = COALESCE(sqlc.narg('settings'), settings),
    config = COALESCE(sqlc.narg('config'), config),
    custom_css = COALESCE(sqlc.narg('custom_css'), custom_css),
    custom_js_head = COALESCE(sqlc.narg('custom_js_head'), custom_js_head),
    custom_js_body = COALESCE(sqlc.narg('custom_js_body'), custom_js_body),
    compiled_css_url = COALESCE(sqlc.narg('compiled_css_url'), compiled_css_url)
WHERE id = $1
RETURNING *;

-- name: GetStore :one
SELECT * FROM stores
WHERE id = $1 LIMIT 1;

-- name: GetStoreBySlug :one
SELECT * FROM stores
WHERE slug = $1 LIMIT 1;

-- name: GetStoreByDomain :one
SELECT * FROM stores
WHERE domain = $1 LIMIT 1;

-- name: ListStoresByTenant :many
SELECT * FROM stores
WHERE tenant_id = $1
ORDER BY name ASC;

-- #############################################################################
-- ## ROLES & PERMISSIONS
-- #############################################################################

-- name: CreateRole :one
INSERT INTO roles (tenant_id, name, description, scope, permissions, is_template)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING *;

-- name: ListRolesByTenant :many
SELECT * FROM roles
WHERE tenant_id = $1 OR tenant_id IS NULL -- Include system roles
ORDER BY name ASC;

-- name: AssignRoleToUserInStore :exec
INSERT INTO user_store_roles (user_id, store_id, role_id)
VALUES ($1, $2, $3)
ON CONFLICT DO NOTHING;

-- name: AssignSaasRoleToUser :exec
INSERT INTO user_saas_roles (user_id, role_id)
VALUES ($1, $2)
ON CONFLICT DO NOTHING;

-- name: GetUserStoreRoles :many
SELECT r.* FROM roles r
JOIN user_store_roles usr ON r.id = usr.role_id
WHERE usr.user_id = $1 AND usr.store_id = $2;

-- name: GetUserSaasRoles :many
SELECT r.* FROM roles r
JOIN user_saas_roles usr ON r.id = usr.role_id
WHERE usr.user_id = $1;
