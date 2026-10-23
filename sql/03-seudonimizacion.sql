-- 9.1 Crear los esquemas
CREATE SCHEMA pii;
CREATE SCHEMA analitica;

-- 9.2 Crear la tabla de correspondencia
CREATE TABLE pii.mapa_cliente (
    token UUID PRIMARY KEY, 
    cliente_id BIGINT UNIQUE REFERENCES public.clientes(id)
);

-- 9.3 Habilitar la extensión necesaria y generar un token para cada cliente
CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO pii.mapa_cliente (token, cliente_id)
SELECT gen_random_uuid(), id FROM clientes;

-- 10. Crear el conjunto de datos para analítica
CREATE TABLE analitica.clientes AS 
SELECT
    m.token AS cliente_token,
    c.edad,
    c.ciudad,
    c.codigo_postal,
    c.fecha_alta
FROM pii.mapa_cliente m
JOIN clientes c ON c.id = m.cliente_id;

-- 11. Actividad 4 - Separación de funciones: Crear el rol y conceder acceso
CREATE ROLE analista NOLOGIN;
GRANT USAGE ON SCHEMA analitica TO analista;
GRANT SELECT ON analitica.clientes TO analista;

-- Verificar la tabla de correspondencia (como administrador)
SELECT * FROM pii.mapa_cliente;

-- 11.1 Verificar los permisos con el rol analista
SET ROLE analista;

-- Prueba 1: Acceso al conjunto analítico (DEBE ESTAR PERMITIDO)
SELECT * FROM analitica.clientes;

-- Prueba 2: Acceso al mapa de correspondencia (DEBE SER RECHAZADO)
SELECT * FROM pii.mapa_cliente;

-- Prueba 3: Acceso directo a los datos originales (DEBE SER RECHAZADO)
SELECT * FROM public.clientes;

-- Regresar al usuario administrador normal
RESET ROLE;