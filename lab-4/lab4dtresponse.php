<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Devin Thomas</title>
</head>
<body>
    <h1>Add Number Result</h1>
    <h2>Devin Thomas</h2>

    <?php
        $firstNumber = $_POST['first_number'] ?? null;
        $secondNumber = $_POST['second_number'] ?? null;

        if (is_numeric($firstNumber) && is_numeric($secondNumber)) {
            $firstNumber = (float) $firstNumber;
            $secondNumber = (float) $secondNumber;
            $sum = $firstNumber + $secondNumber;

            echo '<p>The sum of ' . htmlspecialchars((string) $firstNumber, ENT_QUOTES, 'UTF-8') . ' and ' . htmlspecialchars((string) $secondNumber, ENT_QUOTES, 'UTF-8') . ' is ' . $sum . '.</p>';
        } else {
            echo '<p>Please return to the form and enter two numbers.</p>';
        }
    ?>

    <h2>What did you find challenging on this assignment?</h2>
    <p>
        The most challenging part of this assignment was connecting two PHP pages
        so that information entered in one form could be sent to another page and
        used in a calculation. I am still getting used to PHP because I normally
        use TypeScript with Next.js. Remembering the exact form action, input
        names, POST syntax, and variable types required careful attention. Testing
        with different numbers helped me confirm that the response page received
        the values and calculated their sum.
    </p>
</body>
</html>
