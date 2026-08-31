import { access, readFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const evidenceDir = path.resolve(
  process.env.EVIDENCE_DIR ?? path.join(repoRoot, 'output', 'playwright', 'windows-lab-1'),
);
const reportPath = path.join(evidenceDir, 'evidence.json');
const report = JSON.parse(await readFile(reportPath, 'utf8'));

if (report.status !== 'passed') {
  throw new Error(`Evidence report status is '${report.status}'.`);
}

const requiredKeys = ['welcome', 'project', 'status'];
for (const key of requiredKeys) {
  const check = report.checks.find((entry) => entry.key === key);
  if (!check) {
    throw new Error(`Evidence report is missing the '${key}' check.`);
  }
  for (const fileName of [check.pageScreenshot, check.windowScreenshot]) {
    await access(path.join(evidenceDir, fileName));
  }
}

if (!report.controlPanelScreenshot) {
  throw new Error('Evidence report is missing the XAMPP Control Panel screenshot.');
}
await access(path.join(evidenceDir, report.controlPanelScreenshot));

console.log(`Validated ${report.checks.length} browser checks and ${report.screenshots.length} screenshots.`);
