<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
     <link rel="icon" href="assets/favicon.png" />
     <title>Dropshipper Registration - admin Portal</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f8f9fa;
            min-height: 100vh;
            overflow-x: hidden;
        }

        /* Mobile Menu Button */
        .mobile-menu-btn {
            display: none;
            position: fixed;
            top: 20px;
            left: 20px;
            z-index: 1001;
            background: #6366f1;
            color: white;
            border: none;
            padding: 12px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 18px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }

        .mobile-menu-btn:hover {
            background: #5856eb;
        }

        /* Sidebar */
        .sidebar {
            height: 100vh;
            width: 280px;
            position: fixed;
            top: 0;
            left: 0;
            background: #ffffff;
            box-shadow: 2px 0 10px rgba(0,0,0,0.1);
            z-index: 1000;
            transition: transform 0.3s ease;
            overflow-y: auto;
            border-right: 1px solid #e5e7eb;
            display: flex;
            flex-direction: column;
        }

        .sidebar-header {
            padding: 24px 20px;
            border-bottom: 1px solid #e5e7eb;
            background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
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

        /* Navigation Menu */
        .nav-menu {
            padding: 16px 0;
            flex: 1;
        }

        .nav-section {
            margin-bottom: 8px;
        }

        .nav-section-title {
            padding: 8px 20px;
            font-size: 12px;
            font-weight: 600;
            color: #6b7280;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 4px;
        }

        .nav-item {
            display: block;
            padding: 12px 20px;
            text-decoration: none;
            color: #374151;
            transition: all 0.2s ease;
            border: none;
            background: none;
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 14px;
            font-weight: 500;
            position: relative;
        }

        .nav-item:hover {
            background-color: #f3f4f6;
            color: #6366f1;
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

        /* Enhanced User Profile */
        .user-profile {
            margin-top: auto;
            background: linear-gradient(135deg, #f8fafc, #f1f5f9);
            border-top: 1px solid #e5e7eb;
            border-radius: 12px 12px 0 0;
            overflow: hidden;
            position: sticky;
            bottom: 0;
        }

        .profile-header {
            padding: 20px;
            cursor: pointer;
            transition: all 0.3s ease;
            position: relative;
        }

        .profile-header:hover {
            background: rgba(59, 130, 246, 0.05);
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .user-avatar {
            width: 44px;
            height: 44px;
            background: linear-gradient(135deg, #3b82f6, #1d4ed8);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 16px;
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
            position: relative;
        }

        .online-indicator {
            position: absolute;
            bottom: 2px;
            right: 2px;
            width: 12px;
            height: 12px;
            background: #10b981;
            border: 2px solid white;
            border-radius: 50%;
            box-shadow: 0 0 0 1px rgba(16, 185, 129, 0.3);
        }

        .user-details {
            flex: 1;
        }

        .user-details h4 {
            margin: 0;
            font-size: 15px;
            font-weight: 600;
            color: #1f2937;
        }

        .user-details p {
            margin: 2px 0 0 0;
            font-size: 12px;
            color: #6b7280;
        }

        .profile-toggle {
            color: #6b7280;
            font-size: 12px;
            transition: all 0.3s ease;
            position: absolute;
            right: 20px;
            top: 50%;
            transform: translateY(-50%);
        }

        .profile-toggle.rotated {
            transform: translateY(-50%) rotate(180deg);
        }

        .profile-menu {
            max-height: 0;
            overflow: hidden;
            transition: all 0.3s ease;
            background: white;
            border-top: 1px solid #e5e7eb;
        }

        .profile-menu.expanded {
            max-height: 400px;
        }

        .profile-section {
            padding: 0;
        }

        .profile-section:not(:last-child) {
            border-bottom: 1px solid #f3f4f6;
        }

        .profile-section-title {
            padding: 12px 20px 8px 20px;
            font-size: 11px;
            font-weight: 600;
            color: #6b7280;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            background: #f9fafb;
        }

        .profile-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 20px;
            color: #4b5563;
            text-decoration: none;
            font-size: 13px;
            font-weight: 500;
            transition: all 0.2s ease;
            border: none;
            background: none;
            width: 100%;
            text-align: left;
        }

        .profile-item:hover {
            background: #f3f4f6;
            color: #1f2937;
            transform: translateX(2px);
        }

        .profile-item i {
            width: 16px;
            font-size: 13px;
            color: #6b7280;
            transition: color 0.2s ease;
        }

        .profile-item:hover i {
            color: #3b82f6;
        }

        .logout-item {
            color: #dc2626 !important;
            font-weight: 600;
            margin: 8px 12px 12px 12px;
            border-radius: 8px;
            border: 1px solid #fecaca;
            background: linear-gradient(135deg, #fef2f2, #fee2e2);
        }

        .logout-item:hover {
            background: linear-gradient(135deg, #fee2e2, #fecaca);
            transform: translateX(0);
            box-shadow: 0 2px 8px rgba(220, 38, 38, 0.15);
        }

        .logout-item i {
            color: #dc2626 !important;
        }

        /* Overlay for mobile */
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
            padding: 30px;
            min-height: 100vh;
            transition: margin-left 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .registration-wrapper {
            background: white;
            border-radius: 20px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.1);
            overflow: hidden;
            width: 100%;
            max-width: 1200px;
            position: relative;
            border: 1px solid #e5e7eb;
            display: flex;
            min-height: 700px;
        }

        .registration-header {
            background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
            color: white;
            padding: 40px 30px;
            text-align: center;
            position: relative;
            flex: 0 0 400px;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }

        .registration-header::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(255,255,255,0.05)" stroke-width="1"/></pattern></defs><rect width="100" height="100" fill="url(%23grid)"/></svg>');
            opacity: 0.5;
        }

        .breadcrumb {
            display: flex;
            align-items: center;
            gap: 8px;
            color: rgba(255,255,255,0.8);
            font-size: 14px;
            margin-bottom: 20px;
            justify-content: center;
            position: relative;
            z-index: 1;
        }

        .logo-container {
            width: 100px;
            height: 100px;
            background: rgba(255,255,255,0.95);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.2);
            position: relative;
            z-index: 1;
            padding: 10px;
            overflow: hidden;
        }

        .logo-container img {
            width: 100%;
            height: 100%;
            object-fit: contain;
            border-radius: 50%;
        }

        .logo-container i {
            font-size: 32px;
            color: white;
            display: none;
        }

        .registration-header h2 {
            font-size: 28px;
            font-weight: 700;
            margin-bottom: 8px;
            position: relative;
            z-index: 1;
        }

        .registration-header p {
            font-size: 16px;
            opacity: 0.9;
            position: relative;
            z-index: 1;
        }

        .registration-form {
            padding: 40px;
            flex: 1;
            overflow-y: auto;
            max-height: 700px;
        }

        .form-section {
            margin-bottom: 30px;
        }

        .section-title {
            color: #111827;
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .section-title i {
            color: #6366f1;
        }

        .form-group {
            margin-bottom: 20px;
            position: relative;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #374151;
            font-weight: 500;
            font-size: 14px;
        }

        .input-wrapper {
            position: relative;
        }

        .input-icon {
            position: absolute;
            left: 15px;
            top: 50%;
            transform: translateY(-50%);
            color: #6b7280;
            font-size: 16px;
            z-index: 1;
        }

        .form-group input {
            width: 100%;
            padding: 15px 20px 15px 45px;
            border: 2px solid #e5e7eb;
            border-radius: 12px;
            font-size: 15px;
            background: #f9fafb;
            transition: all 0.3s ease;
            color: #111827;
        }

        .form-group input:focus {
            outline: none;
            border-color: #6366f1;
            background: white;
            box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1);
            transform: translateY(-2px);
        }

        .form-group input:focus + .input-icon {
            color: #6366f1;
        }

        .form-group input::placeholder {
            color: #9ca3af;
            font-weight: 400;
        }

        .submit-btn {
            width: 100%;
            padding: 16px;
            background: linear-gradient(135deg, #6366f1, #8b5cf6);
            color: white;
            border: none;
            border-radius: 12px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3);
        }

        .submit-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(99, 102, 241, 0.4);
        }

        .submit-btn:active {
            transform: translateY(0);
        }

        .submit-btn:disabled {
            background: #9ca3af;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }

        .loading-spinner {
            width: 20px;
            height: 20px;
            border: 2px solid rgba(255,255,255,0.3);
            border-radius: 50%;
            border-top-color: white;
            animation: spin 1s ease-in-out infinite;
            display: none;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        .message {
            margin-top: 20px;
            padding: 15px 20px;
            border-radius: 12px;
            text-align: center;
            font-weight: 500;
            display: none;
            animation: slideDown 0.3s ease;
        }

        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateY(-10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .message.success {
            background: linear-gradient(135deg, #d1fae5, #bbf7d0);
            color: #065f46;
            border: 1px solid #bbf7d0;
        }

        .message.error {
            background: linear-gradient(135deg, #fee2e2, #fecaca);
            color: #991b1b;
            border: 1px solid #fecaca;
        }

        .success-details {
            margin-top: 10px;
            padding: 10px;
            background: rgba(6, 95, 70, 0.1);
            border-radius: 8px;
            font-size: 14px;
        }

        .success-details strong {
            display: block;
            margin-bottom: 5px;
        }

        /* Enhanced Form Styling */
        .section-progress {
            margin-left: auto;
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 12px;
            color: #6b7280;
        }

        .progress-bar {
            width: 60px;
            height: 4px;
            background: #e5e7eb;
            border-radius: 2px;
            overflow: hidden;
        }

        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #6366f1, #8b5cf6);
            width: 0%;
            transition: width 0.3s ease;
        }

        .tooltip {
            position: relative;
            cursor: help;
            color: #6b7280;
            margin-left: 5px;
        }

        .tooltip:hover {
            color: #6366f1;
        }

        .tooltip-popup {
            position: absolute;
            background: #1f2937;
            color: white;
            padding: 8px 12px;
            border-radius: 6px;
            font-size: 12px;
            max-width: 200px;
            z-index: 1000;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            animation: tooltipFadeIn 0.2s ease;
        }

        @keyframes tooltipFadeIn {
            from { opacity: 0; transform: translateY(5px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .char-counter {
            position: absolute;
            right: 15px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 11px;
            color: #7f8c8d;
            background: white;
            padding: 2px 6px;
            border-radius: 4px;
            border: 1px solid #e5e7eb;
        }

        .format-hint {
            font-size: 11px;
            color: #6b7280;
            margin-top: 4px;
            font-style: italic;
        }

        .email-check {
            position: absolute;
            right: 15px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 12px;
            color: #6366f1;
        }

        .error-text {
            color: #dc2626;
            font-size: 12px;
            margin-top: 5px;
            display: none;
            animation: errorSlide 0.3s ease;
        }

        .success-text {
            color: #059669;
            font-size: 12px;
            margin-top: 5px;
            display: none;
            animation: successSlide 0.3s ease;
        }

        @keyframes errorSlide {
            from { opacity: 0; transform: translateX(-10px); }
            to { opacity: 1; transform: translateX(0); }
        }

        @keyframes successSlide {
            from { opacity: 0; transform: translateX(10px); }
            to { opacity: 1; transform: translateX(0); }
        }

        .form-group.error input {
            border-color: #dc2626;
            background: #fef2f2;
            animation: shake 0.5s ease;
        }

        .form-group.success input {
            border-color: #059669;
            background: #f0fdf4;
        }

        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            25% { transform: translateX(-5px); }
            75% { transform: translateX(5px); }
        }

        .form-summary {
            background: linear-gradient(135deg, #f0fdf4, #dcfce7);
            border: 1px solid #bbf7d0;
            border-radius: 12px;
            padding: 20px;
            margin-top: 20px;
            animation: summarySlideIn 0.3s ease;
        }

        @keyframes summarySlideIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .summary-header {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 15px;
            color: #065f46;
        }

        .summary-header i {
            font-size: 20px;
        }

        .summary-header h4 {
            margin: 0;
            font-size: 16px;
            font-weight: 600;
        }

        .summary-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 8px 0;
            border-bottom: 1px solid #bbf7d0;
        }

        .summary-item:last-child {
            border-bottom: none;
        }

        .summary-item .label {
            font-weight: 500;
            color: #065f46;
        }

        .summary-item .value {
            font-weight: 600;
            color: #047857;
        }

        .form-actions {
            display: flex;
            gap: 15px;
            margin-top: 30px;
        }

        .preview-btn {
            flex: 1;
            padding: 14px;
            background: white;
            color: #6366f1;
            border: 2px solid #6366f1;
            border-radius: 12px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .preview-btn:hover:not(:disabled) {
            background: #6366f1;
            color: white;
            transform: translateY(-2px);
        }

        .preview-btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }

        .submit-btn {
            flex: 2;
        }

        .form-footer {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #e5e7eb;
        }

        .completion-status {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 10px;
        }

        .status-item {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 12px;
            color: #6b7280;
            transition: all 0.3s ease;
        }

        .status-item.completed {
            color: #059669;
        }

        .status-item i {
            font-size: 10px;
            transition: all 0.3s ease;
        }

        .status-item.completed i {
            color: #059669;
        }

        .form-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 20px;
        }

        @media (max-width: 1024px) {
            .registration-wrapper {
                flex-direction: column;
                max-width: 600px;
            }
            
            .registration-header {
                flex: none;
            }
            
            .registration-form {
                max-height: none;
            }
        }

        @media (max-width: 768px) {
            .section-progress {
                margin-left: 0;
                margin-top: 10px;
            }
            
            .completion-status {
                flex-direction: column;
                gap: 8px;
            }
            
            .form-actions {
                flex-direction: column;
            }
        }

        /* Input validation styles */
        .form-group.error input {
            border-color: #dc2626;
            background: #fef2f2;
        }

        .form-group.success input {
            border-color: #16a34a;
            background: #f0fdf4;
        }

        .error-text {
            color: #dc2626;
            font-size: 12px;
            margin-top: 5px;
            display: none;
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

            .registration-wrapper {
                max-width: 100%;
            }

            .registration-header {
                padding: 30px 25px;
            }

            .registration-form {
                padding: 30px 25px;
            }

            .form-grid {
                grid-template-columns: 1fr;
                gap: 15px;
            }

            .registration-header h2 {
                font-size: 24px;
            }

            .logo-container {
                width: 70px;
                height: 70px;
            }

            .logo-container i {
                font-size: 28px;
            }

            .user-profile {
                position: relative;
                padding: 16px 20px;
            }
        }

        @media (max-width: 480px) {
            .main {
                padding: 70px 15px 15px 15px;
            }

            .registration-header {
                padding: 25px 20px;
            }

            .registration-form {
                padding: 25px 20px;
            }

            .form-group input {
                padding: 12px 15px 12px 40px;
                font-size: 14px;
            }

            .submit-btn {
                padding: 14px;
                font-size: 15px;
            }

            .registration-header h2 {
                font-size: 22px;
            }
        }

        /* Smooth scrolling */
        .sidebar {
            scrollbar-width: thin;
            scrollbar-color: #d1d5db #f9fafb;
        }

        .sidebar::-webkit-scrollbar {
            width: 6px;
        }

        .sidebar::-webkit-scrollbar-track {
            background: #f9fafb;
        }

        .sidebar::-webkit-scrollbar-thumb {
            background-color: #d1d5db;
            border-radius: 3px;
        }
    </style>
    <!-- Font Awesome for icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body>

<!-- Mobile Menu Button -->
<button class="mobile-menu-btn" onclick="toggleSidebar()">
    <i class="fas fa-bars"></i>
</button>

<!-- Sidebar Overlay -->
<div class="sidebar-overlay" onclick="closeSidebar()"></div>

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
            <a href="employee_dashboard.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
                <i class="fas fa-chart-pie" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>Dashboard</span>
            </a>
        </div>

        <div style="margin-bottom: 8px;">
            <div style="padding: 8px 20px; font-size: 12px; font-weight: 600; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;">Management</div>
            <a href="plans_emp.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
                <i class="fas fa-clipboard-list" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>Plans Management</span>
            </a>
            <div style="padding: 8px 20px; font-size: 12px; font-weight: 600; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;">DROPSHIPPER</div>
            <div style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; color: #2563eb; background-color: #eff6ff; border-right: 3px solid #2563eb; font-size: 14px; font-weight: 500;">
                <i class="fas fa-users" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>Dropshippers Register</span>
            </div>
            <a href="register_dropshipper_details_emp.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
                <i class="fas fa-users" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>Dropshippers Details</span>
            </a>
           
        </div>

    </nav>

    <!-- Enhanced Admin Profile Sidebar -->
    <div style="position: absolute; bottom: 0; left: 0; right: 0; background: #ffffff; border-top: 1px solid #e5e7eb;">
        <!-- Profile Header -->
        <div style="padding: 12px 16px; background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white;">
            <div style="display: flex; align-items: center; gap: 10px;">
                <div style="width: 36px; height: 36px; background: rgba(255,255,255,0.2); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 14px; border: 2px solid rgba(255,255,255,0.3);">
                    AD
                </div>
                <div style="flex: 1;">
                    <h4 style="font-size: 14px; font-weight: 700; margin-bottom: 1px;">Admin User</h4>
                    <p style="font-size: 11px; opacity: 0.9; margin: 0; word-break: break-all;">admin@deodap.com</p>
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

<div class="main">
    <div class="registration-wrapper">
        <div class="registration-header">
            <div class="breadcrumb">
                <i class="fas fa-users"></i>
                <span>Dropshippers</span>
                <span>/</span>
                <span>New Registration</span>
            </div>
            <div class="logo-container">
                <img src="https://dropshipping.deodap.com/images/logo-2.jpg" alt="Company Logo" onerror="this.style.display='none'; this.nextElementSibling.style.display='block';">
                <i class="fas fa-user-plus"></i>
            </div>
            <h2>Dropshipper Registration</h2>
            <p>Register a new dropshipper to the system</p>
        </div>

        <div class="registration-form">
            <form id="registerForm" novalidate>
                <div class="form-section">
                    <div class="section-title">
                        <i class="fas fa-user"></i>
                        Basic Information
                        <div class="section-progress">
                            <span class="progress-text">Step 1 of 3</span>
                            <div class="progress-bar">
                                <div class="progress-fill" data-step="1"></div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="form-grid">
                        <div class="form-group">
                            <label for="seller_name">
                                Seller Name *
                                <span class="tooltip" data-tooltip="Enter the full legal name of the seller or business owner">
                                    <i class="fas fa-info-circle"></i>
                                </span>
                            </label>
                            <div class="input-wrapper">
                                <input type="text" 
                                       id="seller_name" 
                                       name="seller_name" 
                                       placeholder="e.g., John Smith or ABC Trading Co." 
                                       maxlength="100"
                                       required>
                                <i class="fas fa-user input-icon"></i>
                                <div class="char-counter">
                                    <span class="current">0</span>/<span class="max">100</span>
                                </div>
                            </div>
                            <div class="error-text">Please enter a valid seller name (2-100 characters)</div>
                            <div class="success-text">✓ Seller name looks good!</div>
                        </div>

                        <div class="form-group">
                            <label for="store_name">
                                Store Name *
                                <span class="tooltip" data-tooltip="The public name of your store that customers will see">
                                    <i class="fas fa-info-circle"></i>
                                </span>
                            </label>
                            <div class="input-wrapper">
                                <input type="text" 
                                       id="store_name" 
                                       name="store_name" 
                                       placeholder="e.g., Fashion Hub, Tech Store, etc." 
                                       maxlength="80"
                                       required>
                                <i class="fas fa-store input-icon"></i>
                                <div class="char-counter">
                                    <span class="current">0</span>/<span class="max">80</span>
                                </div>
                            </div>
                            <div class="error-text">Please enter a valid store name (2-80 characters)</div>
                            <div class="success-text">✓ Store name looks good!</div>
                        </div>
                    </div>
                </div>

                <div class="form-section">
                    <div class="section-title">
                        <i class="fas fa-address-book"></i>
                        Contact Information
                        <div class="section-progress">
                            <span class="progress-text">Step 2 of 3</span>
                            <div class="progress-bar">
                                <div class="progress-fill" data-step="2"></div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="form-grid">
                        <div class="form-group">
                            <label for="contact_number">
                                Contact Number *
                                <span class="tooltip" data-tooltip="Enter a valid phone number with country code (e.g., +1234567890)">
                                    <i class="fas fa-info-circle"></i>
                                </span>
                            </label>
                            <div class="input-wrapper">
                                <input type="tel" 
                                       id="contact_number" 
                                       name="contact_number" 
                                       placeholder="+1 (555) 123-4567" 
                                       maxlength="20"
                                       required>
                                <i class="fas fa-phone input-icon"></i>
                                <div class="format-hint">Format: +country code followed by number</div>
                            </div>
                            <div class="error-text">Please enter a valid phone number with country code</div>
                            <div class="success-text">✓ Phone number format is correct!</div>
                        </div>

                        <div class="form-group">
                            <label for="email">
                                Email Address *
                                <span class="tooltip" data-tooltip="This email will be used for login and important notifications">
                                    <i class="fas fa-info-circle"></i>
                                </span>
                            </label>
                            <div class="input-wrapper">
                                <input type="email" 
                                       id="email" 
                                       name="email" 
                                       placeholder="seller@example.com" 
                                       maxlength="100"
                                       required>
                                <i class="fas fa-envelope input-icon"></i>
                                <div class="email-check">
                                    <span class="checking" style="display: none;">
                                        <i class="fas fa-spinner fa-spin"></i> Checking availability...
                                    </span>
                                </div>
                            </div>
                            <div class="error-text">Please enter a valid email address</div>
                            <div class="success-text">✓ Email format is valid!</div>
                        </div>
                    </div>
                </div>

                <div class="form-section">
                    <div class="section-title">
                        <i class="fas fa-certificate"></i>
                        Business Information
                        <div class="section-progress">
                            <span class="progress-text">Step 3 of 3</span>
                            <div class="progress-bar">
                                <div class="progress-fill" data-step="3"></div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label for="crn">
                            Company Registration Number (CRN) *
                            <span class="tooltip" data-tooltip="Enter your official business registration number issued by government authorities">
                                <i class="fas fa-info-circle"></i>
                            </span>
                        </label>
                        <div class="input-wrapper">
                            <input type="text" 
                                   id="crn" 
                                   name="crn" 
                                   placeholder="e.g., 12345678, ABC123456789" 
                                   maxlength="50"
                                   pattern="[A-Za-z0-9]+"
                                   required>
                            <i class="fas fa-id-card input-icon"></i>
                            <div class="format-hint">Alphanumeric characters only, no spaces or special characters</div>
                        </div>
                        <div class="error-text">Please enter a valid CRN (alphanumeric, 5-50 characters)</div>
                        <div class="success-text">✓ CRN format is correct!</div>
                    </div>
                    
                    <!-- Form Completion Summary -->
                    <div class="form-summary" id="formSummary" style="display: none;">
                        <div class="summary-header">
                            <i class="fas fa-check-circle"></i>
                            <h4>Registration Summary</h4>
                        </div>
                        <div class="summary-content">
                            <div class="summary-item">
                                <span class="label">Seller Name:</span>
                                <span class="value" id="summary-seller-name">-</span>
                            </div>
                            <div class="summary-item">
                                <span class="label">Store Name:</span>
                                <span class="value" id="summary-store-name">-</span>
                            </div>
                            <div class="summary-item">
                                <span class="label">Contact:</span>
                                <span class="value" id="summary-contact">-</span>
                            </div>
                            <div class="summary-item">
                                <span class="label">Email:</span>
                                <span class="value" id="summary-email">-</span>
                            </div>
                            <div class="summary-item">
                                <span class="label">CRN:</span>
                                <span class="value" id="summary-crn">-</span>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="form-actions">
                    <button type="button" class="preview-btn" id="previewBtn" disabled>
                        <i class="fas fa-eye"></i>
                        Preview Registration
                    </button>
                    <button type="submit" class="submit-btn" id="submitBtn" disabled>
                        <span class="btn-text">Register Dropshipper</span>
                        <div class="loading-spinner" id="loadingSpinner"></div>
                        <i class="fas fa-user-plus" id="submitIcon"></i>
                    </button>
                </div>
                
                <div class="form-footer">
                    <div class="completion-status">
                        <div class="status-item" data-section="basic">
                            <i class="fas fa-circle"></i>
                            <span>Basic Information</span>
                        </div>
                        <div class="status-item" data-section="contact">
                            <i class="fas fa-circle"></i>
                            <span>Contact Information</span>
                        </div>
                        <div class="status-item" data-section="business">
                            <i class="fas fa-circle"></i>
                            <span>Business Information</span>
                        </div>
                    </div>
                </div>
            </form>

            <div class="message" id="message"></div>
        </div>
    </div>
</div>

<script>
    // Sidebar toggle functionality
    function toggleSidebar() {
        const sidebar = document.getElementById('sidebar');
        const overlay = document.querySelector('.sidebar-overlay');
        
        sidebar.classList.toggle('open');
        overlay.classList.toggle('active');
    }

    function closeSidebar() {
        const sidebar = document.getElementById('sidebar');
        const overlay = document.querySelector('.sidebar-overlay');
        
        sidebar.classList.remove('open');
        overlay.classList.remove('active');
    }

    // Close sidebar when clicking on main content on mobile
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

    // Handle window resize
    window.addEventListener('resize', function() {
        if (window.innerWidth > 768) {
            const sidebar = document.getElementById('sidebar');
            const overlay = document.querySelector('.sidebar-overlay');
            
            sidebar.classList.remove('open');
            overlay.classList.remove('active');
        }
    });

    // Profile menu toggle functionality
    function toggleProfileMenu() {
        const profileMenu = document.getElementById('profile-menu');
        const profileToggle = document.getElementById('profile-toggle');
        
        if (profileMenu.style.maxHeight === '0px' || profileMenu.style.maxHeight === '') {
            profileMenu.style.maxHeight = '200px';
            profileToggle.querySelector('i').style.transform = 'rotate(180deg)';
        } else {
            profileMenu.style.maxHeight = '0px';
            profileToggle.querySelector('i').style.transform = 'rotate(0deg)';
        }
    }

    // Form functionality
    const form = document.getElementById('registerForm');
    const messageBox = document.getElementById('message');
    const submitBtn = document.getElementById('submitBtn');
    const loadingSpinner = document.getElementById('loadingSpinner');
    const submitIcon = document.getElementById('submitIcon');
    const btnText = document.querySelector('.btn-text');

    // Enhanced form validation
    function validateField(field) {
        const value = field.value.trim();
        const fieldGroup = field.closest('.form-group');
        const errorText = fieldGroup.querySelector('.error-text');
        const successText = fieldGroup.querySelector('.success-text');
        
        let isValid = true;
        let errorMessage = '';
        
        // Field-specific validation
        if (!value) {
            isValid = false;
            errorMessage = `${field.name.replace('_', ' ')} is required`;
        } else {
            switch(field.name) {
                case 'seller_name':
                case 'store_name':
                    if (value.length < 2) {
                        isValid = false;
                        errorMessage = `${field.name.replace('_', ' ')} must be at least 2 characters`;
                    } else if (value.length > (field.name === 'seller_name' ? 100 : 80)) {
                        isValid = false;
                        errorMessage = `${field.name.replace('_', ' ')} is too long`;
                    }
                    break;
                    
                case 'email':
                    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                    if (!emailRegex.test(value)) {
                        isValid = false;
                        errorMessage = 'Please enter a valid email address';
                    }
                    break;
                    
                case 'contact_number':
                    const phoneRegex = /^\+[1-9]\d{1,14}$/;
                    const cleanPhone = value.replace(/[\s\-\(\)]/g, '');
                    if (!phoneRegex.test(cleanPhone)) {
                        isValid = false;
                        errorMessage = 'Phone number must start with + followed by country code and number';
                    }
                    break;
                    
                case 'crn':
                    const crnRegex = /^[A-Za-z0-9]{5,50}$/;
                    if (!crnRegex.test(value)) {
                        isValid = false;
                        errorMessage = 'CRN must be 5-50 alphanumeric characters only';
                    }
                    break;
            }
        }
        
        // Update UI based on validation result
        if (isValid) {
            fieldGroup.classList.remove('error');
            fieldGroup.classList.add('success');
            errorText.style.display = 'none';
            if (successText) successText.style.display = 'block';
        } else {
            fieldGroup.classList.remove('success');
            fieldGroup.classList.add('error');
            errorText.textContent = errorMessage;
            errorText.style.display = 'block';
            if (successText) successText.style.display = 'none';
        }
        
        // Update character counter
        updateCharCounter(field);
        
        // Update section progress
        updateSectionProgress();
        
        return isValid;
    }
    
    // Character counter functionality
    function updateCharCounter(field) {
        const counter = field.parentElement.querySelector('.char-counter');
        if (counter) {
            const current = counter.querySelector('.current');
            const max = counter.querySelector('.max');
            current.textContent = field.value.length;
            
            // Color coding for character count
            const percentage = (field.value.length / field.maxLength) * 100;
            if (percentage > 90) {
                counter.style.color = '#e74c3c';
            } else if (percentage > 75) {
                counter.style.color = '#f39c12';
            } else {
                counter.style.color = '#7f8c8d';
            }
        }
    }
    
    // Section progress tracking
    function updateSectionProgress() {
        const sections = {
            basic: ['seller_name', 'store_name'],
            contact: ['contact_number', 'email'],
            business: ['crn']
        };
        
        let allValid = true;
        
        Object.keys(sections).forEach(sectionName => {
            const fields = sections[sectionName];
            const validFields = fields.filter(fieldName => {
                const field = document.getElementById(fieldName);
                return field && field.closest('.form-group').classList.contains('success');
            });
            
            const isComplete = validFields.length === fields.length;
            const statusItem = document.querySelector(`[data-section="${sectionName}"]`);
            const progressFill = document.querySelector(`[data-step="${Object.keys(sections).indexOf(sectionName) + 1}"]`);
            
            if (statusItem) {
                if (isComplete) {
                    statusItem.classList.add('completed');
                    statusItem.querySelector('i').className = 'fas fa-check-circle';
                } else {
                    statusItem.classList.remove('completed');
                    statusItem.querySelector('i').className = 'fas fa-circle';
                    allValid = false;
                }
            }
            
            if (progressFill) {
                progressFill.style.width = `${(validFields.length / fields.length) * 100}%`;
            }
        });
        
        // Enable/disable buttons based on form completion
        const previewBtn = document.getElementById('previewBtn');
        const submitBtn = document.getElementById('submitBtn');
        
        if (allValid) {
            previewBtn.disabled = false;
            submitBtn.disabled = false;
            updateFormSummary();
        } else {
            previewBtn.disabled = true;
            submitBtn.disabled = true;
            document.getElementById('formSummary').style.display = 'none';
        }
    }
    
    // Update form summary
    function updateFormSummary() {
        const summary = document.getElementById('formSummary');
        const fields = {
            'summary-seller-name': 'seller_name',
            'summary-store-name': 'store_name',
            'summary-contact': 'contact_number',
            'summary-email': 'email',
            'summary-crn': 'crn'
        };
        
        Object.keys(fields).forEach(summaryId => {
            const field = document.getElementById(fields[summaryId]);
            const summaryElement = document.getElementById(summaryId);
            if (field && summaryElement) {
                summaryElement.textContent = field.value || '-';
            }
        });
        
        summary.style.display = 'block';
    }

    // Enhanced real-time validation and interactions
    const inputs = form.querySelectorAll('input[required]');
    inputs.forEach(input => {
        // Real-time validation
        input.addEventListener('blur', () => validateField(input));
        input.addEventListener('input', () => {
            updateCharCounter(input);
            if (input.closest('.form-group').classList.contains('error')) {
                validateField(input);
            }
        });
        
        // Initialize character counters
        updateCharCounter(input);
        
        // Phone number formatting
        if (input.name === 'contact_number') {
            input.addEventListener('input', function(e) {
                let value = e.target.value.replace(/\D/g, '');
                if (value.length > 0 && !value.startsWith('+')) {
                    value = '+' + value;
                }
                e.target.value = value;
            });
        }
        
        // Email availability check (simulated)
        if (input.name === 'email') {
            let emailTimeout;
            input.addEventListener('input', function(e) {
                const checkingSpan = input.parentElement.querySelector('.checking');
                clearTimeout(emailTimeout);
                
                if (e.target.value.includes('@') && e.target.value.includes('.')) {
                    checkingSpan.style.display = 'inline-block';
                    emailTimeout = setTimeout(() => {
                        checkingSpan.style.display = 'none';
                    }, 1500);
                }
            });
        }
    });
    
    // Tooltip functionality
    document.querySelectorAll('.tooltip').forEach(tooltip => {
        tooltip.addEventListener('mouseenter', function() {
            const tooltipText = this.getAttribute('data-tooltip');
            const tooltipElement = document.createElement('div');
            tooltipElement.className = 'tooltip-popup';
            tooltipElement.textContent = tooltipText;
            document.body.appendChild(tooltipElement);
            
            const rect = this.getBoundingClientRect();
            tooltipElement.style.left = rect.left + 'px';
            tooltipElement.style.top = (rect.top - tooltipElement.offsetHeight - 10) + 'px';
            
            this.tooltipElement = tooltipElement;
        });
        
        tooltip.addEventListener('mouseleave', function() {
            if (this.tooltipElement) {
                document.body.removeChild(this.tooltipElement);
                this.tooltipElement = null;
            }
        });
    });
    
    // Preview button functionality
    document.getElementById('previewBtn').addEventListener('click', function() {
        const summary = document.getElementById('formSummary');
        if (summary.style.display === 'none') {
            summary.style.display = 'block';
            summary.scrollIntoView({ behavior: 'smooth' });
            this.innerHTML = '<i class="fas fa-eye-slash"></i> Hide Preview';
        } else {
            summary.style.display = 'none';
            this.innerHTML = '<i class="fas fa-eye"></i> Preview Registration';
        }
    });

    // Form submission
    form.addEventListener('submit', function(e) {
        e.preventDefault();
        
        // Validate all fields
        let isFormValid = true;
        inputs.forEach(input => {
            if (!validateField(input)) {
                isFormValid = false;
            }
        });
        
        if (!isFormValid) {
            showMessage('Please fix the errors above before submitting.', 'error');
            return;
        }
        
        // Show loading state
        setLoadingState(true);
        hideMessage();
        
        const formData = new FormData(form);

        fetch('https://customprint.deodap.com/api_dropshipper_tracker/register_dropshipper.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.text())
        .then(text => {
            console.log("Raw response:", text);
            let data;
            try {
                data = JSON.parse(text);
            } catch (err) {
                throw new Error("Invalid server response");
            }
            
            setLoadingState(false);
            
            if(data.status === 'success') {
                showMessage(
                    `${data.message}
                    <div class="success-details">
                        <strong>Seller ID: ${data.seller_id}</strong>
                        <strong>Username: ${data.username}</strong>
                    </div>`, 
                    'success'
                );
                form.reset();
                resetValidationStates();
            } else {
                showMessage(data.message, 'error');
            }
        })
        .catch(error => {
            setLoadingState(false);
            showMessage("An error occurred. Please try again later.", 'error');
            console.error('Error:', error);
        });
    });

    function setLoadingState(isLoading) {
        if (isLoading) {
            submitBtn.disabled = true;
            loadingSpinner.style.display = 'block';
            submitIcon.style.display = 'none';
            btnText.textContent = 'Registering...';
        } else {
            submitBtn.disabled = false;
            loadingSpinner.style.display = 'none';
            submitIcon.style.display = 'block';
            btnText.textContent = 'Register Dropshipper';
        }
    }

    function showMessage(message, type) {
        messageBox.innerHTML = message;
        messageBox.className = `message ${type}`;
        messageBox.style.display = 'block';
        messageBox.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    function hideMessage() {
        messageBox.style.display = 'none';
    }

    function resetValidationStates() {
        const formGroups = form.querySelectorAll('.form-group');
        formGroups.forEach(group => {
            group.classList.remove('error', 'success');
            const errorText = group.querySelector('.error-text');
            const successText = group.querySelector('.success-text');
            if (errorText) errorText.style.display = 'none';
            if (successText) successText.style.display = 'none';
        });
        
        // Reset progress indicators
        document.querySelectorAll('.status-item').forEach(item => {
            item.classList.remove('completed');
            item.querySelector('i').className = 'fas fa-circle';
        });
        
        document.querySelectorAll('.progress-fill').forEach(fill => {
            fill.style.width = '0%';
        });
        
        // Reset character counters
        inputs.forEach(input => updateCharCounter(input));
        
        // Hide summary and disable buttons
        document.getElementById('formSummary').style.display = 'none';
        document.getElementById('previewBtn').disabled = true;
        document.getElementById('submitBtn').disabled = true;
    }
    
    // Initialize form state
    updateSectionProgress();
</script>

</body>
</html>