-- 8.1 Crear el rol
CREATE ROLE soporte NOLOGIN;

-- 8.2 Crear una vista de acceso restringido
CREATE VIEW v_clientes_soporte AS 
SELECT
    id, 
    nombre, 
    CONCAT(LEFT(correo, 2), '*****', SUBSTRING(correo FROM POSITION('@' IN correo))) AS correo, 
    CONCAT('******', RIGHT(telefono, 4)) AS telefono,
    CONCAT('*********', RIGHT(rfc, 4)) AS rfc 
FROM clientes;

-- 8.3 Conceder acceso a la vista y revocar acceso a la tabla original
GRANT USAGE ON SCHEMA public TO soporte;
GRANT SELECT ON v_clientes_soporte TO soporte;
REVOKE ALL ON clientes FROM soporte;

-- 8.4 Verificar el resultado con el rol soporte
SET ROLE soporte;

-- Prueba 1: Consultar la vista (debe mostrar los datos con asteriscos)
SELECT * FROM v_clientes_soporte;

-- Prueba 2: Intentar consultar la tabla original (debe dar error de permiso denegado)
SELECT * FROM clientes;

-- Regresar al usuario administrador normal
RESET ROLE;