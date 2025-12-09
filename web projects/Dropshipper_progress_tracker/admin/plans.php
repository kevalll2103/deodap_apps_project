<?php
// plans.php - Enhanced Plans Management System
session_start();

// Security headers
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: strict-origin-when-cross-origin');

// Check if user is logged in
if (!isset($_SESSION['user'])) {
    header("Location: login.php");
    exit();
}

// Validate session
if (!isset($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

$user = $_SESSION['user'];

// Configuration
define('MAX_FILE_SIZE', 5 * 1024 * 1024); // 5MB
define('ALLOWED_IMAGE_TYPES', ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']);
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" href="assets/favicon.png" />
    <title>Plans & Steps Management - Admin Portal</title>
    <meta name="description" content="Manage subscription plans and organize their steps efficiently">
    <meta name="robots" content="noindex, nofollow">
    <style>
        * {
            margin: 0;
            padding: 0;
        }
        body {
            margin: 0;
            padding: 0;
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #ffffff;
            min-height: 100vh;
            color: #333;
            line-height: 1.6;
        }

        body::before {
            content: '';
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background:
                radial-gradient(circle at 20% 80%, rgba(120, 119, 198, 0.3) 0%, transparent 50%),
                radial-gradient(circle at 80% 20%, rgba(255, 119, 198, 0.15) 0%, transparent 50%),
                radial-gradient(circle at 40% 40%, rgba(120, 219, 255, 0.1) 0%, transparent 50%);
            pointer-events: none;
            z-index: -1;
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
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.12);
            z-index: 1000;
            overflow-y: auto;
            border-right: 1px solid rgba(255, 255, 255, 0.2);
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

        /* User Profile Section */
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
            background: linear-gradient(135deg, #6366f1, #8b5cf6);
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
            color: #111827;
            margin-bottom: 2px;
        }

        .user-details p {
            font-size: 12px;
            color: #6b7280;
            margin: 0;
        }

        /* Sidebar Overlay */
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
            padding: 30px 40px;
            min-height: 100vh;
            padding-bottom: 60px;
            background: transparent;
        }

        .header {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            padding: 40px;
            border-radius: 24px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            margin-bottom: 30px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            position: relative;
            overflow: hidden;
        }

        .header::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 4px;
            background: linear-gradient(90deg, #667eea, #764ba2, #f093fb);
        }

        .welcome-text h2 {
            font-size: 32px;
            margin-bottom: 12px;
            color: #111827;
            font-weight: 700;
            background: linear-gradient(135deg, #6366f1, #8b5cf6);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .welcome-text p {
            color: #6b7280;
            font-size: 16px;
            margin-bottom: 20px;
            line-height: 1.6;
            font-weight: 500;
        }

        .breadcrumb {
            display: flex;
            align-items: center;
            gap: 8px;
            color: #6b7280;
            font-size: 14px;
        }

        .breadcrumb i {
            color: #6366f1;
        }

        /* Tab System */
        .tab-container {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            border-radius: 24px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.15);
            border: 1px solid rgba(255,255,255,0.2);
            position: relative;
            overflow: hidden;
        }

        .tab-container::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 4px;
            background: linear-gradient(90deg, #667eea, #764ba2, #f093fb);
        }

        .tabs {
            display: flex;
            gap: 4px;
            margin-bottom: 40px;
            background: rgba(255, 255, 255, 0.8);
            padding: 6px;
            border-radius: 16px;
            border: 1px solid rgba(255, 255, 255, 0.3);
            backdrop-filter: blur(10px);
        }

        .tab-btn {
            background: none;
            border: none;
            padding: 16px 24px;
            cursor: pointer;
            font-size: 15px;
            font-weight: 600;
            color: #6b7280;
            border-radius: 12px;
            display: flex;
            align-items: center;
            gap: 8px;
            position: relative;
            overflow: hidden;
        }

        .tab-btn::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(135deg, #667eea, #764ba2);
            opacity: 0;
        }

        .tab-btn.active {
            color: white;
            background: linear-gradient(135deg, #667eea, #764ba2);
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
        }

        .tab-btn:hover:not(.active) {
            color: #667eea;
            background: rgba(102, 126, 234, 0.1);
        }

        .tab-content {
            display: none;
        }

        .tab-content.active {
            display: block;
        }

        /* Enhanced Buttons */
        .btn {
            padding: 12px 24px;
            border: none;
            border-radius: 12px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            position: relative;
            overflow: hidden;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
        }

        .btn::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
        }

        .btn:hover::before {
            left: 100%;
        }

        .btn-primary {
            background: linear-gradient(135deg, #3b82f6, #1d4ed8);
            border: none;
            color: white;
            position: relative;
            overflow: hidden;
        }

        .btn-primary::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
        }

        .btn-primary:hover::before {
            left: 100%;
        }

        .btn-primary:hover {
            background: linear-gradient(135deg, #2563eb, #1e40af);
            box-shadow: 0 12px 30px rgba(59, 130, 246, 0.5);
        }

        .btn-success {
            background: linear-gradient(135deg, #10b981, #059669);
            border: none;
            color: white;
            position: relative;
            overflow: hidden;
        }

        .btn-success::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
        }

        .btn-success:hover::before {
            left: 100%;
        }

        .btn-success:hover {
            background: linear-gradient(135deg, #059669, #047857);
            box-shadow: 0 12px 30px rgba(16, 185, 129, 0.5);
        }

        .btn-danger {
            background: linear-gradient(135deg, #ef4444, #dc2626);
            border: none;
            color: white;
            position: relative;
            overflow: hidden;
        }

        .btn-danger::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
        }

        .btn-danger:hover::before {
            left: 100%;
        }

        .btn-danger:hover {
            background: linear-gradient(135deg, #dc2626, #b91c1c);
            box-shadow: 0 12px 30px rgba(239, 68, 68, 0.5);
        }

        .btn-warning {
            background: linear-gradient(135deg, #f59e0b, #d97706);
            border: none;
            color: white;
            position: relative;
            overflow: hidden;
        }

        .btn-warning::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
        }

        .btn-warning:hover::before {
            left: 100%;
        }

        .btn-warning:hover {
            background: linear-gradient(135deg, #d97706, #b45309);
            box-shadow: 0 12px 30px rgba(245, 158, 11, 0.5);
        }

        .btn-secondary {
            background: linear-gradient(135deg, #6b7280, #4b5563);
            border: none;
            color: white;
            position: relative;
            overflow: hidden;
        }

        .btn-secondary::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
        }

        .btn-secondary:hover::before {
            left: 100%;
        }

        .btn-secondary:hover {
            background: linear-gradient(135deg, #4b5563, #374151);
            box-shadow: 0 12px 30px rgba(107, 114, 128, 0.5);
        }

        .btn-info {
            background: linear-gradient(135deg, #06b6d4, #0891b2);
            border: none;
            color: white;
            position: relative;
            overflow: hidden;
        }

        .btn-info::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
        }

        .btn-info:hover::before {
            left: 100%;
        }

        .btn-info:hover {
            background: linear-gradient(135deg, #0891b2, #0e7490);
            box-shadow: 0 12px 30px rgba(6, 182, 212, 0.5);
        }

        .btn-dark {
            background: linear-gradient(135deg, #1f2937, #111827);
            border: none;
            color: white;
            position: relative;
            overflow: hidden;
        }

        .btn-dark::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
        }

        .btn-dark:hover::before {
            left: 100%;
        }

        .btn-dark:hover {
            background: linear-gradient(135deg, #111827, #030712);
            transform: translateY(-3px) scale(1.02);
            box-shadow: 0 12px 30px rgba(31, 41, 55, 0.5);
        }

        .btn-sm {
            padding: 8px 15px;
            font-size: 14px;
        }

        /* Plans Table */
        .plans-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 25px;
            background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 8px 32px rgba(0,0,0,0.12);
            border: 1px solid rgba(255,255,255,0.8);
        }

        .plans-table th,
        .plans-table td {
            padding: 18px 20px;
            text-align: left;
            border-bottom: 1px solid rgba(229, 231, 235, 0.5);
        }

        .plans-table th {
            background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
            font-weight: 600;
            color: white;
            font-size: 14px;
            letter-spacing: 0.5px;
            text-transform: uppercase;
            position: relative;
        }

        .plans-table th::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            height: 2px;
            background: linear-gradient(90deg, rgba(255,255,255,0.3), transparent);
        }

        .plans-table td {
            color: #374151;
            font-weight: 500;
            background: rgba(255,255,255,0.7);
        }

        .plans-table tr:hover td {
            background: #f9fafb;
        }

        .status-badge {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }

        .status-active {
            background: #dcfce7;
            color: #166534;
        }

        .status-inactive {
            background: #fee2e2;
            color: #dc2626;
        }

        .status-open {
            background: #fef3c7;
            color: #d97706;
        }

        .status-in-process {
            background: #dbeafe;
            color: #2563eb;
        }

        .status-completed {
            background: #dcfce7;
            color: #166534;
        }

        .action-buttons {
            display: flex;
            gap: 8px;
        }

        /* Enhanced Forms */
        .form-group {
            margin-bottom: 28px;
            position: relative;
        }

        .form-group label {
            display: block;
            margin-bottom: 12px;
            font-weight: 600;
            color: #374151;
            font-size: 15px;
            letter-spacing: 0.3px;
        }

        .form-control {
            width: 100%;
            padding: 16px 20px;
            border: 2px solid rgba(229, 231, 235, 0.6);
            border-radius: 16px;
            font-size: 15px;
            background: rgba(255, 255, 255, 0.9);
            backdrop-filter: blur(10px);
        }

        .form-control:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.15);
            background: rgba(255, 255, 255, 1);
        }

        .form-control:hover {
            border-color: rgba(102, 126, 234, 0.4);
        }

        .form-row {
            display: grid;
            grid-template-columns: 1fr 2fr 1fr;
            gap: 15px;
            align-items: end;
        }

        /* Steps Management */
        .plan-selector {
            margin-bottom: 30px;
            padding: 30px;
            background: white;
            border-radius: 8px;
            border: 1px solid #e5e7eb;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }



        .steps-section {
            margin-top: 30px;
            display: none;
        }

        .steps-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
            padding: 25px 30px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #6366f1;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border: 1px solid #e5e7eb;
        }

        .add-step-form {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            border: 1px solid #e5e7eb;
        }



        .steps-list {
            display: grid;
            gap: 15px;
        }

        .step-item {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-left: 4px solid #6366f1;
            border: 1px solid #e5e7eb;
            margin-bottom: 15px;
        }



        .step-item:hover {
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .step-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }

        .step-number {
            background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
            color: white;
            padding: 8px 12px;
            border-radius: 50px;
            font-weight: bold;
            margin-right: 15px;
            min-width: 40px;
            text-align: center;
        }

        .step-actions {
            margin-left: auto;
            display: flex;
            gap: 10px;
        }

        .step-description {
            margin-left: 55px;
            color: #495057;
            line-height: 1.6;
        }

        .edit-form {
            display: none;
            margin-top: 15px;
            padding: 15px;
            background: #f9fafb;
            border-radius: 8px;
            border: 2px dashed #d1d5db;
        }

        /* Image Upload Styles */
        .image-upload-container {
            position: relative;
        }

        .image-preview {
            margin-top: 10px;
            padding: 10px;
            background: #f9fafb;
            border-radius: 8px;
            border: 1px solid #e5e7eb;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .image-preview img {
            border: 2px solid #e5e7eb;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .step-image {
            max-width: 150px;
            max-height: 100px;
            border-radius: 6px;
            border: 2px solid #e5e7eb;
            margin-top: 8px;
            cursor: pointer;
        }

        .step-image:hover {
            opacity: 0.9;
        }

        .image-actions {
            display: flex;
            gap: 5px;
            margin-top: 8px;
        }

        .image-modal {
            display: none;
            position: fixed;
            z-index: 2000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.8);
        }

        .image-modal-content {
            position: absolute;
            top: 50%;
            left: 50%;
            margin-top: -45vh;
            margin-left: -45vw;
            max-width: 90%;
            max-height: 90%;
        }

        .image-modal-content img {
            max-width: 100%;
            max-height: 100%;
            border-radius: 8px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.5);
        }

        .image-modal-close {
            position: absolute;
            top: 15px;
            right: 25px;
            color: white;
            font-size: 35px;
            font-weight: bold;
            cursor: pointer;
            z-index: 2001;
        }

        .image-modal-close:hover {
            color: #ff6b6b;
        }

        .text-muted {
            color: #6b7280;
            font-size: 12px;
            margin-top: 5px;
        }

        /* Enhanced Modal */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.7);
            backdrop-filter: blur(8px);
        }

        .modal-content {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            padding: 40px;
            border-radius: 24px;
            width: 90%;
            max-width: 540px;
            box-shadow: 0 25px 50px rgba(0,0,0,0.25);
            border: 1px solid rgba(255, 255, 255, 0.2);
            position: relative;
            overflow: hidden;
        }

        .modal-content::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 4px;
            background: linear-gradient(90deg, #667eea, #764ba2, #f093fb);
        }

        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }

        .modal-title {
            font-size: 20px;
            font-weight: 700;
            color: #111827;
        }

        .close {
            color: #aaa;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
        }

        .close:hover {
            color: #667eea;
        }

        /* Alert Messages */
        .alert {
            padding: 18px 24px;
            border-radius: 16px;
            margin-bottom: 25px;
            font-weight: 500;
            backdrop-filter: blur(20px);
            position: relative;
            overflow: hidden;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .alert::before {
            content: '';
            position: absolute;
            left: 0;
            top: 0;
            bottom: 0;
            width: 4px;
            background: currentColor;
        }

        .alert-success {
            background: linear-gradient(135deg, rgba(220, 252, 231, 0.95) 0%, rgba(187, 247, 208, 0.9) 100%);
            color: #166534;
            border: 1px solid rgba(187, 247, 208, 0.6);
            box-shadow: 0 4px 20px rgba(16, 185, 129, 0.15);
        }

        .alert-danger {
            background: linear-gradient(135deg, rgba(254, 226, 226, 0.95) 0%, rgba(252, 165, 165, 0.9) 100%);
            color: #991b1b;
            border: 1px solid rgba(252, 165, 165, 0.6);
            box-shadow: 0 4px 20px rgba(239, 68, 68, 0.15);
        }

        /* Loading and Empty States */
        .loading {
            text-align: center;
            padding: 40px;
            color: #667eea;
        }

        .spinner {
            display: inline-block;
            width: 40px;
            height: 40px;
            border: 3px solid rgba(255, 255, 255, 0.3);
            border-top: 3px solid #667eea;
            border-radius: 50%;
            margin-bottom: 15px;
        }

        /* Enhanced Accessibility improvements */
        .btn:focus,
        .form-control:focus,
        .tab-btn:focus {
            outline: 3px solid #667eea;
            outline-offset: 3px;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.3);
        }

        .sr-only {
            position: absolute;
            width: 1px;
            height: 1px;
            padding: 0;
            margin: -1px;
            overflow: hidden;
            clip: rect(0, 0, 0, 0);
            white-space: nowrap;
            border: 0;
        }

        /* High contrast mode support */
        @media (prefers-contrast: high) {
            .btn, .form-control, .tab-btn {
                border: 2px solid currentColor;
            }

            .sidebar {
                border-right: 3px solid #000;
            }
        }

        /* Reduced motion support */
        @media (prefers-reduced-motion: reduce) {
            *, *::before, *::after {
                animation-duration: 0.01ms !important;
                animation-iteration-count: 1 !important;
                transition-duration: 0.01ms !important;
            }
        }

        /* Focus management for keyboard navigation */
        .modal:focus-within {
            outline: none;
        }

        .tab-btn[aria-selected="true"] {
            position: relative;
        }

        .tab-btn[aria-selected="true"]::after {
            content: '';
            position: absolute;
            bottom: -2px;
            left: 0;
            right: 0;
            height: 3px;
            background: linear-gradient(90deg, #667eea, #764ba2);
            border-radius: 2px;
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #6c757d;
        }

        .empty-state-icon {
            font-size: 4rem;
            margin-bottom: 20px;
            opacity: 0.5;
        }

        /* Responsive Design */
        @media (max-width: 1024px) {
            .sidebar {
                width: 260px;
            }

            .main {
                margin-left: 260px;
            }
        }

        @media (max-width: 768px) {
            .mobile-menu-btn {
                display: block;
            }

            .sidebar {
                transform: translateX(-100%);
                width: 280px;
                z-index: 1001;
            }

            .sidebar.open {
                transform: translateX(0);
            }

            .sidebar-overlay.active {
                display: block;
            }

            .main {
                margin-left: 0;
                padding: 80px 15px 20px 15px;
            }

            .header {
                padding: 25px 20px;
                margin-bottom: 20px;
            }

            .welcome-text h2 {
                font-size: 24px;
                margin-bottom: 6px;
            }

            .welcome-text p {
                font-size: 14px;
            }

            .breadcrumb {
                font-size: 12px;
                margin-bottom: 15px;
            }

            .tab-container {
                padding: 20px;
                border-radius: 16px;
            }

            .tabs {
                flex-wrap: wrap;
                gap: 8px;
                margin-bottom: 20px;
                border-bottom: 1px solid #e5e7eb;
            }

            .tab-btn {
                padding: 10px 16px;
                font-size: 13px;
                flex: 1;
                min-width: 120px;
                text-align: center;
            }

            .form-row {
                grid-template-columns: 1fr;
                gap: 12px;
            }

            .step-header {
                flex-direction: column;
                align-items: flex-start;
                gap: 12px;
            }

            .step-actions {
                margin-left: 0;
                width: 100%;
                justify-content: flex-start;
            }

            .step-description {
                margin-left: 0;
                margin-top: 10px;
            }

            .step-number {
                margin-right: 0;
                margin-bottom: 8px;
            }

            /* Table Responsiveness */
            .plans-table {
                font-size: 12px;
                display: block;
                overflow-x: auto;
                white-space: nowrap;
            }

            .plans-table thead,
            .plans-table tbody,
            .plans-table th,
            .plans-table td,
            .plans-table tr {
                display: block;
            }

            .plans-table thead tr {
                position: absolute;
                top: -9999px;
                left: -9999px;
            }

            .plans-table tr {
                border: 1px solid #e5e7eb;
                margin-bottom: 10px;
                padding: 15px;
                border-radius: 8px;
                background: white;
                box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            }

            .plans-table td {
                border: none;
                position: relative;
                padding: 8px 0 8px 30%;
                text-align: left;
                white-space: normal;
            }

            .plans-table td:before {
                content: attr(data-label) ": ";
                position: absolute;
                left: 0;
                width: 25%;
                padding-right: 10px;
                white-space: nowrap;
                font-weight: 600;
                color: #374151;
            }

            .action-buttons {
                flex-direction: column;
                gap: 8px;
                align-items: stretch;
            }

            .action-buttons .btn {
                width: 100%;
                justify-content: center;
            }

            /* Modal Responsiveness */
            .modal-content {
                margin: 5% auto;
                padding: 20px;
                width: 95%;
                max-width: none;
                border-radius: 12px;
            }

            .modal-header {
                margin-bottom: 15px;
            }

            .modal-title {
                font-size: 18px;
            }

            /* Form Improvements */
            .form-control {
                padding: 14px 16px;
                font-size: 16px; /* Prevents zoom on iOS */
            }

            .btn {
                padding: 14px 20px;
                font-size: 14px;
                min-height: 48px; /* Better touch targets */
            }

            .btn-sm {
                padding: 10px 16px;
                font-size: 13px;
                min-height: 40px;
            }

            /* User Profile */
            .user-profile {
                position: relative;
                padding: 16px 20px;
            }

            .user-avatar {
                width: 36px;
                height: 36px;
                font-size: 14px;
            }

            .user-details h4 {
                font-size: 13px;
            }

            .user-details p {
                font-size: 11px;
            }

            /* Steps Management Mobile */
            .plan-selector {
                padding: 20px;
                margin-bottom: 20px;
            }

            .add-step-form {
                padding: 20px;
                margin-bottom: 15px;
            }

            .steps-header {
                padding: 15px;
                flex-direction: column;
                align-items: flex-start;
                gap: 10px;
            }

            .step-item {
                padding: 15px;
                margin-bottom: 10px;
            }

            .edit-form {
                margin-top: 10px;
                padding: 12px;
            }

            @media (max-width: 480px) {
            body {
                background: #ffffff;
            }

            .main {
                padding: 70px 15px 20px 15px;
            }

            .header {
                padding: 25px 20px;
                border-radius: 20px;
            }

            .tab-container {
                padding: 20px;
                border-radius: 20px;
            }

            .welcome-text h2 {
                font-size: 22px;
            }

            .tab-btn {
                padding: 12px 16px;
                font-size: 13px;
                min-width: 110px;
                border-radius: 10px;
            }

            .modal-content {
                padding: 25px;
                margin: 5% auto;
                width: 95%;
                border-radius: 20px;
            }

            .btn {
                padding: 14px 20px;
                font-size: 14px;
                border-radius: 10px;
            }

            .form-control {
                padding: 14px 16px;
                border-radius: 12px;
            }

            .step-item {
                padding: 20px;
                border-radius: 16px;
                background: rgba(255, 255, 255, 0.95);
                backdrop-filter: blur(20px);
            }

            .step-number {
                padding: 8px 12px;
                font-size: 13px;
                min-width: 36px;
            }

            /* Enhanced Mobile Search and Filter */
            .search-filter-controls {
                grid-template-columns: 1fr !important;
                gap: 15px !important;
            }

            .search-filter-controls .btn {
                margin-top: 0 !important;
                width: 100%;
                padding: 16px !important;
            }

            .plans-table {
                border-radius: 16px;
            }

            .section-header {
                padding: 25px 20px !important;
                border-radius: 16px !important;
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
    <!-- External Resources -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" integrity="sha512-iecdLmaskl7CVkqkXNQ/ZH/XLlvWZOJyj7Yy7tcenmpD1ypASozpmT/E0iPtmFIB46ZmdtAc9eNBvH0H/ZpiBw==" crossorigin="anonymous">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
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
            <a href="dashboard.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
                <i class="fas fa-chart-pie" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>Dashboard</span>
            </a>
        </div>

        <nav style="padding: 16px 0;">
        <div style="margin-bottom: 8px;">
            <div style="padding: 8px 20px; font-size: 12px; font-weight: 600; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;">Management</div>
            <a href="plans.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
                <i class="fas fa-clipboard-list" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>Plans Management</span>
            </a>

             <div style="padding: 8px 20px; font-size: 12px; font-weight: 600; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;">Employee</div>
            <a href="register_employee.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
                <i class="fas fa-users" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>employee Register</span>
            </a>

            <a href="employee_details.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
                <i class="fas fa-users" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>employee Details</span>
            </a>


              <div style="padding: 8px 20px; font-size: 12px; font-weight: 600; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;">Dropshipper</div>
            <a href="register_dropshipper.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
                <i class="fas fa-users" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>Dropshippers Register</span>
            </a>
            <a href="register_dropshipper_details.php" style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; text-decoration: none; color: #111827; font-size: 14px; font-weight: 500; cursor: pointer;">
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
                    <?= strtoupper(substr($user['email'], 0, 2)) ?>
                </div>
                <div style="flex: 1;">
                    <h4 style="font-size: 14px; font-weight: 700; margin-bottom: 1px;">Admin User</h4>
                    <p style="font-size: 11px; opacity: 0.9; margin: 0; word-break: break-all;"><?= htmlspecialchars($user['email']) ?></p>
                </div>
                <div onclick="toggleProfileMenu()" style="width: 28px; height: 28px; background: rgba(255,255,255,0.2); border-radius: 6px; display: flex; align-items: center; justify-content: center; cursor: pointer;" id="profile-toggle">
                    <i class="fas fa-chevron-up" style="font-size: 12px;"></i>
                </div>
            </div>
        </div>

        <!-- Expandable Profile Menu -->
        <div id="profile-menu" style="max-height: 0; overflow: hidden; background: #ffffff;">
            <div style="padding: 0;">
                <!-- Profile Actions -->
                <div style="padding: 8px 0;">
                    <a href="profile.php" style="display: flex; align-items: center; gap: 10px; padding: 8px 16px; text-decoration: none; color: #111827; font-size: 13px; font-weight: 500;" onmouseover="this.style.background='#f9fafb'" onmouseout="this.style.background='transparent'">
                        <i class="fas fa-user-edit" style="width: 14px; text-align: center; color: #6366f1;"></i>
                        <span>Edit Profile</span>
                    </a>

                    <a href="settings.php" style="display: flex; align-items: center; gap: 10px; padding: 8px 16px; text-decoration: none; color: #111827; font-size: 13px; font-weight: 500;" onmouseover="this.style.background='#f9fafb'" onmouseout="this.style.background='transparent'">
                        <i class="fas fa-cog" style="width: 14px; text-align: center; color: #6366f1;"></i>
                        <span>Settings</span>
                    </a>
                </div>

                <!-- Logout Section -->
                <div style="padding: 12px 16px; border-top: 1px solid #f3f4f6;">
                    <a href="logout.php" style="display: flex; align-items: center; justify-content: center; gap: 6px; padding: 8px; background: #fee2e2; color: #dc2626; text-decoration: none; border-radius: 6px; font-size: 13px; font-weight: 600;" onmouseover="this.style.background='#fecaca'" onmouseout="this.style.background='#fee2e2'">
                        <i class="fas fa-sign-out-alt"></i>
                        <span>Sign Out</span>
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="main">
    <!-- Header -->
    <div class="header">
        <div class="welcome-text">
            <div class="breadcrumb">
                <i class="fas fa-home"></i>
                <span>Dashboard</span>
                <i class="fas fa-angle-right"></i>
                <span>Plans & Steps Management</span>
            </div>
            <h2>📋 Plans & Steps Management</h2>
            <p>Manage your subscription plans and organize their steps efficiently</p>
        </div>
    </div>

    <!-- Main Container -->
    <div class="tab-container">
        <!-- Tab Navigation -->
        <div class="tabs">
            <button class="tab-btn active" onclick="switchTab('plans')">
                <i class="fas fa-list"></i> Plans Management
            </button>
            <button class="tab-btn" onclick="switchTab('steps')">
                <i class="fas fa-tasks"></i> Steps Management
            </button>
        </div>

        <div id="alert-container"></div>

        <!-- Plans Management Tab -->
        <div id="plans-tab" class="tab-content active">
            <div class="section-header fade-in" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 35px; padding: 30px 35px; background: rgba(255, 255, 255, 0.95); backdrop-filter: blur(20px); border-radius: 20px; border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 20px 40px rgba(0,0,0,0.1); position: relative; overflow: hidden;">
                <div style="position: absolute; top: 0; left: 0; right: 0; height: 4px; background: linear-gradient(90deg, #667eea, #764ba2, #f093fb);"></div>
                <div>
                    <h3 style="font-size: 28px; font-weight: 700; color: #111827; margin-bottom: 6px; background: linear-gradient(135deg, #667eea, #764ba2); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;">📋 All Plans</h3>
                    <p style="color: #6b7280; font-size: 15px; margin: 0; font-weight: 500;">Manage your subscription plans and pricing</p>
                </div>
                <button class="btn btn-primary pulse-on-hover" onclick="openAddModal()">
                    <i class="fas fa-plus"></i>
                    Add New Plan
                </button>
            </div>

            <div id="plans-table-container">
                <div class="loading">
                    <div class="spinner"></div>
                    Loading plans...
                </div>
            </div>
        </div>

        <!-- Steps Management Tab -->
        <div id="steps-tab" class="tab-content">
            <!-- Plan Selector -->
            <div class="plan-selector">
                <h3>🎯 Select a Plan</h3>
                <div class="form-group">
                    <label for="planSelect">Choose Plan:</label>
                    <select class="form-control" id="planSelect">
                        <option value="">-- Select a plan --</option>
                    </select>
                </div>
                <button class="btn btn-primary" onclick="loadPlanSteps()">
                    <i class="fas fa-search"></i>
                    Load Steps
                </button>
            </div>

            <!-- Steps Section -->
            <div id="stepsSection" class="steps-section">
                <div class="steps-header">
                    <h3 id="planTitle">Plan Steps</h3>
                    <span id="stepCount" class="status-badge status-active">0 steps</span>
                </div>

                <!-- Search and Filter Section -->
                <div class="search-filter-section" style="background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%); padding: 25px 30px; border-radius: 16px; margin-bottom: 25px; box-shadow: 0 8px 32px rgba(0,0,0,0.12); border: 1px solid rgba(255,255,255,0.8); backdrop-filter: blur(10px); position: relative; overflow: hidden;">
                    <div style="position: absolute; top: 0; left: 0; right: 0; height: 3px; background: linear-gradient(90deg, #f59e0b, #d97706);"></div>
                    <h4 style="margin-bottom: 18px; color: #374151; font-size: 18px; font-weight: 600; display: flex; align-items: center; gap: 8px;">🔍 Search & Filter Steps</h4>
                    <div class="search-filter-controls" style="display: grid; grid-template-columns: 2fr 1fr 1fr auto; gap: 15px; align-items: end;">
                        <div class="form-group" style="margin-bottom: 0;">
                            <label for="stepSearch">Search Steps:</label>
                            <input type="text" class="form-control" id="stepSearch" placeholder="Search by step description..." onkeyup="filterSteps()">
                        </div>
                        <div class="form-group" style="margin-bottom: 0;">
                            <label for="statusFilter">Filter by Status:</label>
                            <select class="form-control" id="statusFilter" onchange="filterSteps()">
                                <option value="">All Statuses</option>
                                <option value="open">Open</option>
                                <option value="in process">In Process</option>
                                <option value="completed">Completed</option>
                            </select>
                        </div>
                        <div class="form-group" style="margin-bottom: 0;">
                            <label for="sortBy">Sort by:</label>
                            <select class="form-control" id="sortBy" onchange="filterSteps()">
                                <option value="step_number_asc">Step # (Low to High)</option>
                                <option value="step_number_desc">Step # (High to Low)</option>
                                <option value="status">Status</option>
                                <option value="description">Description (A-Z)</option>
                            </select>
                        </div>
                        <div class="form-group" style="margin-bottom: 0;">
                            <button class="btn btn-primary" onclick="clearFilters()" style="margin-top: 24px;">
                                <i class="fas fa-times"></i> Clear
                            </button>
                        </div>
                    </div>
                    <div class="filter-results" style="margin-top: 10px; font-size: 14px; color: #6b7280;">
                        <span id="filterResults">Showing all steps</span>
                    </div>
                </div>

                <!-- Add Step Form -->
                <div class="add-step-form">
                    <h4>➕ Add New Step</h4>
                    <form id="addStepForm" enctype="multipart/form-data">
                        <div class="form-row">
                            <div class="form-group">
                                <label for="stepNumber">Step #:</label>
                                <input type="number" class="form-control" id="stepNumber" min="1" required>
                            </div>
                            <div class="form-group">
                                <label for="stepDescription">Description:</label>
                                <input type="text" class="form-control" id="stepDescription" maxlength="255" required>
                            </div>
                            <div class="form-group">
                                <label for="stepStatus">Status:</label>
                                <select class="form-control" id="stepStatus">
                                    <option value="open">Open</option>
                                    <option value="in process">In Process</option>
                                    <option value="completed">Completed</option>
                                </select>
                            </div>
                        </div>
                        <div class="form-group">
                            <label for="stepImage">Step Image (Optional):</label>
                            <div class="image-upload-container">
                                <input type="file" class="form-control" id="stepImage" accept="image/*">
                                <div class="image-preview" id="imagePreview" style="display: none;">
                                    <img id="previewImg" src="" alt="Preview" style="max-width: 200px; max-height: 150px; border-radius: 8px; margin-top: 10px;">
                                    <button type="button" class="btn btn-sm btn-danger" onclick="clearImagePreview()" style="margin-left: 10px;">
                                        <i class="fas fa-times"></i> Remove
                                    </button>
                                </div>
                            </div>
                            <small class="text-muted">Supported formats: JPG, PNG, GIF, WebP (Max: 5MB)</small>
                        </div>
                        <div class="form-group">
                            <button type="submit" class="btn btn-success">
                                <i class="fas fa-plus"></i>
                                Add Step
                            </button>
                        </div>
                    </form>
                </div>

                <!-- Steps List -->
                <div id="stepsList" class="steps-list"></div>
            </div>
        </div>
    </div>
</div>

<!-- Add/Edit Plan Modal -->
<div id="planModal" class="modal">
    <div class="modal-content">
        <div class="modal-header">
            <h3 class="modal-title" id="modalTitle">Add New Plan</h3>
            <span class="close" onclick="closePlanModal()">&times;</span>
        </div>
        <form id="planForm">
            <input type="hidden" id="planId" name="id">
            <div class="form-group">
                <label for="planName">Plan Name *</label>
                <input type="text" class="form-control" id="planName" name="name" required>
            </div>
            <div class="form-group">
                <label for="planDescription">Description</label>
                <textarea class="form-control" id="planDescription" name="description" placeholder="Plan description..." style="min-height: 80px; resize: vertical;"></textarea>
            </div>
            <div class="form-group">
                <label for="planPrice">Price (₹)</label>
                <div class="input-group">
                    <span class="input-group-text">₹</span>
                    <input type="number" class="form-control" id="planPrice" name="price" step="0.01" min="0" placeholder="0.00">
                </div>
            </div>
            <div class="form-group">
                <label for="planStatus">Status</label>
                <select class="form-control" id="planStatus" name="is_active">
                    <option value="1">Active</option>
                    <option value="0">Inactive</option>
                </select>
            </div>
            <div style="display: flex; gap: 12px; justify-content: flex-end; margin-top: 30px;">
                <button type="button" class="btn" onclick="closePlanModal()" style="background: #6b7280; color: white;">Cancel</button>
                <button type="submit" class="btn btn-success" id="submitBtn">Save Plan</button>
            </div>
        </form>
    </div>
</div>

<!-- Image Modal -->
<div id="imageModal" class="image-modal">
    <span class="image-modal-close" onclick="closeImageModal()">&times;</span>
    <div class="image-modal-content">
        <img id="modalImage" src="" alt="Step Image">
    </div>
</div>

<!-- Hidden File Input for Image Upload -->
<input type="file" id="hiddenImageInput" accept="image/*" style="display: none;">

<script>
    const API_URL = 'https://customprint.deodap.com/api_dropshipper_tracker/plans_complete.php';
    const CSRF_TOKEN = '<?= $_SESSION['csrf_token'] ?>';
    const MAX_FILE_SIZE = <?= MAX_FILE_SIZE ?>;
    const ALLOWED_TYPES = <?= json_encode(ALLOWED_IMAGE_TYPES) ?>;

    let currentEditId = null;
    let currentPlanId = null;
    let allSteps = [];
    let isLoading = false;
    let currentFilters = {
        search: '',
        status: '',
        sort: 'step_number_asc'
    };
    let currentTab = 'plans'; // Track current active tab

    // Initialize
    document.addEventListener('DOMContentLoaded', function() {
        loadPlans();
        loadPlansForSteps();
        restoreTabState(); // Restore tab state first
        restoreStepManagementState();

        // Add step form handler
        document.getElementById('addStepForm').addEventListener('submit', function(e) {
            e.preventDefault();
            addStep();
        // Initialize
        document.addEventListener('DOMContentLoaded', function() {
            loadPlans();
            loadPlansForSteps();
            loadEmployees(); // Load employees for assignment dropdown
            restoreTabState(); // Restore tab state first
            restoreStepManagementState();

            // Add step form handler
            document.getElementById('addStepForm').addEventListener('submit', function(e) {
                e.preventDefault();
                addStep();
            });

            // Plan form handler
            document.getElementById('planForm').addEventListener('submit', function(e) {
                e.preventDefault();
                savePlan();
            });
        });

        // Navigation functions
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

        // Tab switching
        function switchTab(tab) {
            const tabs = document.querySelectorAll('.tab-btn');
            const contents = document.querySelectorAll('.tab-content');

            tabs.forEach(t => t.classList.remove('active'));
            contents.forEach(c => c.classList.remove('active'));

            document.querySelector(`[onclick="switchTab('${tab}')"]`).classList.add('active');
            document.getElementById(`${tab}-tab`).classList.add('active');

            // Update current tab and save state
            currentTab = tab;
            saveTabState();

            if (tab === 'steps') {
                loadPlansForSteps();
            }
        }

        // Enhanced validation functions
        function validatePlanForm() {
            const name = document.getElementById('planName').value.trim();
            const price = document.getElementById('planPrice').value;

            if (!name) {
                showAlert('Plan name is required', 'danger');
                return false;
            }

            if (name.length < 3) {
                showAlert('Plan name must be at least 3 characters long', 'danger');
                return false;
            }

            if (price && (isNaN(price) || parseFloat(price) < 0)) {
                showAlert('Price must be a valid positive number', 'danger');
                return false;
            }

            return true;
        }

        function validateImageFile(file) {
            if (!file) return true;

            if (file.size > MAX_FILE_SIZE) {
                showAlert(`Image file is too large. Maximum size is ${(MAX_FILE_SIZE / (1024 * 1024)).toFixed(1)}MB`, 'danger');
                return false;
            }

            if (!ALLOWED_TYPES.includes(file.type)) {
                showAlert('Invalid file type. Please select JPG, PNG, GIF, or WebP image', 'danger');
                return false;
            }

            return true;
        }

        function sanitizeInput(input) {
            return input.replace(/[<>]/g, '');
        }

        // Enhanced alert system with auto-dismiss
        function showAlert(message, type = 'success', duration = 5000) {
            const alertContainer = document.getElementById('alert-container');
            const alertDiv = document.createElement('div');
            alertDiv.className = `alert alert-${type}`;
            alertDiv.innerHTML = `
                <i class="fas fa-${type === 'success' ? 'check-circle' : 'exclamation-circle'}"></i>
                ${sanitizeInput(message)}
                <button type="button" class="btn-close" onclick="this.parentElement.remove()" style="margin-left: auto; background: none; border: none; font-size: 18px; cursor: pointer;">&times;</button>
            `;

            alertContainer.innerHTML = '';
            alertContainer.appendChild(alertDiv);

            // Auto-dismiss after duration
            if (duration > 0) {
                setTimeout(() => {
                    if (alertDiv.parentElement) {
                        alertDiv.remove();
                    }
                }, duration);
            }

            // Manual dismiss on click
            alertDiv.onclick = function() {
                alertDiv.remove();
            };
        }

        // Loading state management
        function setLoadingState(element, isLoading, originalText = '') {
            if (isLoading) {
                element.disabled = true;
                element.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Loading...';
            } else {
                element.disabled = false;
                element.innerHTML = originalText;
            }
        }

        // Plans Management Functions
        async function loadPlans() {
            const container = document.getElementById('plans-table-container');
            container.innerHTML = '<div class="loading"><div class="spinner"></div>Loading plans...</div>';

            try {
                const response = await fetch(`${API_URL}?action=fetch`);
                const data = await response.json();

                if (data.success) {
                    displayPlans(data.plans);
                } else {
                    showAlert('Error loading plans: ' + data.message, 'danger');
                    container.innerHTML = '<div class="loading">Error loading plans. Please try again.</div>';
                }
            } catch (error) {
                console.error('Error:', error);
                showAlert('Failed to connect to API. Please check your connection.', 'danger');
                container.innerHTML = '<div class="loading">Failed to load plans. Please refresh the page.</div>';
            }
        }

        function displayPlans(plans) {
            const container = document.getElementById('plans-table-container');

            if (plans.length === 0) {
                container.innerHTML = `
                    <div class="empty-state">
                        <div class="empty-state-icon">📋</div>
                        <h3>No Plans Found</h3>
                        <p>Get started by creating your first subscription plan.</p>
                        <button class="btn btn-primary" onclick="openAddModal()">
                            <i class="fas fa-plus"></i> Create First Plan
                        </button>
                    </div>
                `;
                return;
            }

            let html = `
                <table class="plans-table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Name</th>
                            <th>Description</th>
                            <th>Price</th>
                            <th>Status</th>
                            <th>Created</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
            `;

            // Function to convert number to Roman numerals
            function toRoman(num) {
                const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
                const numerals = ['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
                let result = '';
                for (let i = 0; i < values.length; i++) {
                    while (num >= values[i]) {
                        result += numerals[i];
                        num -= values[i];
                    }
                }
                return result;
            }

            plans.forEach((plan, index) => {
                const status = plan.is_active == 1 ? 'Active' : 'Inactive';
                const statusClass = plan.is_active == 1 ? 'status-active' : 'status-inactive';
                const createdDate = new Date(plan.created_at).toLocaleDateString();

                html += `
                    <tr>
                        <td data-label="#"><strong>${toRoman(index + 1)}</strong></td>
                        <td data-label="Name"><strong>${plan.name}</strong></td>
                        <td data-label="Description">${plan.description || '-'}</td>
                        <td data-label="Price">₹${parseFloat(plan.price).toLocaleString('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2})}</td>
                        <td data-label="Status"><span class="status-badge ${statusClass}">${status}</span></td>
                        <td data-label="Created">${createdDate}</td>
                        <td data-label="Actions">
                            <div class="action-buttons">
                                <button class="btn btn-warning btn-sm" onclick="editPlan(${plan.id}, '${plan.name}', '${(plan.description || '').replace(/'/g, "\\'")}', ${plan.price}, ${plan.is_active})">
                                    <i class="fas fa-edit"></i> Edit
                                </button>
                                <button class="btn btn-danger btn-sm" onclick="deletePlan(${plan.id}, '${plan.name.replace(/'/g, "\\'")}')">
                                    <i class="fas fa-trash"></i> Delete
                                </button>
                            </div>
                        </td>
                    </tr>
                `;
            });

            html += `
                    </tbody>
                </table>
            `;

            container.innerHTML = html;
        }

        function openAddModal() {
            document.getElementById('modalTitle').textContent = 'Add New Plan';
            document.getElementById('submitBtn').textContent = 'Save Plan';
            document.getElementById('planForm').reset();
            document.getElementById('planId').value = '';
            currentEditId = null;
            document.getElementById('planModal').style.display = 'block';
        }

        function editPlan(id, name, description, price, isActive) {
            document.getElementById('modalTitle').textContent = 'Edit Plan';
            document.getElementById('submitBtn').textContent = 'Update Plan';
            document.getElementById('planId').value = id;
            document.getElementById('planName').value = name;
            document.getElementById('planDescription').value = description;
            document.getElementById('planPrice').value = price;
            document.getElementById('planStatus').value = isActive;
            currentEditId = id;
            document.getElementById('planModal').style.display = 'block';
        }

        function closePlanModal() {
            document.getElementById('planModal').style.display = 'none';
            document.getElementById('planForm').reset();
            currentEditId = null;
        }

        async function deletePlan(id, name) {
            if (!confirm(`Are you sure you want to delete the plan "${name}"? This action cannot be undone.`)) {
                return;
            }

            const formData = new FormData();
            formData.append('action', 'delete');
            formData.append('id', id);

            try {
                const response = await fetch(API_URL, {
                    method: 'POST',
                    body: formData
                });

                const data = await response.json();

                if (data.success) {
                    showAlert('Plan deleted successfully!', 'success');
                    loadPlans();
                    loadPlansForSteps(); // Refresh plans in steps tab
                } else {
                    showAlert('Error deleting plan: ' + data.message, 'danger');
                }
            } catch (error) {
                console.error('Error:', error);
                showAlert('Failed to delete plan. Please try again.', 'danger');
            }
        }

        async function savePlan() {
            // Validate form before submission
            if (!validatePlanForm()) {
                return;
            }

            if (isLoading) return;
            isLoading = true;

            const submitBtn = document.getElementById('submitBtn');
            const originalText = submitBtn.textContent;
            setLoadingState(submitBtn, true, originalText);

            const formData = new FormData(document.getElementById('planForm'));
            const action = currentEditId ? 'update' : 'insert';
            formData.append('action', action);
            formData.append('csrf_token', CSRF_TOKEN);

            try {
                const response = await fetch(API_URL, {
                    method: 'POST',
                    body: formData
                });

                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }

                const data = await response.json();

                if (data.success) {
                    showAlert(data.message || 'Plan saved successfully!', 'success');
                    closePlanModal();
                    loadPlans();
                    loadPlansForSteps();
                } else {
                    showAlert(data.message || 'Failed to save plan', 'danger');
                }
            } catch (error) {
                console.error('Error saving plan:', error);
                showAlert('Network error. Please check your connection and try again.', 'danger');
            } finally {
                isLoading = false;
            }
        }

        // New function to load employees for assignment dropdown
        async function loadEmployees() {
            const employeeSelect = document.getElementById('employeeSelect');
            employeeSelect.innerHTML = '<option value="">-- Select an employee --</option>';

            try {
                const response = await fetch('https://customprint.deodap.com/api_dropshipper_tracker/emp_details.php');
                const data = await response.json();

                if (data.success && Array.isArray(data.data)) {
                    data.data.forEach(emp => {
                        const option = document.createElement('option');
                        option.value = emp.emp_id;
                        option.textContent = `${emp.emp_name} (${emp.emp_code})`;
                        employeeSelect.appendChild(option);
                    });
                } else {
                    showAlert('Failed to load employees', 'danger');
                }
            } catch (error) {
                showAlert('Error loading employees: ' + error.message, 'danger');
            }
        }

        // Function to assign employee to plan
        async function assignEmployeeToPlan() {
            const empId = document.getElementById('employeeSelect').value;
            const planId = document.getElementById('planSelect').value;

            if (!empId) {
                showAlert('Please select an employee', 'danger');
                return;
            }

            if (!planId) {
                showAlert('Please select a plan', 'danger');
                return;
            }

            const formData = new FormData();
            formData.append('action', 'add_plan');
            formData.append('emp_id', empId);
            formData.append('plan_id', planId);
            formData.append('plan_source', 'plans_php');

            try {
                const response = await fetch('https://customprint.deodap.com/api_dropshipper_tracker/emp_plan_step.php', {
                    method: 'POST',
                    body: formData
                });

                const data = await response.json();

                if (data.success) {
                    showAlert('Employee assigned to plan successfully!', 'success');
                } else {
                    showAlert(data.message || 'Failed to assign employee to plan', 'danger');
                }
            } catch (error) {
                showAlert('Error assigning employee to plan: ' + error.message, 'danger');
            }
        }
        });

        // Plan form handler
        document.getElementById('planForm').addEventListener('submit', function(e) {
            e.preventDefault();
            savePlan();
        });
    });

    // Navigation functions
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

    // Tab switching
    function switchTab(tab) {
        const tabs = document.querySelectorAll('.tab-btn');
        const contents = document.querySelectorAll('.tab-content');

        tabs.forEach(t => t.classList.remove('active'));
        contents.forEach(c => c.classList.remove('active'));

        document.querySelector(`[onclick="switchTab('${tab}')"]`).classList.add('active');
        document.getElementById(`${tab}-tab`).classList.add('active');

        // Update current tab and save state
        currentTab = tab;
        saveTabState();

        if (tab === 'steps') {
            loadPlansForSteps();
        }
    }

    // Enhanced validation functions
    function validatePlanForm() {
        const name = document.getElementById('planName').value.trim();
        const price = document.getElementById('planPrice').value;

        if (!name) {
            showAlert('Plan name is required', 'danger');
            return false;
        }

        if (name.length < 3) {
            showAlert('Plan name must be at least 3 characters long', 'danger');
            return false;
        }

        if (price && (isNaN(price) || parseFloat(price) < 0)) {
            showAlert('Price must be a valid positive number', 'danger');
            return false;
        }

        return true;
    }

    function validateImageFile(file) {
        if (!file) return true;

        if (file.size > MAX_FILE_SIZE) {
            showAlert(`Image file is too large. Maximum size is ${(MAX_FILE_SIZE / (1024 * 1024)).toFixed(1)}MB`, 'danger');
            return false;
        }

        if (!ALLOWED_TYPES.includes(file.type)) {
            showAlert('Invalid file type. Please select JPG, PNG, GIF, or WebP image', 'danger');
            return false;
        }

        return true;
    }

    function sanitizeInput(input) {
        return input.replace(/[<>]/g, '');
    }

    // Enhanced alert system with auto-dismiss
    function showAlert(message, type = 'success', duration = 5000) {
        const alertContainer = document.getElementById('alert-container');
        const alertDiv = document.createElement('div');
        alertDiv.className = `alert alert-${type}`;
        alertDiv.innerHTML = `
            <i class="fas fa-${type === 'success' ? 'check-circle' : 'exclamation-circle'}"></i>
            ${sanitizeInput(message)}
            <button type="button" class="btn-close" onclick="this.parentElement.remove()" style="margin-left: auto; background: none; border: none; font-size: 18px; cursor: pointer;">&times;</button>
        `;

        alertContainer.innerHTML = '';
        alertContainer.appendChild(alertDiv);

        // Auto-dismiss after duration
        if (duration > 0) {
            setTimeout(() => {
                if (alertDiv.parentElement) {
                    alertDiv.remove();
                }
            }, duration);
        }

        // Manual dismiss on click
        alertDiv.onclick = function() {
            alertDiv.remove();
        };
    }

    // Loading state management
    function setLoadingState(element, isLoading, originalText = '') {
        if (isLoading) {
            element.disabled = true;
            element.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Loading...';
        } else {
            element.disabled = false;
            element.innerHTML = originalText;
        }
    }

    // Plans Management Functions
    async function loadPlans() {
        const container = document.getElementById('plans-table-container');
        container.innerHTML = '<div class="loading"><div class="spinner"></div>Loading plans...</div>';

        try {
            const response = await fetch(`${API_URL}?action=fetch`);
            const data = await response.json();

            if (data.success) {
                displayPlans(data.plans);
            } else {
                showAlert('Error loading plans: ' + data.message, 'danger');
                container.innerHTML = '<div class="loading">Error loading plans. Please try again.</div>';
            }
        } catch (error) {
            console.error('Error:', error);
            showAlert('Failed to connect to API. Please check your connection.', 'danger');
            container.innerHTML = '<div class="loading">Failed to load plans. Please refresh the page.</div>';
        }
    }

    function displayPlans(plans) {
        const container = document.getElementById('plans-table-container');

        if (plans.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">📋</div>
                    <h3>No Plans Found</h3>
                    <p>Get started by creating your first subscription plan.</p>
                    <button class="btn btn-primary" onclick="openAddModal()">
                        <i class="fas fa-plus"></i> Create First Plan
                    </button>
                </div>
            `;
            return;
        }

        let html = `
            <table class="plans-table">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Name</th>
                        <th>Description</th>
                        <th>Price</th>
                        <th>Status</th>
                        <th>Created</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
        `;

        // Function to convert number to Roman numerals
        function toRoman(num) {
            const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
            const numerals = ['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
            let result = '';
            for (let i = 0; i < values.length; i++) {
                while (num >= values[i]) {
                    result += numerals[i];
                    num -= values[i];
                }
            }
            return result;
        }

        plans.forEach((plan, index) => {
            const status = plan.is_active == 1 ? 'Active' : 'Inactive';
            const statusClass = plan.is_active == 1 ? 'status-active' : 'status-inactive';
            const createdDate = new Date(plan.created_at).toLocaleDateString();

            html += `
                <tr>
                    <td data-label="#"><strong>${toRoman(index + 1)}</strong></td>
                    <td data-label="Name"><strong>${plan.name}</strong></td>
                    <td data-label="Description">${plan.description || '-'}</td>
                    <td data-label="Price">₹${parseFloat(plan.price).toLocaleString('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2})}</td>
                    <td data-label="Status"><span class="status-badge ${statusClass}">${status}</span></td>
                    <td data-label="Created">${createdDate}</td>
                    <td data-label="Actions">
                        <div class="action-buttons">
                            <button class="btn btn-warning btn-sm" onclick="editPlan(${plan.id}, '${plan.name}', '${(plan.description || '').replace(/'/g, "\\'")}', ${plan.price}, ${plan.is_active})">
                                <i class="fas fa-edit"></i> Edit
                            </button>
                            <button class="btn btn-danger btn-sm" onclick="deletePlan(${plan.id}, '${plan.name.replace(/'/g, "\\'")}')">
                                <i class="fas fa-trash"></i> Delete
                            </button>
                        </div>
                    </td>
                </tr>
            `;
        });

        html += `
                </tbody>
            </table>
        `;

        container.innerHTML = html;
    }

    function openAddModal() {
        document.getElementById('modalTitle').textContent = 'Add New Plan';
        document.getElementById('submitBtn').textContent = 'Save Plan';
        document.getElementById('planForm').reset();
        document.getElementById('planId').value = '';
        currentEditId = null;
        document.getElementById('planModal').style.display = 'block';
    }

    function editPlan(id, name, description, price, isActive) {
        document.getElementById('modalTitle').textContent = 'Edit Plan';
        document.getElementById('submitBtn').textContent = 'Update Plan';
        document.getElementById('planId').value = id;
        document.getElementById('planName').value = name;
        document.getElementById('planDescription').value = description;
        document.getElementById('planPrice').value = price;
        document.getElementById('planStatus').value = isActive;
        currentEditId = id;
        document.getElementById('planModal').style.display = 'block';
    }

    function closePlanModal() {
        document.getElementById('planModal').style.display = 'none';
        document.getElementById('planForm').reset();
        currentEditId = null;
    }

    async function deletePlan(id, name) {
        if (!confirm(`Are you sure you want to delete the plan "${name}"? This action cannot be undone.`)) {
            return;
        }

        const formData = new FormData();
        formData.append('action', 'delete');
        formData.append('id', id);

        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                body: formData
            });

            const data = await response.json();

            if (data.success) {
                showAlert('Plan deleted successfully!', 'success');
                loadPlans();
                loadPlansForSteps(); // Refresh plans in steps tab
            } else {
                showAlert('Error deleting plan: ' + data.message, 'danger');
            }
        } catch (error) {
            console.error('Error:', error);
            showAlert('Failed to delete plan. Please try again.', 'danger');
        }
    }

    async function savePlan() {
        // Validate form before submission
        if (!validatePlanForm()) {
            return;
        }

        if (isLoading) return;
        isLoading = true;

        const submitBtn = document.getElementById('submitBtn');
        const originalText = submitBtn.textContent;
        setLoadingState(submitBtn, true, originalText);

        const formData = new FormData(document.getElementById('planForm'));
        const action = currentEditId ? 'update' : 'insert';
        formData.append('action', action);
        formData.append('csrf_token', CSRF_TOKEN);

        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                body: formData
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();

            if (data.success) {
                showAlert(data.message || 'Plan saved successfully!', 'success');
                closePlanModal();
                loadPlans();
                loadPlansForSteps();
            } else {
                showAlert(data.message || 'Failed to save plan', 'danger');
            }
        } catch (error) {
            console.error('Error saving plan:', error);
            showAlert('Network error. Please check your connection and try again.', 'danger');
        } finally {
            isLoading = false;
        }
    }

    // Steps Management Functions
    async function loadPlansForSteps() {
        try {
            const response = await fetch(`${API_URL}?action=fetch`);
            const data = await response.json();

            if (data.success) {
                const planSelect = document.getElementById('planSelect');
                planSelect.innerHTML = '<option value="">-- Select a plan --</option>';

                data.plans.forEach(plan => {
                    const option = document.createElement('option');
                    option.value = plan.id;
                    option.textContent = `${plan.name} (₹${parseFloat(plan.price).toLocaleString('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2})})`;
                    planSelect.appendChild(option);
                });
            } else {
                showAlert(data.message || 'Failed to load plans', 'danger');
            }
        } catch (error) {
            showAlert('Error loading plans: ' + error.message, 'danger');
        }
    }

    async function loadPlanSteps() {
        const planId = document.getElementById('planSelect').value;

        if (!planId) {
            showAlert('Please select a plan first', 'danger');
            return;
        }

        currentPlanId = planId;
        const stepsSection = document.getElementById('stepsSection');
        const stepsList = document.getElementById('stepsList');

        // Save current state
        saveStepManagementState();

        // Show loading
        stepsList.innerHTML = '<div class="loading"><div class="spinner"></div><p>Loading steps...</p></div>';
        stepsSection.style.display = 'block';

        try {
            const response = await fetch(`${API_URL}?action=fetch_steps&plan_id=${planId}`);
            const data = await response.json();

            if (data.success) {
                allSteps = data.steps || [];
                filteredSteps = [...allSteps];

                // Apply current filters after loading
                applyCurrentFilters();
                updateStepCount();
                updateFilterResults();

                // Update plan title
                const planSelect = document.getElementById('planSelect');
                const selectedOption = planSelect.options[planSelect.selectedIndex];
                document.getElementById('planTitle').textContent = `Steps for: ${selectedOption.textContent}`;

                // Set next step number
                const nextStepNumber = allSteps.length > 0 ? Math.max(...allSteps.map(s => parseInt(s.step_number))) + 1 : 1;
                document.getElementById('stepNumber').value = nextStepNumber;
            } else {
                showAlert(data.message || 'Failed to load steps', 'danger');
                stepsList.innerHTML = '';
            }
        } catch (error) {
            showAlert('Error loading steps: ' + error.message, 'danger');
            stepsList.innerHTML = '';
        }
    }

    let filteredSteps = [];

    function renderSteps(stepsToRender = null) {
        const stepsList = document.getElementById('stepsList');
        const steps = stepsToRender || allSteps;

        if (steps.length === 0) {
            stepsList.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">📝</div>
                    <h3>No steps found</h3>
                    <p>${allSteps.length === 0 ? 'Add your first step to get started!' : 'No steps match your search criteria.'}</p>
                </div>
            `;
            return;
        }

        stepsList.innerHTML = steps.map(step => `
            <div class="step-item" id="step-${step.id}">
                <div class="step-header">
                    <div style="display: flex; align-items: center; gap: 15px;">
                        <span class="step-number">${step.step_number}</span>
                        <div class="step-description" style="margin-left: 0; color: #374151; line-height: 1.6; font-weight: 500; flex: 1;">${step.step_description}</div>
                    </div>
                    <div class="step-actions">
                        <select class="form-control" style="width: 120px; margin-right: 10px;" onchange="updateStepStatus(${step.id}, this.value)">
                            <option value="open" ${step.status === 'open' ? 'selected' : ''}>Open</option>
                            <option value="in process" ${step.status === 'in process' ? 'selected' : ''}>In Process</option>
                            <option value="completed" ${step.status === 'completed' ? 'selected' : ''}>Completed</option>
                        </select>
                        <button class="btn btn-warning btn-sm" onclick="editStep(${step.id})">
                            <i class="fas fa-edit"></i> Edit
                        </button>
                        <button class="btn btn-danger btn-sm" onclick="deleteStep(${step.id}, ${step.step_number})">
                            <i class="fas fa-trash"></i> Delete
                        </button>
                    </div>
                </div>
                <div class="step-status-info" style="margin: 10px 0 8px 0;">
                    <span class="status-badge status-${step.status ? step.status.replace(' ', '-') : 'open'}">${step.status || 'Open'}</span>
                </div>

                ${step.step_image ? `
                    <div class="step-image-container">
                        <img src="https://customprint.deodap.com/uploads/${step.step_image}"
                             alt="Step ${step.step_number} Image"
                             class="step-image"
                             onclick="openImageModal('https://customprint.deodap.com/uploads/${step.step_image}')">
                        <div class="image-actions">
                            <button class="btn btn-sm btn-primary" onclick="changeStepImage(${step.id})">
                                <i class="fas fa-camera"></i> Change
                            </button>
                            <button class="btn btn-sm btn-danger" onclick="removeStepImage(${step.id})">
                                <i class="fas fa-trash"></i> Remove
                            </button>
                        </div>
                    </div>
                ` : `
                    <div class="no-image-container">
                        <button class="btn btn-sm btn-primary" onclick="addStepImage(${step.id})">
                            <i class="fas fa-camera"></i> Add Image
                        </button>
                    </div>
                `}

                <!-- Edit Form (hidden by default) -->
                <div class="edit-form" id="edit-form-${step.id}">
                    <form onsubmit="updateStep(event, ${step.id})" enctype="multipart/form-data">
                        <div class="form-row">
                            <div class="form-group">
                                <label>Step #:</label>
                                <input type="number" class="form-control" value="${step.step_number}" name="step_number" min="1" required>
                            </div>
                            <div class="form-group">
                                <label>Description:</label>
                                <input type="text" class="form-control" value="${step.step_description}" name="step_description" maxlength="255" required>
                            </div>
                            <div class="form-group">
                                <label>Status:</label>
                                <select class="form-control" name="status">
                                    <option value="open" ${step.status === 'open' ? 'selected' : ''}>Open</option>
                                    <option value="in process" ${step.status === 'in process' ? 'selected' : ''}>In Process</option>
                                    <option value="completed" ${step.status === 'completed' ? 'selected' : ''}>Completed</option>
                                </select>
                            </div>
                        </div>
                        <div class="form-group">
                            <label>Update Image (Optional):</label>
                            <input type="file" class="form-control" name="step_image" accept="image/*" id="edit-image-${step.id}">
                            <small class="text-muted">Leave empty to keep current image</small>
                        </div>
                        <div class="form-group">
                            <button type="submit" class="btn btn-success btn-sm">
                                <i class="fas fa-save"></i> Save
                            </button>
                            <button type="button" class="btn btn-sm" onclick="cancelEdit(${step.id})" style="background: #6b7280; color: white;">
                                <i class="fas fa-times"></i> Cancel
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        `).join('');
    }

    function updateStepCount() {
        document.getElementById('stepCount').textContent = `${allSteps.length} step${allSteps.length !== 1 ? 's' : ''}`;
    }

    async function addStep() {
        const stepNumber = document.getElementById('stepNumber').value;
        const stepDescription = document.getElementById('stepDescription').value;
        const stepStatus = document.getElementById('stepStatus').value;
        const stepImage = document.getElementById('stepImage').files[0];

        if (!currentPlanId) {
            showAlert('Please select a plan first', 'danger');
            return;
        }

        // Validate inputs
        if (!stepNumber || !stepDescription) {
            showAlert('Please fill in all required fields', 'danger');
            return;
        }

        // Validate image if provided
        if (!validateImageFile(stepImage)) {
            return;
        }

        if (isLoading) return;
        isLoading = true;

        const formData = new FormData();
        formData.append('action', 'insert_step');
        formData.append('plan_id', currentPlanId);
        formData.append('step_number', stepNumber);
        formData.append('step_description', stepDescription);
        formData.append('status', stepStatus);

        // Add image if selected
        if (stepImage) {
            formData.append('step_image', stepImage);

        }



        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                body: formData
            });

            console.log('Response status:', response.status);
            console.log('Response headers:', response.headers);

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const responseText = await response.text();


            let data;
            try {
                data = JSON.parse(responseText);
            } catch (parseError) {
                console.error('JSON parse error:', parseError);
                showAlert('Invalid response from server. Please check console for details.', 'danger');
                return;
            }



            if (data.success) {
                showAlert('Step added successfully!', 'success');

                // Clear form
                document.getElementById('stepDescription').value = '';
                document.getElementById('stepImage').value = '';
                clearImagePreview();

                // Reload steps and maintain current state
                await loadPlanSteps();
            } else {
                showAlert(data.message || 'Failed to add step', 'danger');
            }
        } catch (error) {
            showAlert('Network error: ' + error.message, 'danger');
        } finally {
            isLoading = false;
        }
    }

    function editStep(stepId) {
        const editForm = document.getElementById(`edit-form-${stepId}`);
        editForm.style.display = editForm.style.display === 'block' ? 'none' : 'block';
    }

    function cancelEdit(stepId) {
        document.getElementById(`edit-form-${stepId}`).style.display = 'none';
    }

    async function updateStep(event, stepId) {
        event.preventDefault();

        const form = event.target;
        const formData = new FormData();
        formData.append('action', 'update_step');
        formData.append('id', stepId);
        formData.append('step_number', form.step_number.value);
        formData.append('step_description', form.step_description.value);
        formData.append('status', form.status.value);

        // Add image if selected
        const imageFile = form.step_image.files[0];
        if (imageFile) {
            formData.append('step_image', imageFile);
        }

        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                body: formData
            });

            const data = await response.json();

            if (data.success) {
                showAlert('Step updated successfully!', 'success');

                // Hide edit form and reload steps
                cancelEdit(stepId);
                await loadPlanSteps();
            } else {
                showAlert(data.message || 'Failed to update step', 'danger');
            }
        } catch (error) {
            showAlert('Error updating step: ' + error.message, 'danger');
        }
    }

    async function deleteStep(stepId, stepNumber) {
        if (!confirm(`Are you sure you want to delete Step ${stepNumber}?`)) {
            return;
        }

        const formData = new FormData();
        formData.append('action', 'delete_step');
        formData.append('id', stepId);

        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                body: formData
            });

            const data = await response.json();

            if (data.success) {
                showAlert('Step deleted successfully!', 'success');
                await loadPlanSteps();
            } else {
                showAlert(data.message || 'Failed to delete step', 'danger');
            }
        } catch (error) {
            showAlert('Error deleting step: ' + error.message, 'danger');
        }
    }

    // Update step status function
    async function updateStepStatus(stepId, newStatus) {
        const formData = new FormData();
        formData.append('action', 'update_step_status');
        formData.append('id', stepId);
        formData.append('status', newStatus);

        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                body: formData
            });

            const data = await response.json();

            if (data.success) {
                showAlert(data.message, 'success');

                // Update the status badge in the UI
                const stepItem = document.getElementById(`step-${stepId}`);
                const statusBadge = stepItem.querySelector('.status-badge');
                if (statusBadge) {
                    statusBadge.className = `status-badge status-${newStatus.replace(' ', '-')}`;
                    statusBadge.textContent = newStatus.charAt(0).toUpperCase() + newStatus.slice(1);
                }

                // Update the step in allSteps array
                const stepIndex = allSteps.findIndex(step => step.id == stepId);
                if (stepIndex !== -1) {
                    allSteps[stepIndex].status = newStatus;
                    // Re-apply current filters
                    filterSteps();
                }
            } else {
                showAlert(data.message || 'Failed to update step status', 'danger');
                // Reload steps to reset the dropdown
                loadPlanSteps();
            }
        } catch (error) {
            showAlert('Error updating step status: ' + error.message, 'danger');
            // Reload steps to reset the dropdown
            loadPlanSteps();
        }
    }

    // Modal and window event handlers
    window.onclick = function(event) {
        const modal = document.getElementById('planModal');
        const imageModal = document.getElementById('imageModal');

        if (event.target === modal) {
            closePlanModal();
        }

        if (event.target === imageModal) {
            closeImageModal();
        }
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

    // Image handling functions
    function clearImagePreview() {
        document.getElementById('stepImage').value = '';
        document.getElementById('imagePreview').style.display = 'none';
    }

    function openImageModal(imageSrc) {
        document.getElementById('modalImage').src = imageSrc;
        document.getElementById('imageModal').style.display = 'block';
    }

    function closeImageModal() {
        document.getElementById('imageModal').style.display = 'none';
    }

    async function addStepImage(stepId) {
        const hiddenInput = document.getElementById('hiddenImageInput');
        hiddenInput.onchange = async function(e) {
            const file = e.target.files[0];
            if (!file) return;

            // Validate image
            const maxSize = 5 * 1024 * 1024; // 5MB
            const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];

            if (file.size > maxSize) {
                showAlert('Image file is too large. Maximum size is 5MB', 'danger');
                hiddenInput.value = '';
                return;
            }

            if (!allowedTypes.includes(file.type)) {
                showAlert('Invalid file type. Please select JPG, PNG, GIF, or WebP image', 'danger');
                hiddenInput.value = '';
                return;
            }

            const formData = new FormData();
            formData.append('action', 'upload_step_image');
            formData.append('step_id', stepId);
            formData.append('step_image', file);



            try {
                const response = await fetch(API_URL, {
                    method: 'POST',
                    body: formData
                });

                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }

                const responseText = await response.text();


                let data;
                try {
                    data = JSON.parse(responseText);
                } catch (parseError) {
                    console.error('JSON parse error:', parseError);
                    showAlert('Invalid response from server. Please check console for details.', 'danger');
                    hiddenInput.value = '';
                    return;
                }

                if (data.success) {
                    showAlert('Image uploaded successfully!', 'success');
                    await loadPlanSteps();
                } else {
                    showAlert(data.message || 'Failed to upload image', 'danger');
                }
            } catch (error) {
                showAlert('Network error: ' + error.message, 'danger');
            }

            hiddenInput.value = '';
        };
        hiddenInput.click();
    }

    async function changeStepImage(stepId) {
        const hiddenInput = document.getElementById('hiddenImageInput');
        hiddenInput.onchange = async function(e) {
            const file = e.target.files[0];
            if (!file) return;

            // Validate image
            const maxSize = 5 * 1024 * 1024; // 5MB
            const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];

            if (file.size > maxSize) {
                showAlert('Image file is too large. Maximum size is 5MB', 'danger');
                hiddenInput.value = '';
                return;
            }

            if (!allowedTypes.includes(file.type)) {
                showAlert('Invalid file type. Please select JPG, PNG, GIF, or WebP image', 'danger');
                hiddenInput.value = '';
                return;
            }

            const formData = new FormData();
            formData.append('action', 'upload_step_image');
            formData.append('step_id', stepId);
            formData.append('step_image', file);



            try {
                const response = await fetch(API_URL, {
                    method: 'POST',
                    body: formData
                });

                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }

                const responseText = await response.text();


                let data;
                try {
                    data = JSON.parse(responseText);
                } catch (parseError) {
                    console.error('JSON parse error:', parseError);
                    showAlert('Invalid response from server. Please check console for details.', 'danger');
                    hiddenInput.value = '';
                    return;
                }

                if (data.success) {
                    showAlert('Image updated successfully!', 'success');
                    await loadPlanSteps();
                } else {
                    showAlert(data.message || 'Failed to update image', 'danger');
                }
            } catch (error) {
                showAlert('Network error: ' + error.message, 'danger');
            }

            hiddenInput.value = '';
        };
        hiddenInput.click();
    }

    async function removeStepImage(stepId) {
        if (!confirm('Are you sure you want to remove this image?')) {
            return;
        }

        const formData = new FormData();
        formData.append('action', 'remove_step_image');
        formData.append('step_id', stepId);

        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                body: formData
            });

            const data = await response.json();

            if (data.success) {
                showAlert('Image removed successfully!', 'success');
                await loadPlanSteps();
            } else {
                showAlert(data.message || 'Failed to remove image', 'danger');
            }
        } catch (error) {
            showAlert('Error removing image: ' + error.message, 'danger');
        }
    }

    // Image preview for add step form
    document.addEventListener('DOMContentLoaded', function() {
        const stepImageInput = document.getElementById('stepImage');
        if (stepImageInput) {
            stepImageInput.addEventListener('change', function(e) {
                const file = e.target.files[0];
                const preview = document.getElementById('imagePreview');
                const previewImg = document.getElementById('previewImg');

                if (file) {
                    const reader = new FileReader();
                    reader.onload = function(e) {
                        previewImg.src = e.target.result;
                        preview.style.display = 'flex';
                    };
                    reader.readAsDataURL(file);
                } else {
                    preview.style.display = 'none';
                }
            });
        }
    });

    // Close image modal when clicking outside
    window.onclick = function(event) {
        const modal = document.getElementById('planModal');
        const imageModal = document.getElementById('imageModal');

        if (event.target === modal) {
            closePlanModal();
        }

        if (event.target === imageModal) {
            closeImageModal();
        }
    }

    // Search and Filter Functions
    function filterSteps() {
        const searchTerm = document.getElementById('stepSearch').value.toLowerCase();
        const statusFilter = document.getElementById('statusFilter').value;
        const sortBy = document.getElementById('sortBy').value;

        // Update current filters
        currentFilters.search = searchTerm;
        currentFilters.status = statusFilter;
        currentFilters.sort = sortBy;

        // Save state
        saveStepManagementState();

        // Apply filters
        applyCurrentFilters();
    }

    function applyCurrentFilters() {
        // Start with all steps
        filteredSteps = [...allSteps];

        // Apply search filter
        if (currentFilters.search) {
            filteredSteps = filteredSteps.filter(step =>
                step.step_description.toLowerCase().includes(currentFilters.search)
            );
        }

        // Apply status filter
        if (currentFilters.status) {
            filteredSteps = filteredSteps.filter(step =>
                step.status === currentFilters.status
            );
        }

        // Apply sorting
        switch (currentFilters.sort) {
            case 'step_number_asc':
                filteredSteps.sort((a, b) => parseInt(a.step_number) - parseInt(b.step_number));
                break;
            case 'step_number_desc':
                filteredSteps.sort((a, b) => parseInt(b.step_number) - parseInt(a.step_number));
                break;
            case 'status':
                filteredSteps.sort((a, b) => {
                    const statusOrder = { 'open': 1, 'in process': 2, 'completed': 3 };
                    return (statusOrder[a.status] || 0) - (statusOrder[b.status] || 0);
                });
                break;
            case 'description':
                filteredSteps.sort((a, b) => a.step_description.localeCompare(b.step_description));
                break;
            default:
                filteredSteps.sort((a, b) => parseInt(a.step_number) - parseInt(b.step_number));
        }

        // Update the display
        renderSteps(filteredSteps);
        updateFilterResults();
    }

    function clearFilters() {
        document.getElementById('stepSearch').value = '';
        document.getElementById('statusFilter').value = '';
        document.getElementById('sortBy').value = 'step_number_asc';

        // Reset current filters
        currentFilters = {
            search: '',
            status: '',
            sort: 'step_number_asc'
        };

        // Save state
        saveStepManagementState();

        // Reset to show all steps
        filteredSteps = [...allSteps];
        filteredSteps.sort((a, b) => parseInt(a.step_number) - parseInt(b.step_number));
        renderSteps(filteredSteps);
        updateFilterResults();
    }

    function updateFilterResults() {
        const filterResults = document.getElementById('filterResults');
        const totalSteps = allSteps.length;
        const shownSteps = filteredSteps.length;

        if (shownSteps === totalSteps) {
            filterResults.textContent = `Showing all ${totalSteps} step${totalSteps !== 1 ? 's' : ''}`;
        } else {
            filterResults.textContent = `Showing ${shownSteps} of ${totalSteps} step${totalSteps !== 1 ? 's' : ''}`;
        }
    }

    // State management functions
    function saveTabState() {
        localStorage.setItem('activeTab', currentTab);
    }

    function restoreTabState() {
        const savedTab = localStorage.getItem('activeTab');
        if (savedTab && (savedTab === 'plans' || savedTab === 'steps')) {
            currentTab = savedTab;

            // Update UI to show correct tab
            const tabs = document.querySelectorAll('.tab-btn');
            const contents = document.querySelectorAll('.tab-content');

            tabs.forEach(t => t.classList.remove('active'));
            contents.forEach(c => c.classList.remove('active'));

            document.querySelector(`[onclick="switchTab('${savedTab}')"]`).classList.add('active');
            document.getElementById(`${savedTab}-tab`).classList.add('active');
        }
    }

    function saveStepManagementState() {
        const state = {
            planId: currentPlanId,
            filters: currentFilters,
            timestamp: Date.now()
        };
        localStorage.setItem('stepManagementState', JSON.stringify(state));
    }

    function restoreStepManagementState() {
        try {
            const savedState = localStorage.getItem('stepManagementState');
            if (!savedState) return;

            const state = JSON.parse(savedState);

            // Check if state is not too old (1 hour)
            if (Date.now() - state.timestamp > 3600000) {
                localStorage.removeItem('stepManagementState');
                return;
            }

            // Restore plan selection
            if (state.planId) {
                const planSelect = document.getElementById('planSelect');
                if (planSelect) {
                    planSelect.value = state.planId;
                    currentPlanId = state.planId;
                }
            }

            // Restore filters
            if (state.filters) {
                currentFilters = { ...state.filters };

                // Set filter UI elements
                const stepSearch = document.getElementById('stepSearch');
                const statusFilter = document.getElementById('statusFilter');
                const sortBy = document.getElementById('sortBy');

                if (stepSearch) stepSearch.value = currentFilters.search || '';
                if (statusFilter) statusFilter.value = currentFilters.status || '';
                if (sortBy) sortBy.value = currentFilters.sort || 'step_number_asc';
            }

            // Auto-load steps if plan was selected
            if (state.planId && document.getElementById('planSelect').value) {
                setTimeout(() => {
                    loadPlanSteps();
                }, 100);
            }
        } catch (error) {
            console.error('Error restoring state:', error);
            localStorage.removeItem('stepManagementState');
        }
    }

    // Profile menu toggle functionality
    function toggleProfileMenu() {
        const profileMenu = document.getElementById('profile-menu');
        const profileToggle = document.getElementById('profile-toggle');

        if (profileMenu.style.maxHeight === '0px' || profileMenu.style.maxHeight === '') {
            profileMenu.style.maxHeight = '200px';
        } else {
            profileMenu.style.maxHeight = '0px';
        }
    }
</script>

</body>
</html>