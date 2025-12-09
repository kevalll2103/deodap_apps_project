<?php
// splashscreen.php
session_start();

// Redirect based on session and role after 3 seconds
if (isset($_SESSION['user'])) {
    $role = $_SESSION['user']['role'] ?? '';

    if ($role === 'admin') {
        header("Refresh: 3; URL=admin/dashboard.php");
    } elseif ($role === 'employee') {
        header("Refresh: 3; URL=employee/employee_dashboard.php");
    }
} else {
    header("Refresh: 3; URL=login.php");
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" href="assets/favicon.png" />
    <title>Welcome | Deodap Admin</title>
    <meta name="description" content="Deodap Admin Portal - Dropshipper Progress Tracker">
    <link rel="icon" href="https://www.deodap.in/cdn/shop/files/deodap-logo.png?v=169" />
    <!-- Font Awesome for icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 25%, #ff9ff3 50%, #54a0ff 75%, #5f27cd 100%);
            background-size: 400% 400%;
            animation: gradientShift 8s ease infinite;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            color: white;
            flex-direction: column;
            text-align: center;
            overflow: hidden;
            position: relative;
        }

        /* Animated background particles */
        .particles {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
            z-index: 1;
        }

        .particle {
            position: absolute;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 50%;
            animation: float 6s ease-in-out infinite;
        }

        .ecommerce-icon {
            position: absolute;
            color: rgba(255, 255, 255, 0.2);
            font-size: 24px;
            animation: float 8s ease-in-out infinite;
        }

        .ecommerce-icon:nth-child(6) { left: 15%; top: 20%; animation-delay: 0s; }
        .ecommerce-icon:nth-child(7) { left: 85%; top: 30%; animation-delay: 2s; }
        .ecommerce-icon:nth-child(8) { left: 10%; top: 70%; animation-delay: 4s; }
        .ecommerce-icon:nth-child(9) { left: 90%; top: 80%; animation-delay: 1s; }
        .ecommerce-icon:nth-child(10) { left: 50%; top: 10%; animation-delay: 3s; }

        .particle:nth-child(1) { width: 80px; height: 80px; left: 10%; animation-delay: 0s; }
        .particle:nth-child(2) { width: 120px; height: 120px; left: 20%; animation-delay: 2s; }
        .particle:nth-child(3) { width: 60px; height: 60px; left: 70%; animation-delay: 4s; }
        .particle:nth-child(4) { width: 100px; height: 100px; left: 80%; animation-delay: 1s; }
        .particle:nth-child(5) { width: 40px; height: 40px; left: 50%; animation-delay: 3s; }

        @keyframes gradientShift {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }

        @keyframes float {
            0%, 100% { transform: translateY(100vh) rotate(0deg); opacity: 0; }
            10% { opacity: 1; }
            90% { opacity: 1; }
            100% { transform: translateY(-100px) rotate(360deg); opacity: 0; }
        }

        .splash-container {
            position: relative;
            z-index: 10;
            animation: fadeInUp 1s ease-out;
        }

        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .logo-container {
            position: relative;
            margin-bottom: 40px;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .logo {
            width: 150px;
            height: 150px;
            background: rgba(255, 255, 255, 0.15);
            backdrop-filter: blur(10px);
            border: 2px solid rgba(255, 255, 255, 0.2);
            border-radius: 50%;
            display: flex;
            justify-content: center;
            align-items: center;
            color: white;
            font-weight: bold;
            font-size: 32px;
            box-shadow: 
                0 8px 32px rgba(0, 0, 0, 0.3),
                inset 0 1px 0 rgba(255, 255, 255, 0.2);
            position: relative;
            overflow: hidden;
            margin: 0 auto;
        }

        .logo::before {
            content: '';
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: linear-gradient(45deg, transparent, rgba(255, 255, 255, 0.1), transparent);
            transform: rotate(45deg);
            animation: shimmer 2s linear infinite;
        }

        .logo img {
            width: 80px;
            height: auto;
            z-index: 2;
            position: relative;
        }



        @keyframes shimmer {
            0% { transform: translateX(-100%) translateY(-100%) rotate(45deg); }
            100% { transform: translateX(100%) translateY(100%) rotate(45deg); }
        }

        .brand-text {
            margin-bottom: 30px;
        }

        .brand-text h1 {
            font-size: 48px;
            margin-bottom: 10px;
            font-weight: 700;
            letter-spacing: 2px;
            background: linear-gradient(45deg, #fff, #f0f0f0);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            text-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
            animation: textGlow 2s ease-in-out infinite alternate;
        }

        .brand-text .subtitle {
            font-size: 20px;
            opacity: 0.9;
            font-weight: 400;
            letter-spacing: 1px;
            margin-bottom: 8px;
        }

        .brand-text .tagline {
            font-size: 16px;
            opacity: 0.7;
            font-style: italic;
        }

        @keyframes textGlow {
            from { text-shadow: 0 2px 10px rgba(0, 0, 0, 0.3); }
            to { text-shadow: 0 2px 20px rgba(255, 255, 255, 0.3); }
        }

        .loading-section {
            margin-top: 40px;
        }

        .loading-text {
            font-size: 18px;
            margin-bottom: 20px;
            opacity: 0.8;
            animation: pulse 2s ease-in-out infinite;
        }

        .loader-container {
            position: relative;
            display: inline-block;
        }

        .loader {
            width: 50px;
            height: 50px;
            border: 3px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top: 3px solid #fff;
            animation: spin 1s linear infinite;
        }

        .loader-ring {
            position: absolute;
            top: -10px;
            left: -10px;
            width: 70px;
            height: 70px;
            border: 2px solid rgba(255, 255, 255, 0.1);
            border-radius: 50%;
            border-top: 2px solid rgba(255, 255, 255, 0.3);
            animation: spin 2s linear infinite reverse;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        @keyframes pulse {
            0%, 100% { opacity: 0.8; }
            50% { opacity: 1; }
        }

        .progress-bar {
            width: 200px;
            height: 4px;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 2px;
            margin: 30px auto 0;
            overflow: hidden;
            position: relative;
        }

        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #fff, rgba(255, 255, 255, 0.8));
            border-radius: 2px;
            animation: progress 3s ease-in-out infinite;
        }

        @keyframes progress {
            0% { width: 0%; }
            50% { width: 70%; }
            100% { width: 100%; }
        }

        /* Responsive Design */
        @media (max-width: 768px) {
            .logo {
                width: 120px;
                height: 120px;
                font-size: 28px;
            }

            .logo img {
                width: 60px;
            }

            .brand-text h1 {
                font-size: 36px;
                letter-spacing: 1px;
            }

            .brand-text .subtitle {
                font-size: 18px;
            }

            .brand-text .tagline {
                font-size: 14px;
            }

            .particle {
                display: none; /* Hide particles on mobile for performance */
            }
        }

        @media (max-width: 480px) {
            .logo {
                width: 100px;
                height: 100px;
                font-size: 24px;
            }

            .logo img {
                width: 50px;
            }

            .brand-text h1 {
                font-size: 28px;
            }

            .brand-text .subtitle {
                font-size: 16px;
            }

            .progress-bar {
                width: 150px;
            }
        }

        /* Accessibility improvements */
        @media (prefers-reduced-motion: reduce) {
            * {
                animation-duration: 0.01ms !important;
                animation-iteration-count: 1 !important;
                transition-duration: 0.01ms !important;
            }
        }
    </style>
</head>
<body>
    <!-- Animated background particles -->
    <div class="particles">
        <div class="particle"></div>
        <div class="particle"></div>
        <div class="particle"></div>
        <div class="particle"></div>
        <div class="particle"></div>
        <div class="ecommerce-icon"><i class="fas fa-shopping-bag"></i></div>
        <div class="ecommerce-icon"><i class="fas fa-credit-card"></i></div>
        <div class="ecommerce-icon"><i class="fas fa-truck"></i></div>
        <div class="ecommerce-icon"><i class="fas fa-tags"></i></div>
        <div class="ecommerce-icon"><i class="fas fa-chart-bar"></i></div>
    </div>

    <div class="splash-container">
        <div class="logo-container">
            <div class="logo">
                <img src="assets/logo.png" alt="Deodap Logo" onerror="this.style.display='none'; this.parentNode.innerHTML='<i class=\'fas fa-shopping-cart\'></i>';">
            </div>
        </div>

        <div class="brand-text">
            <h1>Deodap E-Commerce</h1>
            <p class="subtitle">Dropshipping Management Hub</p>
            <p class="tagline">Scale Your Online Business • Track Orders • Maximize Profits</p>
        </div>

        <div class="loading-section">
            <p class="loading-text">
                <i class="fas fa-shopping-cart" style="margin-right: 8px;"></i>
                Setting up your store...
            </p>
            <div class="loader-container">
                <div class="loader-ring"></div>
                <div class="loader"></div>
            </div>
            <div class="progress-bar">
                <div class="progress-fill"></div>
            </div>
        </div>
    </div>

    <script>
        // Add some interactive elements
        document.addEventListener('DOMContentLoaded', function() {
            // Create additional floating elements
            const container = document.querySelector('.particles');
            
            // Add more particles dynamically
            for (let i = 0; i < 3; i++) {
                const particle = document.createElement('div');
                particle.className = 'particle';
                particle.style.width = Math.random() * 60 + 20 + 'px';
                particle.style.height = particle.style.width;
                particle.style.left = Math.random() * 100 + '%';
                particle.style.animationDelay = Math.random() * 6 + 's';
                particle.style.animationDuration = (Math.random() * 3 + 4) + 's';
                container.appendChild(particle);
            }

            // Add click interaction to logo
            const logo = document.querySelector('.logo');
            logo.addEventListener('click', function() {
                this.style.transform = 'scale(1.1) rotate(360deg)';
                setTimeout(() => {
                    this.style.transform = '';
                }, 600);
            });

            // Update loading text dynamically
            const loadingTexts = [
                '<i class="fas fa-shopping-cart"></i> Setting up your store...',
                '<i class="fas fa-truck fa-spin"></i> Loading shipping options...',
                '<i class="fas fa-chart-line"></i> Preparing sales analytics...',
                '<i class="fas fa-dollar-sign"></i> Calculating profits...',
                '<i class="fas fa-boxes"></i> Syncing inventory...',
                '<i class="fas fa-check-circle"></i> Ready to sell!'
            ];
            
            let textIndex = 0;
            const loadingTextEl = document.querySelector('.loading-text');
            
            const textInterval = setInterval(() => {
                textIndex = (textIndex + 1) % loadingTexts.length;
                loadingTextEl.innerHTML = loadingTexts[textIndex];
            }, 750);

            // Clear interval after redirect
            setTimeout(() => {
                clearInterval(textInterval);
            }, 2800);
        });
    </script>
</body>
</html>
