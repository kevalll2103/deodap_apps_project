<?php
// login.php
session_start();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = $_POST['email'] ?? '';
    $password = $_POST['password'] ?? '';

    if (empty($email) || empty($password)) {
        $response = [
            "success" => false,
            "message" => "Please provide email and password."
        ];
    } else {
        // 🔗 Your API endpoint (admin + user login check)
        $url = "https://customprint.deodap.com/api_dropshipper_tracker/admin.php";

        $postData = [
            'email' => $email,
            'password' => $password
        ];

        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($postData));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

        $responseJson = curl_exec($ch);
        $err = curl_error($ch);
        curl_close($ch);

        if ($err) {
            $response = [
                "success" => false,
                "message" => "cURL Error: $err"
            ];
        } else {
            $response = json_decode($responseJson, true);
        }

        if (!empty($response['success']) && $response['success'] == 1) {
            // ✅ store user data in session
            $_SESSION['user'] = $response['data'];

            // ✅ redirect by role
            if ($response['data']['role'] === "admin") {
                header("Location: admin/dashboard.php");
                exit();
            } elseif ($response['data']['role'] === "employee") {
                header("Location: employee/employee_dashboard.php");
                exit();
            } else {
                header("Location: dropshipper_wise_plan.php");
                exit();
            }
        }
    }

    if (!empty($response)) {
        $errorMsg = $response['message'] ?? "Login failed.";
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" href="assets/favicon.png" />
    <title>Login | Employee Portal</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body {
            font-family: 'Inter', sans-serif;
            background: url('assets/elisa.jpg') no-repeat center center fixed;
            background-size: cover;
            display: flex; min-height: 100vh;
            margin: 0; position: relative;
        }
        body::before {
            content:''; position:absolute; top:0; left:0; right:0; bottom:0;
            background:rgba(0,0,0,0.3); z-index:1;
        }
        .login-container {
            position: relative; z-index: 2;
            width:100%; max-width:500px;
            margin-left:auto; margin-right:50px;
            display:flex; align-items:center; padding:20px;
        }
        .login-card {
            background:rgba(255,255,255,0.95);
            backdrop-filter: blur(10px);
            padding:50px 40px; border-radius:20px;
            box-shadow:0 20px 40px rgba(0,0,0,0.1);
            text-align:center; animation:slideUp 0.6s ease-out;
            border:1px solid rgba(255,255,255,0.3);
        }
        @keyframes slideUp {
            from {opacity:0; transform:translateY(30px);}
            to {opacity:1; transform:translateY(0);}
        }
        .logo-section { margin-bottom:35px; }
        .logo-icon {
            width:70px; height:70px;
            background:linear-gradient(135deg,#667eea,#764ba2);
            border-radius:50%; display:flex; align-items:center; justify-content:center;
            margin:0 auto 20px; box-shadow:0 8px 20px rgba(102,126,234,0.3);
        }
        .logo-icon i { font-size:30px; color:white; }
        .login-card h2 {
            margin-bottom:10px; font-size:28px;
            font-weight:700; color:#2d3748;
        }
        .subtitle { color:#718096; font-size:16px; margin-bottom:35px; }
        .form-group { position:relative; margin-bottom:25px; text-align:left; }
        .form-group label { display:block; margin-bottom:8px; font-weight:600; color:#4a5568; font-size:14px; }
        .input-wrapper { position:relative; }
        .input-wrapper i {
            position:absolute; left:15px; top:50%; transform:translateY(-50%);
            color:#a0aec0; font-size:16px; z-index:1;
        }
        .form-group input {
            width:100%; padding:16px 16px 16px 50px;
            border:2px solid #e2e8f0; border-radius:12px;
            font-size:16px; background:rgba(255,255,255,0.9);
            transition:all 0.3s ease; font-weight:500;
        }
        .form-group input:focus {
            border-color:#667eea; outline:none;
            box-shadow:0 0 0 3px rgba(102,126,234,0.1);
            background:#fff; transform:translateY(-1px);
        }
        .login-btn {
            width:100%; padding:18px;
            background:linear-gradient(135deg,#667eea,#764ba2);
            border:none; color:#fff; font-size:16px; font-weight:600;
            border-radius:12px; cursor:pointer; transition:all 0.3s ease;
            text-transform:uppercase; letter-spacing:1px;
            margin-top:10px; position:relative; overflow:hidden;
        }
        .login-btn:hover { transform:translateY(-2px); box-shadow:0 10px 25px rgba(102,126,234,0.4); }
        .error-message {
            background:linear-gradient(135deg,#fed7d7,#feb2b2);
            color:#c53030; padding:15px 20px; border-radius:12px;
            margin-bottom:25px; font-size:14px; font-weight:500;
            border-left:4px solid #e53e3e; animation:shake 0.5s;
        }
        @keyframes shake {
            0%,100%{transform:translateX(0);} 25%{transform:translateX(-5px);} 75%{transform:translateX(5px);}
        }
        .footer-text { margin-top:30px; color:#718096; font-size:14px; }
        @media (max-width:768px){ .login-container{margin:auto; max-width:450px;} }
        @media (max-width:480px){
            .login-card{padding:40px 30px;}
            .login-card h2{font-size:24px;}
            .form-group input{padding:14px 14px 14px 45px; font-size:15px;}
            .login-btn{padding:16px; font-size:15px;}
        }
        .login-btn.loading { pointer-events:none; opacity:0.8; }
        .login-btn.loading::after {
            content:''; position:absolute; width:20px; height:20px;
            border:2px solid transparent; border-top:2px solid white;
            border-radius:50%; animation:spin 1s linear infinite;
            top:50%; left:50%; transform:translate(-50%,-50%);
        }
        @keyframes spin { 0%{transform:translate(-50%,-50%) rotate(0deg);} 100%{transform:translate(-50%,-50%) rotate(360deg);} }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="login-card">
            <div class="logo-section">
                <div class="logo-icon"><i class="fas fa-user-shield"></i></div>
                <h2>Employee Portal</h2>
                <p class="subtitle">Sign in to access your dashboard</p>
            </div>

            <?php if (!empty($errorMsg)): ?>
                <div class="error-message">
                    <i class="fas fa-exclamation-triangle"></i>
                    <?= htmlspecialchars($errorMsg) ?>
                </div>
            <?php endif; ?>

            <form action="login.php" method="POST" id="loginForm">
                <div class="form-group">
                    <label for="email">Email Address</label>
                    <div class="input-wrapper">
                        <i class="fas fa-envelope"></i>
                        <input type="email" id="email" name="email" placeholder="Enter your email address" required>
                    </div>
                </div>

                <div class="form-group">
                    <label for="password">Password</label>
                    <div class="input-wrapper">
                        <i class="fas fa-lock"></i>
                        <input type="password" id="password" name="password" placeholder="Enter your password" required>
                    </div>
                </div>

                <button type="submit" class="login-btn" id="loginBtn">
                    <span>Sign In</span>
                </button>
            </form>

            <div class="footer-text">
                <p>Secure employee access portal</p>
            </div>
        </div>
    </div>

    <script>
        document.getElementById('loginForm').addEventListener('submit', function() {
            const btn = document.getElementById('loginBtn');
            btn.classList.add('loading');
            btn.innerHTML = '';
        });
    </script>
</body>
</html>
