<?php
$host = getenv('DB_HOST');
$user = getenv('DB_USER');
$pass = getenv('DB_PASS');
$db   = getenv('DB_NAME');

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("❌ Échec de la connexion à la base de données : " . $conn->connect_error);
}

echo "<h1>🏢 Bienvenue sur l'Intranet YMMO</h1>";
echo "<p>✅ Connexion à la base de données <strong>$db</strong> réussie !</p>";
echo "<p>Utilisateur SQL : <strong>$user</strong></p>";
echo "<hr>";
echo "<p>Dernière mise à jour : " . date('d/m/Y H:i:s') . "</p>";
?>
