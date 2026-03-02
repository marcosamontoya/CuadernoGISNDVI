// ============================================
// CREDENCIALES CDSE — Copernicus Data Space
// ============================================
//
// Instrucciones:
//  1. Registrate GRATIS en https://dataspace.copernicus.eu
//  2. Reemplazá los valores de abajo con tu email y contraseña
//  3. Guardá el archivo — las credenciales quedan para siempre
//
// ⚠️  NO subas este archivo a GitHub si tu repo es público.
//     Agregá "credentials.js" a tu .gitignore
//

const CDSE_CREDENTIALS = {
    user: 'marcosamontoya@gmail.com',   // ← tu email de CDSE, ej: 'tu@email.com'
    pass: 'Julsan$20101'    // ← tu contraseña de CDSE
};

// NO MODIFICAR ABAJO
if (typeof module !== 'undefined' && module.exports) {
    module.exports = CDSE_CREDENTIALS;
}
