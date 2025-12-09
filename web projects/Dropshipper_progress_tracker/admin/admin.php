<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

include 'db.php'; // DB connection

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        "success" => false,
        "message" => "Only POST method is allowed"
    ]);
    exit;
}

$email    = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';

if (empty($email) || empty($password)) {
    echo json_encode([
        "success" => false,
        "message" => "Email and Password are required"
    ]);
    exit;
}

try {
    // check user in admin_login table
    $stmt = $conn->prepare("SELECT id, email, password, role FROM admin_login WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 1) {
        $user = $result->fetch_assoc();

        if ($user['password'] === $password) { // plain text password check

            // ✅ update login time in admin_login
            $update = $conn->prepare("UPDATE admin_login SET login_time = NOW() WHERE id = ?");
            $update->bind_param("i", $user['id']);
            $update->execute();

            // ✅ insert new log for this user
            $insert = $conn->prepare("INSERT INTO admin_login_logs (user_id) VALUES (?)");
            $insert->bind_param("i", $user['id']);
            $insert->execute();

            echo json_encode([
                "success" => true,
                "message" => "Login successful",
                "data" => [
                    "id"       => $user['id'],
                    "email"    => $user['email'],
                    "role"     => $user['role']
                ]
            ]);
            exit;
        } else {
            echo json_encode([
                "success" => false,
                "message" => "Invalid password"
            ]);
            exit;
        }
    } else {
        // If not found in admin_login, check employee_register table
        $stmtEmp = $conn->prepare("SELECT id, email, plain_password, role FROM employee_register WHERE email = ?");
        $stmtEmp->bind_param("s", $email);
        $stmtEmp->execute();
        $resultEmp = $stmtEmp->get_result();

        if ($resultEmp->num_rows === 1) {
            $userEmp = $resultEmp->fetch_assoc();

            if ($userEmp['plain_password'] === $password) { // plain text password check

                // ✅ update login time in employee_register
                $updateEmp = $conn->prepare("UPDATE employee_register SET created_at = NOW() WHERE id = ?");
                $updateEmp->bind_param("i", $userEmp['id']);
                $updateEmp->execute();

                // ✅ insert new log for this user
                $insertEmp = $conn->prepare("INSERT INTO admin_login_logs (user_id, emp_code) VALUES (?, ?)");
                $insertEmp->bind_param("is", $userEmp['id'], $userEmp['emp_id'] ?? '');
                $insertEmp->execute();

                echo json_encode([
                    "success" => true,
                    "message" => "Login successful",
                    "data" => [
                        "id"       => $userEmp['id'],
                        "email"    => $userEmp['email'],
                        "role"     => $userEmp['role']
                    ]
                ]);
                exit;
            } else {
                echo json_encode([
                    "success" => false,
                    "message" => "Invalid password"
                ]);
                exit;
            }
        } else {
            echo json_encode([
                "success" => false,
                "message" => "User not found"
            ]);
            exit;
        }
    }
} catch (Exception $e) {
    echo json_encode([
        "success" => false,
        "message" => "Error: " . $e->getMessage()
    ]);
    exit;
}
