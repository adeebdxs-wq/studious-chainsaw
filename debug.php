<?php
// ملف لعرض أخطاء PHP
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

echo "<h2>معلومات النظام</h2>";
echo "PHP Version: " . phpversion() . "<br>";
echo "Document Root: " . $_SERVER['DOCUMENT_ROOT'] . "<br>";
echo "Request URI: " . $_SERVER['REQUEST_URI'] . "<br>";

echo "<h2>ملفات API</h2>";
$apiFiles = [
    '/ship-registration/api/config.php',
    '/ship-registration/api/auth/login.php',
    '/ship-registration/api/auth/check_session.php',
    '/ship-registration/api/auth/logout.php'
];

foreach ($apiFiles as $file) {
    $fullPath = $_SERVER['DOCUMENT_ROOT'] . $file;
    if (file_exists($fullPath)) {
        echo "✅ $file - موجود<br>";
    } else {
        echo "❌ $file - غير موجود<br>";
    }
}

echo "<h2>اتصال قاعدة البيانات</h2>";
try {
    require_once 'api/config.php';
    $pdo = getDB();
    if ($pdo) {
        echo "✅ اتصال قاعدة البيانات ناجح<br>";
        
        $stmt = $pdo->query("SELECT COUNT(*) as count FROM users");
        $result = $stmt->fetch();
        echo "عدد المستخدمين: " . $result['count'] . "<br>";
        
        if ($result['count'] > 0) {
            $users = $pdo->query("SELECT id, email, full_name, role FROM users LIMIT 5");
            echo "<h3>المستخدمين:</h3>";
            echo "<ul>";
            while ($user = $users->fetch()) {
                echo "<li>{$user['email']} - {$user['full_name']} ({$user['role']})</li>";
            }
            echo "</ul>";
        }
    } else {
        echo "❌ فشل اتصال قاعدة البيانات<br>";
    }
} catch (Exception $e) {
    echo "❌ خطأ: " . $e->getMessage() . "<br>";
}