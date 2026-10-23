# Informe de Laboratorio 01: Protección y Privacidad de Datos
**Estudiante:** Jesús Jared Recio Ozúa  
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Fecha:** 22 de octubre de 2026  

---

## 19.1 Clasificación
En la tabla `clientes` se identificaron dos categorías principales de atributos que requieren protección:
1. **Identificadores directos (`nombre`, `correo`, `telefono`, `rfc`):** Permiten individualizar y contactar de forma directa a una persona física. Su exposición puede derivar en robo de identidad, fraude o suplantación.
2. **Cuasi-identificadores (`id`, `edad`, `ciudad`, `codigo_postal`, `fecha_alta`):** Aunque por separado no revelan quién es la persona, al combinarse entre sí permiten aislar e identificar a un individuo dentro de una población reducida.

## 19.2 Enmascaramiento
* **Qué se ocultó:** Se ocultaron parcialmente los valores de `correo` (mostrando solo los 2 primeros caracteres y el dominio), `telefono` (mostrando solo los últimos 4 dígitos) y `rfc` (mostrando solo los últimos 4 caracteres), además de omitir `edad`, `ciudad`, `codigo_postal` y `fecha_alta`.
* **Para quién:** Para el rol `soporte` (Área de soporte y atención a clientes).
* **Por qué:** Porque el personal de soporte necesita validar la identidad del cliente para atender solicitudes, pero por principio de mínimo privilegio no necesita visualizar sus datos completos.
* **Qué mecanismo se utilizó:** Enmascaramiento dinámico mediante una vista de PostgreSQL (`CREATE VIEW v_clientes_soporte`) utilizando funciones de cadenas (`CONCAT`, `LEFT`, `RIGHT`, `SUBSTRING`), combinado con control de acceso (`GRANT SELECT` sobre la vista y `REVOKE ALL` sobre la tabla original `clientes`).

## 19.3 Seudonimización
* **Cómo se generaron los tokens:** Se habilitó la extensión `pgcrypto` y se utilizó la función `gen_random_uuid()` para generar un identificador sustituto (UUID) aleatorio por cada cliente.
* **Dónde se encuentra el mapa de correspondencia:** En el esquema protegido `pii`, dentro de la tabla `pii.mapa_cliente` (que asocia cada `token` con su `cliente_id`).
* **Quién debería poder acceder a él:** Únicamente el Administrador de Base de Datos (DBA) o procesos estrictamente autorizados bajo auditoría; nunca el área de analítica.
* **Por qué se separaron los permisos:** Aplicando el principio de separación de funciones (*Separation of Duties*), se otorgó al rol `analista` acceso de lectura exclusivo a `analitica.clientes` y se le restringió el acceso a `pii.mapa_cliente` y `public.clientes`. Si el analista pudiera consultar el mapa, revertiría la seudonimización relacionando el token con el cliente original.

## 19.4 Anonimización
* **Identificadores eliminados:** Se eliminaron todos los identificadores directos (`id`, `nombre`, `correo`, `telefono`, `rfc`) y el token individual.
* **Atributos generalizados:** La `edad` se transformó en rangos (`18-30`, `31-45`, `46+`) y el `codigo_postal` se truncó a sus primeros dígitos para representar regiones, agrupando los registros mediante `COUNT(*)` y `GROUP BY`.
* **Grupos suprimidos:** Mediante la cláusula `HAVING COUNT(*) >= 5` (y `>= 3` en el reto con macro-regiones), se suprimieron los grupos con pocos registros para evitar exponer individuos aislados.
* **Riesgo de reidentificación que permanece:** Si un tercero cuenta con fuentes externas y conoce la edad aproximada y ubicación de una persona perteneciente a un grupo pequeño, aún existe posibilidad de inferencia o reidentificación contextual.

## 19.5 Retención
* **Criterio utilizado:** Se estableció un periodo de conservación de 5 años a partir de `fecha_alta` (`WHERE fecha_alta < CURRENT_DATE - INTERVAL '5 years'`).
* **Información que debería conservarse:** Registros de clientes activos o cuya alta/relación contractual sea menor a 5 años por obligaciones operativas y fiscales, así como estadísticas agregadas anónimas.
* **Información que podría eliminarse:** Datos personales identificativos (`nombre`, `correo`, `telefono`, `rfc`) y su mapa de correspondencia una vez vencido el plazo legal de 5 años.
* **Controles previos a la eliminación:** Respaldo cifrado previo, aprobación formal del área jurídica y de negocio, verificación de ausencia de litigios activos y registro en bitácora de auditoría.

## 19.6 Conclusiones
* **¿Qué técnica utilizarías para un área de soporte?** Enmascaramiento dinámico mediante vistas restringidas, permitiendo verificar datos parciales sin exponer la información completa.
* **¿Qué técnica utilizarías para un área de analítica?** Seudonimización mediante tokens sustitutos en un esquema separado del mapa de correspondencia.
* **¿Qué técnica utilizarías para publicar estadísticas?** Anonimización combinando generalización por rangos, agregación y supresión de grupos pequeños.
* **¿Por qué ninguna de estas técnicas sustituye al control de acceso?** Porque cualquier transformación (vistas enmascaradas o tablas seudonimizadas) resulta inútil si los usuarios mantienen privilegios de lectura sobre las tablas originales o los mapas de correspondencia. El control de acceso (`GRANT`/`REVOKE`) es la base que obliga a cada rol a consumir únicamente la capa de datos que le corresponde.

---

## 20. Preguntas de reflexión

1. **¿Cuál es la diferencia entre enmascaramiento y seudonimización?**  
   El enmascaramiento oculta parcialmente la visualización de un dato real (ej. `an*****@example.test`) para validación operativa, mientras que la seudonimización sustituye la identidad directa por un identificador artificial (token) manteniendo la relación real en una tabla separada.

2. **¿Por qué la seudonimización no significa anonimización?**  
   Porque la seudonimización es reversible mediante la tabla de correspondencia (`pii.mapa_cliente`), mientras que la anonimización busca impedir de forma irreversible que el dato vuelva a asociarse con la persona.

3. **¿Por qué eliminar nombre y RFC no garantiza que un conjunto de datos sea anónimo?**  
   Porque permanecen cuasi-identificadores (como edad, ciudad y código postal) cuya combinación puede ser única para una persona dentro del conjunto de datos.

4. **¿Qué función tienen los cuasi-identificadores?**  
   Son atributos que por sí mismos no identifican a nadie, pero combinados entre sí o con fuentes externas reducen el grupo de coincidencias hasta individualizar a una persona.

5. **¿Por qué es importante separar el mapa de seudonimización?**  
   Porque quien posea tanto los datos seudonimizados como el mapa de correspondencia puede cruzarlos y recuperar inmediatamente la identidad de todos los registros.

6. **¿Qué principio de seguridad se aplica al impedir que el analista acceda al mapa?**  
   El principio de Separación de Funciones (*Separation of Duties*) y el principio de Mínimo Privilegio (*Least Privilege*).

7. **¿Por qué una vista puede ser preferible a entregar acceso directo a la tabla?**  
   Porque permite filtrar filas/columnas y aplicar funciones de enmascaramiento al vuelo sin duplicar el almacenamiento ni exponer los datos originales de la tabla física.

8. **¿Qué diferencia existe entre proteger un dato para visualización y protegerlo contra acceso no autorizado?**  
   Proteger para visualización (enmascaramiento) limita qué tanto ve en pantalla un usuario autorizado; proteger contra acceso no autorizado (control de acceso) bloquea a nivel motor de base de datos cualquier consulta de usuarios sin privilegios.

9. **¿Por qué la retención forma parte de la protección de datos?**  
   Porque eliminar de forma controlada la información que ya cumplió su finalidad evita que dichos datos puedan ser expuestos en futuros incidentes de seguridad.

10. **¿Qué riesgo existe si una organización conserva información indefinidamente?**  
    Aumenta el volumen de datos expuestos y la severidad del impacto ante una filtración o ataque, además de incumplir el principio de minimización y limitación del plazo de conservación.