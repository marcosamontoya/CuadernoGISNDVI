# 🔧 Diagnóstico - Login No Funciona

## 🎯 Archivo de Diagnóstico Creado

He creado **test_configuracion.html** para ayudarte a diagnosticar el problema.

---

## ✅ Pasos para Diagnosticar

### 1️⃣ Abrir test_configuracion.html

1. Abre el archivo `test_configuracion.html` en tu navegador
2. Este archivo te mostrará exactamente qué está fallando

### 2️⃣ Seguir las Verificaciones

El archivo test verifica automáticamente:

**✅ Verificación 1: config.js**
- Si el archivo existe
- Si tiene credenciales configuradas
- Si las credenciales no son de ejemplo

**✅ Verificación 2: Conexión Supabase**
- Clic en "Probar Conexión"
- Verifica si puede conectarse a tu base de datos

**✅ Verificación 3: Registro**
- Ingresar un email de prueba
- Probar crear una cuenta
- Ver si funciona el registro

**✅ Verificación 4: Login**
- Intentar iniciar sesión
- Ver mensajes de error específicos

**✅ Verificación 5: Tablas**
- Verificar si las tablas existen en Supabase
- Ver cuáles faltan

---

## 🔍 Problemas Comunes y Soluciones

### Problema 1: "No se encontró config.js"

**Causa:** El archivo config.js no está en la misma carpeta

**Solución:**
```
📁 tu-carpeta/
├── agrolabor_gis_completo.html
├── test_configuracion.html  ← Abrir este
├── config.js                ← DEBE estar aquí
└── supabase_schema_gis.sql
```

### Problema 2: "Debes configurar credenciales"

**Causa:** config.js tiene los valores de ejemplo

**Solución:**
1. Abrir `config.js` en un editor de texto
2. Ir a [Supabase](https://supabase.com)
3. Tu proyecto → Settings → API
4. Copiar:
   - Project URL
   - anon public key
5. Pegar en config.js:

```javascript
const SUPABASE_CONFIG = {
    url: 'https://xyzabc123.supabase.co',  // ← Tu URL aquí
    anonKey: 'eyJhbGciOiJIUzI1NiIs...',    // ← Tu key aquí
    options: { ... }
};
```

### Problema 3: "Error de conexión" o "tabla no existe"

**Causa:** No ejecutaste el SQL en Supabase

**Solución:**
1. Ir a Supabase → SQL Editor
2. Copiar TODO el contenido de `supabase_schema_gis.sql`
3. Pegar en el editor
4. Clic en "Run"
5. Esperar a que termine (puede tardar 10-30 segundos)
6. Verificar que no hay errores

### Problema 4: "Invalid login credentials"

**Causa:** Email o contraseña incorrectos, o cuenta no confirmada

**Solución:**
1. Verificar que el email es correcto
2. Verificar la contraseña
3. **IMPORTANTE:** Revisar bandeja de entrada
4. Buscar email de Supabase
5. Hacer clic en "Confirm your email"
6. Intentar login nuevamente

### Problema 5: "User already registered"

**Causa:** Ya existe una cuenta con ese email

**Solución:**
- Usar ese email para hacer login (no registro)
- O usar un email diferente
- O eliminar el usuario en Supabase:
  ```sql
  DELETE FROM auth.users WHERE email = 'tu@email.com';
  ```

---

## 📋 Checklist de Diagnóstico

Usa test_configuracion.html y marca lo que funciona:

- [ ] ✅ config.js encontrado
- [ ] ✅ config.js con credenciales configuradas
- [ ] ✅ Conexión a Supabase exitosa
- [ ] ✅ Registro funciona (crea usuario)
- [ ] ✅ Email de confirmación recibido
- [ ] ✅ Email confirmado (hacer clic en link)
- [ ] ✅ Login funciona
- [ ] ✅ Todas las tablas existen

---

## 🔧 Si Todo Falla

### Opción 1: Empezar de Cero

```sql
-- En Supabase SQL Editor:
-- 1. ELIMINAR TODO
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- 2. Reinstalar extensiones
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 3. Ejecutar supabase_schema_gis.sql completo
```

### Opción 2: Crear Proyecto Nuevo

1. Ir a Supabase
2. Crear nuevo proyecto
3. Esperar a que se inicialice (5-10 minutos)
4. Ejecutar supabase_schema_gis.sql
5. Actualizar config.js con nuevas credenciales

---

## 📞 Información para Debugging

Si necesitas ayuda, proporciona esta información:

1. **¿Qué falla en test_configuracion.html?**
   - ¿Cuál verificación da error?
   - ¿Qué mensaje de error aparece?

2. **Navegador:**
   - ¿Chrome, Firefox, Safari, Edge?
   - Abrir consola (F12) y copiar errores

3. **Config.js:**
   - ¿Está en la misma carpeta?
   - ¿Tiene credenciales reales (no de ejemplo)?

4. **Supabase:**
   - ¿Ejecutaste el SQL completo?
   - ¿Hay errores en SQL Editor?
   - ¿El proyecto está activo (no pausado)?

5. **Email:**
   - ¿Recibiste email de confirmación?
   - ¿Confirmaste el email?

---

## ✨ Próximos Pasos

**Una vez que test_configuracion.html muestre todo ✅:**

1. Cerrar test_configuracion.html
2. Abrir agrolabor_gis_completo.html
3. Intentar login nuevamente
4. Debería funcionar

---

## 🎯 Ejemplo de Test Exitoso

```
✅ config.js encontrado y configurado
✅ Conexión exitosa a Supabase
✅ Registro exitoso! (revisa email)
✅ Login exitoso!
✅ Todas las tablas existen
```

**Si ves esto → El sistema está listo** 🎉

---

**Usa test_configuracion.html primero para identificar exactamente dónde está el problema.**
