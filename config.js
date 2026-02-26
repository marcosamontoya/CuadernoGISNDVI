// ============================================
// CONFIGURACIÓN DE SUPABASE
// ============================================

/**
 * Instrucciones para configurar:
 * 
 * 1. Ve a tu proyecto de Supabase (https://supabase.com)
 * 2. En Settings > API encontrarás:
 *    - Project URL
 *    - Project API keys > anon public
 * 3. Reemplaza los valores abajo con tus credenciales
 */

const SUPABASE_CONFIG = {
    // URL de tu proyecto Supabase
    url: 'https://yoxyezmyygkhwwaopmiy.supabase.co',
    
    // Anon Key (llave pública)
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlveHllem15eWdraHd3YW9wbWl5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIwNDMwMDIsImV4cCI6MjA4NzYxOTAwMn0.5XA7FnO4Cmwr7thiO7wyL6OnCN6C1h0K58zL-zIEyL4',
    
    // Opciones adicionales (opcional)
    options: {
        auth: {
            autoRefreshToken: true,
            persistSession: true,
            detectSessionInUrl: true
        }
    }
};

// NO MODIFICAR ABAJO DE ESTA LÍNEA
// ============================================

// Exportar configuración
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SUPABASE_CONFIG;
}
