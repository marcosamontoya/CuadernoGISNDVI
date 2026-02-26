-- ============================================
-- AGROLABOR GIS - Schema Completo v2
-- Compatible con Supabase + PostGIS
-- Incluye todas las correcciones para el
-- frontend agrolabor_gis_v2.html
-- ============================================

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- TABLA: usuarios
-- ============================================
CREATE TABLE IF NOT EXISTS usuarios (
    id               UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email            VARCHAR(255) NOT NULL UNIQUE,
    nombre_completo  VARCHAR(255),
    created_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);

-- Trigger: crear perfil al registrarse
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.usuarios (id, email, nombre_completo)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- TABLA: fincas
-- ============================================
CREATE TABLE IF NOT EXISTS fincas (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre      VARCHAR(100) NOT NULL,
    ubicacion   TEXT,
    activa      BOOLEAN DEFAULT true,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, nombre)
);

CREATE INDEX IF NOT EXISTS idx_fincas_user_id ON fincas(user_id);
CREATE INDEX IF NOT EXISTS idx_fincas_activa  ON fincas(activa);

-- ============================================
-- TABLA: cuarteles  (geometría PostGIS)
-- ============================================
CREATE TABLE IF NOT EXISTS cuarteles (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id              UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    finca_id             UUID NOT NULL REFERENCES fincas(id)  ON DELETE CASCADE,
    nombre               VARCHAR(100) NOT NULL,
    variedad             VARCHAR(100),
    geometry             GEOMETRY(POLYGON, 4326),
    superficie_hectareas DECIMAL(10,2),
    cultivo              VARCHAR(100),
    rendimiento_estimado DECIMAL(10,2),
    color_mapa           VARCHAR(7) DEFAULT '#5a9a4a',
    activo               BOOLEAN DEFAULT true,
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(finca_id, nombre)
);

CREATE INDEX IF NOT EXISTS idx_cuarteles_geometry ON cuarteles USING GIST(geometry);
CREATE INDEX IF NOT EXISTS idx_cuarteles_user_id  ON cuarteles(user_id);
CREATE INDEX IF NOT EXISTS idx_cuarteles_finca_id ON cuarteles(finca_id);
CREATE INDEX IF NOT EXISTS idx_cuarteles_activo   ON cuarteles(activo);

-- ============================================
-- TABLA: trabajadores
-- ============================================
CREATE TABLE IF NOT EXISTS trabajadores (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre       VARCHAR(100) NOT NULL,
    apellido     VARCHAR(100) NOT NULL,
    rut          VARCHAR(20),
    telefono     VARCHAR(20),
    email        VARCHAR(100),
    fecha_ingreso DATE,
    activo       BOOLEAN DEFAULT true,
    created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trabajadores_user_id ON trabajadores(user_id);
CREATE INDEX IF NOT EXISTS idx_trabajadores_activo  ON trabajadores(activo);

-- ============================================
-- TABLA: tipos_labor
-- ============================================
CREATE TABLE IF NOT EXISTS tipos_labor (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre      VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    activo      BOOLEAN DEFAULT true,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tipos_labor_nombre ON tipos_labor(nombre);
CREATE INDEX IF NOT EXISTS idx_tipos_labor_activo ON tipos_labor(activo);

-- ============================================
-- TABLA: registros_horas
-- IMPORTANTE: tipo_labor_id es NULLABLE para
-- permitir registros con tipo_labor_texto libre
-- (ej: Labranza + implemento, que se pasa como texto)
-- ============================================
CREATE TABLE IF NOT EXISTS registros_horas (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fecha               DATE NOT NULL,
    trabajador_id       UUID NOT NULL REFERENCES trabajadores(id) ON DELETE RESTRICT,
    cuartel_id          UUID NOT NULL REFERENCES cuarteles(id)    ON DELETE RESTRICT,
    tipo_labor_id       UUID REFERENCES tipos_labor(id) ON DELETE RESTRICT,  -- NULLABLE
    tipo_labor_texto    VARCHAR(100),   -- Para tipos sin ID en la BD
    horas               DECIMAL(5,2) NOT NULL CHECK (horas > 0 AND horas <= 24),
    ubicacion_registro  GEOMETRY(POINT, 4326),
    observaciones       TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_registros_fecha        ON registros_horas(fecha);
CREATE INDEX IF NOT EXISTS idx_registros_trabajador   ON registros_horas(trabajador_id);
CREATE INDEX IF NOT EXISTS idx_registros_cuartel      ON registros_horas(cuartel_id);
CREATE INDEX IF NOT EXISTS idx_registros_tipo_labor   ON registros_horas(tipo_labor_id);

-- ============================================
-- TABLA: stock_deposito  ← NUEVA en v2
-- Inventario de productos del depósito
-- ============================================
CREATE TABLE IF NOT EXISTS stock_deposito (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id              UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre               VARCHAR(200) NOT NULL,
    tipo                 VARCHAR(50)  NOT NULL CHECK (tipo IN (
                             'herbicida','fungicida','insecticida','acaricida',
                             'fertilizante','bioestimulante','coadyuvante','otro'
                         )),
    cantidad_disponible  NUMERIC(12,3) NOT NULL DEFAULT 0 CHECK (cantidad_disponible >= 0),
    unidad               VARCHAR(10)  NOT NULL DEFAULT 'L'
                             CHECK (unidad IN ('L','kg','g','ml','unidad')),
    cantidad_minima      NUMERIC(12,3) DEFAULT 0,
    observaciones        TEXT,
    activo               BOOLEAN DEFAULT true,
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stock_user_id ON stock_deposito(user_id);
CREATE INDEX IF NOT EXISTS idx_stock_tipo    ON stock_deposito(tipo);
CREATE INDEX IF NOT EXISTS idx_stock_activo  ON stock_deposito(activo);
CREATE INDEX IF NOT EXISTS idx_stock_nombre  ON stock_deposito(nombre);

-- ============================================
-- FUNCIÓN updated_at genérica
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_fincas_updated_at         ON fincas;
DROP TRIGGER IF EXISTS update_cuarteles_updated_at      ON cuarteles;
DROP TRIGGER IF EXISTS update_trabajadores_updated_at   ON trabajadores;
DROP TRIGGER IF EXISTS update_tipos_labor_updated_at    ON tipos_labor;
DROP TRIGGER IF EXISTS update_registros_horas_updated_at ON registros_horas;
DROP TRIGGER IF EXISTS update_stock_updated_at          ON stock_deposito;

CREATE TRIGGER update_fincas_updated_at
    BEFORE UPDATE ON fincas FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_cuarteles_updated_at
    BEFORE UPDATE ON cuarteles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_trabajadores_updated_at
    BEFORE UPDATE ON trabajadores FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tipos_labor_updated_at
    BEFORE UPDATE ON tipos_labor FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_registros_horas_updated_at
    BEFORE UPDATE ON registros_horas FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_stock_updated_at
    BEFORE UPDATE ON stock_deposito FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- TRIGGER: Calcular superficie automáticamente
-- ============================================
CREATE OR REPLACE FUNCTION calcular_superficie_cuartel()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.geometry IS NOT NULL THEN
        NEW.superficie_hectareas = ROUND(
            (ST_Area(NEW.geometry::geography) / 10000)::NUMERIC, 2
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_calcular_superficie ON cuarteles;
CREATE TRIGGER trigger_calcular_superficie
    BEFORE INSERT OR UPDATE OF geometry ON cuarteles
    FOR EACH ROW EXECUTE FUNCTION calcular_superficie_cuartel();

-- ============================================
-- VISTA: cuarteles_geojson  (CORREGIDA)
-- geometry_json se expone como JSON y como TEXT
-- para compatibilidad total con el frontend
-- ============================================
CREATE OR REPLACE VIEW cuarteles_geojson AS
SELECT
    c.id,
    c.nombre,
    c.finca_id,
    f.nombre                             AS finca_nombre,
    c.variedad,
    c.cultivo,
    c.superficie_hectareas,
    c.rendimiento_estimado,
    c.color_mapa,
    c.activo,
    c.user_id,
    -- Como objeto JSON (para acceso directo en JS)
    ST_AsGeoJSON(c.geometry)::json       AS geometry_json,
    -- Como texto (por si el frontend hace JSON.parse())
    ST_AsGeoJSON(c.geometry)             AS geometry_text,
    json_build_object(
        'type', 'Feature',
        'properties', json_build_object(
            'id',             c.id,
            'nombre',         c.nombre,
            'finca',          f.nombre,
            'variedad',       c.variedad,
            'cultivo',        c.cultivo,
            'superficie_ha',  c.superficie_hectareas,
            'rendimiento',    c.rendimiento_estimado,
            'color',          c.color_mapa
        ),
        'geometry', ST_AsGeoJSON(c.geometry)::json
    ) AS feature_json
FROM cuarteles c
JOIN fincas f ON c.finca_id = f.id;

-- ============================================
-- VISTA: registros_completos
-- LEFT JOIN en tipos_labor (nullable)
-- ============================================
CREATE OR REPLACE VIEW registros_completos AS
SELECT
    rh.id,
    rh.fecha,
    rh.horas,
    rh.observaciones,
    ST_AsGeoJSON(rh.ubicacion_registro)  AS ubicacion_json,
    t.id                                 AS trabajador_id,
    t.nombre                             AS trabajador_nombre,
    t.apellido                           AS trabajador_apellido,
    t.rut                                AS trabajador_rut,
    c.id                                 AS cuartel_id,
    c.nombre                             AS cuartel_nombre,
    c.variedad                           AS cuartel_variedad,
    c.superficie_hectareas               AS cuartel_superficie,
    c.cultivo                            AS cuartel_cultivo,
    c.rendimiento_estimado               AS cuartel_rendimiento,
    ST_AsGeoJSON(c.geometry)             AS cuartel_geometry_json,
    f.id                                 AS finca_id,
    f.nombre                             AS finca_nombre,
    f.ubicacion                          AS finca_ubicacion,
    tl.id                                AS tipo_labor_id,
    COALESCE(tl.nombre, rh.tipo_labor_texto, 'Sin tipo') AS tipo_labor_nombre,
    tl.descripcion                       AS tipo_labor_descripcion,
    rh.created_at,
    rh.updated_at
FROM registros_horas rh
JOIN  trabajadores t  ON rh.trabajador_id = t.id
JOIN  cuarteles    c  ON rh.cuartel_id    = c.id
JOIN  fincas       f  ON c.finca_id       = f.id
LEFT JOIN tipos_labor tl ON rh.tipo_labor_id = tl.id;

-- ============================================
-- FUNCIÓN: obtener_cuarteles_geojson
-- ============================================
CREATE OR REPLACE FUNCTION obtener_cuarteles_geojson(
    p_finca_id UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'type',     'FeatureCollection',
        'features', COALESCE(json_agg(feature_json), '[]'::json)
    )
    INTO result
    FROM cuarteles_geojson
    WHERE (p_finca_id IS NULL OR finca_id = p_finca_id)
    AND activo = true;

    RETURN COALESCE(result, '{"type":"FeatureCollection","features":[]}'::json);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCIÓN: crear_cuartel_desde_geojson
-- Usado al importar KML/GeoJSON/Shapefile
-- ============================================
CREATE OR REPLACE FUNCTION crear_cuartel_desde_geojson(
    p_finca_id    UUID,
    p_nombre      VARCHAR,
    p_geojson     JSON,
    p_cultivo     VARCHAR  DEFAULT NULL,
    p_variedad    VARCHAR  DEFAULT NULL,
    p_rendimiento DECIMAL  DEFAULT NULL,
    p_color       VARCHAR  DEFAULT '#5a9a4a'
)
RETURNS UUID AS $$
DECLARE
    nuevo_id  UUID;
    geometria GEOMETRY;
    v_user_id UUID;
BEGIN
    SELECT user_id INTO v_user_id FROM fincas WHERE id = p_finca_id;

    geometria := ST_SetSRID(ST_GeomFromGeoJSON(p_geojson::text), 4326);

    IF ST_GeometryType(geometria) NOT IN ('ST_Polygon', 'ST_MultiPolygon') THEN
        RAISE EXCEPTION 'La geometría debe ser un polígono';
    END IF;

    INSERT INTO cuarteles (
        user_id, finca_id, nombre, geometry,
        cultivo, variedad, rendimiento_estimado, color_mapa
    )
    VALUES (
        v_user_id, p_finca_id, p_nombre, geometria,
        p_cultivo, p_variedad, p_rendimiento, p_color
    )
    RETURNING id INTO nuevo_id;

    RETURN nuevo_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCIÓN: punto_en_cuartel
-- ============================================
CREATE OR REPLACE FUNCTION punto_en_cuartel(p_lat DECIMAL, p_lng DECIMAL)
RETURNS TABLE (
    cuartel_id     UUID,
    cuartel_nombre VARCHAR,
    finca_nombre   VARCHAR,
    cultivo        VARCHAR,
    variedad       VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.nombre, f.nombre, c.cultivo, c.variedad
    FROM cuarteles c
    JOIN fincas f ON c.finca_id = f.id
    WHERE ST_Contains(c.geometry, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326))
    AND c.activo = true;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCIÓN: estadisticas_por_cultivo
-- ============================================
CREATE OR REPLACE FUNCTION estadisticas_por_cultivo()
RETURNS TABLE (
    cultivo             VARCHAR,
    total_cuarteles     BIGINT,
    superficie_total    DECIMAL,
    rendimiento_promedio DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.cultivo,
        COUNT(*)::BIGINT,
        ROUND(SUM(c.superficie_hectareas)::NUMERIC, 2),
        ROUND(AVG(c.rendimiento_estimado)::NUMERIC, 2)
    FROM cuarteles c
    WHERE c.activo = true AND c.cultivo IS NOT NULL
    GROUP BY c.cultivo
    ORDER BY SUM(c.superficie_hectareas) DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCIÓN: obtener_horas_por_finca
-- ============================================
CREATE OR REPLACE FUNCTION obtener_horas_por_finca(
    p_finca_id    UUID DEFAULT NULL,
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin    DATE DEFAULT NULL
)
RETURNS TABLE (
    finca_nombre    VARCHAR,
    cuartel_nombre  VARCHAR,
    cuartel_id      UUID,
    variedad        VARCHAR,
    cultivo         VARCHAR,
    superficie      DECIMAL,
    total_horas     DECIMAL,
    total_registros BIGINT,
    geometry_json   JSON
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.nombre,
        c.nombre,
        c.id,
        c.variedad,
        c.cultivo,
        c.superficie_hectareas,
        SUM(rh.horas)::DECIMAL,
        COUNT(*)::BIGINT,
        ST_AsGeoJSON(c.geometry)::JSON
    FROM registros_horas rh
    JOIN cuarteles c ON rh.cuartel_id = c.id
    JOIN fincas    f ON c.finca_id    = f.id
    WHERE (p_finca_id    IS NULL OR f.id    = p_finca_id)
    AND   (p_fecha_inicio IS NULL OR rh.fecha >= p_fecha_inicio)
    AND   (p_fecha_fin    IS NULL OR rh.fecha <= p_fecha_fin)
    GROUP BY f.nombre, c.nombre, c.id, c.variedad, c.cultivo,
             c.superficie_hectareas, c.geometry
    ORDER BY f.nombre, c.nombre;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================
ALTER TABLE usuarios        ENABLE ROW LEVEL SECURITY;
ALTER TABLE fincas          ENABLE ROW LEVEL SECURITY;
ALTER TABLE cuarteles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE trabajadores    ENABLE ROW LEVEL SECURITY;
ALTER TABLE tipos_labor     ENABLE ROW LEVEL SECURITY;
ALTER TABLE registros_horas ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_deposito  ENABLE ROW LEVEL SECURITY;

-- Limpia políticas anteriores antes de recrear
DO $$ DECLARE r RECORD;
BEGIN
    FOR r IN SELECT policyname, tablename FROM pg_policies
             WHERE tablename IN ('usuarios','fincas','cuarteles','trabajadores',
                                  'tipos_labor','registros_horas','stock_deposito')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', r.policyname, r.tablename);
    END LOOP;
END $$;

-- usuarios
CREATE POLICY "usuarios_select" ON usuarios FOR SELECT  USING (auth.uid() = id);
CREATE POLICY "usuarios_update" ON usuarios FOR UPDATE  USING (auth.uid() = id);

-- fincas
CREATE POLICY "fincas_select" ON fincas FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "fincas_insert" ON fincas FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "fincas_update" ON fincas FOR UPDATE  USING (auth.uid() = user_id);
CREATE POLICY "fincas_delete" ON fincas FOR DELETE  USING (auth.uid() = user_id);

-- cuarteles
CREATE POLICY "cuarteles_select" ON cuarteles FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "cuarteles_insert" ON cuarteles FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "cuarteles_update" ON cuarteles FOR UPDATE  USING (auth.uid() = user_id);
CREATE POLICY "cuarteles_delete" ON cuarteles FOR DELETE  USING (auth.uid() = user_id);

-- trabajadores
CREATE POLICY "trabajadores_select" ON trabajadores FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "trabajadores_insert" ON trabajadores FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "trabajadores_update" ON trabajadores FOR UPDATE  USING (auth.uid() = user_id);
CREATE POLICY "trabajadores_delete" ON trabajadores FOR DELETE  USING (auth.uid() = user_id);

-- tipos_labor: lectura pública
CREATE POLICY "tipos_labor_select" ON tipos_labor FOR SELECT USING (true);

-- registros_horas
CREATE POLICY "registros_select" ON registros_horas FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM trabajadores t
        WHERE t.id = registros_horas.trabajador_id AND t.user_id = auth.uid()
    ));
CREATE POLICY "registros_insert" ON registros_horas FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM trabajadores t
        WHERE t.id = registros_horas.trabajador_id AND t.user_id = auth.uid()
    ));
CREATE POLICY "registros_update" ON registros_horas FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM trabajadores t
        WHERE t.id = registros_horas.trabajador_id AND t.user_id = auth.uid()
    ));
CREATE POLICY "registros_delete" ON registros_horas FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM trabajadores t
        WHERE t.id = registros_horas.trabajador_id AND t.user_id = auth.uid()
    ));

-- stock_deposito
CREATE POLICY "stock_select" ON stock_deposito FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "stock_insert" ON stock_deposito FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "stock_update" ON stock_deposito FOR UPDATE  USING (auth.uid() = user_id);
CREATE POLICY "stock_delete" ON stock_deposito FOR DELETE  USING (auth.uid() = user_id);

-- ============================================
-- TIPOS DE LABOR POR DEFECTO (completo v2)
-- ============================================
INSERT INTO tipos_labor (nombre, descripcion) VALUES
    ('Poda',               'Poda de árboles y plantas'),
    ('Riego',              'Riego de cultivos'),
    ('Cosecha',            'Recolección de frutos o granos'),
    ('Fertilización',      'Aplicación de fertilizantes y enmiendas'),
    ('Pulverización',      'Aplicación de agroquímicos o fitosanitarios'),
    ('Labranza',           'Labranza primaria o secundaria del suelo'),
    ('Desmalezado',        'Control mecánico o manual de malezas'),
    ('Plantación',         'Plantación o trasplante de cultivos'),
    ('Mantenimiento',      'Mantenimiento general de instalaciones'),
    ('Fumigación',         'Control de plagas con fumigante'),
    ('Raleo',              'Raleo de frutos o plantas'),
    ('Amarre / tutoreo',   'Atado y conducción de plantas'),
    ('Transporte',         'Traslado de insumos o cosecha'),
    ('Monitoreo',          'Seguimiento sanitario o fenológico')
ON CONFLICT (nombre) DO NOTHING;

-- ============================================
-- MIGRACIÓN: si ya tenés tablas del schema v1
-- Ejecutar solo si ya existe la BD
-- ============================================

-- Agregar tipo_labor_texto a registros_horas si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'registros_horas'
          AND column_name = 'tipo_labor_texto'
    ) THEN
        ALTER TABLE registros_horas ADD COLUMN tipo_labor_texto VARCHAR(100);
        RAISE NOTICE 'Columna tipo_labor_texto agregada a registros_horas';
    END IF;
END $$;

-- Hacer tipo_labor_id nullable (era NOT NULL en v1)
DO $$
BEGIN
    ALTER TABLE registros_horas ALTER COLUMN tipo_labor_id DROP NOT NULL;
    RAISE NOTICE 'tipo_labor_id ahora es nullable';
EXCEPTION WHEN others THEN
    RAISE NOTICE 'tipo_labor_id ya era nullable, sin cambios';
END $$;

-- Actualizar color por defecto de cuarteles al verde pastel v2
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'cuarteles' AND column_name = 'color_mapa'
    ) THEN
        ALTER TABLE cuarteles
            ALTER COLUMN color_mapa SET DEFAULT '#5a9a4a';
    END IF;
END $$;

-- ============================================
-- COMENTARIOS
-- ============================================
COMMENT ON TABLE  stock_deposito IS 'Inventario de productos del depósito: agroquímicos, fertilizantes, etc.';
COMMENT ON COLUMN stock_deposito.cantidad_disponible IS 'Se descuenta al registrar labores de pulverización o fertilización';
COMMENT ON COLUMN stock_deposito.cantidad_minima     IS 'Umbral de alerta de stock bajo (se muestra en la UI)';
COMMENT ON COLUMN registros_horas.tipo_labor_id      IS 'Nullable desde v2: puede ser NULL si se usa tipo_labor_texto';
COMMENT ON COLUMN registros_horas.tipo_labor_texto   IS 'Texto libre para tipos sin ID, ej: Labranza + implemento específico';
COMMENT ON VIEW   cuarteles_geojson                  IS 'geometry_json (JSON) y geometry_text (TEXT) para máxima compatibilidad con Leaflet';
COMMENT ON VIEW   registros_completos                IS 'LEFT JOIN en tipos_labor por el campo nullable tipo_labor_id';
