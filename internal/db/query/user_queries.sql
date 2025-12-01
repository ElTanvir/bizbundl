-- name: CreateUser :one
INSERT INTO users (
    username,
    hashed_password,
    first_name,
    last_name,
    email,
    phone,
    role
) VALUES (
    $1, $2, $3, $4, $5, $6, $7
) RETURNING *;

-- name: GetUserById :one
SELECT * FROM users
WHERE id = $1 LIMIT 1;

-- name: GetUserByEmail :one
SELECT * FROM users
WHERE email = $1 LIMIT 1;

-- name: GetUserByUsername :one
SELECT * FROM users
WHERE username = $1 LIMIT 1;

-- name: ListUsers :many
SELECT * FROM users
WHERE 
    (sqlc.narg('role')::user_role IS NULL OR role = sqlc.narg('role'))
    AND (sqlc.narg('search')::text IS NULL OR 
         first_name ILIKE '%' || sqlc.narg('search') || '%' OR 
         last_name ILIKE '%' || sqlc.narg('search') || '%' OR 
         email ILIKE '%' || sqlc.narg('search') || '%' OR 
         username ILIKE '%' || sqlc.narg('search') || '%')
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: UpdateUser :one
UPDATE users
SET 
    first_name = COALESCE(sqlc.narg('first_name'), first_name),
    last_name = COALESCE(sqlc.narg('last_name'), last_name),
    email = COALESCE(sqlc.narg('email'), email),
    phone = COALESCE(sqlc.narg('phone'), phone),
    role = COALESCE(sqlc.narg('role'), role),
    is_email_verified = COALESCE(sqlc.narg('is_email_verified'), is_email_verified),
    is_active = COALESCE(sqlc.narg('is_active'), is_active),
    hashed_password = COALESCE(sqlc.narg('hashed_password'), hashed_password)
WHERE id = $1
RETURNING *;

-- name: DeleteUser :exec
UPDATE users
SET deleted_at = now()
WHERE id = $1;

-- name: HardDeleteUser :exec
DELETE FROM users
WHERE id = $1;
