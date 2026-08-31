# Lab 1 - XAMPP on Windows

This lab sets up a local Apache, MariaDB, and PHP development environment with
XAMPP. The project page confirms that PHP is being served from XAMPP's `htdocs`
document root.

## Automated run

From the repository root in PowerShell:

```powershell
npm install
npx playwright install chromium
npm run lab:windows
npm run validate
```

The command is restart-safe. It will:

1. Reuse XAMPP if it is already installed.
2. Otherwise download the official Windows ZIP for XAMPP 8.2.12 and extract
   it. The script uses `C:\xampp` when the account can write there; otherwise it
   uses `.runtime\xampp` inside this repository so an administrator prompt is
   not required.
3. Copy `index.php` and `status.php` into the selected XAMPP `htdocs\project`
   folder.
4. Start Apache and MySQL through the XAMPP Control Panel, with a direct
   process fallback when Windows UI automation cannot click the controls.
5. Open `/dashboard/`, `/project/index.php`, and `/project/status.php` in a
   clean Playwright-managed Chromium profile.
6. Save both page-only checks and native window screenshots. The native browser
   screenshots include the address bar; the control-panel screenshot includes
   the Windows XAMPP UI.

If another program already owns port `3306`, the runner leaves it alone and
configures XAMPP MariaDB on the first free port from `3307` through `3315`. The
selected port is recorded in `evidence.json`, and the status URL includes it as
`?port=...`. If Windows displays a firewall prompt, the helper keeps Private
Networks enabled and does not enable Public Networks.

## Evidence

Generated files are in `output/playwright/windows-lab-1/`:

- `control-panel-window.png` - XAMPP Control Panel with Apache and MySQL
- `welcome-window.png` - XAMPP welcome page with the browser address bar
- `project-window.png` - `Devin Thomas` page with the browser address bar
- `status-window.png` - optional PHP status page
- `evidence.json` - URLs, assertions, browser isolation, and file checks

The browser profile is generated under the same output folder and is never the
user's normal Chrome profile. The local server is stopped when the run finishes
unless `-KeepServices` is supplied to the PowerShell script.

The local server is intended for coursework and development, not public
hosting. See [the Windows walkthrough](WINDOWS-WALKTHROUGH.md) for the manual
equivalent and troubleshooting notes.

