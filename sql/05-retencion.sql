-- 14. Actividad 7 - Retención de datos
-- Identificar los registros que superan el periodo de conservación de 5 años
SELECT * FROM clientes WHERE fecha_alta < CURRENT_DATE - INTERVAL '5 years';