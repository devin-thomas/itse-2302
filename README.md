# ITSE 2302

Coursework for ITSE 2302, organized by lab.

## Labs

- [Lab 1 - XAMPP local server setup](lab-1/README.md)
- [Lab 2 - HTML, CSS, and PHP page](lab-2/lab2dt.php)
- [Lab 3 - PHP array](lab-3/lab3dt.php)
- [Lab 4 - PHP calculation form](lab-4/lab4dt.php)

The Windows version of Lab 1 is automated. From PowerShell, run:

```powershell
npm install
npx playwright install chromium
npm run lab:windows
npm run validate
```

The automation installs or reuses XAMPP, serves the project page, and creates
submission-ready evidence under `output/playwright/windows-lab-1/`.

