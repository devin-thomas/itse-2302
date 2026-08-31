# ITSE 2302

Coursework for ITSE 2302, organized by lab.

## Labs

- [Lab 1 - XAMPP local server setup](lab-1/README.md)

The Windows version of Lab 1 is automated. From PowerShell, run:

```powershell
npm install
npx playwright install chromium
npm run lab:windows
npm run validate
```

The automation installs or reuses XAMPP, serves the project page, and creates
submission-ready evidence under `output/playwright/windows-lab-1/`.

