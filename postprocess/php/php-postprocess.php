<?php

$dir = './generated/php/lib/Model';
if ($argc > 2) {
    die("Only supports one directory to process at a time.".PHP_EOL);
} else if ($argc == 2) {
    $dir = $argv[1];
}

if (!is_dir($dir)) {
    die("Given path " . $dir . " is not a valid directory path or does not exist.".PHP_EOL);
}

$dir=realpath($dir);

echo "Processing all generated model files in: " . $dir.PHP_EOL;
$files = scandir($dir);

echo "Found " . count($files)." files in directory.".PHP_EOL;

$model_namespace = "\Calcasa\Api\V0\Model\\";

$full_regex = '/protected static \$openAPITypes = \[[^;]*\];/s';

$sub_regex = "/'(?P<name>[^']+)'\s*=>\s*'(?P<type>[^']+)'(?P<comma>,?)/m";

$lang_primitives = array(
    "bool",
    "boolean",
    "int",
    "integer",
    "double",
    "float",
    "string",
    "object",
    "array",
    "\\DateTime",
    "\\SplFileObject",
    "mixed",
    "number",
    "void",
    "byte"
);
foreach ($files as $file) {
    if ($file == "ModelInterface.php")
        continue;

    $filepath = realpath($dir . '/' . $file);
    if (!is_file($filepath))
        continue;
    if (!is_readable($filepath)) {
        echo "Unreadable file: " . $filepath . PHP_EOL;
        continue;
    }

    echo "Processing file: " . $filepath . PHP_EOL;
    $filecontent = file_get_contents($filepath);
    $matches = array();
    if (preg_match($full_regex, $filecontent, $matches, PREG_OFFSET_CAPTURE)) {
        $openApiTypes = $matches[0][0];
        $openApiTypesOffset = $matches[0][1];
        $submatches = array();

        $openApiTypesFixed = preg_replace_callback(
            $sub_regex,
            function ($callback_matches) {
                global $lang_primitives, $model_namespace;
                $type = $callback_matches['type'];
                if (!in_array($type, $lang_primitives) && strstr($type, $model_namespace) === false) {
                    return "'" . $callback_matches['name'] . "' => '" . $model_namespace . $callback_matches['type'] . "'" . $callback_matches['comma'];
                } else {
                    return $callback_matches[0];
                }
            },
            $openApiTypes
        );
        $filecontent = substr_replace($filecontent, $openApiTypesFixed, $openApiTypesOffset, strlen($openApiTypes));

        file_put_contents($filepath, $filecontent);
    }
}
