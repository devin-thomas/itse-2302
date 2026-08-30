#!/bin/zsh

clear
printf '\n'
printf '  XAMPP 8.2.4-0 - LOCAL SERVER STATUS\n'
printf '  ===================================\n\n'

if curl -fsS -o /dev/null http://localhost/dashboard/; then
    printf '  [RUNNING] Apache Web Server     http://localhost/dashboard/\n'
else
    printf '  [STOPPED] Apache Web Server\n'
fi

if nc -z 127.0.0.1 3306 2>/dev/null; then
    printf '  [RUNNING] MySQL Database        127.0.0.1:3306\n'
else
    printf '  [STOPPED] MySQL Database\n'
fi

if curl -fsS http://localhost/project/index.php | rg -q 'Devin Thomas'; then
    printf '  [RUNNING] Project page          http://localhost/project/index.php\n'
else
    printf '  [FAILED]  Project page\n'
fi

printf '\n  Installed at: /Applications/XAMPP\n'
printf '  Project file: /Applications/XAMPP/xamppfiles/htdocs/project/index.php\n\n'
