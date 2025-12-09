<?php  
// comments.php
session_start();

// Check if user is logged in
if (!isset($_SESSION['user'])) {
    header("Location: login.php");
    exit();
}

$user = $_SESSION['user'];
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" href="assets/favicon.png" />
    <title>Comments & Feedback - Admin Portal</title>
    <!-- Font Awesome for icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root {
            --primary-color: #6366f1;
            --secondary-color: #4f46e5;
            --accent-color: #10b981;
            --text-primary: #111827;
            --text-secondary: #6b7280;
            --border-color: #e5e7eb;
            --background-light: #f9fafb;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #ffffff;
            min-height: 100vh;
            overflow-x: hidden;
            color: var(--text-primary);
            line-height: 1.6;
        }

        /* Mobile Menu Button */
        .mobile-menu-btn {
            display: none;
            position: fixed;
            top: 20px;
            left: 20px;
            z-index: 1001;
            background: var(--primary-color);
            color: white;
            border: none;
            padding: 12px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 18px;
            box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3);
        }

        .mobile-menu-btn:hover {
            background: var(--secondary-color);
        }

        /* Sidebar - Same as dashboard */
        .sidebar {
            height: 100vh;
            width: 280px;
            position: fixed;
            top: 0;
            left: 0;
            background: #ffffff;
            box-shadow: 2px 0 15px rgba(0,0,0,0.08);
            z-index: 1000;
            overflow-y: auto;
            border-right: 1px solid var(--border-color);
        }

        .sidebar-header {
            padding: 30px 20px;
            border-bottom: 1px solid var(--border-color);
            background: var(--primary-color);
        }

        .sidebar-brand {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 8px;
        }

        .sidebar-brand .brand-icon {
            width: 32px;
            height: 32px;
            background: rgba(255,255,255,0.2);
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 18px;
        }

        .sidebar-brand h3 {
            color: white;
            font-size: 20px;
            font-weight: 700;
            margin: 0;
        }

        .sidebar-subtitle {
            color: rgba(255,255,255,0.8);
            font-size: 14px;
            margin: 0;
            font-weight: 400;
        }

        .nav-menu {
            padding: 16px 0;
        }

        .nav-section {
            margin-bottom: 8px;
        }

        .nav-section-title {
            padding: 8px 20px;
            font-size: 12px;
            font-weight: 600;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 4px;
        }

        .nav-item {
            display: block;
            padding: 12px 20px;
            text-decoration: none;
            color: var(--text-primary);
            border: none;
            background: none;
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 14px;
            font-weight: 500;
            position: relative;
            cursor: pointer;
        }

        .nav-item:hover {
            background-color: var(--background-light);
            color: var(--primary-color);
        }

        .nav-item.active {
            background-color: #eff6ff;
            color: #2563eb;
            border-right: 3px solid #2563eb;
        }

        .nav-item i {
            width: 20px;
            text-align: center;
            font-size: 16px;
        }

        .nav-item.logout {
            color: #dc2626;
            margin-top: 16px;
            border-top: 1px solid #e5e7eb;
            padding-top: 20px;
        }

        .nav-item.logout:hover {
            background-color: #fef2f2;
            color: #dc2626;
        }

        .user-profile {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            padding: 20px;
            border-top: 1px solid #e5e7eb;
            background: #f9fafb;
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .user-avatar {
            width: 40px;
            height: 40px;
            background: var(--primary-color);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 16px;
        }

        .user-details h4 {
            font-size: 14px;
            font-weight: 600;
            color: var(--text-primary);
            margin-bottom: 2px;
        }

        .user-details p {
            font-size: 12px;
            color: var(--text-secondary);
            margin: 0;
        }

        .sidebar-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            z-index: 999;
        }

        /* Main content */
        .main {
            margin-left: 280px;
            padding: 25px;
            min-height: 100vh;
            background: var(--background-light);
        }

        .header {
            background: white;
            padding: 35px 30px;
            border-radius: 16px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            margin-bottom: 25px;
            border: 1px solid var(--border-color);
        }

        .header-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 20px;
        }

        .welcome-text h2 {
            font-size: 28px;
            margin-bottom: 10px;
            color: var(--text-primary);
            font-weight: 700;
        }

        .welcome-text p {
            color: var(--text-secondary);
            font-size: 16px;
            margin-bottom: 20px;
            line-height: 1.6;
        }

        .breadcrumb {
            display: flex;
            align-items: center;
            gap: 8px;
            color: var(--text-secondary);
            font-size: 14px;
        }

        .breadcrumb i {
            color: var(--primary-color);
        }

        /* Filter Controls */
        .filter-controls {
            display: flex;
            gap: 16px;
            align-items: center;
            flex-wrap: wrap;
        }

        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .filter-label {
            font-size: 12px;
            font-weight: 600;
            color: var(--text-secondary);
            text-transform: uppercase;
        }

        .filter-select, .filter-input {
            padding: 8px 12px;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            font-size: 14px;
            background: white;
            color: var(--text-primary);
            min-width: 150px;
        }

        .filter-select:focus, .filter-input:focus {
            outline: none;
            border-color: var(--primary-color);
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
        }

        .filter-btn {
            background: var(--primary-color);
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 8px;
            font-size: 14px;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 8px;
            margin-top: 18px;
        }

        .filter-btn:hover {
            background: var(--secondary-color);
        }

        .clear-btn {
            background: #6b7280;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 8px;
            font-size: 14px;
            cursor: pointer;
            margin-top: 18px;
        }

        .clear-btn:hover {
            background: #4b5563;
        }

        /* Stats Cards */
        .stats-row {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 25px;
        }

        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            border: 1px solid var(--border-color);
        }

        .stat-value {
            font-size: 24px;
            font-weight: 700;
            color: var(--text-primary);
            margin-bottom: 4px;
        }

        .stat-label {
            font-size: 14px;
            color: var(--text-secondary);
        }

        /* Comments Container */
        .comments-container {
            background: white;
            border-radius: 16px;
            box-shadow: 0 4px 25px rgba(0,0,0,0.08);
            border: 1px solid var(--border-color);
            overflow: hidden;
        }

        .comments-header {
            padding: 30px;
            border-bottom: 1px solid var(--border-color);
        }

        .comments-title {
            font-size: 24px;
            font-weight: 700;
            color: var(--text-primary);
            margin-bottom: 8px;
        }

        .comments-subtitle {
            color: var(--text-secondary);
            font-size: 14px;
        }

        /* Seller Groups */
        .seller-group {
            margin-bottom: 30px;
            border: 1px solid var(--border-color);
            border-radius: 12px;
            overflow: hidden;
            background: white;
        }

        .seller-header {
            display: flex;
            align-items: flex-start;
            gap: 16px;
            padding: 24px 30px;
            background: #f8fafc;
            border-bottom: 2px solid var(--primary-color);
        }

        .seller-info {
            flex: 1;
        }

        .seller-meta {
            display: flex;
            align-items: center;
            gap: 16px;
            margin-bottom: 12px;
            flex-wrap: wrap;
        }

        .seller-name {
            font-weight: 700;
            color: var(--text-primary);
            font-size: 18px;
        }

        .seller-badge {
            background: var(--primary-color);
            color: white;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }

        .comment-count {
            background: var(--accent-color);
            color: white;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }

        .seller-details {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 12px;
            font-size: 14px;
            color: var(--text-secondary);
        }

        .seller-comments {
            padding: 0;
        }

        /* Compact Comment Items */
        .comment-item-compact {
            padding: 20px 30px;
            border-bottom: 1px solid #f3f4f6;
            transition: all 0.2s ease;
        }

        .comment-item-compact:hover {
            background-color: #fafafa;
        }

        .comment-item-compact:last-child {
            border-bottom: none;
        }

        .comment-mini-header {
            margin-bottom: 12px;
        }

        .plan-step-info {
            display: flex;
            align-items: center;
            gap: 16px;
            flex-wrap: wrap;
            font-size: 14px;
        }

        .plan-name, .step-name {
            background: #e0f2fe;
            color: #0277bd;
            padding: 6px 12px;
            border-radius: 8px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .step-name {
            background: #f3e8ff;
            color: #7c3aed;
        }

        .comment-date {
            color: var(--text-secondary);
            font-size: 13px;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .comment-content-compact {
            background: #f8fafc;
            padding: 16px;
            border-radius: 8px;
            border-left: 4px solid var(--primary-color);
            font-size: 15px;
            line-height: 1.6;
            color: var(--text-primary);
        }

        /* Comment Items */
        .comments-list {
            max-height: 600px;
            overflow-y: auto;
        }

        .comment-item {
            padding: 24px 30px;
            border-bottom: 1px solid #f3f4f6;
            transition: all 0.2s ease;
        }

        .comment-item:hover {
            background-color: #fafafa;
        }

        .comment-header {
            display: flex;
            align-items: flex-start;
            gap: 16px;
            margin-bottom: 12px;
        }

        .comment-avatar {
            width: 40px;
            height: 40px;
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 14px;
            flex-shrink: 0;
        }

        .comment-info {
            flex: 1;
        }

        .comment-meta {
            display: flex;
            align-items: center;
            gap: 16px;
            margin-bottom: 8px;
            flex-wrap: wrap;
        }

        .comment-author {
            font-weight: 600;
            color: var(--text-primary);
            font-size: 16px;
        }

        .comment-date {
            color: var(--text-secondary);
            font-size: 14px;
        }

        .comment-badge {
            background: #e0f2fe;
            color: #0277bd;
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }

        .comment-details {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 12px;
            margin-bottom: 12px;
            font-size: 14px;
            color: var(--text-secondary);
        }

        .detail-item {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .detail-item i {
            width: 16px;
            color: var(--primary-color);
        }

        .comment-content {
            background: #f8fafc;
            padding: 16px;
            border-radius: 8px;
            border-left: 4px solid var(--primary-color);
            font-size: 15px;
            line-height: 1.6;
            color: var(--text-primary);
        }

        /* Loading and Empty States */
        .loading {
            text-align: center;
            padding: 60px;
            color: var(--text-secondary);
        }

        .loading i {
            font-size: 32px;
            margin-bottom: 16px;
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
        }

        .empty-state {
            text-align: center;
            padding: 80px 30px;
            color: var(--text-secondary);
        }

        .empty-state i {
            font-size: 48px;
            margin-bottom: 16px;
            color: #d1d5db;
        }

        .empty-state h3 {
            font-size: 18px;
            margin-bottom: 8px;
            color: var(--text-primary);
        }

        /* Responsive Design */
        @media (max-width: 768px) {
            .mobile-menu-btn {
                display: block;
            }

            .sidebar {
                transform: translateX(-100%);
            }

            .sidebar.open {
                transform: translateX(0);
            }

            .sidebar-overlay.active {
                display: block;
            }

            .main {
                margin-left: 0;
                padding: 80px 20px 20px 20px;
            }

            .header {
                padding: 30px 20px;
            }

            .header-content {
                flex-direction: column;
                align-items: flex-start;
            }

            .filter-controls {
                flex-direction: column;
                align-items: stretch;
            }

            .filter-group {
                flex-direction: row;
                align-items: center;
                justify-content: space-between;
            }

            .filter-select, .filter-input {
                min-width: 0;
                flex: 1;
            }

            .comments-header {
                padding: 20px;
            }

            .comment-item {
                padding: 20px;
            }

            .comment-meta {
                flex-direction: column;
                align-items: flex-start;
                gap: 8px;
            }

            .comment-details {
                grid-template-columns: 1fr;
            }

            .stats-row {
                grid-template-columns: repeat(2, 1fr);
            }

            .seller-header {
                padding: 20px;
                flex-direction: column;
                align-items: flex-start;
                gap: 12px;
            }

            .seller-meta {
                flex-direction: column;
                align-items: flex-start;
                gap: 8px;
            }

            .seller-details {
                grid-template-columns: 1fr;
            }

            .comment-item-compact {
                padding: 16px 20px;
            }

            .plan-step-info {
                flex-direction: column;
                align-items: flex-start;
                gap: 8px;
            }
        }
    </style>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body style="margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #ffffff; min-height: 100vh; overflow-x: hidden; color: #111827; line-height: 1.6;">

<!-- Mobile Menu Button -->
<button class="mobile-menu-btn" onclick="toggleSidebar()" style="display: none; position: fixed; top: 20px; left: 20px; z-index: 1001; background: #6366f1; color: white; border: none; padding: 12px; border-radius: 8px; cursor: pointer; font-size: 18px; box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3);">
    <i class="fas fa-bars"></i>
</button>

<!-- Sidebar Overlay -->
<div class="sidebar-overlay" onclick="closeSidebar()" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 999;"></div>

<div class="sidebar" id="sidebar" style="height: 100vh; width: 280px; position: fixed; top: 0; left: 0; background: #ffffff; box-shadow: 2px 0 15px rgba(0,0,0,0.08); z-index: 1000; overflow-y: auto; border-right: 1px solid #e5e7eb;">
    <div style="padding: 30px 20px; border-bottom: 1px solid #e5e7eb; background: #6366f1;">
        <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 8px;">
            <div style="width: 32px; height: 32px; background: rgba(255,255,255,0.2); border-radius: 8px; display: flex; align-items: center; justify-content: center; color: white; font-size: 18px;">
                <i class="fas fa-clipboard-list"></i>
            </div>
            <div>
                <h3 style="color: white; font-size: 20px; font-weight: 700; margin: 0;">Plan Progress Tracking</h3>
                <p style="color: rgba(255,255,255,0.8); font-size: 14px; margin: 0; font-weight: 400;">Dropshipper Management</p>
            </div>
        </div>
    </div>

    <nav style="padding: 16px 0;">
        <div style="margin-bottom: 8px;">
            <a href="dashboard.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
                <i class="fas fa-chart-pie" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>Dashboard</span>
            </a>
        </div>

        <div style="margin-bottom: 8px;">
            <div style="padding: 8px 20px; font-size: 12px; font-weight: 600; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;">Management</div>
            <a href="plans.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
                <i class="fas fa-clipboard-list" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>Plans Management</span>
            </a>
            <div style="padding: 8px 20px; font-size: 12px; font-weight: 600; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;">EMPLOYEE</div>

            <a href="register_employee.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
                <i class="fas fa-users" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>employees Register</span>
            </a>
            <a href="employee_details.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
                <i class="fas fa-users" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>employees Details</span>
            </a>
                        <div style="padding: 8px 20px; font-size: 12px; font-weight: 600; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;">DROPSHIPPER</div>

            <a href="register_dropshipper.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
                <i class="fas fa-users" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>Dropshippers Register</span>
            </a>
            <a href="register_dropshipper_details.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
                <i class="fas fa-users" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>Dropshippers Details</span>
            </a>
            <div style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; color: #2563eb; background-color: #eff6ff; border-right: 3px solid #2563eb; font-size: 14px; font-weight: 500;">
                <i class="fas fa-comments" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>Comments & Feedback</span>
            </div>
        </div>

    </nav>

    <!-- Enhanced Admin Profile Sidebar -->
    <div style="position: absolute; bottom: 0; left: 0; right: 0; background: #ffffff; border-top: 1px solid #e5e7eb;">
        <!-- Profile Header -->
        <div style="padding: 12px 16px; background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white;">
            <div style="display: flex; align-items: center; gap: 10px;">
                <div style="width: 36px; height: 36px; background: rgba(255,255,255,0.2); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 14px; border: 2px solid rgba(255,255,255,0.3);">
                    <?= strtoupper(substr($user['email'], 0, 2)) ?>
                </div>
                <div style="flex: 1;">
                    <h4 style="font-size: 14px; font-weight: 700; margin-bottom: 1px;">Admin User</h4>
                    <p style="font-size: 11px; opacity: 0.9; margin: 0; word-break: break-all;"><?= htmlspecialchars($user['email']) ?></p>
                </div>
                <div onclick="toggleProfileMenu()" style="width: 28px; height: 28px; background: rgba(255,255,255,0.2); border-radius: 6px; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.3s ease;" id="profile-toggle">
                    <i class="fas fa-chevron-up" style="font-size: 12px;"></i>
                </div>
            </div>
        </div>

        <!-- Expandable Profile Menu -->
        <div id="profile-menu" style="max-height: 0; overflow: hidden; transition: max-height 0.3s ease; background: #ffffff;">
            <div style="padding: 0;">
                <!-- Profile Actions -->
                <div style="padding: 8px 0;">
                    <a href="profile.php" style="display: flex; align-items: center; gap: 10px; padding: 8px 16px; text-decoration: none; color: #111827; font-size: 13px; font-weight: 500; transition: all 0.3s ease;" onmouseover="this.style.background='#f9fafb'" onmouseout="this.style.background='transparent'">
                        <i class="fas fa-user-edit" style="width: 14px; text-align: center; color: #6366f1;"></i>
                        <span>Edit Profile</span>
                    </a>
                    
                    <a href="settings.php" style="display: flex; align-items: center; gap: 10px; padding: 8px 16px; text-decoration: none; color: #111827; font-size: 13px; font-weight: 500; transition: all 0.3s ease;" onmouseover="this.style.background='#f9fafb'" onmouseout="this.style.background='transparent'">
                        <i class="fas fa-cog" style="width: 14px; text-align: center; color: #6366f1;"></i>
                        <span>Settings</span>
                    </a>
                </div>

                <!-- Logout Section -->
                <div style="padding: 12px 16px; border-top: 1px solid #f3f4f6;">
                    <a href="logout.php" style="display: flex; align-items: center; justify-content: center; gap: 6px; padding: 8px; background: #fee2e2; color: #dc2626; text-decoration: none; border-radius: 6px; font-size: 13px; font-weight: 600; transition: all 0.3s ease;" onmouseover="this.style.background='#fecaca'" onmouseout="this.style.background='#fee2e2'">
                        <i class="fas fa-sign-out-alt"></i>
                        <span>Sign Out</span>
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="main" style="margin-left: 280px; padding: 25px; min-height: 100vh; padding-bottom: 80px; background: #f9fafb;">
    <!-- Header -->
    <div class="header">
        <div class="header-content">
            <div class="welcome-text">
                <div class="breadcrumb">
                    <i class="fas fa-home"></i>
                    <a href="dashboard.php" style="color: var(--text-secondary); text-decoration: none;">Dashboard</a>
                    <span>/</span>
                    <span>Comments & Feedback</span>
                </div>
                <h2>Comments & Feedback</h2>
                <p>Manage and review all comments from dropshippers across different plans and steps.</p>
            </div>
            
            <!-- Filter Controls -->
            <div class="filter-controls">
                <div class="filter-group">
                    <label class="filter-label">Filter by Seller</label>
                    <select id="sellerFilter" class="filter-select">
                        <option value="">All Sellers</option>
                    </select>
                </div>
                
                <div class="filter-group">
                    <label class="filter-label">Filter by Plan</label>
                    <select id="planFilter" class="filter-select">
                        <option value="">All Plans</option>
                    </select>
                </div>
                
                <div class="filter-group">
                    <label class="filter-label">Search Comments</label>
                    <input type="text" id="searchInput" class="filter-input" placeholder="Search comments...">
                </div>
                
                <button class="filter-btn" onclick="applyFilters()">
                    <i class="fas fa-filter"></i>
                    Apply Filters
                </button>
                
                <button class="clear-btn" onclick="clearFilters()">
                    <i class="fas fa-times"></i>
                    Clear
                </button>
            </div>
        </div>
    </div>

    <!-- Stats Row -->
    <div class="stats-row">
        <div class="stat-card">
            <div class="stat-value" id="totalComments">-</div>
            <div class="stat-label">Total Comments</div>
        </div>
        <div class="stat-card">
            <div class="stat-value" id="uniqueSellers">-</div>
            <div class="stat-label">Unique Sellers</div>
        </div>
        <div class="stat-card">
            <div class="stat-value" id="todayComments">-</div>
            <div class="stat-label">Today's Comments</div>
        </div>
        <div class="stat-card">
            <div class="stat-value" id="activePlans">-</div>
            <div class="stat-label">Plans with Comments</div>
        </div>
    </div>

    <!-- Comments Container -->
    <div class="comments-container">
        <div class="comments-header">
            <h3 class="comments-title" id="commentsTitle">All Comments</h3>
            <p class="comments-subtitle" id="commentsSubtitle">Showing all comments from dropshippers</p>
        </div>
        
        <div class="comments-list" id="commentsList">
            <div class="loading">
                <i class="fas fa-spinner fa-spin"></i>
                <p>Loading comments...</p>
            </div>
        </div>
    </div>
</div>

<script>
    let allComments = [];
    let filteredComments = [];
    let currentFilters = {
        seller: '',
        plan: '',
        search: ''
    };

    // Navigation handling
    function toggleSidebar() {
        const sidebar = document.getElementById('sidebar');
        const overlay = document.querySelector('.sidebar-overlay');
        
        // Check if sidebar is currently hidden
        const isHidden = sidebar.style.transform === 'translateX(-100%)' || 
                        sidebar.style.transform === '' || 
                        window.getComputedStyle(sidebar).transform === 'matrix(1, 0, 0, 1, -280, 0)' ||
                        window.getComputedStyle(sidebar).transform.includes('translateX(-100%)');
        
        if (isHidden) {
            // Show sidebar
            sidebar.style.transform = 'translateX(0px)';
            sidebar.classList.add('open');
            overlay.style.display = 'block';
            overlay.classList.add('active');
        } else {
            // Hide sidebar
            sidebar.style.transform = 'translateX(-100%)';
            sidebar.classList.remove('open');
            overlay.style.display = 'none';
            overlay.classList.remove('active');
        }
    }

    function closeSidebar() {
        const sidebar = document.getElementById('sidebar');
        const overlay = document.querySelector('.sidebar-overlay');
        
        sidebar.style.transform = 'translateX(-100%)';
        sidebar.classList.remove('open');
        overlay.style.display = 'none';
        overlay.classList.remove('active');
    }

    // Profile menu toggle function
    function toggleProfileMenu() {
        const profileMenu = document.getElementById('profile-menu');
        const profileToggle = document.getElementById('profile-toggle');
        const chevronIcon = profileToggle.querySelector('i');
        
        if (profileMenu.style.maxHeight === '0px' || profileMenu.style.maxHeight === '') {
            profileMenu.style.maxHeight = '200px';
            chevronIcon.classList.remove('fa-chevron-up');
            chevronIcon.classList.add('fa-chevron-down');
        } else {
            profileMenu.style.maxHeight = '0px';
            chevronIcon.classList.remove('fa-chevron-down');
            chevronIcon.classList.add('fa-chevron-up');
        }
    }

    // Request notification permission
    function requestNotificationPermission() {
        if ('Notification' in window) {
            Notification.requestPermission().then(permission => {
                if (permission === 'granted') {
                    console.log('Notification permission granted');
                }
            });
        }
    }

    // Show notification function
    function showNotification(title, options = {}) {
        if (!('Notification' in window)) {
            console.warn('This browser does not support desktop notifications');
            return;
        }

        if (Notification.permission === 'granted') {
            const notification = new Notification(title, {
                icon: 'https://customprint.deodap.com/api_dropshipper_tracker/logo.png',
                badge: 'https://customprint.deodap.com/api_dropshipper_tracker/logo.png',
                ...options
            });

            notification.onclick = () => {
                window.focus();
                notification.close();
            };

            return notification;
        } else if (Notification.permission !== 'denied') {
            Notification.requestPermission().then(permission => {
                if (permission === 'granted') {
                    showNotification(title, options);
                }
            });
        }
    }

    // Load comments from API
    function loadComments() {
        fetch('https://customprint.deodap.com/api_dropshipper_tracker/admin_all_comments.php')
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    const prevCount = allComments.length;
                    const newComments = [];
                    
                    // If we had previous comments, find the new ones
                    if (prevCount > 0) {
                        const existingIds = new Set(allComments.map(c => c.id));
                        newComments.push(...data.comments.filter(comment => !existingIds.has(comment.id)));
                    }
                    
                    allComments = data.comments;
                    filteredComments = [...allComments];
                    
                    // Show notifications for new comments
                    if (newComments.length > 0) {
                        newComments.forEach(comment => {
                            const sellerName = comment.seller_name || 'A seller';
                            const commentText = comment.comment_text.length > 50 
                                ? comment.comment_text.substring(0, 50) + '...' 
                                : comment.comment_text;
                                
                            showNotification(`New Comment from ${sellerName}`, {
                                body: `${commentText}`,
                                tag: `comment-${comment.id}`,
                                data: {
                                    url: window.location.href,
                                    commentId: comment.id
                                }
                            });
                        });
                        
                        // Also show a summary notification
                        if (newComments.length > 1) {
                            const sellers = [...new Set(newComments.map(c => c.seller_name))];
                            const sellerList = sellers.length <= 3 
                                ? sellers.join(', ')
                                : `${sellers.length} sellers`;
                                
                            showNotification('New Comments Added', {
                                body: `${newComments.length} new comments from ${sellerList}`,
                                tag: 'new-comments-summary'
                            });
                        }
                    }
                    
                    // Check for seller_id parameter in URL
                    const urlParams = new URLSearchParams(window.location.search);
                    const sellerId = urlParams.get('seller_id');
                    
                    if (sellerId) {
                        currentFilters.seller = sellerId;
                        document.getElementById('sellerFilter').value = sellerId;
                    }
                    
                    updateStats();
                    populateFilters();
                    applyFilters();
                } else {
                    showError('Error loading comments: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                showError('Failed to load comments. Please check your connection.');
            });
    }

    function updateStats() {
        const totalComments = allComments.length;
        const uniqueSellers = new Set(allComments.map(c => c.seller_id)).size;
        const today = new Date().toISOString().split('T')[0];
        const todayComments = allComments.filter(c => c.created_at.startsWith(today)).length;
        const activePlans = new Set(allComments.map(c => c.plan_name)).size;

        document.getElementById('totalComments').textContent = totalComments.toLocaleString();
        document.getElementById('uniqueSellers').textContent = uniqueSellers;
        document.getElementById('todayComments').textContent = todayComments;
        document.getElementById('activePlans').textContent = activePlans;
    }

    // FIXED FUNCTION - No more duplicate sellers
    function populateFilters() {
        const sellerFilter = document.getElementById('sellerFilter');
        const planFilter = document.getElementById('planFilter');

        // Clear existing options (keep "All" option)
        sellerFilter.innerHTML = '<option value="">All Sellers</option>';
        planFilter.innerHTML = '<option value="">All Plans</option>';

        // Get unique sellers using Map to avoid duplicates
        const sellerMap = new Map();
        
        allComments.forEach(comment => {
            if (!sellerMap.has(comment.seller_id)) {
                sellerMap.set(comment.seller_id, {
                    id: comment.seller_id,
                    name: comment.seller_name
                });
            }
        });

        // Convert Map to array and sort by seller name
        const uniqueSellers = Array.from(sellerMap.values()).sort((a, b) => a.name.localeCompare(b.name));

        uniqueSellers.forEach(seller => {
            const option = document.createElement('option');
            option.value = seller.id;
            option.textContent = `${seller.name} (ID: ${seller.id})`;
            sellerFilter.appendChild(option);
        });

        // Get unique plans and sort them
        const uniquePlans = [...new Set(allComments.map(c => c.plan_name))].sort();
        
        uniquePlans.forEach(plan => {
            const option = document.createElement('option');
            option.value = plan;
            option.textContent = plan;
            planFilter.appendChild(option);
        });
    }

    function applyFilters() {
        const sellerFilter = document.getElementById('sellerFilter').value;
        const planFilter = document.getElementById('planFilter').value;
        const searchInput = document.getElementById('searchInput').value.toLowerCase();

        currentFilters = {
            seller: sellerFilter,
            plan: planFilter,
            search: searchInput
        };

        filteredComments = allComments.filter(comment => {
            const matchesSeller = !sellerFilter || comment.seller_id === sellerFilter;
            const matchesPlan = !planFilter || comment.plan_name === planFilter;
            const matchesSearch = !searchInput || 
                comment.comment_text.toLowerCase().includes(searchInput) ||
                comment.seller_name.toLowerCase().includes(searchInput) ||
                comment.store_name.toLowerCase().includes(searchInput) ||
                comment.step_name.toLowerCase().includes(searchInput);

            return matchesSeller && matchesPlan && matchesSearch;
        });

        displayComments();
        updateFilteredStats();
    }

    function clearFilters() {
        document.getElementById('sellerFilter').value = '';
        document.getElementById('planFilter').value = '';
        document.getElementById('searchInput').value = '';
        
        currentFilters = { seller: '', plan: '', search: '' };
        filteredComments = [...allComments];
        
        displayComments();
        updateFilteredStats();
    }

    function updateFilteredStats() {
        const title = document.getElementById('commentsTitle');
        const subtitle = document.getElementById('commentsSubtitle');

        if (currentFilters.seller || currentFilters.plan || currentFilters.search) {
            title.textContent = `Filtered Comments (${filteredComments.length})`;
            
            let filterDesc = [];
            if (currentFilters.seller) {
                const sellerName = allComments.find(c => c.seller_id === currentFilters.seller)?.seller_name;
                filterDesc.push(`Seller: ${sellerName}`);
            }
            if (currentFilters.plan) filterDesc.push(`Plan: ${currentFilters.plan}`);
            if (currentFilters.search) filterDesc.push(`Search: "${currentFilters.search}"`);
            
            subtitle.textContent = `Filtered by ${filterDesc.join(', ')}`;
        } else {
            title.textContent = 'All Comments';
            subtitle.textContent = 'Showing all comments from dropshippers';
        }
    }

    function displayComments() {
        const container = document.getElementById('commentsList');

        if (filteredComments.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-comments"></i>
                    <h3>No Comments Found</h3>
                    <p>No comments match your current filters.</p>
                    <button class="clear-btn" onclick="clearFilters()" style="margin-top: 16px;">
                        <i class="fas fa-refresh"></i> Clear Filters
                    </button>
                </div>
            `;
            return;
        }

        // Group comments by seller_id
        const groupedComments = {};
        filteredComments.forEach(comment => {
            if (!groupedComments[comment.seller_id]) {
                groupedComments[comment.seller_id] = {
                    seller_info: {
                        seller_id: comment.seller_id,
                        seller_name: comment.seller_name,
                        store_name: comment.store_name,
                        email: comment.email,
                        contact_number: comment.contact_number,
                        crn: comment.crn
                    },
                    comments: []
                };
            }
            groupedComments[comment.seller_id].comments.push(comment);
        });

        let html = '';
        
        // Display grouped comments
        Object.values(groupedComments).forEach(group => {
            const seller = group.seller_info;
            const initials = seller.seller_name.split(' ').map(n => n[0]).join('').toUpperCase();

            html += `
                <div class="seller-group">
                    <!-- Seller Header (shown once per seller) -->
                    <div class="seller-header">
                        <div class="comment-avatar">${initials}</div>
                        <div class="seller-info">
                            <div class="seller-meta">
                                <div class="seller-name">${seller.seller_name}</div>
                                <div class="seller-badge">ID: ${seller.seller_id}</div>
                                <div class="comment-count">${group.comments.length} Comments</div>
                            </div>
                            
                            <div class="seller-details">
                                <div class="detail-item">
                                    <i class="fas fa-store"></i>
                                    <span><strong>Store:</strong> ${seller.store_name}</span>
                                </div>
                                <div class="detail-item">
                                    <i class="fas fa-envelope"></i>
                                    <span>${seller.email}</span>
                                </div>
                                <div class="detail-item">
                                    <i class="fas fa-phone"></i>
                                    <span>${seller.contact_number}</span>
                                </div>
                                <div class="detail-item">
                                    <i class="fas fa-id-badge"></i>
                                    <span><strong>CRN:</strong> ${seller.crn}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Comments List for this seller -->
                    <div class="seller-comments">
            `;
            
            // Add all comments for this seller
            group.comments.forEach(comment => {
                const date = new Date(comment.created_at);
                const formattedDate = date.toLocaleDateString() + ' at ' + date.toLocaleTimeString();

                html += `
                    <div class="comment-item-compact">
                        <div class="comment-mini-header">
                            <div class="plan-step-info">
                                <span class="plan-name"><i class="fas fa-clipboard-list"></i> ${comment.plan_name}</span>
                                <span class="step-name"><i class="fas fa-step-forward"></i> ${comment.step_name}</span>
                                <span class="comment-date"><i class="fas fa-calendar"></i> ${formattedDate}</span>
                            </div>
                        </div>
                        <div class="comment-content-compact">
                            ${comment.comment_text}
                        </div>
                    </div>
                `;
            });

            html += `
                    </div>
                </div>
            `;
        });

        container.innerHTML = html;
    }

    function showError(message) {
        const container = document.getElementById('commentsList');
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-exclamation-triangle"></i>
                <h3>Error</h3>
                <p>${message}</p>
                <button class="filter-btn" onclick="loadComments()" style="margin-top: 16px;">
                    <i class="fas fa-refresh"></i> Retry
                </button>
            </div>
        `;
    }

    // Mobile responsiveness
    document.addEventListener('click', function(e) {
        const sidebar = document.getElementById('sidebar');
        const mobileBtn = document.querySelector('.mobile-menu-btn');
        
        if (window.innerWidth <= 768 && 
            !sidebar.contains(e.target) && 
            !mobileBtn.contains(e.target) && 
            sidebar.classList.contains('open')) {
            closeSidebar();
        }
    });

    window.addEventListener('resize', function() {
        if (window.innerWidth > 768) {
            const sidebar = document.getElementById('sidebar');
            const overlay = document.querySelector('.sidebar-overlay');
            
            sidebar.classList.remove('open');
            overlay.classList.remove('active');
        }
    });

    document.addEventListener('DOMContentLoaded', function() {
        // Request notification permission when page loads
        requestNotificationPermission();
        
        // Initial load of comments
        loadComments();

        // Refresh comments every 30 seconds
        setInterval(loadComments, 30000);
        
        // Add search input event listener
        document.getElementById('searchInput').addEventListener('input', function() {
            // Debounce search
            clearTimeout(this.searchTimeout);
            this.searchTimeout = setTimeout(() => {
                applyFilters();
            }, 300);
        });

        // ✅ PUSH SUBSCRIPTION CODE ADD KARYU
        if ('serviceWorker' in navigator && 'PushManager' in window) {
            navigator.serviceWorker.register("sw.js").then(async (reg) => {
                try {
                    const subscription = await reg.pushManager.subscribe({
                        userVisibleOnly: true,
                        applicationServerKey: "BACgJ841C_jo3RG0tpzGcGJA9FHhi3yu377WwA6LdZybG3FcMQL9YM6bLRf_Vk4F49WNKn8soilzRCIs1tPsQ_E"
                    });

                    console.log("Subscription object:", subscription);

                    // JSON ma convert
                    const subscriptionJson = JSON.stringify(subscription);
                    console.log("Subscription JSON:", subscriptionJson);

                    // Save to server via AJAX
                    await fetch("https://customprint.deodap.com/api_dropshipper_tracker/save_subscription.php", {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: subscriptionJson
                    });
                } catch (err) {
                    console.error("Push subscription failed:", err);
                }
            });
        } else {
            console.warn("Push messaging is not supported in this browser.");
        }
    });
</script>

</body>
</html>