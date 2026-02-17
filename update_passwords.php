<?php
// ملف: C:\xampp\htdocs\ship-registration\update_passwords.php
require_once 'api/config.php';

echo "<h2>تحديث كلمات المرور</h2>";

$pdo = getDB();
if (!$pdo) {
    die("❌ فشل الاتصال بقاعدة البيانات");
}

// كلمات المرور الجديدة
$passwords = [
    'admin@maritime.gov.ye' => 'admin123',
    'aden@maritime.gov.ye' => 'aden123',
    'mukalla@maritime.gov.ye' => 'mukalla123'
];

foreach ($passwords as $email => $plainPassword) {
    // تشفير كلمة المرور
    $hashedPassword = password_hash($plainPassword, PASSWORD_DEFAULT);
    
    // تحديث في قاعدة البيانات
    $stmt = $pdo->prepare("UPDATE users SET password_hash = ? WHERE email = ?");
    $result = $stmt->execute([$hashedPassword, $email]);
    
    if ($result && $stmt->rowCount() > 0) {
        echo "✅ تم تحديث كلمة المرور لـ: $email<br>";
        echo "كلمة المرور الجديدة: $plainPassword<br>";
        echo "التشفير الجديد: $hashedPassword<br><br>";
    } else {
        echo "❌ فشل تحديث كلمة المرور لـ: $email (قد يكون البريد غير موجود)<br><br>";
    }
}

// التحقق من التحديث
echo "<h3>البيانات بعد التحديث:</h3>";
$stmt = $pdo->query("SELECT id, email, password_hash FROM users");
$users = $stmt->fetchAll();

foreach ($users as $user) {
    echo "البريد: " . $user['email'] . "<br>";
    echo "كلمة المرور المشفرة: " . $user['password_hash'] . "<br><br>";
}
?>