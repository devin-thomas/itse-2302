import { chromium } from 'playwright';
import { mkdir, rm, writeFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const evidenceDir = path.resolve(
  process.env.EVIDENCE_DIR ?? path.join(repoRoot, 'output', 'playwright', 'windows-lab-1'),
);
const profileDir = path.join(evidenceDir, 'browser-profile');
const captureWindowScript = path.join(repoRoot, 'scripts', 'capture-window.ps1');
const baseUrl = (process.env.BASE_URL ?? 'http://localhost').replace(/\/$/, '');
const controlPanelProcessId = Number.parseInt(process.env.CONTROL_PANEL_PROCESS_ID ?? '0', 10);
const mysqlPort = Number.parseInt(process.env.XAMPP_MYSQL_PORT ?? '3306', 10);
const headed = process.env.HEADLESS !== '1';

const pagesToCapture = [
  {
    key: 'welcome',
    label: 'Welcome',
    url: `${baseUrl}/dashboard/`,
    requiredText: 'Welcome to XAMPP for Windows',
  },
  {
    key: 'project',
    label: 'Project',
    url: `${baseUrl}/project/index.php`,
    requiredText: 'Devin Thomas',
  },
  {
    key: 'status',
    label: 'Status',
    url: `${baseUrl}/project/status.php?port=${mysqlPort}`,
    requiredText: 'XAMPP Live Status',
  },
];

await mkdir(evidenceDir, { recursive: true });
await rm(profileDir, { recursive: true, force: true });

const report = {
  status: 'running',
  browser: 'Playwright-managed Chromium',
  isolation: {
    headed,
    profileDir,
    personalBrowserProfileUsed: false,
  },
  baseUrl,
  mysqlPort,
  checks: [],
  screenshots: [],
  startedAt: new Date().toISOString(),
};

function runPowerShell(args) {
  return new Promise((resolve, reject) => {
    const child = spawn('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ...args], {
      cwd: repoRoot,
      windowsHide: true,
    });
    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (chunk) => { stdout += chunk; });
    child.stderr.on('data', (chunk) => { stderr += chunk; });
    child.on('error', reject);
    child.on('close', (code) => {
      if (code === 0) {
        resolve({ stdout, stderr });
        return;
      }
      reject(new Error(`PowerShell capture failed with code ${code}: ${stderr || stdout}`));
    });
  });
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

let context;
try {
  if (!headed) {
    throw new Error('Native evidence requires a headed browser so the address bar can be captured.');
  }

  context = await chromium.launchPersistentContext(profileDir, {
    headless: false,
    viewport: { width: 1365, height: 760 },
    deviceScaleFactor: 1,
    locale: 'en-US',
    timezoneId: 'America/Chicago',
    colorScheme: 'light',
    args: [
      '--window-size=1440,900',
      '--window-position=80,60',
      '--disable-extensions',
      '--disable-sync',
      '--disable-translate',
      '--no-first-run',
      '--no-default-browser-check',
    ],
  });

  const page = context.pages()[0] ?? await context.newPage();
  const consoleErrors = [];
  const pageErrors = [];
  page.on('console', (message) => {
    if (message.type() === 'error') {
      consoleErrors.push({ url: page.url(), message: message.text() });
    }
  });
  page.on('pageerror', (error) => {
    pageErrors.push({ url: page.url(), message: error.message });
  });

  for (const item of pagesToCapture) {
    const consoleErrorStart = consoleErrors.length;
    const pageErrorStart = pageErrors.length;
    const response = await page.goto(item.url, { waitUntil: 'domcontentloaded', timeout: 30_000 });
    await page.waitForTimeout(350);
    const bodyText = await page.locator('body').innerText();
    assert(response && response.status() === 200, `${item.url} returned HTTP ${response?.status() ?? 'no response'}.`);
    assert(bodyText.includes(item.requiredText), `${item.url} did not contain '${item.requiredText}'.`);
    if (item.key === 'status') {
      const runningCount = (bodyText.match(/RUNNING/g) ?? []).length;
      assert(runningCount >= 2, `${item.url} did not report both Apache and MySQL as RUNNING.`);
    }

    const pageScreenshot = path.join(evidenceDir, `${item.key}-page.png`);
    await page.screenshot({ path: pageScreenshot, fullPage: true });

    const windowTitle = `XAMPP Windows Evidence - ${item.label}`;
    await page.evaluate((title) => { document.title = title; }, windowTitle);
    await page.waitForTimeout(500);
    const windowScreenshot = path.join(evidenceDir, `${item.key}-window.png`);
    await runPowerShell([
      captureWindowScript,
      '-TitleLike', `${windowTitle}*`,
      '-OutputPath', windowScreenshot,
      '-UsePrintWindow',
    ]);

    report.checks.push({
      key: item.key,
      url: item.url,
      httpStatus: response.status(),
      requiredText: item.requiredText,
      pageScreenshot: path.basename(pageScreenshot),
      windowScreenshot: path.basename(windowScreenshot),
      consoleErrors: consoleErrors.slice(consoleErrorStart),
      pageErrors: pageErrors.slice(pageErrorStart),
    });
    report.screenshots.push(path.basename(windowScreenshot));
  }

  if (controlPanelProcessId > 0) {
    const panelScreenshot = path.join(evidenceDir, 'control-panel-window.png');
    await runPowerShell([
      captureWindowScript,
      '-ProcessId', String(controlPanelProcessId),
      '-OutputPath', panelScreenshot,
    ]);
    report.controlPanelScreenshot = path.basename(panelScreenshot);
    report.screenshots.unshift(path.basename(panelScreenshot));
  }

  const localChecks = report.checks.filter((check) => check.key !== 'welcome');
  const localConsoleErrors = localChecks.flatMap((check) => check.consoleErrors);
  const localPageErrors = localChecks.flatMap((check) => check.pageErrors);
  assert(localConsoleErrors.length === 0, `Local pages reported console errors: ${JSON.stringify(localConsoleErrors)}`);
  assert(localPageErrors.length === 0, `Local pages reported page errors: ${JSON.stringify(localPageErrors)}`);
  report.status = 'passed';
}
catch (error) {
  report.status = 'failed';
  report.error = error instanceof Error ? error.message : String(error);
  throw error;
}
finally {
  report.finishedAt = new Date().toISOString();
  await writeFile(path.join(evidenceDir, 'evidence.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
  if (context) {
    await context.close();
  }
}
