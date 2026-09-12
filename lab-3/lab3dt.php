<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Devin Thomas</title>
    <style>
        .array {
            border: 3px dashed black;
            width: 50%;
            margin: auto;
        }
    </style>
</head>
<body>
    <h1>PHP Array</h1>
    <h2>Devin Thomas</h2>

    <div class="array">
        <?php
            $DT = array("T", "h", "o", "m", "a", "s");
            echo $DT[0] . "<br>";
            echo $DT[1] . "<br>";
            echo $DT[2] . "<br>";
            echo $DT[3] . "<br>";
            echo $DT[4] . "<br>";
            echo $DT[5] . "<br>";
        ?>
    </div>

    <h2>What did you find challenging on this assignment?</h2>
    <p>
        The most challenging part of this assignment was learning how PHP arrays
        work and how individual elements can be accessed using their index
        numbers. I also had to make sure that each character of my last name was
        stored as a separate element and displayed on its own line. The CSS
        portion helped me practice using borders, widths, and margins to control
        how an element appears and where it is positioned on the page.
    </p>
</body>
</html>
