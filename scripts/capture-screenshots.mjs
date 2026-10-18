import puppeteer from 'puppeteer';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..');
const assetsDir = path.join(rootDir, 'docs', 'assets');

if (!fs.existsSync(assetsDir)) {
  fs.mkdirSync(assetsDir, { recursive: true });
}

const BASE_URL = 'https://ca-web-portal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io';

async function capture() {
  console.log('=====================================================================');
  console.log('  AUTOMATIZACION DE CAPTURA VISUAL: PORTAL ESTUDIANTIL AZURE CLOUD   ');
  console.log('  URL Base  :', BASE_URL);
  console.log('  Resolución: 1920x1080 Full HD');
  console.log('=====================================================================\n');

  const browser = await puppeteer.launch({
    headless: true,
    executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--window-size=1920,1080'],
    defaultViewport: { width: 1920, height: 1080 }
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 1920, height: 1080 });

    // -------------------------------------------------------------
    // 1. CAPTURA DE PANTALLA: LOGIN INSTITUCIONAL
    // -------------------------------------------------------------
    console.log('1. Navegando hacia la pantalla de Login...');
    await page.goto(`${BASE_URL}/login`, { waitUntil: 'networkidle2', timeout: 30000 });
    await new Promise((r) => setTimeout(r, 2000));

    const loginPath = path.join(assetsDir, '01_login_cloud.png');
    await page.screenshot({ path: loginPath, fullPage: false });
    console.log('   [OK] Captura 1 guardada:', loginPath);

    // -------------------------------------------------------------
    // 2. INICIO DE SESIÓN CON alu01 / password123
    // -------------------------------------------------------------
    console.log('\n2. Ingresando credenciales de alu01...');
    await page.waitForSelector('#username', { timeout: 10000 });
    await page.type('#username', 'alu01');
    await page.type('#password', 'password123');

    console.log('   Enviando formulario de inicio de sesión...');
    await page.click('button[type="submit"]');

    // Esperar navegación o carga de dashboard
    await page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 30000 }).catch(() => {});
    await new Promise((r) => setTimeout(r, 4000));

    // -------------------------------------------------------------
    // 3. CAPTURA DE PANTALLA: DASHBOARD PRINCIPAL
    // -------------------------------------------------------------
    console.log('\n3. Verificando y capturando Dashboard del estudiante...');
    const dashPath = path.join(assetsDir, '02_dashboard_cloud.png');
    await page.screenshot({ path: dashPath, fullPage: false });
    console.log('   [OK] Captura 2 guardada:', dashPath);

    // -------------------------------------------------------------
    // 4. CAPTURA DE PANTALLA: MATRÍCULA Y NOTAS
    // -------------------------------------------------------------
    console.log('\n4. Navegando hacia Matrícula y Notas (/matricula-notas)...');
    await page.goto(`${BASE_URL}/matricula-notas`, { waitUntil: 'networkidle2', timeout: 30000 });
    await new Promise((r) => setTimeout(r, 4000));

    const notasPath = path.join(assetsDir, '03_notas_cloud.png');
    await page.screenshot({ path: notasPath, fullPage: false });
    console.log('   [OK] Captura 3 guardada:', notasPath);

    // -------------------------------------------------------------
    // 5. CAPTURA DE PANTALLA: TESORERÍA Y PAGOS
    // -------------------------------------------------------------
    console.log('\n5. Navegando hacia Tesorería y Pagos (/pagos)...');
    await page.goto(`${BASE_URL}/pagos`, { waitUntil: 'networkidle2', timeout: 30000 });
    await new Promise((r) => setTimeout(r, 4000));

    const tesoreriaPath = path.join(assetsDir, '04_tesoreria_cloud.png');
    await page.screenshot({ path: tesoreriaPath, fullPage: false });
    console.log('   [OK] Captura 4 guardada:', tesoreriaPath);

    console.log('\n=====================================================================');
    console.log('  AUTOMATIZACION COMPLETADA: 4 CAPTURAS GENERADAS EXITOSAMENTE      ');
    console.log('=====================================================================');
  } catch (err) {
    console.error('Error durante la captura:', err);
    process.exitCode = 1;
  } finally {
    await browser.close();
  }
}

capture();
