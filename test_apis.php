<?php
echo "<h2>اختبار APIs</h2>";

$apis = [
    'Ships API' => '/ship-registration/api/ships/get.php',
    'Applications API' => '/ship-registration/api/applications/get.php',
    'Notifications API' => '/ship-registration/api/notifications/get.php',
    'Login API' => '/ship-registration/api/auth/login.php'
];

foreach ($apis as $name => $url) {
    echo "<h3>$name</h3>";
    $fullUrl = "http://localhost" . $url;
    $ch = curl_init($fullUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HEADER, false);
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    
    echo "URL: $fullUrl<br>";
    echo "HTTP Status: $httpCode<br>";
    
    if ($httpCode == 200) {
        $json = json_decode($response, true);
        if ($json === null && json_last_error() !== JSON_ERROR_NONE) {
            echo "❌ ليس JSON صحيح<br>";
            echo "الاستجابة: " . htmlspecialchars(substr($response, 0, 200)) . "<br>";
        } else {
            echo "✅ JSON صحيح<br>";
            echo "عدد العناصر: " . (is_array($json) ? count($json) : 'كائن') . "<br>";
        }
    } else {
        echo "❌ فشل: " . htmlspecialchars(substr($response, 0, 200)) . "<br>";
    }
    
    echo "<hr>";
}
?>