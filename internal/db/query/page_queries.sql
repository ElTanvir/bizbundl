-- #############################################################################
-- ## PAGES (Landing Pages & Custom Designs)
-- #############################################################################

-- name: CreatePage :one
INSERT INTO pages (
    store_id, name, slug, content, draft_content, is_published, type,
    custom_css, custom_js_head, custom_js_body
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10
) RETURNING *;

-- name: GetPage :one
SELECT * FROM pages
WHERE id = $1 LIMIT 1;

-- name: GetPageBySlug :one
SELECT * FROM pages
WHERE store_id = $1 AND slug = $2 LIMIT 1;

-- name: ListPages :many
SELECT * FROM pages
WHERE store_id = $1
ORDER BY updated_at DESC;

-- name: UpdatePage :one
UPDATE pages
SET 
    name = COALESCE(sqlc.narg('name'), name),
    slug = COALESCE(sqlc.narg('slug'), slug),
    content = COALESCE(sqlc.narg('content'), content),
    draft_content = COALESCE(sqlc.narg('draft_content'), draft_content),
    is_published = COALESCE(sqlc.narg('is_published'), is_published),
    type = COALESCE(sqlc.narg('type'), type),
    custom_css = COALESCE(sqlc.narg('custom_css'), custom_css),
    custom_js_head = COALESCE(sqlc.narg('custom_js_head'), custom_js_head),
    custom_js_body = COALESCE(sqlc.narg('custom_js_body'), custom_js_body)
WHERE id = $1 AND store_id = $2
RETURNING *;

-- name: DeletePage :exec
DELETE FROM pages
WHERE id = $1 AND store_id = $2;

-- name: PublishPage :one
-- Copies draft_content to content and sets is_published = true
UPDATE pages
SET 
    content = draft_content,
    is_published = TRUE,
    updated_at = now()
WHERE id = $1 AND store_id = $2
RETURNING *;
