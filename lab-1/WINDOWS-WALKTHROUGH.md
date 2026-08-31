# XAMPP assignment walkthrough (Windows)

The automated path is the recommended way to produce the evidence for this
lab. It uses the same required result as the Mac version while handling the
Windows-specific XAMPP Control Panel and document-root locations.

## Automated path

Run these commands from the repository root in PowerShell:

```powershell
npm install
npx playwright install chromium
npm run lab:windows
npm run validate
```

The default command tries `C:\xampp` first. If the current Windows account is
not allowed to write to the drive root, it uses `.runtime\xampp` instead. Both
locations are valid XAMPP document roots; the selected path is recorded in
`output/playwright/windows-lab-1/evidence.json`.

The run downloads XAMPP 8.2.12 from the official Apache Friends download link,
extracts it, copies this lab's PHP files to `htdocs\project`, starts Apache and
MySQL, and opens these pages:

- `http://localhost/dashboard/`
- `http://localhost/project/index.php`
- `http://localhost/project/status.php` (or `status.php?port=3307` when the
  default MySQL port is occupied)

The runner never stops an unrelated service. If port `3306` is already in use,
it configures XAMPP MariaDB on the first free port from `3307` through `3315`
and records the selected port in `evidence.json`. If Windows shows a firewall
prompt, the automation keeps Private Networks enabled and leaves Public
Networks disabled.

The browser is a fresh Playwright-managed Chromium profile stored only in the
generated output directory. The native window captures preserve the browser
toolbar/address bar required by the assignment. The Control Panel capture is a
separate native-window screenshot.

## Manual equivalent

1. Open `xampp-control.exe` from the selected XAMPP root.
2. Click `Start` beside Apache and MySQL.
3. Confirm that `http://localhost/dashboard/` shows the XAMPP welcome page.
4. Confirm that `http://localhost/project/index.php` shows `Devin Thomas`.
5. Confirm that `http://localhost/project/status.php` shows both services as
   `RUNNING` (add `?port=3307` if the runner selected the fallback port shown in
   `evidence.json`).
6. Save screenshots of the Control Panel, welcome page, and project page with
   the browser address bar visible.
7. Stop Apache and MySQL when finished.

For a deliberate inspection run that leaves the services available, use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-windows-lab.ps1 -KeepServices
```

The XAMPP services are local-only coursework infrastructure. Do not enable
public network access for this assignment.
