<?php
$mysql = @fsockopen('127.0.0.1', 3306, $errorCode, $errorMessage, 1);
$mysqlRunning = is_resource($mysql);
if ($mysqlRunning) {
    fclose($mysql);
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>XAMPP Live Status</title>
    <style>
        :root {
            font-family: Arial, sans-serif;
            color-scheme: light dark;
            background: #101820;
            color: #f7f3ec;
        }
        body {
            min-height: 100vh;
            margin: 0;
            display: grid;
            place-items: center;
            padding: 2rem;
            background: linear-gradient(145deg, #101820, #1e2d37);
        }
        main {
            width: min(50rem, 100%);
            padding: 2.5rem;
            border: 1px solid #ffffff26;
            border-radius: 1rem;
            background: #0b1117d9;
            box-shadow: 0 1.5rem 4rem #0008;
        }
        header {
            display: flex;
            align-items: center;
            gap: 1rem;
            margin-bottom: 2rem;
        }
        .logo {
            display: grid;
            place-items: center;
            width: 3.5rem;
            height: 3.5rem;
            border-radius: 0.7rem;
            background: #fb7a24;
            font-size: 1.7rem;
            font-weight: 900;
        }
        h1, p { margin: 0; }
        h1 { font-size: clamp(2rem, 5vw, 3.5rem); }
        header p { margin-top: 0.25rem; color: #b7c2c8; }
        .service {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 2rem;
            padding: 1.2rem 0;
            border-top: 1px solid #ffffff21;
        }
        .service strong { font-size: 1.1rem; }
        .service small { display: block; margin-top: 0.35rem; color: #b7c2c8; }
        .status {
            padding: 0.5rem 0.8rem;
            border-radius: 999px;
            background: #183d2a;
            color: #7ee2a8;
            font-weight: 800;
        }
        .stopped { background: #4b2020; color: #ff9c9c; }
        footer { margin-top: 1.5rem; color: #b7c2c8; font-size: 0.85rem; }
    </style>
</head>
<body>
    <main>
        <header>
            <div class="logo">X</div>
            <div>
                <h1>XAMPP Live Status</h1>
                <p>macOS compatibility proof &middot; XAMPP 8.2.4-0</p>
            </div>
        </header>
        <div class="service">
            <div><strong>Apache Web Server</strong><small>Serving this page on port 80</small></div>
            <span class="status">RUNNING</span>
        </div>
        <div class="service">
            <div><strong>MySQL Database</strong><small>127.0.0.1:3306</small></div>
            <span class="status <?= $mysqlRunning ? '' : 'stopped' ?>"><?= $mysqlRunning ? 'RUNNING' : 'STOPPED' ?></span>
        </div>
        <footer>Installed at /Applications/XAMPP &middot; Local development only</footer>
    </main>
</body>
</html>
