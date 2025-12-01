-- name: GetCSSVariableByName :one
SELECT * FROM css_variables WHERE name = $1;
