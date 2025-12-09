<?php
// dashboard.php
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
    <title>Dropshipper Plans - Progress Tracker</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #2563eb;
            --primary-dark: #1d4ed8;
            --primary-light: #3b82f6;
            --success: #10b981;
            --success-light: #d1fae5;
            --warning: #f59e0b;
            --warning-light: #fef3c7;
            --danger: #ef4444;
            --danger-light: #fee2e2;
            --gray-50: #ffffff;
            --gray-100: #f8fafc;
            --gray-200: #e2e8f0;
            --gray-300: #cbd5e1;
            --gray-400: #94a3b8;
            --gray-500: #64748b;
            --gray-600: #475569;
            --gray-700: #334155;
            --gray-800: #1e293b;
            --gray-900: #0f172a;
            --white: #ffffff;
            --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
            --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
            --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
            --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
            --radius-sm: 6px;
            --radius-md: 8px;
            --radius-lg: 12px;
            --radius-xl: 16px;
            --transition: all 0.2s ease-in-out;
        }

        * {
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: var(--white);
            color: var(--gray-800);
            margin: 0;
            padding: 20px;
            min-height: 100vh;
            line-height: 1.6;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: var(--white);
            border-radius: var(--radius-xl);
            box-shadow: var(--shadow-lg);
            overflow: hidden;
            border: 1px solid var(--gray-200);
        }

        .header {
            background: var(--white);
            color: var(--gray-800);
            padding: 2rem;
            text-align: center;
            position: relative;
            border-bottom: 2px solid var(--gray-200);
        }

        .header h1 {
            font-size: 2.5rem;
            font-weight: 700;
            margin: 0 0 0.5rem 0;
            color: var(--primary);
        }

        .header p {
            font-size: 1.1rem;
            color: var(--gray-600);
            margin: 0;
        }



        /* Client Pending Styles */
.btn-pending {
    background-color: #f59e0b;
    color: white;
    border: none;
    padding: 0.5rem 1rem;
    border-radius: 0.375rem;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.875rem;
    margin-right: 0.5rem;
    transition: background-color 0.2s;
}

.btn-pending:hover {
    background-color: #d97706;
}

.btn-pending.active {
    background-color: #10b981;
}

.btn-pending.active:hover {
    background-color: #0d9f6e;
}

.client-pending-note {
    background-color: #fffbeb;
    border-left: 4px solid #f59e0b;
    padding: 0.75rem 1rem;
    margin: 0.75rem 0;
    border-radius: 0.25rem;
    font-size: 0.875rem;
}

.client-pending-note p {
    margin: 0.5rem 0 0.75rem;
    color: #5f6c80;
}

.btn-edit-note {
    background: none;
    border: 1px solid #e2e8f0;
    color: #4a5568;
    padding: 0.25rem 0.75rem;
    border-radius: 0.25rem;
    font-size: 0.75rem;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 0.25rem;
}

.btn-edit-note:hover {
    background-color: #f8fafc;
}
        /* Compact Dropshipper Details */
        .dropshipper-info-card {
            background: var(--gray-100);
            border-radius: var(--radius-lg);
            padding: 1.5rem;
            margin: 1rem;
            border: 1px solid var(--gray-200);
            box-shadow: var(--shadow-sm);
            position: relative;
        }

        .dropshipper-info-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 3px;
            background: var(--primary);
        }

        .dropshipper-header {
            display: flex;
            align-items: center;
            gap: 1rem;
            margin-bottom: 1rem;
            flex-wrap: wrap;
        }

        .dropshipper-avatar {
            width: 60px;
            height: 60px;
            background: var(--primary);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
            color: white;
            border: 3px solid var(--white);
            box-shadow: var(--shadow-md);
            flex-shrink: 0;
        }

        .dropshipper-info h2 {
            margin: 0 0 0.25rem 0;
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--gray-800);
        }

        .dropshipper-info p {
            margin: 0;
            color: var(--gray-500);
            font-size: 1rem;
            font-weight: 500;
        }

        .dropshipper-details-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
        }

        .detail-item {
            background: var(--white);
            padding: 1rem;
            border-radius: var(--radius-md);
            border: 1px solid var(--gray-200);
            box-shadow: var(--shadow-sm);
        }

        .detail-item:hover {
        }

        .detail-item label {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            font-size: 0.75rem;
            color: var(--gray-500);
            margin-bottom: 0.5rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .detail-item label i {
            color: var(--primary);
        }

        .detail-item span {
            font-size: 1rem;
            font-weight: 600;
            color: var(--gray-800);
            display: block;
        }

        /* Plan Cards */
        .plans-container {
            padding: 2rem;
            background: var(--white);
        }

        .plan-card {
            background: var(--white);
            border-radius: var(--radius-lg);
            margin-bottom: 2rem;
            box-shadow: var(--shadow-md);
            border: 1px solid var(--gray-200);
            overflow: hidden;
        }

        .plan-card:hover {
        }

        .plan-header {
            padding: 1.5rem;
            background: var(--gray-100);
            color: var(--gray-800);
            font-weight: 600;
            display: flex;
            justify-content: space-between;
            align-items: center;
            cursor: pointer;
            user-select: none;
            position: relative;
            border-bottom: 1px solid var(--gray-200);
        }

        .plan-header:hover {
            background: var(--gray-200);
        }

        .plan-header-left {
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .plan-header-right {
            display: flex;
            align-items: center;
            gap: 0.75rem;
        }

        .roman-number {
            font-size: 1.25rem;
            font-weight: 700;
            background: var(--primary);
            color: white;
            padding: 0.5rem 1rem;
            border-radius: var(--radius-sm);
        }

        .plan-toggle, .plan-delete-btn {
            border: none;
            padding: 0.75rem 1rem;
            border-radius: var(--radius-sm);
            cursor: pointer;
            transition: var(--transition);
            font-weight: 500;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .plan-toggle {
            background: var(--primary);
            color: white;
        }

        .plan-toggle:hover {
            background: var(--primary-dark);
        }

        .plan-delete-btn {
            background: var(--danger);
            color: white;
        }

        .plan-delete-btn:hover {
            background: #dc2626;
        }

        /* Steps Grid */
        .steps-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 1.5rem;
            padding: 0;
            background: var(--gray-50);
            max-height: 0;
            overflow: hidden;
            height: 0;
            transition: max-height 0.4s cubic-bezier(0.4, 0, 0.2, 1), padding 0.4s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .steps-grid.expanded {
            max-height: 5000px;
            height: auto;
            padding: 2rem;
            transition: max-height 0.6s cubic-bezier(0.4, 0, 0.2, 1), padding 0.6s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .step-card {
            background: var(--white);
            border-radius: var(--radius-md);
            box-shadow: var(--shadow-sm);
            padding: 1.5rem;
            border: 1px solid var(--gray-200);
            position: relative;
        }

        .step-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 4px;
            height: 100%;
            background: var(--primary);
            opacity: 0;
        }

        .step-card:hover {
        }

        .step-card:hover::before {
        }

        .step-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 1rem;
            gap: 1rem;
        }

        .step-header h4 {
            margin: 0;
            font-size: 1.25rem;
            font-weight: 600;
            color: var(--gray-800);
            flex: 1;
        }

        .status-dropdown {
            padding: 0.5rem 0.75rem;
            border: 2px solid var(--gray-300);
            border-radius: var(--radius-sm);
            background: var(--white);
            font-size: 0.875rem;
            font-weight: 500;
            cursor: pointer;
            min-width: 120px;
            transition: var(--transition);
        }

        .status-dropdown:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(0, 0, 0, 0.1);
        }

        .status-dropdown:hover {
            border-color: var(--primary);
        }

        .step-description {
            margin-bottom: 1rem;
            color: var(--gray-600);
            line-height: 1.6;
        }

        .step-custom-description {
            background: var(--gray-100);
            padding: 1rem;
            border-radius: var(--radius-sm);
            margin: 1rem 0;
            font-style: italic;
            color: var(--gray-600);
            border-left: 4px solid var(--primary);
        }

        .step-actions {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 1rem;
            gap: 1rem;
        }

        .upload-btn, .delete-image-btn, .chat-btn {
            border: none;
            padding: 0.75rem 1rem;
            border-radius: var(--radius-sm);
            cursor: pointer;
            font-size: 0.875rem;
            font-weight: 500;
            display: flex;
            align-items: center;
            gap: 0.5rem;
            transition: var(--transition);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .upload-btn {
            background: var(--primary);
            color: white;
        }

        .upload-btn:hover {
            background: var(--primary-dark);
        }

        .delete-image-btn {
            background: var(--danger);
            color: white;
        }

        .delete-image-btn:hover {
            background: #dc2626;
        }

        .chat-btn {
            background: #3498db;
            color: white;
        }

        .chat-btn:hover {
            background: #2e6da4;
        }

        .step-image, .image-preview {
            max-width: 100%;
            max-height: 250px;
            border-radius: var(--radius-md);
            margin-top: 1rem;
            cursor: pointer;
            transition: var(--transition);
            object-fit: cover;
            border: 2px solid var(--gray-200);
        }

        .step-image:hover, .image-preview:hover {
            transform: scale(1.02);
            box-shadow: var(--shadow-lg);
            border-color: var(--primary);
        }

        .step-updated {
            color: var(--gray-400);
            font-size: 0.875rem;
            margin-top: 1rem;
            padding-top: 1rem;
            border-top: 1px solid var(--gray-200);
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .step-updated::before {
            content: '🕒';
            font-size: 1rem;
        }

        /* Status Badges */
        .step-status {
            font-size: 0.875rem;
            font-weight: 600;
            border-radius: 20px;
            padding: 0.5rem 1rem;
            margin-bottom: 1rem;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .status-pending {
            background: var(--warning-light);
            color: #92400e;
        }

        .status-pending::before {
            content: '⏳';
        }

        .status-in-progress {
            background: #bfdbfe;
            color: #1e40af;
        }

        .status-in-progress::before {
            content: '🔄';
        }

        .status-completed {
            background: var(--success-light);
            color: #065f46;
        }

        .status-completed::before {
            content: '✅';
        }

        .status-open {
            background: var(--success-light);
            color: #065f46;
        }

        .status-open::before {
            content: '📂';
        }

        /* Modal */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.6);
            backdrop-filter: blur(5px);
        }

        .modal-content {
            background: var(--white);
            margin: 3% auto;
            padding: 2rem;
            width: 90%;
            max-width: 600px;
            border-radius: var(--radius-xl);
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: var(--shadow-xl);
            position: relative;
        }

        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
            padding-bottom: 1rem;
            border-bottom: 2px solid var(--gray-200);
        }

        .modal-header h2 {
            margin: 0;
            color: var(--gray-800);
            font-size: 1.75rem;
            font-weight: 700;
        }

        .close {
            color: var(--gray-400);
            font-size: 2rem;
            font-weight: bold;
            cursor: pointer;
            transition: var(--transition);
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
        }

        .close:hover {
            color: var(--gray-600);
            background: var(--gray-100);
            transform: scale(1.1);
        }

        /* Forms */
        .form-group {
            margin-bottom: 1.5rem;
        }

        .form-group label {
            display: block;
            margin-bottom: 0.75rem;
            font-weight: 600;
            color: var(--gray-700);
            font-size: 1rem;
        }

        .form-control {
            width: 100%;
            padding: 1rem;
            border: 2px solid var(--gray-300);
            border-radius: var(--radius-md);
            font-size: 1rem;
            transition: var(--transition);
            background: var(--white);
        }

        .form-control:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(0, 0, 0, 0.1);
            transform: translateY(-1px);
        }

        .form-control:hover {
            border-color: var(--primary);
        }

        /* Buttons */
        .btn {
            padding: 1rem 1.5rem;
            border: none;
            border-radius: var(--radius-md);
            cursor: pointer;
            font-weight: 600;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            transition: var(--transition);
            font-size: 1rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-md);
        }

        .btn-primary {
            background: var(--primary);
            color: white;
        }

        .btn-primary:hover {
            background: var(--primary-dark);
        }

        .btn-secondary {
            background: var(--gray-600);
            color: white;
        }

        .btn-secondary:hover {
            background: var(--gray-700);
        }

        .btn-danger {
            background: var(--danger);
            color: white;
        }

        .btn-danger:hover {
            background: #dc2626;
        }

        /* Add Plan Section */
        .add-plan-section {
            background: var(--gray-50);
            border: 2px dashed var(--gray-300);
            border-radius: var(--radius-xl);
            padding: 3rem;
            text-align: center;
            margin: 2rem 0;
            transition: var(--transition);
        }

        .add-plan-section:hover {
            border-color: var(--primary);
            background: var(--gray-100);
        }

        .add-plan-section h3 {
            margin: 1rem 0 0.5rem 0;
            color: var(--gray-700);
            font-size: 1.5rem;
            font-weight: 700;
        }

        .add-plan-section p {
            color: var(--gray-500);
            margin-bottom: 2rem;
            font-size: 1.1rem;
        }

        .add-plan-section i {
            color: var(--primary);
        }

        /* Loading States */
        .loading {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 2rem;
            text-align: center;
            color: var(--gray-600);
        }

        .loading i {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            color: var(--primary);
            animation: spin 1s linear infinite;
        }

        .loading p {
            margin: 0.5rem 0 0;
            font-size: 1rem;
        }

        .error-message {
            padding: 2rem;
            text-align: center;
            color: var(--danger);
            background-color: var(--danger-light);
            border-radius: var(--radius-md);
            margin: 1rem 0;
        }

        .error-message i {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            display: block;
        }

        .error-message h3 {
            margin: 0.5rem 0;
            color: var(--danger);
        }

        .error-message p {
            margin: 0.5rem 0 1.5rem;
            color: var(--gray-700);
        }

        .error-message .btn {
            margin-top: 1rem;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        /* Alerts */
        .alert {
            margin: 1rem 0;
            padding: 1rem 1.5rem;
            border-radius: var(--radius-md);
            font-weight: 500;
            display: flex;
            align-items: center;
            gap: 0.75rem;
            animation: alertSlideIn 0.3s ease-out;
        }

        @keyframes alertSlideIn {
            from { transform: translateY(-10px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }

        .alert-success {
            background: var(--success-light);
            color: #065f46;
            border-left: 4px solid var(--success);
        }

        .alert-success::before {
            content: '✅';
        }

        .alert-danger {
            background: var(--danger-light);
            color: #b91c1c;
            border-left: 4px solid var(--danger);
        }

        .alert-danger::before {
            content: '❌';
        }

        /* Image Modal */
        .image-modal {
            display: none;
            position: fixed;
            z-index: 1001;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.95);
            backdrop-filter: blur(10px);
        }

        .image-modal-content {
            margin: auto;
            display: block;
            max-width: 90%;
            max-height: 90%;
            margin-top: 5vh;
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-xl);
        }

        .close-image-modal {
            position: absolute;
            top: 20px;
            right: 40px;
            color: #f1f1f1;
            font-size: 3rem;
            font-weight: bold;
            cursor: pointer;
            transition: var(--transition);
            width: 60px;
            height: 60px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
            background: rgba(0,0,0,0.5);
            backdrop-filter: blur(10px);
        }

        .close-image-modal:hover {
            background: rgba(255,255,255,0.2);
            transform: scale(1.1);
        }

        .nav-arrow {
            color: white;
            font-size: 2rem;
            cursor: pointer;
            background: rgba(0,0,0,0.7);
            border-radius: 50%;
            width: 60px;
            height: 60px;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: var(--transition);
            backdrop-filter: blur(10px);
        }

        .nav-arrow:hover {
            background: rgba(255,255,255,0.2);
            transform: scale(1.1);
        }

        .image-navigation {
            position: fixed;
            top: 50%;
            width: 100%;
            display: flex;
            justify-content: space-between;
            padding: 0 2rem;
            pointer-events: none;
        }

        .image-navigation > * {
            pointer-events: auto;
        }

        .image-caption {
            margin: 1rem auto;
            color: white;
            text-align: center;
            max-width: 80%;
            padding: 1rem;
            background: rgba(0,0,0,0.7);
            border-radius: var(--radius-md);
            backdrop-filter: blur(10px);
            font-weight: 500;
        }

        /* Responsive Design */
        @media (max-width: 768px) {
            body {
                padding: 10px;
            }

            .container {
                border-radius: var(--radius-lg);
            }

            .header {
                padding: 1.5rem;
            }

            .header h1 {
                font-size: 2rem;
            }

            .dropshipper-info-card {
                margin: 1rem;
                padding: 1rem;
            }

            .dropshipper-header {
                flex-direction: column;
                text-align: center;
            }

            .dropshipper-details-grid {
                grid-template-columns: 1fr;
                gap: 1rem;
            }

            .plans-container {
                padding: 1rem;
            }

            .plan-header {
                flex-direction: column;
                gap: 1rem;
                text-align: center;
                padding: 1rem;
            }

            .plan-header-right {
                flex-wrap: wrap;
                justify-content: center;
            }

            .steps-grid {
                grid-template-columns: 1fr;
                padding: 1rem;
                gap: 1rem;
            }

            .step-header {
                flex-direction: column;
                align-items: stretch;
                gap: 0.5rem;
            }

            .step-actions {
                flex-direction: column;
                gap: 0.5rem;
            }

            .modal-content {
                margin: 5% auto;
                width: 95%;
                padding: 1.5rem;
            }

            .modal-header h2 {
                font-size: 1.5rem;
            }

            .nav-arrow {
                width: 50px;
                height: 50px;
                font-size: 1.5rem;
            }

            .close-image-modal {
                width: 50px;
                height: 50px;
                font-size: 2rem;
                top: 15px;
                right: 20px;
            }
        }

        @media (max-width: 480px) {
            .header h1 {
                font-size: 1.75rem;
            }

            .dropshipper-avatar {
                width: 50px;
                height: 50px;
                font-size: 1.25rem;
            }

            .dropshipper-info h2 {
                font-size: 1.25rem;
            }

            .roman-number {
                font-size: 1rem;
                padding: 0.25rem 0.5rem;
            }

            .btn {
                padding: 0.75rem 1rem;
                font-size: 0.875rem;
            }

            .upload-btn, .delete-image-btn {
                padding: 0.5rem 0.75rem;
                font-size: 0.75rem;
            }
        }

        /* Accessibility Enhancements */
        @media (prefers-reduced-motion: reduce) {
            *,
            *::before,
            *::after {
                animation-duration: 0.01ms !important;
                animation-iteration-count: 1 !important;
                transition-duration: 0.01ms !important;
            }
        }

        /* Focus Styles for Better Accessibility */
        .plan-header:focus-visible,
        .btn:focus-visible,
        .upload-btn:focus-visible,
        .delete-image-btn:focus-visible {
            outline: 3px solid var(--primary);
            outline-offset: 2px;
        }

        .status-dropdown:focus-visible,
        .form-control:focus-visible {
            outline: 3px solid var(--primary);
            outline-offset: 1px;
        }

        /* Print Styles */
        @media print {
            .plan-toggle,
            .plan-delete-btn,
            .upload-btn,
            .delete-image-btn,
            .modal {
                display: none !important;
            }

            .plan-card {
                break-inside: avoid;
                page-break-inside: avoid;
            }

            .steps-grid {
                max-height: none !important;
                overflow: visible !important;
            }

            .step-card {
                break-inside: avoid;
                page-break-inside: avoid;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Dropshipper Details Section -->
        <div id="dropshipper-details" class="dropshipper-info-card" style="display: none;">
            <div class="dropshipper-header">
                <div class="dropshipper-avatar">
                    <i class="fas fa-user-tie"></i>
                </div>
                <div class="dropshipper-info">
                    <h2 id="dropshipper-name">Loading...</h2>
                    <p id="dropshipper-store">Loading store details...</p>
                </div>
            </div>
            <div class="dropshipper-details-grid">
                <div class="detail-item">
                    <label><i class="fas fa-id-badge"></i> Seller ID</label>
                    <span id="seller-id">-</span>
                </div>
                <div class="detail-item">
                    <label><i class="fas fa-phone"></i> Contact</label>
                    <span id="contact-number">-</span>
                </div>
                <div class="detail-item">
                    <label><i class="fas fa-envelope"></i> Email</label>
                    <span id="email">-</span>
                </div>
                <div class="detail-item">
                    <label><i class="fas fa-certificate"></i> CRN</label>
                    <span id="crn">-</span>
                </div>
            </div>
        </div>

        <div class="header">
            <h1><i class="fas fa-user-tie"></i> Dropshipper Plans</h1>
            <p>Track progress and manage dropshipper-specific plan steps with enhanced monitoring</p>
        </div>

        <div id="alert-container"></div>

        <div class="plans-container" id="plans-container">
            <div class="loading">
                <i class="fas fa-spinner fa-spin"></i>
                <h3>Loading Plans</h3>
                <p>Please wait while we fetch the latest plan data...</p>
            </div>
        </div>
    </div>

    <!-- Enhanced Add Plan Modal -->
    <div id="add-plan-modal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2><i class="fas fa-plus-circle"></i> Add Plan to Dropshipper</h2>
                <span class="close" aria-label="Close modal">&times;</span>
            </div>
            <form id="add-plan-form">
                <input type="hidden" id="dropshipper-id" name="dropshipper_id">
                <div class="form-group">
                    <label for="plan-select">Select Plan:</label>
                    <select id="plan-select" name="plan_id" class="form-control" required>
                        <option value="">Choose a plan...</option>
                    </select>
                </div>
                <div class="loading" id="plan-loading">
                    <i class="fas fa-spinner fa-spin"></i>
                    <p>Loading available plans...</p>
                </div>
                <div style="display: flex; gap: 1rem; justify-content: flex-end; margin-top: 2rem;">
                    <button type="button" class="btn btn-secondary" onclick="closeModal()">
                        <i class="fas fa-times"></i> Cancel
                    </button>
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-plus"></i> Add Plan
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Enhanced Image Preview Modal -->
    <div id="imageModal" class="image-modal">
        <span class="close-image-modal" onclick="closeImageModal()" aria-label="Close image">&times;</span>
        <div class="image-navigation">
            <div class="nav-arrow" onclick="navigateImage(-1)" aria-label="Previous image">&#10094;</div>
            <div class="nav-arrow" onclick="navigateImage(1)" aria-label="Next image">&#10095;</div>
        </div>
        <img id="expandedImage" class="image-modal-content" src="" alt="Expanded Image">
        <div id="imageCaption" class="image-caption"></div>
    </div>

    <script>
        const API_URL = 'https://customprint.deodap.com/api_dropshipper_tracker/one_dropshipper_plan.php';
        let imageList = [];
        let currentDropshipperId = null;
        let expandedPlans = new Set();

        // Enhanced utility functions
        function showAlert(message, type = 'success') {
            const container = document.getElementById('alert-container');
            const alertId = 'alert-' + Date.now();
            container.innerHTML = `<div id="${alertId}" class="alert alert-${type}">${message}</div>`;
            setTimeout(() => {
                const alertElement = document.getElementById(alertId);
                if (alertElement) {
                    alertElement.style.animation = 'alertSlideOut 0.3s ease-out forwards';
                    setTimeout(() => {
                        if (container.contains(alertElement)) {
                            container.removeChild(alertElement);
                        }
                    }, 300);
                }
            }, 4000);
        }

        // Refresh dropshipper details
        async function refreshDropshipperDetails() {
            if (!currentDropshipperId) {
                showAlert('No dropshipper selected to refresh', 'danger');
                return;
            }
            showAlert('Refreshing dropshipper details...', 'success');
            await loadDropshipperDetails(currentDropshipperId);
        }

        // Edit mode removed as per task requirements

        // Edit functionality removed as per task requirements

        // Edit functionality removed as per task requirements

        // Edit functionality removed as per task requirements

        // Email validation removed as edit functionality is removed

        function getStatusClass(status) {
            const statusMap = {
                'completed': 'status-completed',
                'in process': 'status-in-progress',
                'pending': 'status-pending',
                'open': 'status-open'
            };
            return statusMap[status] || 'status-pending';
        }

        function formatDate(dateString) {
            if (!dateString) return 'Not updated';
            try {
                const date = new Date(dateString);
                return date.toLocaleDateString('en-IN', {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                });
            } catch (error) {
                return 'Invalid date';
            }
        }

        function toRoman(num) {
            const roman = [
                { value: 1000, symbol: 'M' }, { value: 900, symbol: 'CM' },
                { value: 500, symbol: 'D' }, { value: 400, symbol: 'CD' },
                { value: 100, symbol: 'C' }, { value: 90, symbol: 'XC' },
                { value: 50, symbol: 'L' }, { value: 40, symbol: 'XL' },
                { value: 10, symbol: 'X' }, { value: 9, symbol: 'IX' },
                { value: 5, symbol: 'V' }, { value: 4, symbol: 'IV' },
                { value: 1, symbol: 'I' }
            ];

            let result = '';
            for (let i = 0; i < roman.length; i++) {
                while (num >= roman[i].value) {
                    result += roman[i].symbol;
                    num -= roman[i].value;
                }
            }
            return result;
        }

function togglePending(btn) {
  const card = btn.closest('.step-card');
  const body = {
    action: "toggle_client_pending",
    step_id: card.dataset.stepId,
    plan_id: card.dataset.planId,
    dropshipper_id: card.dataset.dropshipperId
  };

  fetch(API_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  })
  .then(res => res.json())
  .then(data => {
    card.querySelector('.status').innerText = "Flag: " + (data.success ? "Updated" : data.message);
  })
  .catch(err => console.error(err));
}

function saveNote(btn) {
  const card = btn.closest('.step-card');
  const note = card.querySelector('textarea').value;
  const body = {
    action: "insert_client_pending_note",  // use "update_client_pending_note" if editing existing
    step_id: card.dataset.stepId,
    plan_id: card.dataset.planId,
    dropshipper_id: card.dataset.dropshipperId,
    note: note
  };

  fetch(API_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  })
  .then(res => res.json())
  .then(data => {
    card.querySelector('.status').innerText = data.success ? "Note saved ✅" : "Error: " + data.message;
  })
  .catch(err => console.error(err));
}

function deleteNote(btn) {
  const card = btn.closest('.step-card');
  const body = {
    action: "delete_client_pending_note",
    step_id: card.dataset.stepId,
    plan_id: card.dataset.planId,
    dropshipper_id: card.dataset.dropshipperId
  };

  fetch(API_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  })
  .then(res => res.json())
  .then(data => {
    card.querySelector('textarea').value = "";
    card.querySelector('.status').innerText = data.success ? "Note deleted ❌" : "Error: " + data.message;
  })
  .catch(err => console.error(err));
}
        // Enhanced plan management functions
        function togglePlan(planId) {
            const stepsGrid = document.getElementById(`steps-${planId}`);
            const toggleBtn = document.getElementById(`toggle-${planId}`);

            if (!stepsGrid || !toggleBtn) return;

            if (stepsGrid.classList.contains('expanded')) {
                stepsGrid.classList.remove('expanded');
                toggleBtn.innerHTML = '<i class="fas fa-chevron-down"></i> Expand';
                toggleBtn.setAttribute('aria-expanded', 'false');
                expandedPlans.delete(planId);
            } else {
                stepsGrid.classList.add('expanded');
                toggleBtn.innerHTML = '<i class="fas fa-chevron-up"></i> Collapse';
                toggleBtn.setAttribute('aria-expanded', 'true');
                expandedPlans.add(planId);
            }
        }

        async function deletePlan(planId) {
            if (!confirm('Are you sure you want to delete this plan? This action cannot be undone.')) {
                return;
            }

            try {
                showAlert('Deleting plan...', 'warning');

                const response = await fetch(API_URL, {
                    method: 'DELETE',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-Requested-With': 'XMLHttpRequest'
                    },
                    body: JSON.stringify({
                        action: "delete_plan",
                        dropshipper_id: parseInt(currentDropshipperId),
                        plan_id: parseInt(planId)
                    })
                });

                if (!response.ok) {
                    const errorData = await response.json().catch(() => ({}));
                    throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
                }

                const data = await response.json();
                if (data.success) {
                    showAlert('Plan deleted successfully!', 'success');
                    await loadDropshipperPlans(currentDropshipperId);
                } else {
                    throw new Error(data.message || 'Failed to delete plan');
                }
            } catch (error) {
                console.error('Error deleting plan:', error);
                showAlert(error.message || 'Failed to delete plan. Please try again.', 'danger');
            }
        }
async function deleteStepImage(stepId) {
    if (!confirm('Are you sure you want to delete this image?')) {
        return;
    }

    try {
        showAlert('Deleting image...', 'warning');

        const response = await fetch(API_URL, {
            method: 'POST',  // Changed from DELETE to POST
            headers: {
                'Content-Type': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({
                action: "delete_step_image",
                dropshipper_id: parseInt(currentDropshipperId),
                step_id: parseInt(stepId)
            })
        });

        // First check if we got a response at all
        if (!response) {
            throw new Error('No response from server');
        }

        // Get the response text first to handle non-JSON responses
        const responseText = await response.text();
        let data;

        try {
            // Try to parse as JSON
            data = JSON.parse(responseText);
        } catch (e) {
            // If not JSON, it's probably an HTML error page
            console.error('Non-JSON response:', responseText);
            throw new Error('Server returned an error page. Please check the console for details.');
        }

        // Now check the response status
        if (!response.ok) {
            const errorMessage = data.message || `HTTP error! status: ${response.status}`;
            console.error('Server error:', {
                status: response.status,
                statusText: response.statusText,
                data: data
            });
            throw new Error(errorMessage);
        }

        // If we got here, the request was successful
        if (data.success) {
            showAlert('Image deleted successfully!', 'success');
            // Refresh the plans to show the updated state
            await loadDropshipperPlans(currentDropshipperId);
        } else {
            throw new Error(data.message || 'Failed to delete image');
        }
    } catch (error) {
        console.error('Error deleting image:', {
            error: error,
            message: error.message,
            stack: error.stack
        });
        showAlert(`Error: ${error.message}`, 'danger');
    }
}

        // Enhanced image handling
        function openImageModal(imageUrl, altText = '') {
            const modal = document.getElementById('imageModal');
            const modalImg = document.getElementById('expandedImage');
            const captionText = document.getElementById('imageCaption');

            // Get all images on the page
            const images = Array.from(document.querySelectorAll('.image-preview, .step-image'));
            imageList = images.map(img => ({
                src: img.src,
                alt: img.alt || 'Image'
            }));

            // Find the clicked image index
            let currentImageIndex = imageList.findIndex(img => img.src === imageUrl);

            if (currentImageIndex === -1) {
                currentImageIndex = 0;
            }

            // Display the clicked image
            modal.style.display = 'block';
            modalImg.src = imageUrl;
            modalImg.alt = altText;
            captionText.innerHTML = altText || `Image ${currentImageIndex + 1} of ${imageList.length}`;

            // Prevent body scroll when modal is open
            document.body.style.overflow = 'hidden';
        }

        function closeImageModal() {
            const modal = document.getElementById('imageModal');
            modal.style.display = 'none';
            document.body.style.overflow = 'auto';
        }

        function navigateImage(direction) {
            if (imageList.length === 0) return;

            const captionText = document.getElementById('imageCaption');
            const match = captionText.textContent.match(/Image (\d+)/);
            let currentImageIndex = match ? parseInt(match[1]) - 1 : 0;

            currentImageIndex += direction;

            // Loop handling
            if (currentImageIndex >= imageList.length) {
                currentImageIndex = 0;
            } else if (currentImageIndex < 0) {
                currentImageIndex = imageList.length - 1;
            }

            const image = imageList[currentImageIndex];
            const modalImg = document.getElementById('expandedImage');

            modalImg.src = image.src;
            modalImg.alt = image.alt;
            captionText.innerHTML = image.alt || `Image ${currentImageIndex + 1} of ${imageList.length}`;
        }

        // Enhanced dropshipper data loading with better error handling
        async function loadDropshipperDetails(dropshipperId) {
            const loadingIndicator = document.createElement('div');
            loadingIndicator.className = 'loading';
            loadingIndicator.innerHTML = `
                <i class="fas fa-spinner fa-spin"></i>
                <p>Loading dropshipper details...</p>
            `;

            const detailsContainer = document.getElementById('dropshipper-details');
            detailsContainer.innerHTML = '';
            detailsContainer.appendChild(loadingIndicator);
            detailsContainer.style.display = 'block';

            try {
                const response = await fetch(`https://customprint.deodap.com/api_dropshipper_tracker/one_dropshipper_details.php?dropshipper_id=${dropshipperId}`);

                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }

                const data = await response.json();
                console.log('Dropshipper API Response:', data); // For debugging

                if (!data || !data.success || !data.dropshipper) {
                    throw new Error('No dropshipper data found in response');
                }

                const dropshipper = data.dropshipper;
                displayDropshipperDetails(dropshipper);
                showAlert('Dropshipper details loaded successfully', 'success');

            } catch (error) {
                console.error('Error loading dropshipper details:', error);

                // Show error in the details container
                detailsContainer.innerHTML = `
                    <div class="error-message">
                        <i class="fas fa-exclamation-triangle"></i>
                        <h3>Failed to load dropshipper details</h3>
                        <p>${error.message || 'Please try again later.'}</p>
                        <button class="btn btn-primary" onclick="loadDropshipperDetails(${dropshipperId})">
                            <i class="fas fa-sync-alt"></i> Retry
                        </button>
                    </div>
                `;

                showAlert(`Error: ${error.message || 'Failed to load dropshipper details'}`, 'danger');
            }
        }

        function displayDropshipperDetails(dropshipper) {
            console.log('Displaying dropshipper details:', dropshipper);

            const detailsContainer = document.getElementById('dropshipper-details');

            // Recreate the HTML structure with the actual data
            detailsContainer.innerHTML = `
                <div class="dropshipper-header">
                    <div class="dropshipper-avatar">
                        <i class="fas fa-user-tie"></i>
                    </div>
                    <div class="dropshipper-info">
                        <h2 id="dropshipper-name">${dropshipper.seller_name || 'N/A'}</h2>
                        <p id="dropshipper-store">${dropshipper.store_name || 'N/A'}</p>
                    </div>
                </div>
                <div class="dropshipper-details-grid">
                    <div class="detail-item">
                        <label><i class="fas fa-id-badge"></i> Seller ID</label>
                        <span id="seller-id">${dropshipper.seller_id || 'N/A'}</span>
                    </div>
                    <div class="detail-item">
                        <label><i class="fas fa-phone"></i> Contact</label>
                        <span id="contact-number">${dropshipper.contact_number || 'N/A'}</span>
                    </div>
                    <div class="detail-item">
                        <label><i class="fas fa-envelope"></i> Email</label>
                        <span id="email">${dropshipper.email || 'N/A'}</span>
                    </div>
                    <div class="detail-item">
                        <label><i class="fas fa-certificate"></i> CRN</label>
                        <span id="crn">${dropshipper.crn || 'N/A'}</span>
                    </div>
                </div>
            `;

            // Update avatar with initials
            updateAvatarWithInitials(dropshipper.seller_name);

            // Show the details card with animation
            detailsContainer.style.display = 'block';
            detailsContainer.style.animation = 'modalSlideIn 0.5s ease-out';

            // Edit mode removed, no need to store original data
        }

        // Helper function to update avatar with initials
        function updateAvatarWithInitials(name) {
            const avatar = document.querySelector('.dropshipper-avatar');
            if (!avatar || !name) return;

            // Clear any existing content
            avatar.innerHTML = '';

            // Get initials (first letter of first two words)
            const initials = name
                .split(' ')
                .slice(0, 2)
                .map(word => word[0])
                .join('')
                .toUpperCase();

            // Set the initials in the avatar
            const initialsElement = document.createElement('div');
            initialsElement.className = 'avatar-initials';
            initialsElement.textContent = initials;

            // Add some basic styling
            initialsElement.style.display = 'flex';
            initialsElement.style.alignItems = 'center';
            initialsElement.style.justifyContent = 'center';
            initialsElement.style.width = '100%';
            initialsElement.style.height = '100%';
            initialsElement.style.fontSize = '1.5rem';
            initialsElement.style.fontWeight = 'bold';
            initialsElement.style.color = 'white';

            avatar.appendChild(initialsElement);
        }

        async function loadDropshipperPlans(dropshipperId) {
            currentDropshipperId = dropshipperId;
            const container = document.getElementById('plans-container');

            try {
                container.innerHTML = `
                    <div class="loading" style="display: block;">
                        <i class="fas fa-spinner fa-spin"></i>
                        <h3>Loading Plans</h3>
                        <p>Fetching the latest plan data...</p>
                    </div>
                `;

                const response = await fetch(`${API_URL}?dropshipper_id=${dropshipperId}`);

                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }

                const data = await response.json();

                if (data.success) {
                    displayPlans(data);
                } else {
                    displayPlans({ plans: [] });
                }
            } catch (error) {
                console.error('Error loading plans:', error);
                displayPlans({ plans: [] });
                showAlert('Failed to load plans. Please refresh the page.', 'danger');
            }
        }

        async function loadAvailablePlans() {
            const loading = document.getElementById('plan-loading');
            const select = document.getElementById('plan-select');

            loading.style.display = 'block';
            select.innerHTML = '<option value="">Loading...</option>';
            select.disabled = true;

            try {
                const response = await fetch(`${API_URL}?fetch_plans=true`);

                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }

                const data = await response.json();

                if (data.success && data.plans && data.plans.length > 0) {
                    select.innerHTML = '<option value="">Choose a plan...</option>';
                    data.plans.forEach(plan => {
                        const option = document.createElement('option');
                        option.value = plan.id;
                        option.textContent = `${plan.name} (${plan.steps_count} steps)`;
                        select.appendChild(option);
                    });
                } else {
                    select.innerHTML = '<option value="">No plans available</option>';
                }
            } catch (error) {
                console.error('Error loading plans:', error);
                select.innerHTML = '<option value="">Error loading plans</option>';
                showAlert('Failed to load available plans. Please try again.', 'danger');
            } finally {
                loading.style.display = 'none';
                select.disabled = false;
            }
        }

        function displayPlans(data) {
            const container = document.getElementById('plans-container');

            if (!data.plans || data.plans.length === 0) {
                container.innerHTML = `
                    <div class="add-plan-section">
                        <i class="fas fa-plus-circle" style="font-size:4em;"></i>
                        <h3>No Plans Found</h3>
                        <p>This dropshipper doesn't have any plans assigned yet. Add a plan to get started with progress tracking.</p>
                        <button class="btn btn-primary" onclick="openAddPlanModal()">
                            <i class="fas fa-plus"></i> Add Your First Plan
                        </button>
                    </div>`;
                return;
            }

            let html = `
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; flex-wrap: wrap; gap: 1rem;">
                    <div>
                        <h3 style="margin: 0; color: var(--gray-700);">Active Plans (${data.plans.length})</h3>
                        <p style="margin: 0; color: var(--gray-500);">Track and manage plan progress</p>
                    </div>
                    <button class="btn btn-primary" onclick="openAddPlanModal()">
                        <i class="fas fa-plus"></i> Add Another Plan
                    </button>
                </div>`;

            data.plans.forEach((plan, planIndex) => {
                const planId = plan.plan_id || plan.id;
                const romanPlanNum = toRoman(planIndex + 1);
                const completedSteps = plan.steps.filter(step => step.status === 'completed').length;
                const totalSteps = plan.steps.length;
                const progressPercentage = totalSteps > 0 ? (completedSteps / totalSteps * 100).toFixed(0) : 0;

                html += `
                <div class="plan-card">
                    <div class="plan-header" onclick="togglePlan(${planId})" role="button" tabindex="0" aria-expanded="false">
                        <div class="plan-header-left">
                            <span class="roman-number">${romanPlanNum}</span>
                            <div>
                                <div>${plan.plan_name}</div>
                                <div style="font-size: 0.9em; opacity: 0.8;">
                                    ${completedSteps}/${totalSteps} steps completed (${progressPercentage}%)
                                </div>
                            </div>
                        </div>
                        <div class="plan-header-right">
                            <button id="toggle-${planId}" class="plan-toggle" onclick="event.stopPropagation(); togglePlan(${planId})" aria-label="Toggle plan details">
                                <i class="fas fa-chevron-down"></i> Expand
                            </button>
                            <button class="plan-delete-btn" onclick="event.stopPropagation(); deletePlan(${planId})" aria-label="Delete plan">
                                <i class="fas fa-trash"></i> Delete
                            </button>
                        </div>
                    </div>
                    <div id="steps-${planId}" class="steps-grid">
                        ${plan.steps.map((step, stepIndex) => {
                            const stepId = step.step_id || step.id;
                            const hasCustomImage = step.custom_image && step.custom_image.trim() !== '';
                            const hasStepImage = step.step_image && step.step_image.trim() !== '';

                            return `
                                <div class="step-card">
                                    <div class="step-header">
                                        <h4>${step.step_name || `Step ${stepIndex + 1}`}</h4>
                                        <select class="status-dropdown"
                                                onchange="changeStepStatus(${stepId}, this.value)"
                                                data-step-id="${stepId}"
                                                aria-label="Change step status">
                                            <option value="pending" ${step.status === 'pending' || step.status === 'open' ? 'selected' : ''}>Pending</option>
                                            <option value="in process" ${step.status === 'in process' ? 'selected' : ''}>In Process</option>
                                            <option value="completed" ${step.status === 'completed' ? 'selected' : ''}>Completed</option>
                                        </select>
                                    </div>

                                    <div class="step-status ${getStatusClass(step.status)}" aria-label="Current status">
                                        ${step.status || 'pending'}
                                    </div>

                                    <div class="step-description">
                                        ${step.step_description || 'No description available'}
                                    </div>

                                    ${step.custom_description ? `
                                        <div class="step-custom-description">
                                            <strong>Custom Note:</strong> ${step.custom_description}
                                        </div>
                                    ` : ''}

                                    <div class="step-actions">
                                        <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
                                            <input type="file"
                                                   id="image-upload-${stepId}"
                                                   style="display: none;"
                                                   accept="image/*"
                                                   onchange="handleImageUpload(${stepId}, this.files[0])"
                                                   aria-label="Upload image for step">
                                            <button class="upload-btn"
                                                    onclick="document.getElementById('image-upload-${stepId}').click()"
                                                    aria-label="Upload image">
                                                <i class="fas fa-upload"></i> Upload Image
                                            </button>
                                            ${hasCustomImage ? `
                                                <button class="delete-image-btn"
                                                        onclick="deleteStepImage(${stepId})"
                                                        aria-label="Delete uploaded image">
                                                    <i class="fas fa-trash"></i> Delete Image
                                                </button>
                                            ` : ''}
                                            <button class="chat-btn"
                                                    onclick="openChat(${currentDropshipperId}, ${stepId}, event)"
                                                    aria-label="Open chat for this step">
                                                <i class="fas fa-comment"></i> Chat
                                            </button>




<button class="btn btn-pending ${step.client_pending ? 'active' : ''}"
        onclick="toggleClientPending(${stepId}, this, ${step.client_pending ? 0 : 1})"
        title="${step.client_pending ? 'Mark as not pending' : 'Mark as pending'}">
    <i class="fas ${step.client_pending ? 'fa-check-circle' : 'fa-clock'}"></i>
    ${step.client_pending ? 'Pending' : 'Mark Pending'}
</button>


${step.client_pending ? `
    <div class="client-pending-note">
        <strong>Pending Note:</strong>
        <p>${step.client_pending_note || 'No notes provided'}</p>
        <button class="btn-edit-note" onclick="editClientNote(${stepId}, '${step.client_pending_note || ''}')">
            <i class="fas fa-edit"></i> Edit Note
        </button>
    </div>
` : ''}
                                        </div>
                                    </div>

                                    ${hasCustomImage ? `
                                        <img src="${step.custom_image}"
                                             class="image-preview"
                                             onclick="openImageModal('${step.custom_image}', 'Custom Image for ${step.step_name || 'Step'}')"
                                             alt="Custom step image"
                                             onerror="this.style.display='none'"
                                             loading="lazy" />
                                    ` : ''}

                                    ${hasStepImage ? `
                                        <img src="${step.step_image}"
                                             class="step-image"
                                             onclick="openImageModal('${step.step_image}', 'Reference Image for ${step.step_name || 'Step'}')"
                                             alt="Step reference image"
                                             onerror="this.style.display='none'"
                                             loading="lazy">
                                    ` : ''}

                                    <div class="step-updated">
                                        Last updated: ${formatDate(step.updated_at)}
                                    </div>
                                </div>
                            `;
                        }).join('')}
                    </div>
                </div>`;
            });

            container.innerHTML = html;

            // Re-expand previously expanded plans
            expandedPlans.forEach(planId => {
                const stepsGrid = document.getElementById(`steps-${planId}`);
                const toggleBtn = document.getElementById(`toggle-${planId}`);
                if (stepsGrid && toggleBtn) {
                    stepsGrid.classList.add('expanded');
                    toggleBtn.innerHTML = '<i class="fas fa-chevron-up"></i> Collapse';
                    const planHeader = toggleBtn.closest('.plan-header');
                    if (planHeader) {
                        planHeader.setAttribute('aria-expanded', 'true');
                    }
                }
            });
        }

//         async function changeStepStatus(stepId, newStatus) {
//             if (!currentDropshipperId) {
//                 showAlert('Dropshipper ID not found', 'danger');
//                 return;
//             }
//
//             const dropdown = document.querySelector(`[data-step-id="${stepId}"]`);
//             const originalStatus = dropdown?.dataset.originalStatus || dropdown?.value;
//
//             try {
//                 // Show loading state
//                 if (dropdown) {
//                     dropdown.disabled = true;
//                     dropdown.dataset.originalStatus = originalStatus;
//                 }
//
//                 const requestData = {
//                     action: "update_step_status",
//                     dropshipper_id: parseInt(currentDropshipperId),
//                     step_id: parseInt(stepId),
//                     status: newStatus
//                 };
//
//                 const response = await fetch(API_URL, {
//                     method: 'POST',
//                     headers: {
//                         'Content-Type': 'application/json',
//                         'X-Requested-With': 'XMLHttpRequest'
//                     },
//                     body: JSON.stringify(requestData)
//                 });
//
//                 if (!response.ok) {
//                     const errorData = await response.json().catch(() => ({}));
//                     throw new Error(errorData.message || `Server returned ${response.status}: ${response.statusText}`);
//                 }
//
//                 const data = await response.json();
//
//                 if (data.success) {
//                     showAlert(`Step status updated to "${newStatus}"`, 'success');
//                     await loadDropshipperPlans(currentDropshipperId);
//                 } else {
//                     throw new Error(data.message || 'Failed to update step status');
//                 }
//             } catch (error) {
//                 console.error('Error updating step status:', error);
//                 showAlert(error.message || 'Failed to update step status. Please try again.', 'danger');
//
//
//                 if (dropdown && originalStatus) {
//                     dropdown.value = originalStatus;
//                 }
//             } finally {
//                 if (dropdown) {
//                     dropdown.disabled = false;
//                 }
//             }
//         }
//
// async function changeStepStatus(stepId, newStatus) {
//     if (!currentDropshipperId) {
//         showAlert('Dropshipper ID not found', 'danger');
//         return;
//     }
//
//     const dropdown = document.querySelector(`[data-step-id="${stepId}"]`);
//     const originalStatus = dropdown?.dataset.originalStatus || dropdown?.value;
//
//     try {
//         // Show loading state
//         if (dropdown) {
//             dropdown.disabled = true;
//             dropdown.dataset.originalStatus = originalStatus;
//         }
//
//         const requestData = {
//             action: "update_step_status",
//             dropshipper_id: parseInt(currentDropshipperId),
//             step_id: parseInt(stepId),
//             status: newStatus
//         };
//
//         const response = await fetch(API_URL, {
//             method: 'POST',
//             headers: {
//                 'Content-Type': 'application/json',
//                 'X-Requested-With': 'XMLHttpRequest'
//             },
//             body: JSON.stringify(requestData)
//         });
//
//         // Check response content type
//         const contentType = response.headers.get("content-type");
//         let data = {};
//
//         if (contentType && contentType.includes("application/json")) {
//             data = await response.json();
//         } else {
//             // Server returned HTML or something else
//             const text = await response.text();
//             throw new Error("Server error (not JSON): " + text);
//         }
//
//         if (data.success) {
//             showAlert(`Step status updated to "${newStatus}"`, 'success');
//             await loadDropshipperPlans(currentDropshipperId);
//         } else {
//             throw new Error(data.message || 'Failed to update step status');
//         }
//
//     } catch (error) {
//         console.error('Error updating step status:', error);
//         showAlert(error.message || 'Failed to update step status. Please try again.', 'danger');
//
//         if (dropdown && originalStatus) {
//             dropdown.value = originalStatus;
//         }
//     } finally {
//         if (dropdown) {
//             dropdown.disabled = false;
//         }
//     }
// }

async function changeStepStatus(stepId, newStatus) {
    if (!currentDropshipperId) {
        showAlert('Dropshipper ID not found', 'danger');
        return;
    }

    const dropdown = document.querySelector(`[data-step-id="${stepId}"]`);
    const originalStatus = dropdown?.dataset.originalStatus || dropdown?.value;

    try {
        // Show loading state
        if (dropdown) {
            dropdown.disabled = true;
            dropdown.dataset.originalStatus = originalStatus;
        }

        const requestData = {
            action: "update_step_status",
            dropshipper_id: parseInt(currentDropshipperId),
            step_id: parseInt(stepId),
            status: newStatus
        };

        console.log('Sending request:', requestData); // Debug log

        const response = await fetch(API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify(requestData)
        });

        // First get the response text to inspect it
        const responseText = await response.text();
        console.log('Raw response:', responseText); // Debug log

        let data = {};

        // Check if response starts with HTML error tags
        if (responseText.trim().startsWith('<br') || responseText.trim().startsWith('<!DOCTYPE') || responseText.trim().startsWith('<html')) {
            console.error('Server returned HTML error page:', responseText);
            throw new Error('Server error: The server returned an HTML error page instead of JSON. Please check the server logs for PHP errors.');
        }

        // Try to parse as JSON
        try {
            data = JSON.parse(responseText);
        } catch (parseError) {
            console.error('JSON parse error:', parseError);
            console.error('Response was:', responseText);
            throw new Error('Invalid server response: Expected JSON but got: ' + responseText.substring(0, 100) + '...');
        }

        // Check HTTP status
        if (!response.ok) {
            const errorMessage = data.message || `HTTP ${response.status}: ${response.statusText}`;
            throw new Error(errorMessage);
        }

        if (data.success) {
            showAlert(`Step status updated to "${newStatus}"`, 'success');
            await loadDropshipperPlans(currentDropshipperId);
        } else {
            throw new Error(data.message || 'Failed to update step status');
        }

    } catch (error) {
        console.error('Error updating step status:', error);

        // Provide more specific error messages
        let errorMessage = error.message;
        if (errorMessage.includes('fetch')) {
            errorMessage = 'Network error. Please check your internet connection and try again.';
        } else if (errorMessage.includes('JSON')) {
            errorMessage = 'Server response error. Please try refreshing the page.';
        }

        showAlert(`Failed to update status: ${errorMessage}`, 'danger');

        // Revert dropdown to original status
        if (dropdown && originalStatus) {
            dropdown.value = originalStatus;
        }
    } finally {
        if (dropdown) {
            dropdown.disabled = false;
        }
    }
}

        // Toggle client pending status
async function toggleClientPending(stepId, button, newStatus) {
    if (!currentDropshipperId) {
        showAlert('Dropshipper ID not found', 'danger');
        return;
    }

    try {
        const response = await fetch(API_URL, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                action: 'toggle_client_pending',
                dropshipper_id: currentDropshipperId,
              plan_step_id: stepId,
                client_pending: newStatus
            })
        });

        const result = await response.json();
        if (result.success) {
            showAlert(result.message, 'success');
            // Toggle button state
            button.classList.toggle('active', newStatus === 1);
            const icon = button.querySelector('i');
            if (newStatus === 1) {
                button.innerHTML = '<i class="fas fa-check-circle"></i> Pending';
                // If we're marking as pending, prompt for a note
                const note = prompt('Please enter a note for this pending status:');
                if (note !== null) {
                    await updateClientNote(stepId, note);
                }
            } else {
                button.innerHTML = '<i class="fas fa-clock"></i> Mark Pending';
            }
            // Reload the plans to update the UI
            loadDropshipperPlans(currentDropshipperId);
        } else {
            showAlert(result.message || 'Failed to update pending status', 'danger');
        }
    } catch (error) {
        console.error('Error toggling pending status:', error);
        showAlert('An error occurred while updating pending status', 'danger');
    }
}

// Update client note
async function updateClientNote(stepId, note) {
    if (!currentDropshipperId) {
        showAlert('Dropshipper ID not found', 'danger');
        return;
    }

    try {
        const response = await fetch(API_URL, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                action: 'update_client_note',
                dropshipper_id: currentDropshipperId,
              plan_step_id: stepId,
                note: note
            })
        });

        const result = await response.json();
        if (!result.success) {
            showAlert(result.message || 'Failed to update note', 'danger');
        }
    } catch (error) {
        console.error('Error updating note:', error);
        showAlert('An error occurred while updating the note', 'danger');
    }
}

// Edit client note
function editClientNote(stepId, currentNote) {
    const newNote = prompt('Edit your note:', currentNote || '');
    if (newNote !== null) {
        updateClientNote(stepId, newNote).then(() => {
            loadDropshipperPlans(currentDropshipperId);
        });
    }
}
        async function handleImageUpload(stepId, file) {
            try {
                if (!file) {
                    throw new Error('No file selected');
                }

                if (!currentDropshipperId) {
                    throw new Error('Dropshipper ID not found');
                }

                // Validate file type
                if (!file.type.startsWith('image/')) {
                    throw new Error('Please select a valid image file (JPEG, PNG, GIF, or WebP)');
                }

                // Validate file size (max 5MB)
                const maxSize = 5 * 1024 * 1024; // 5MB
                if (file.size > maxSize) {
                    throw new Error('File size too large. Please select an image smaller than 5MB');
                }

                showAlert('Uploading image...', 'info');

                const formData = new FormData();
                formData.append('action', 'upload_step_image');
                formData.append('dropshipper_id', currentDropshipperId);
                formData.append('step_id', stepId);
                formData.append('step_image', file);

                const response = await fetch(API_URL, {
                    method: 'POST',
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest'
                    },
                    body: formData
                });

                const responseData = await response.json().catch(() => ({}));

                if (!response.ok) {
                    const errorMessage = responseData.message ||
                                       `Server error: ${response.status} ${response.statusText}`;
                    throw new Error(errorMessage);
                }

                if (responseData.success) {
                    showAlert('Image uploaded successfully!', 'success');
                    await loadDropshipperPlans(currentDropshipperId);
                } else {
                    throw new Error(responseData.message || 'Failed to upload image');
                }
            } catch (error) {
                console.error('Upload error:', {
                    error: error,
                    message: error.message,
                    stack: error.stack
                });

                // Get error message safely
                let errorMessage = 'An unknown error occurred during upload';

                if (error && typeof error === 'object') {
                    if (error.message && typeof error.message === 'string') {
                        errorMessage = error.message;
                    } else if (error.name) {
                        errorMessage = error.name;
                    }
                } else if (typeof error === 'string') {
                    errorMessage = error;
                }

                // Add more specific error messages for common issues
                if (errorMessage.includes && errorMessage.includes('413')) {
                    errorMessage = 'File too large. The server rejected the upload because the file exceeds the maximum allowed size.';
                } else if (errorMessage.includes && errorMessage.includes('500')) {
                    errorMessage = 'Server error while processing the upload. Please try again later.';
                } else if (errorMessage.includes && errorMessage.includes('NetworkError')) {
                    errorMessage = 'Network error. Please check your internet connection and try again.';
                }

                showAlert(`Upload failed: ${errorMessage}`, 'danger');
            }
    }

        function openAddPlanModal() {
            const modal = document.getElementById('add-plan-modal');
            const dropshipperIdInput = document.getElementById('dropshipper-id');

            modal.style.display = 'block';
            dropshipperIdInput.value = currentDropshipperId;
            document.body.style.overflow = 'hidden';

            loadAvailablePlans();
        }

        function closeModal() {
            const modal = document.getElementById('add-plan-modal');
            modal.style.display = 'none';
            document.body.style.overflow = 'auto';

            // Reset form
            document.getElementById('add-plan-form').reset();
        }

        function openChat(dropshipperId, stepId, event) {
    if (event) {
        event.preventDefault();
        event.stopPropagation();
    }
    const url = `messge.php?dropshipper_id=${dropshipperId}&plan_step_id=${stepId}`;
    window.location.href = url; // 🔥 એજ tab માં ખૂલશે
    return false;
}


        // Event listeners and initialization
        function setupEventListeners() {
            // Modal click outside to close
            window.addEventListener('click', function(event) {
                const imageModal = document.getElementById('imageModal');
                const addPlanModal = document.getElementById('add-plan-modal');

                if (event.target === imageModal) {
                    closeImageModal();
                }
                if (event.target === addPlanModal) {
                    closeModal();
                }
            });

            // Keyboard navigation
            document.addEventListener('keydown', function(event) {
                const imageModal = document.getElementById('imageModal');
                const addPlanModal = document.getElementById('add-plan-modal');

                if (event.key === 'Escape') {
                    if (imageModal.style.display === 'block') {
                        closeImageModal();
                    }
                    if (addPlanModal.style.display === 'block') {
                        closeModal();
                    }
                }

                // Image navigation with arrow keys
                if (imageModal.style.display === 'block') {
                    if (event.key === 'ArrowLeft') {
                        event.preventDefault();
                        navigateImage(-1);
                    } else if (event.key === 'ArrowRight') {
                        event.preventDefault();
                        navigateImage(1);
                    }
                }
            });

            // Add plan form submission
            document.getElementById('add-plan-form').addEventListener('submit', async function(e) {
                e.preventDefault();

                const formData = new FormData(this);
                const planId = formData.get('plan_id');
                const dropshipperId = document.getElementById('dropshipper-id').value;

                if (!planId) {
                    showAlert('Please select a plan', 'danger');
                    return;
                }

                const submitBtn = this.querySelector('button[type="submit"]');
                const originalText = submitBtn.innerHTML;
                submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Adding Plan...';
                submitBtn.disabled = true;

                try {
                    const response = await fetch(API_URL, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-Requested-With': 'XMLHttpRequest'
                        },
                        body: JSON.stringify({
                            action: "add_plan",
                            dropshipper_id: parseInt(dropshipperId),
                            plan_id: parseInt(planId),
                            plan_source: "plans_php"
                        })
                    });

                    const data = await response.json();

                    if (data.success) {
                        showAlert('Plan added successfully!', 'success');
                        closeModal();
                        await loadDropshipperPlans(currentDropshipperId);
                    } else {
                        throw new Error(data.message || 'Failed to add plan');
                    }
                } catch (error) {
                    console.error('Error adding plan:', error);
                    showAlert(error.message || 'Failed to add plan. Please try again.', 'danger');
                } finally {
                    submitBtn.innerHTML = originalText;
                    submitBtn.disabled = false;
                }
            });

            // Close modal button
            document.querySelector('.close').addEventListener('click', closeModal);
        }

        async function loadAllPlans() {
            const container = document.getElementById('plans-container');
            container.innerHTML = `
                <div class="loading" style="display: block;">
                    <i class="fas fa-spinner fa-spin"></i>
                    <h3>Loading Plans</h3>
                    <p>Fetching available plans...</p>
                </div>
            `;

            try {
                const response = await fetch(`${API_URL}?fetch_plans=true`);

                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }

                const data = await response.json();

                if (data.success && data.plans && data.plans.length > 0) {
                    let html = `
                        <div style="margin-bottom: 2rem;">
                            <h3 style="color: var(--gray-700); margin-bottom: 0.5rem;">Available Plans (${data.plans.length})</h3>
                            <p style="color: var(--gray-500); margin: 0;">Browse all available plans in the system</p>
                        </div>
                        <div class="plans-container">
                    `;

                    data.plans.forEach((plan, index) => {
                        const romanNum = toRoman(index + 1);
                        html += `
                            <div class="plan-card">
                                <div class="plan-header" style="cursor: default;">
                                    <div class="plan-header-left">
                                        <span class="roman-number">${romanNum}</span>
                                        <div>
                                            <div>${plan.name}</div>
                                            <div style="font-size: 0.9em; opacity: 0.8;">
                                                ${plan.steps_count} steps • ₹${parseFloat(plan.price || 0).toFixed(2)}
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="steps-grid expanded">
                                    <div class="step-card">
                                        <div class="step-description">
                                            <strong>Description:</strong> ${plan.description || 'No description available'}
                                        </div>
                                        <div style="display: flex; justify-content: space-between; margin-top: 1rem;">
                                            <span><strong>Steps:</strong> ${plan.steps_count}</span>
                                            <span><strong>Price:</strong> ₹${parseFloat(plan.price || 0).toFixed(2)}</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        `;
                    });
                    html += '</div>';
                    container.innerHTML = html;
                } else {
                    container.innerHTML = `
                        <div class="no-data">
                            <i class="fas fa-clipboard-list"></i>
                            <h3>No Plans Available</h3>
                            <p>There are currently no plans configured in the system.</p>
                        </div>
                    `;
                }
            } catch (error) {
                console.error('Error loading all plans:', error);
                container.innerHTML = `
                    <div class="no-data">
                        <i class="fas fa-exclamation-triangle" style="color: var(--danger);"></i>
                        <h3>Error Loading Plans</h3>
                        <p>Failed to fetch plans. Please check your connection and try again.</p>
                        <button class="btn btn-primary" onclick="loadAllPlans()" style="margin-top: 1rem;">
                            <i class="fas fa-refresh"></i> Retry
                        </button>
                    </div>
                `;
                showAlert('Failed to load plans. Please try again.', 'danger');
            }
        }

        // Initialize application
        document.addEventListener('DOMContentLoaded', function() {
            setupEventListeners();

            const urlParams = new URLSearchParams(window.location.search);
            const dropshipperId = urlParams.get('dropshipper_id');

            if (dropshipperId) {
                document.querySelector('.header h1').innerHTML = '<i class="fas fa-user-tie"></i> Dropshipper Progress Tracker';
                loadDropshipperDetails(dropshipperId);
                loadDropshipperPlans(dropshipperId);
            } else {
                document.querySelector('.header h1').innerHTML = '<i class="fas fa-list"></i> All Available Plans';
                document.querySelector('.header p').textContent = 'Browse and explore all available plans in the system';
                loadAllPlans();
            }
        });

        // Add some utility CSS animations
        const style = document.createElement('style');
        style.textContent = `
            @keyframes alertSlideOut {
                to {
                    transform: translateY(-10px);
                    opacity: 0;
                    height: 0;
                    padding: 0;
                    margin: 0;
                }
            }

            @keyframes pulse {
                0%, 100% { opacity: 1; }
                50% { opacity: 0.5; }
            }

            .loading {
                animation: pulse 2s infinite;
            }

            .step-card:hover .step-updated::before {
                animation: pulse 1s infinite;
            }
        `;
        document.head.appendChild(style);

        // Performance optimization: Lazy loading for images
        if ('IntersectionObserver' in window) {
            const imageObserver = new IntersectionObserver((entries, observer) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        const img = entry.target;
                        if (img.dataset.src) {
                            img.src = img.dataset.src;
                            img.removeAttribute('data-src');
                            observer.unobserve(img);
                        }
                    }
                });
            });

            // This will be used for future lazy loading implementation
            window.setupLazyLoading = function() {
                const images = document.querySelectorAll('img[data-src]');
                images.forEach(img => imageObserver.observe(img));
            };
        }

        // Service Worker registration for offline functionality (optional)
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', function() {
                // Uncomment to enable offline functionality
                // navigator.serviceWorker.register('/sw.js').then(function(registration) {
                //     console.log('ServiceWorker registration successful');
                // }).catch(function(err) {
                //     console.log('ServiceWorker registration failed');
                // });
            });
        }
    </script>
</body>
</html>