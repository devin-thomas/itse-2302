<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Devin Thomas</title>
    <style>
        body {
            margin: 0;
            background-color: #e8f1f5;
            color: #183b56;
            font-family: Georgia, "Times New Roman", serif;
        }

        main {
            width: 86%;
            margin: 2rem auto;
            padding: 2rem;
            border: 2px solid #2f6690;
            background-color: #ffffff;
        }

        h1 {
            color: #174a6e;
        }

        p {
            width: 88%;
            margin: 1.5rem auto;
            padding: 1rem;
            border: 2px solid #3d8b8b;
            color: #24527a;
            line-height: 1.6;
        }

        form {
            margin: 1.5rem 0;
        }

        label,
        input,
        button {
            margin: 0.4rem;
        }

        input,
        button {
            padding: 0.5rem;
        }

        button {
            background-color: #2f6690;
            color: #ffffff;
            border: 1px solid #174a6e;
            cursor: pointer;
        }

        table {
            border-collapse: collapse;
            margin-top: 1.5rem;
        }

        th,
        td {
            border: 1px solid #739ab8;
            padding: 0.7rem;
            text-align: left;
        }
    </style>
</head>
<body>
    <main>
        <h1>Devin Thomas</h1>
        <br>

        <form action="" method="post">
            <label for="first-name">First name:</label>
            <input type="text" id="first-name" name="first_name">
            <label for="last-name">Last name:</label>
            <input type="text" id="last-name" name="last_name">
            <button type="submit">Submit</button>
        </form>

        <table>
            <tr>
                <th>Assignment</th>
                <th>Student</th>
            </tr>
            <tr>
                <td>Lab 2</td>
                <td>Devin Thomas</td>
            </tr>
        </table>

        <p>
            One challenge on this assignment was dealing with PHP, which is new to me because I usually work in TypeScript for Next.js projects when I do web development. I had to pay attention to PHP syntax, the placement of the PHP tags, and how the server processes the file before the browser displays it. Writing the required HTML and CSS was more familiar, but connecting everything in one PHP page took extra care.
        </p>
    </main>

    <?php
    $name = 'Devin Thomas';
    echo '<p class="php-output">This page was rendered with PHP for ' . htmlspecialchars($name, ENT_QUOTES, 'UTF-8') . '.</p>';
    ?>
</body>
</html>
