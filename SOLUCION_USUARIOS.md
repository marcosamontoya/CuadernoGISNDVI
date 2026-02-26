# ✅ Solución - Registro de Usuarios

## 🔧 Problema Resuelto

El sistema ahora incluye:
- ✅ Tabla `usuarios` para perfiles
- ✅ Trigger automático al registrarse
- ✅ Políticas RLS (Row Level Security) completas
- ✅ Cada usuario ve solo sus datos

---

## 🚀 Pasos para Configurar

### 1️⃣ ELIMINAR Base de Datos Anterior (si existe)

Si ya ejecutaste el SQL anterior, **debes eliminar todo primero**:

```sql
-- En Supabase SQL Editor, ejecutar:
DROP TABLE IF EXISTS registros_horas CASCADE;
DROP TABLE IF EXISTS tipos_labor CASCADE;
DROP TABLE IF EXISTS trabajadores CASCADE;
DROP TABLE IF EXISTS cuarteles CASCADE;
DROP TABLE IF EXISTS fincas CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS crear_cuartel_desde_geojson CASCADE;
DROP FUNCTION IF EXISTS obtener_cuarteles_geojson CASCADE;
```

### 2️⃣ Ejecutar Nuevo Schema

**Importante**: Ejecutar `supabase_schema_gis.sql` COMPLETO (todo el archivo)

Este script ahora incluye:
- ✅ Tabla `usuarios` vinculada a `auth.users`
- ✅ Trigger que crea perfil automáticamente al registrarse
- ✅ Todas las tablas con columna `user_id`
- ✅ Políticas RLS activadas
- ✅ Tipos de labor por defecto

### 3️⃣ Verificar Instalación

Ejecutar en Supabase SQL Editor:

```sql
-- Verificar que las tablas existen
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Deberías ver:
-- usuarios
-- fincas
-- cuarteles
-- trabajadores
-- tipos_labor
-- registros_horas

-- Verificar RLS habilitado
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Todas deben tener rowsecurity = true

-- Verificar tipos de labor insertados
SELECT * FROM tipos_labor;
```

---

## 👤 Cómo Funciona el Registro

### Flujo Completo:

```
1. Usuario completa formulario de registro
   ↓
2. Supabase crea usuario en auth.users
   ↓
3. Trigger "on_auth_user_created" se activa automáticamente
   ↓
4. Se crea registro en tabla "usuarios" con:
   - id (mismo que auth.users)
   - email
   - nombre_completo (del formulario)
   ↓
5. Supabase envía email de confirmación
   ↓
6. Usuario confirma email (hacer clic en link)
   ↓
7. Usuario puede iniciar sesión
   ↓
8. Al crear fincas/cuarteles/etc se guarda su user_id
```

### Ver Usuarios Registrados:

```sql
-- Ver usuarios en auth
SELECT id, email, created_at, email_confirmed_at
FROM auth.users;

-- Ver perfiles en usuarios
SELECT id, email, nombre_completo, created_at
FROM usuarios;

-- Deberían coincidir los IDs
```

---

## 🔐 Row Level Security (RLS)

### ¿Qué hace RLS?

**Cada usuario solo ve sus propios datos**:
- ✅ Fincas: Solo las que creó
- ✅ Cuarteles: Solo los de sus fincas
- ✅ Trabajadores: Solo los que registró
- ✅ Registros: Solo los de sus trabajadores

### Verificar Políticas:

```sql
-- Ver todas las políticas
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE schemaname = 'public';

-- Deberías ver políticas para:
-- usuarios (SELECT, UPDATE)
-- fincas (SELECT, INSERT, UPDATE, DELETE)
-- cuarteles (SELECT, INSERT, UPDATE, DELETE)
-- trabajadores (SELECT, INSERT, UPDATE, DELETE)
-- registros_horas (SELECT, INSERT, UPDATE, DELETE)
```

---

## 🧪 Probar el Sistema

### Test 1: Crear Cuenta

1. Abrir `agrolabor_gis_completo.html`
2. Clic en "Registrarse"
3. Completar:
   - Nombre: Juan Pérez
   - Email: juan@test.com
   - Contraseña: 123456
   - Confirmar: 123456
4. Clic en "Crear Cuenta"
5. **Ver en Supabase**:

```sql
SELECT * FROM auth.users WHERE email = 'juan@test.com';
SELECT * FROM usuarios WHERE email = 'juan@test.com';
-- Ambos deben existir con el mismo ID
```

### Test 2: Confirmar Email

1. Revisar bandeja de entrada (también spam)
2. Hacer clic en el link de confirmación
3. Verificar en Supabase:

```sql
SELECT email, email_confirmed_at 
FROM auth.users 
WHERE email = 'juan@test.com';
-- email_confirmed_at debe tener una fecha
```

### Test 3: Iniciar Sesión y Crear Datos

1. Iniciar sesión con juan@test.com
2. Crear una finca
3. Verificar en Supabase:

```sql
SELECT * FROM fincas;
-- Debe aparecer la finca con el user_id de Juan
```

### Test 4: Privacidad (2 usuarios)

1. Crear segunda cuenta: maria@test.com
2. Iniciar sesión con Maria
3. Crear una finca
4. **Verificar**: Maria NO ve las fincas de Juan
5. En Supabase:

```sql
-- Ver todas las fincas (como admin)
SELECT f.nombre, u.email 
FROM fincas f 
JOIN usuarios u ON f.user_id = u.id;

-- Debe mostrar:
-- Finca de Juan | juan@test.com
-- Finca de Maria | maria@test.com
```

---

## ⚠️ Problemas Comunes

### "Cannot read property 'id' of null"

**Causa**: No hay sesión activa
**Solución**: 
- Cerrar sesión y volver a iniciar sesión
- Verificar que config.js tiene credenciales correctas

### "duplicate key value violates unique constraint"

**Causa**: Ya existe un registro con ese valor único
**Solución**:
- En fincas: Usa nombres diferentes
- En trabajadores: Usa RUTs diferentes
- O elimina el registro existente

### "new row violates row-level security policy"

**Causa**: Intentando crear datos sin user_id o con user_id incorrecto
**Solución**:
- Verificar que el usuario está autenticado
- El código actualizado ya incluye user_id automáticamente

### "relation 'auth.users' does not exist"

**Causa**: Estás en el schema equivocado
**Solución**:
```sql
-- Cambiar al schema correcto
SET search_path TO public, auth;
```

### Email de confirmación no llega

**Soluciones**:
1. Revisar carpeta de spam
2. En Supabase → Authentication → Settings:
   - Verificar que "Enable email confirmations" está activado
3. Usar email real (no temporales como temp-mail)
4. Para desarrollo, desactivar confirmación:
   - Authentication → Settings → "Enable email confirmations" = OFF

---

## 📊 Estructura de Tablas Actualizada

```
auth.users (Supabase automático)
    ↓
usuarios (nuestro perfil)
    ↓
    ├── fincas
    │   └── cuarteles (con geometría)
    │       └── registros_horas
    │           └── tipo_labor
    │           └── trabajador
    └── trabajadores
```

---

## 🔄 Migrar Datos Existentes (si tenías datos)

Si ya tenías datos en la versión anterior:

```sql
-- CUIDADO: Esto es solo un ejemplo, ajustar según tus datos

-- 1. Crear un usuario de prueba
-- (registrarse manualmente primero)

-- 2. Obtener el ID del usuario
SELECT id FROM usuarios WHERE email = 'tu@email.com';

-- 3. Asignar ese user_id a datos existentes
UPDATE fincas SET user_id = 'UUID-DEL-USUARIO';
UPDATE cuarteles SET user_id = 'UUID-DEL-USUARIO';
UPDATE trabajadores SET user_id = 'UUID-DEL-USUARIO';
```

---

## ✅ Checklist Final

- [ ] Ejecutaste DROP TABLE para limpiar
- [ ] Ejecutaste supabase_schema_gis.sql completo
- [ ] Verificaste que tabla usuarios existe
- [ ] Verificaste que RLS está habilitado
- [ ] Creaste una cuenta de prueba
- [ ] Confirmaste el email
- [ ] Pudiste iniciar sesión
- [ ] Creaste una finca y aparece en Supabase
- [ ] La finca tiene tu user_id correcto
- [ ] Estado muestra "Conectado" (verde)

---

## 🎉 Sistema Listo

Ahora tienes un sistema completo con:
- ✅ Autenticación de usuarios
- ✅ Registro y login funcional
- ✅ Cada usuario ve solo sus datos (RLS)
- ✅ Tabla de usuarios en Supabase
- ✅ Perfiles creados automáticamente

**¡Ya puedes usar AgroLabor GIS de forma segura!** 🌾🗺️
