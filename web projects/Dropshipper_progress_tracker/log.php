<?php
session_start();
include 'db.php';

if(isset($_POST['login'])) {
    $username = $_POST['username'];
    $password = $_POST['password'];
    $crn = $_POST['crn'];

    // Prepare SQL query to prevent SQL Injection
    $stmt = $conn->prepare("SELECT * FROM register_dropshipper WHERE username=:username AND crn=:crn LIMIT 1");
    $stmt->execute(['username' => $username, 'crn' => $crn]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if($user) {
        // Verify password
        if($user['password'] === $password) { // Replace with password_verify() if hashed
            // Store seller_id instead of id
            $_SESSION['user_id'] = $user['seller_id'];  
            $_SESSION['username'] = $user['username'];
            echo "Login successful! Welcome " . $user['username'];
            // Redirect to dashboard or homepage
            // header("Location: dashboard.php");
        } else {
            echo "Invalid password!";
        }
    } else {
        echo "User not found or invalid CRN!";
    }
}
?>

<!-- Simple HTML form -->
<form method="POST" action="">
    Username: <input type="text" name="username" required><br>
    CRN: <input type="text" name="crn" required><br>
    Password: <input type="password" name="password" required><br>
    <button type="submit" name="login">Login</button>
</form>
