<?php 
// dashboard.php (Admin Dashboard)
session_start();

// Check if user is logged in
if (!isset($_SESSION['user'])) {
    header("Location: login.php");
    exit();
}

$user = $_SESSION['user'];

// ✅ Role check (only admin allowed)
if (!isset($user['role']) || $user['role'] !== 'admin') {
    // જો employee અથવા બીજું role હોય તો access deny
    header("Location: employee_dashboard.php");
    exit();
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" href="assets/favicon.png" />
    <title>Dashboard - Admin Portal</title>
    <!-- Font Awesome for icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        /* Notification Styles */
        .notification-container {
            position: relative;
            margin-right: 15px;
        }
        
        .notification-bell {
            position: relative;
            cursor: pointer;
            padding: 10px;
            border-radius: 50%;
            transition: all 0.3s ease;
        }
        
        .notification-bell:hover {
            background-color: #f3f4f6;
        }
        
        .notification-badge {
            position: absolute;
            top: 0;
            right: 0;
            background-color: #ef4444;
            color: white;
            border-radius: 50%;
            width: 18px;
            height: 18px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 10px;
            font-weight: bold;
        }
        
        .notification-dropdown {
            position: absolute;
            top: 100%;
            right: 0;
            width: 350px;
            max-height: 500px;
            overflow-y: auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
            border: 1px solid #e5e7eb;
            z-index: 1000;
            display: none;
            margin-top: 10px;
        }
        
        .notification-header {
            padding: 15px;
            border-bottom: 1px solid #e5e7eb;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .notification-title {
            font-weight: 600;
            color: #111827;
            margin: 0;
        }
        
        .mark-all-read {
            background: none;
            border: none;
            color: #6366f1;
            font-size: 13px;
            cursor: pointer;
            padding: 4px 8px;
            border-radius: 4px;
        }
        
        .mark-all-read:hover {
            background: #f3f4f6;
        }
        
        .notification-item {
            padding: 15px;
            border-bottom: 1px solid #f3f4f6;
            cursor: pointer;
            transition: background 0.2s;
        }
        
        .notification-item:hover {
            background: #f9fafb;
        }
        
        .notification-item.unread {
            background: #f8fafc;
            border-left: 3px solid #6366f1;
        }
        
        .notification-message {
            font-size: 14px;
            color: #374151;
            margin-bottom: 4px;
        }
        
        .notification-time {
            font-size: 12px;
            color: #9ca3af;
        }
        
        .no-notifications {
            padding: 20px;
            text-align: center;
            color: #9ca3af;
            font-size: 14px;
        }
    </style>
</head>
<body style="margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #ffffff; min-height: 100vh; overflow-x: hidden; color: #111827; line-height: 1.6;">

<!-- Mobile Menu Button -->
<button class="mobile-menu-btn" onclick="toggleSidebar()" style="display: none; position: fixed; top: 20px; left: 20px; z-index: 1001; background: #6366f1; color: white; border: none; padding: 12px; border-radius: 8px; cursor: pointer; font-size: 18px; box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3);">
    <i class="fas fa-bars"></i>
</button>

<!-- Sidebar Overlay -->



       
<div class="sidebar-overlay" onclick="closeSidebar()" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 999;"></div>

<div class="sidebar" id="sidebar" style="height: 100vh; width: 280px; position: fixed; top: 0; left: 0; background: #ffffff; box-shadow: 2px 0 15px rgba(0,0,0,0.08); z-index: 1000; overflow-y: auto; border-right: 1px solid #e5e7eb;">
    <div style="padding: 30px 20px; border-bottom: 1px solid #e5e7eb; background: linear-gradient(135deg, #6366f1, #8b5cf6);">
        <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 8px;">
            <div style="width: 40px; height: 40px; background: rgba(255,255,255,0.15); border-radius: 12px; display: flex; align-items: center; justify-content: center; color: white; font-size: 20px; border: 2px solid rgba(255,255,255,0.2);">
                <i class="fas fa-clipboard-list"></i>
            </div>
            <div>
                <h3 style="color: white; font-size: 22px; font-weight: 700; margin: 0; text-shadow: 0 2px 4px rgba(0,0,0,0.1);">Dropshipper Progress Tracker</h3>
                <p style="color: rgba(255,255,255,0.9); font-size: 14px; margin: 0; font-weight: 500;">Employee Dashboard • Portal</p>
            </div>
        </div>
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
    <!-- Enhanced Dashboard Header -->
    <div style="background: linear-gradient(135deg, #ffffff, #f8fafc); padding: 40px 35px; border-radius: 20px; box-shadow: 0 8px 32px rgba(0,0,0,0.12); margin-bottom: 30px; border: 1px solid #e5e7eb; position: relative; overflow: hidden;">
        <!-- Background Pattern -->
        <div style="position: absolute; top: 0; right: 0; width: 200px; height: 200px; background: radial-gradient(circle, rgba(99, 102, 241, 0.05) 0%, transparent 70%); border-radius: 50%; transform: translate(50%, -50%);"></div>
        
        <div style="position: relative; z-index: 1;">
            <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px;">
                <div>
                    <div style="display: flex; align-items: center; gap: 8px; color: #6b7280; font-size: 14px; margin-bottom: 12px;">
                        <i class="fas fa-home" style="color: #6366f1;"></i>
                        <span>Dashboard</span>
                        <i class="fas fa-chevron-right" style="font-size: 12px;"></i>
                        <span style="color: #111827; font-weight: 600;">Overview</span>
                    </div>
                    <h2 style="font-size: 32px; margin-bottom: 8px; color: #111827; font-weight: 800; background: linear-gradient(135deg, #111827, #6366f1); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;">Welcome back, Admin!</h2>
                    <p style="color: #6b7280; font-size: 16px; margin: 0; line-height: 1.6;">Here's your business overview and key metrics for today.</p>
                </div>
                
                <!-- Quick Actions -->
                <div style="display: flex; gap: 12px; align-items: center;">
                    <button onclick="refreshDashboard()" style="background: #f3f4f6; color: #6b7280; border: none; padding: 12px; border-radius: 12px; cursor: pointer; transition: all 0.3s ease; display: flex; align-items: center; justify-content: center;" onmouseover="this.style.background='#e5e7eb'; this.style.color='#374151'" onmouseout="this.style.background='#f3f4f6'; this.style.color='#6b7280'">
                        <i class="fas fa-sync-alt" style="font-size: 16px;"></i>
                    </button>
                    <button onclick="toggleAutoUpdate()" id="autoUpdateToggle" style="background: linear-gradient(135deg, #10b981, #059669); color: white; border: none; padding: 12px; border-radius: 12px; font-weight: 600; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.3s ease; box-shadow: 0 4px 15px rgba(16, 185, 129, 0.3);" onmouseover="this.style.transform='translateY(-2px)'; this.style.boxShadow='0 6px 20px rgba(16, 185, 129, 0.4)'" onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='0 4px 15px rgba(16, 185, 129, 0.3)'">
                        <i class="fas fa-play" style="font-size: 14px;"></i>
                    </button>
                    <button onclick="exportDashboardData()" style="background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; border: none; padding: 12px 20px; border-radius: 12px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 8px; transition: all 0.3s ease; box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3);" onmouseover="this.style.transform='translateY(-2px)'; this.style.boxShadow='0 6px 20px rgba(99, 102, 241, 0.4)'" onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='0 4px 15px rgba(99, 102, 241, 0.3)'">
                        <i class="fas fa-download" style="font-size: 14px;"></i>
                        <span>Export</span>
                    </button>
                    <div class="notification-container">
                        <div class="notification-bell" id="notificationBell">
                            <i class="fas fa-bell" style="font-size: 20px; color: #6b7280;"></i>
                            <span class="notification-badge" id="notificationBadge" style="display: none;">0</span>
                        </div>
                        <div class="notification-dropdown" id="notificationDropdown">
                            <div class="notification-header">
                                <h3 class="notification-title">Notifications</h3>
                                <button class="mark-all-read" id="markAllRead">Mark all as read</button>
                            </div>
                            <div id="notificationList">
                                <div class="no-notifications">No new notifications</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Live Stats Bar -->
            <div style="display: flex; gap: 24px; align-items: center; padding: 16px 0; border-top: 1px solid #e5e7eb;">
                <div style="display: flex; align-items: center; gap: 8px;">
                    <div style="width: 8px; height: 8px; background: #10b981; border-radius: 50%; animation: pulse 2s infinite;"></div>
                    <span style="font-size: 14px; color: #6b7280;">System Status: <strong style="color: #10b981;">Online</strong></span>
                </div>
                <div style="display: flex; align-items: center; gap: 8px;">
                    <i class="fas fa-clock" style="color: #6b7280; font-size: 14px;"></i>
                    <span style="font-size: 14px; color: #6b7280;">Last Updated: <strong id="last-updated">Just now</strong></span>
                </div>
                <div style="display: flex; align-items: center; gap: 8px;">
                    <i class="fas fa-user-clock" style="color: #6b7280; font-size: 14px;"></i>
                    <span style="font-size: 14px; color: #6b7280;">Session: <strong id="session-time">00:00:00</strong></span>
                </div>
                <div style="display: flex; align-items: center; gap: 8px;">
                    <i class="fas fa-sync" style="color: #6b7280; font-size: 14px;"></i>
                    <span style="font-size: 14px; color: #6b7280;" id="auto-update-indicator">Auto-update: ON</span>
                </div>
            </div>
        </div>
    </div>

    <!-- Enhanced Dashboard Stats -->
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 24px; margin-bottom: 30px;">
        <div onclick="window.location.href='plans.php'" class="stat-card" style="background: linear-gradient(135deg, #ffffff, #f8fafc); padding: 28px; border-radius: 20px; box-shadow: 0 8px 32px rgba(0,0,0,0.12); border: 1px solid #e5e7eb; cursor: pointer; position: relative; overflow: hidden; transition: all 0.3s ease;">
            <!-- Background Gradient -->
            <div style="position: absolute; top: -50%; right: -50%; width: 100px; height: 100px; background: radial-gradient(circle, rgba(99, 102, 241, 0.1) 0%, transparent 70%); border-radius: 50%;"></div>
            
            <div style="position: relative; z-index: 1;">
                <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px;">
                    <div style="width: 56px; height: 56px; border-radius: 16px; display: flex; align-items: center; justify-content: center; font-size: 24px; color: white; background: linear-gradient(135deg, #6366f1, #8b5cf6); box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3);">
                        <i class="fas fa-clipboard-list"></i>
                    </div>
                    <div style="background: rgba(99, 102, 241, 0.1); color: #6366f1; padding: 6px 12px; border-radius: 20px; font-size: 12px; font-weight: 600;">
                        <i class="fas fa-arrow-up" style="font-size: 10px;"></i> +12%
                    </div>
                </div>
                <div style="font-size: 32px; font-weight: 800; color: #111827; margin-bottom: 8px; line-height: 1;" id="total-plans">-</div>
                <div style="color: #6b7280; font-size: 16px; font-weight: 600; margin-bottom: 12px;">Total Plans</div>
                <div style="display: flex; align-items: center; justify-content: between; padding-top: 12px; border-top: 1px solid #f3f4f6;">
                    <div style="display: flex; align-items: center; gap: 6px;">
                        <div style="width: 8px; height: 8px; background: #10b981; border-radius: 50%;"></div>
                        <span style="font-size: 14px; color: #6b7280;"><span id="active-plans" style="font-weight: 600; color: #111827;">-</span> active</span>
                    </div>
                    <i class="fas fa-external-link-alt" style="color: #d1d5db; font-size: 14px;"></i>
                </div>
            </div>
        </div>

        <div onclick="window.location.href='register_dropshipper_details.php'" class="stat-card" style="background: linear-gradient(135deg, #ffffff, #f0f9ff); padding: 28px; border-radius: 20px; box-shadow: 0 8px 32px rgba(0,0,0,0.12); border: 1px solid #e5e7eb; cursor: pointer; position: relative; overflow: hidden; transition: all 0.3s ease;">
            <!-- Background Gradient -->
            <div style="position: absolute; top: -50%; right: -50%; width: 100px; height: 100px; background: radial-gradient(circle, rgba(59, 130, 246, 0.1) 0%, transparent 70%); border-radius: 50%;"></div>
            
            <div style="position: relative; z-index: 1;">
                <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px;">
                    <div style="width: 56px; height: 56px; border-radius: 16px; display: flex; align-items: center; justify-content: center; font-size: 24px; color: white; background: linear-gradient(135deg, #3b82f6, #1d4ed8); box-shadow: 0 4px 15px rgba(59, 130, 246, 0.3);">
                        <i class="fas fa-users"></i>
                    </div>
                    <div style="background: rgba(59, 130, 246, 0.1); color: #3b82f6; padding: 6px 12px; border-radius: 20px; font-size: 12px; font-weight: 600;">
                        <i class="fas fa-arrow-up" style="font-size: 10px;"></i> +8%
                    </div>
                </div>
                <div style="font-size: 32px; font-weight: 800; color: #111827; margin-bottom: 8px; line-height: 1;" id="total-dropshippers">-</div>
                <div style="color: #6b7280; font-size: 16px; font-weight: 600; margin-bottom: 12px;">Total Dropshippers</div>
                <div style="display: flex; align-items: center; justify-content: between; padding-top: 12px; border-top: 1px solid #f3f4f6;">
                    <div style="display: flex; align-items: center; gap: 6px;">
                        <div style="width: 8px; height: 8px; background: #f59e0b; border-radius: 50%;"></div>
                        <span style="font-size: 14px; color: #6b7280;"><span id="recent-dropshippers" style="font-weight: 600; color: #111827;">-</span> this month</span>
                    </div>
                    <i class="fas fa-external-link-alt" style="color: #d1d5db; font-size: 14px;"></i>
                </div>
            </div>
        </div>

        <div onclick="window.location.href='comments.php'" class="stat-card" style="background: linear-gradient(135deg, #ffffff, #fef2f2); padding: 28px; border-radius: 20px; box-shadow: 0 8px 32px rgba(0,0,0,0.12); border: 1px solid #e5e7eb; cursor: pointer; position: relative; overflow: hidden; transition: all 0.3s ease;">
            <!-- Background Gradient -->
            <div style="position: absolute; top: -50%; right: -50%; width: 100px; height: 100px; background: radial-gradient(circle, rgba(239, 68, 68, 0.1) 0%, transparent 70%); border-radius: 50%;"></div>
            
            <div style="position: relative; z-index: 1;">
                <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px;">
                    <div style="width: 56px; height: 56px; border-radius: 16px; display: flex; align-items: center; justify-content: center; font-size: 24px; color: white; background: linear-gradient(135deg, #ef4444, #dc2626); box-shadow: 0 4px 15px rgba(239, 68, 68, 0.3);">
                        <i class="fas fa-comments"></i>
                    </div>
                    <div style="background: rgba(239, 68, 68, 0.1); color: #ef4444; padding: 6px 12px; border-radius: 20px; font-size: 12px; font-weight: 600;">
                        <i class="fas fa-arrow-up" style="font-size: 10px;"></i> +15%
                    </div>
                </div>
                <div id="totalComments" style="font-size: 32px; font-weight: 800; color: #111827; margin-bottom: 8px; line-height: 1;">Loading...</div>
                <div style="color: #6b7280; font-size: 16px; font-weight: 600; margin-bottom: 12px;">Total Comments</div>
                <div style="display: flex; align-items: center; justify-content: between; padding-top: 12px; border-top: 1px solid #f3f4f6;">
                    <div style="display: flex; align-items: center; gap: 6px;">
                        <div style="width: 8px; height: 8px; background: #ef4444; border-radius: 50%;"></div>
                        <span id="todayComments" style="font-size: 14px; color: #6b7280;">Loading...</span>
                    </div>
                    <i class="fas fa-external-link-alt" style="color: #d1d5db; font-size: 14px;"></i>
                </div>
            </div>
        </div>

<script>
    async function loadCommentsStats(isAutoUpdate = false) {
        try {
            if (isAutoUpdate) {
                console.log('Auto-updating comments stats...');
            }

            const response = await fetch("https://customprint.deodap.com/api_dropshipper_tracker/admin_all_comments.php");
            const data = await response.json();

            if (data.success) {
                // Check if data has actually changed
                const newDataHash = JSON.stringify({total: data.total_comments, today: data.today_comments});
                const oldDataHash = localStorage.getItem('commentsDataHash');

                if (isAutoUpdate && newDataHash === oldDataHash) {
                    console.log('Comments data unchanged, skipping update');
                    return;
                }

                document.getElementById("totalComments").textContent = data.total_comments;
                document.getElementById("todayComments").textContent = data.today_comments + " comments today";

                localStorage.setItem('commentsDataHash', newDataHash);
                lastUpdateTimestamps.comments = Date.now();

                if (isAutoUpdate) {
                    console.log('Comments stats auto-updated successfully');
                    // Add subtle visual feedback for comments update
                    const commentsCard = document.querySelector('.stat-card:nth-child(3)');
                    if (commentsCard) {
                        commentsCard.style.boxShadow = '0 8px 32px rgba(239, 68, 68, 0.3)';
                        setTimeout(() => {
                            commentsCard.style.boxShadow = '0 8px 32px rgba(0,0,0,0.12)';
                        }, 1000);
                    }
                }
            } else {
                if (!isAutoUpdate) {
                    document.getElementById("totalComments").textContent = "0";
                    document.getElementById("todayComments").textContent = "No data available";
                }
            }
        } catch (error) {
            console.error("Error loading comments:", error);
            if (!isAutoUpdate) {
                document.getElementById("totalComments").textContent = "Error";
                document.getElementById("todayComments").textContent = "Error loading data";
            }
        }
    }

    // 
    document.addEventListener("DOMContentLoaded", loadCommentsStats);
</script>




        <div onclick="comingSoon('Revenue')" class="stat-card" style="background: linear-gradient(135deg, #ffffff, #fffbeb); padding: 28px; border-radius: 20px; box-shadow: 0 8px 32px rgba(0,0,0,0.12); border: 1px solid #e5e7eb; cursor: pointer; position: relative; overflow: hidden; transition: all 0.3s ease;">
            <!-- Background Gradient -->
            <div style="position: absolute; top: -50%; right: -50%; width: 100px; height: 100px; background: radial-gradient(circle, rgba(245, 158, 11, 0.1) 0%, transparent 70%); border-radius: 50%;"></div>
            
            <div style="position: relative; z-index: 1;">
                <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px;">
                    <div style="width: 56px; height: 56px; border-radius: 16px; display: flex; align-items: center; justify-content: center; font-size: 24px; color: white; background: linear-gradient(135deg, #f59e0b, #d97706); box-shadow: 0 4px 15px rgba(245, 158, 11, 0.3);">
                        <i class="fas fa-dollar-sign"></i>
                    </div>
                    <div style="background: rgba(245, 158, 11, 0.1); color: #f59e0b; padding: 6px 12px; border-radius: 20px; font-size: 12px; font-weight: 600;">
                        <i class="fas fa-arrow-up" style="font-size: 10px;"></i> +8.2%
                    </div>
                </div>
                <div style="font-size: 32px; font-weight: 800; color: #111827; margin-bottom: 8px; line-height: 1;">$45.2K</div>
                <div style="color: #6b7280; font-size: 16px; font-weight: 600; margin-bottom: 12px;">Revenue This Month</div>
                <div style="display: flex; align-items: center; justify-content: between; padding-top: 12px; border-top: 1px solid #f3f4f6;">
                    <div style="display: flex; align-items: center; gap: 6px;">
                        <div style="width: 8px; height: 8px; background: #10b981; border-radius: 50%;"></div>
                        <span style="font-size: 14px; color: #6b7280;"><strong style="color: #111827;">+8.2%</strong> growth</span>
                    </div>
                    <i class="fas fa-external-link-alt" style="color: #d1d5db; font-size: 14px;"></i>
                </div>
            </div>
        </div>
    </div>

    <!-- Plans Overview Section -->
    <div style="background: white; border-radius: 16px; padding: 30px; box-shadow: 0 4px 25px rgba(0,0,0,0.08); border: 1px solid #e5e7eb; margin-bottom: 30px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px;">
            <h3 style="font-size: 24px; font-weight: 700; color: #111827;">Plans Overview</h3>
            <a href="plans.php" style="background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; border: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; cursor: pointer; text-decoration: none;">
                <i class="fas fa-eye"></i>
                View All Plans
            </a>
        </div>

        <div id="dashboard-plans-container">
            <div style="text-align: center; padding: 40px; color: #6b7280; display: flex; align-items: center; justify-content: center; gap: 8px;">
                <i class="fas fa-spinner fa-spin"></i>
                Loading plans...
            </div>
        </div>
    </div>

    <!-- Dropshippers Overview Section -->
    <div style="background: white; border-radius: 16px; padding: 30px; box-shadow: 0 4px 25px rgba(0,0,0,0.08); border: 1px solid #e5e7eb;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px;">
            <h3 style="font-size: 24px; font-weight: 700; color: #111827;">Recent Dropshippers</h3>
            <a href="register_dropshipper_details.php" style="background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; border: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; cursor: pointer; text-decoration: none;">
                <i class="fas fa-eye"></i>
                View All Dropshippers
            </a>
        </div>

        <div id="dashboard-dropshippers-container">
            <div style="text-align: center; padding: 40px; color: #6b7280; display: flex; align-items: center; justify-content: center; gap: 8px;">
                <i class="fas fa-spinner fa-spin"></i>
                Loading dropshippers...
            </div>
        </div>
    </div>
</div>

<script>
    let dashboardPlansData = [];
    let dashboardDropshippersData = [];

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

    // Enhanced Coming Soon function with better UX
    function comingSoon(feature) {
        const modal = document.createElement('div');
        modal.style.cssText = `
            position: fixed; top: 0; left: 0; width: 100%; height: 100%; 
            background: rgba(0,0,0,0.5); z-index: 10000; display: flex; 
            align-items: center; justify-content: center;
        `;
        
        modal.innerHTML = `
            <div style="background: white; padding: 40px; border-radius: 20px; max-width: 400px; text-align: center; box-shadow: 0 20px 60px rgba(0,0,0,0.3);">
                <div style="width: 80px; height: 80px; background: linear-gradient(135deg, #6366f1, #8b5cf6); border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 20px; color: white; font-size: 32px;">
                    <i class="fas fa-rocket"></i>
                </div>
                <h3 style="font-size: 24px; font-weight: 700; color: #111827; margin-bottom: 12px;">${feature} Coming Soon!</h3>
                <p style="color: #6b7280; margin-bottom: 24px; line-height: 1.6;">This feature is under development and will include detailed ${feature.toLowerCase()} analytics, management tools, and advanced reporting capabilities.</p>
                <button onclick="this.parentElement.parentElement.remove()" style="background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; border: none; padding: 12px 24px; border-radius: 12px; font-weight: 600; cursor: pointer;">Got it!</button>
            </div>
        `;
        
        document.body.appendChild(modal);
        modal.onclick = (e) => { if (e.target === modal) modal.remove(); };
    }
    
    // Dashboard refresh function
    function refreshDashboard() {
        const refreshBtn = event.target.closest('button');
        const icon = refreshBtn.querySelector('i');
        
        // Add spinning animation
        icon.style.animation = 'spin 1s linear infinite';
        refreshBtn.disabled = true;
        
        // Update last updated time
        document.getElementById('last-updated').textContent = 'Refreshing...';
        
        // Reload all data
        loadAllDashboardData();
        loadCommentsStats();
        
        // Reset button after 2 seconds
        setTimeout(() => {
            icon.style.animation = '';
            refreshBtn.disabled = false;
            document.getElementById('last-updated').textContent = 'Just now';
        }, 2000);
    }
    
    // Export dashboard data function
    function exportDashboardData() {
        const exportBtn = event.target.closest('button');
        const originalText = exportBtn.innerHTML;
        
        // Show loading state
        exportBtn.innerHTML = '<i class="fas fa-spinner fa-spin" style="font-size: 14px;"></i><span>Exporting...</span>';
        exportBtn.disabled = true;
        
        // Simulate export process
        setTimeout(() => {
            // Create CSV content
            let csvContent = 'Dashboard Summary Report\n\n';
            csvContent += 'Metric,Value\n';
            csvContent += `Total Plans,${document.getElementById('total-plans').textContent}\n`;
            csvContent += `Active Plans,${document.getElementById('active-plans').textContent}\n`;
            csvContent += `Total Dropshippers,${document.getElementById('total-dropshippers').textContent}\n`;
            csvContent += `Recent Dropshippers,${document.getElementById('recent-dropshippers').textContent}\n`;
            csvContent += `Total Comments,${document.getElementById('totalComments').textContent}\n`;
            csvContent += `Export Date,${new Date().toLocaleString()}\n`;
            
            // Download CSV
            const blob = new Blob([csvContent], { type: 'text/csv' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `dashboard-summary-${new Date().toISOString().split('T')[0]}.csv`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            window.URL.revokeObjectURL(url);
            
            // Reset button
            exportBtn.innerHTML = originalText;
            exportBtn.disabled = false;
            
            // Show success message
            showNotification('Dashboard data exported successfully!', 'success');
        }, 1500);
    }
    
    // Notification system
    function showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        const bgColor = type === 'success' ? '#10b981' : type === 'error' ? '#ef4444' : '#6366f1';
        
        notification.style.cssText = `
            position: fixed; top: 20px; right: 20px; z-index: 10001;
            background: ${bgColor}; color: white; padding: 16px 24px;
            border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.3);
            font-weight: 600; transform: translateX(400px);
            transition: transform 0.3s ease;
        `;
        
        notification.innerHTML = `
            <div style="display: flex; align-items: center; gap: 12px;">
                <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle'}"></i>
                <span>${message}</span>
            </div>
        `;
        
        document.body.appendChild(notification);
        
        // Animate in
        setTimeout(() => notification.style.transform = 'translateX(0)', 100);
        
        // Auto remove after 4 seconds
        setTimeout(() => {
            notification.style.transform = 'translateX(400px)';
            setTimeout(() => notification.remove(), 300);
        }, 4000);
    }

    // Auto-update configuration
    let autoUpdateEnabled = true;
    let autoUpdateIntervals = {
        plans: 30000,      // 30 seconds
        dropshippers: 45000, // 45 seconds
        comments: 20000     // 20 seconds
    };
    let autoUpdateTimers = {};
    let isUserActive = true;
    let lastUpdateTimestamps = {
        plans: 0,
        dropshippers: 0,
        comments: 0
    };

    // Initialize data loading
    function loadAllDashboardData() {
        console.log('Starting data loading sequence...');
        loadDashboardPlans();
        loadDropshippersData();
        loadCommentsStats();

        // Start auto-update cycles
        if (autoUpdateEnabled) {
            startAutoUpdates();
        }
    }

    // Start auto-update cycles
    function startAutoUpdates() {
        console.log('Starting auto-update cycles...');

        // Auto-update plans
        autoUpdateTimers.plans = setInterval(() => {
            if (autoUpdateEnabled && isUserActive) {
                loadDashboardPlans(true); // true = auto-update mode
            }
        }, autoUpdateIntervals.plans);

        // Auto-update dropshippers
        autoUpdateTimers.dropshippers = setInterval(() => {
            if (autoUpdateEnabled && isUserActive) {
                loadDropshippersData(true); // true = auto-update mode
            }
        }, autoUpdateIntervals.dropshippers);

        // Auto-update comments
        autoUpdateTimers.comments = setInterval(() => {
            if (autoUpdateEnabled && isUserActive) {
                loadCommentsStats(true); // true = auto-update mode
            }
        }, autoUpdateIntervals.comments);

        showNotification('Auto-update enabled - Dashboard will refresh automatically', 'success');
    }

    // Stop auto-updates
    function stopAutoUpdates() {
        console.log('Stopping auto-update cycles...');
        Object.values(autoUpdateTimers).forEach(timer => clearInterval(timer));
        autoUpdateTimers = {};
        showNotification('Auto-update paused', 'info');
    }

    // Toggle auto-update
    function toggleAutoUpdate() {
        autoUpdateEnabled = !autoUpdateEnabled;
        if (autoUpdateEnabled) {
            startAutoUpdates();
        } else {
            stopAutoUpdates();
        }
        updateAutoUpdateIndicator();
        updateAutoUpdateButton();
    }

    // Update auto-update button appearance
    function updateAutoUpdateButton() {
        const button = document.getElementById('autoUpdateToggle');
        if (button) {
            const icon = button.querySelector('i');
            if (autoUpdateEnabled) {
                button.style.background = 'linear-gradient(135deg, #10b981, #059669)';
                button.style.boxShadow = '0 4px 15px rgba(16, 185, 129, 0.3)';
                if (icon) icon.className = 'fas fa-pause';
            } else {
                button.style.background = 'linear-gradient(135deg, #ef4444, #dc2626)';
                button.style.boxShadow = '0 4px 15px rgba(239, 68, 68, 0.3)';
                if (icon) icon.className = 'fas fa-play';
            }
        }
    }

    // Update auto-update indicator
    function updateAutoUpdateIndicator() {
        const indicator = document.getElementById('auto-update-indicator');
        if (indicator) {
            const status = autoUpdateEnabled ? (isUserActive ? 'ON' : 'PAUSED') : 'OFF';
            indicator.textContent = `Auto-update: ${status}`;
            indicator.style.color = autoUpdateEnabled ? (isUserActive ? '#10b981' : '#f59e0b') : '#ef4444';
        }
    }

    // User activity detection
    function setupUserActivityDetection() {
        let activityTimeout;

        function resetActivityTimeout() {
            clearTimeout(activityTimeout);
            if (!isUserActive) {
                isUserActive = true;
                console.log('User became active');
                updateAutoUpdateIndicator();
            }

            activityTimeout = setTimeout(() => {
                isUserActive = false;
                console.log('User became inactive');
                updateAutoUpdateIndicator();
            }, 30000); // 30 seconds of inactivity
        }

        // Activity events
        const activityEvents = ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart', 'click'];
        activityEvents.forEach(event => {
            document.addEventListener(event, resetActivityTimeout, { passive: true });
        });

        // Start with user as active
        resetActivityTimeout();
    }

    // Enhanced dropshippers loading
    function loadDropshippersData(isAutoUpdate = false) {
        console.log('Loading dropshippers data...', isAutoUpdate ? '(auto-update)' : '');

        if (isAutoUpdate) {
            // Add subtle update indicator for dropshippers
            const container = document.getElementById('dashboard-dropshippers-container');
            const updateIndicator = document.createElement('div');
            updateIndicator.id = 'dropshippers-update-indicator';
            updateIndicator.style.cssText = `
                position: absolute; top: 10px; right: 10px; z-index: 10;
                background: rgba(59, 130, 246, 0.1); color: #3b82f6;
                padding: 4px 8px; border-radius: 12px; font-size: 12px;
                display: flex; align-items: center; gap: 4px;
            `;
            updateIndicator.innerHTML = '<i class="fas fa-sync fa-spin" style="font-size: 10px;"></i> Updating...';

            // Remove existing indicator
            const existingIndicator = document.getElementById('dropshippers-update-indicator');
            if (existingIndicator) existingIndicator.remove();

            container.style.position = 'relative';
            container.appendChild(updateIndicator);

            // Remove indicator after 2 seconds
            setTimeout(() => {
                if (updateIndicator.parentNode) {
                    updateIndicator.remove();
                }
            }, 2000);
        }

        fetch('https://customprint.deodap.com/api_dropshipper_tracker/dropshipper_details.php')
            .then(response => {
                console.log('Dropshippers API response status:', response.status);
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                console.log('Dropshippers API response:', data);

                if (data.success && Array.isArray(data.dropshippers)) {
                    // Check if data has actually changed
                    const newDataHash = JSON.stringify(data.dropshippers);
                    const oldDataHash = localStorage.getItem('dropshippersDataHash');

                    if (isAutoUpdate && newDataHash === oldDataHash) {
                        console.log('Dropshippers data unchanged, skipping update');
                        return;
                    }

                    dashboardDropshippersData = data.dropshippers;
                    localStorage.setItem('dropshippersDataHash', newDataHash);
                    lastUpdateTimestamps.dropshippers = Date.now();

                    updateDropshippersStats(data.dropshippers);
                    displayDashboardDropshippers(data.dropshippers);

                    if (isAutoUpdate) {
                        console.log('Dropshippers auto-updated successfully');
                    }
                } else {
                    console.error('Error loading dropshippers:', data.message || 'Invalid data structure');
                    if (!isAutoUpdate) {
                        document.getElementById('total-dropshippers').textContent = '0';
                        document.getElementById('recent-dropshippers').textContent = '0';
                        displayDropshippersError();
                    }
                }
            })
            .catch(error => {
                console.error('Error loading dropshippers:', error);
                if (!isAutoUpdate) {
                    document.getElementById('total-dropshippers').textContent = 'Error';
                    document.getElementById('recent-dropshippers').textContent = 'Error';
                    displayDropshippersError();
                }
            });
    }

    function updateDropshippersStats(dropshippers) {
        const totalDropshippers = dropshippers.length;
        
        // Calculate this month's registrations
        const currentMonth = new Date().getMonth();
        const currentYear = new Date().getFullYear();
        
        const thisMonthDropshippers = dropshippers.filter(dropshipper => {
            if (!dropshipper.created_at) return false;
            const createdDate = new Date(dropshipper.created_at);
            return createdDate.getMonth() === currentMonth && 
                   createdDate.getFullYear() === currentYear;
        }).length;
        
        console.log(`Total dropshippers: ${totalDropshippers}, This month: ${thisMonthDropshippers}`);
        
        document.getElementById('total-dropshippers').textContent = totalDropshippers.toLocaleString();
        document.getElementById('recent-dropshippers').textContent = thisMonthDropshippers;
    }

    function displayDashboardDropshippers(dropshippers) {
        console.log('Displaying dropshippers:', dropshippers.length);
        
        const container = document.getElementById('dashboard-dropshippers-container');
        
        if (dropshippers.length === 0) {
            container.innerHTML = `
                <div style="text-align: center; padding: 60px 20px; color: #6b7280;">
                    <i class="fas fa-users" style="font-size: 48px; margin-bottom: 16px; color: #d1d5db;"></i>
                    <h3 style="font-size: 18px; margin-bottom: 8px; color: #111827;">No Dropshippers Found</h3>
                    <p style="margin-bottom: 24px;">No dropshippers have registered yet.</p>
                    <a href="register_dropshipper.php" style="background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; border: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; cursor: pointer; text-decoration: none; display: inline-flex; align-items: center; gap: 8px;">
                        <i class="fas fa-plus"></i> Register First Dropshipper
                    </a>
                </div>
            `;
            return;
        }
        
        // Show only first 6 dropshippers on dashboard
        const displayDropshippers = dropshippers.slice(0, 6);
        
        let html = '<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 24px;">';
        
        displayDropshippers.forEach(dropshipper => {
            const createdDate = dropshipper.created_at ? new Date(dropshipper.created_at).toLocaleDateString() : 'Unknown';
            const initials = (dropshipper.seller_name || 'N/A').split(' ').map(n => n[0] || '').join('').toUpperCase() || 'DS';
            
            html += `
                <div onclick="openDropshipperDetails('${dropshipper.seller_id}')" style="background: white; padding: 24px; border-radius: 16px; box-shadow: 0 4px 25px rgba(0,0,0,0.08); border: 1px solid #e5e7eb; cursor: pointer; position: relative; overflow: hidden; transition: all 0.3s ease;">
                    <div style="display: flex; align-items: center; gap: 16px; margin-bottom: 16px;">
                        <div style="width: 48px; height: 48px; background: linear-gradient(135deg, #3b82f6, #1d4ed8); border-radius: 12px; display: flex; align-items: center; justify-content: center; color: white; font-weight: 700; font-size: 18px;">
                            ${initials}
                        </div>
                        <div>
                            <h4 style="font-size: 16px; font-weight: 700; color: #111827; margin-bottom: 4px;">${dropshipper.seller_name || 'Unknown'}</h4>
                            <p style="font-size: 12px; color: #6b7280; margin: 0;">ID: ${dropshipper.seller_id}</p>
                        </div>
                    </div>
                    <div style="color: #6b7280; font-size: 14px; margin-bottom: 16px; line-height: 1.5;">
                        <strong>${dropshipper.store_name || 'No store name'}</strong>
                    </div>
                    <div style="display: flex; align-items: center; gap: 8px; font-size: 12px; color: #6b7280; margin-bottom: 8px;">
                        <i class="fas fa-envelope" style="width: 16px; color: #9ca3af;"></i>
                        ${dropshipper.email || 'No email'}
                    </div>
                    <div style="display: flex; align-items: center; gap: 8px; font-size: 12px; color: #6b7280; margin-bottom: 16px;">
                        <i class="fas fa-phone" style="width: 16px; color: #9ca3af;"></i>
                        ${dropshipper.contact_number || 'No phone'}
                    </div>
                    <div style="display: flex; justify-content: space-between; align-items: center; padding-top: 16px; border-top: 1px solid #e5e7eb;">
                        <span style="padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; background: #dcfce7; color: #166534;">Active</span>
                        <span style="font-size: 12px; color: #9ca3af;">${createdDate}</span>
                    </div>
                </div>
            `;
        });
        
        html += '</div>';
        
        // Add "View All" message if there are more dropshippers
        if (dropshippers.length > 6) {
            html += `
                <div style="text-align: center; margin-top: 24px; padding-top: 24px; border-top: 1px solid #e5e7eb;">
                    <p style="color: #6b7280; margin-bottom: 16px;">
                        Showing ${displayDropshippers.length} of ${dropshippers.length} dropshippers
                    </p>
                    <a href="register_dropshipper_details.php" style="background: #6b7280; color: white; border: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; cursor: pointer; text-decoration: none; display: inline-flex; align-items: center; gap: 8px;">
                        <i class="fas fa-eye"></i> View All ${dropshippers.length} Dropshippers
                    </a>
                </div>
            `;
        }
        
        container.innerHTML = html;
        console.log('Dropshippers display completed');
    }

    function displayDropshippersError() {
        const container = document.getElementById('dashboard-dropshippers-container');
        container.innerHTML = `
            <div style="text-align: center; padding: 60px 20px; color: #6b7280;">
                <i class="fas fa-exclamation-triangle" style="font-size: 48px; margin-bottom: 16px; color: #d1d5db;"></i>
                <h3 style="font-size: 18px; margin-bottom: 8px; color: #111827;">Error Loading Dropshippers</h3>
                <p style="margin-bottom: 24px;">Failed to load dropshipper data. Please try again.</p>
                <button onclick="loadDropshippersData()" style="background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; border: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; cursor: pointer;">
                    <i class="fas fa-refresh"></i> Retry
                </button>
            </div>
        `;
    }

    // Dashboard Plans Functions
    function loadDashboardPlans(isAutoUpdate = false) {
        const container = document.getElementById('dashboard-plans-container');

        // For auto-updates, don't show loading spinner, just update quietly
        if (!isAutoUpdate) {
            container.innerHTML = `
                <div style="text-align: center; padding: 40px; color: #6b7280; display: flex; align-items: center; justify-content: center; gap: 8px;">
                    <i class="fas fa-spinner fa-spin"></i>
                    Loading plans...
                </div>
            `;
        } else {
            // Add subtle update indicator
            const updateIndicator = document.createElement('div');
            updateIndicator.id = 'plans-update-indicator';
            updateIndicator.style.cssText = `
                position: absolute; top: 10px; right: 10px; z-index: 10;
                background: rgba(99, 102, 241, 0.1); color: #6366f1;
                padding: 4px 8px; border-radius: 12px; font-size: 12px;
                display: flex; align-items: center; gap: 4px;
            `;
            updateIndicator.innerHTML = '<i class="fas fa-sync fa-spin" style="font-size: 10px;"></i> Updating...';

            // Remove existing indicator
            const existingIndicator = document.getElementById('plans-update-indicator');
            if (existingIndicator) existingIndicator.remove();

            container.style.position = 'relative';
            container.appendChild(updateIndicator);

            // Remove indicator after 2 seconds
            setTimeout(() => {
                if (updateIndicator.parentNode) {
                    updateIndicator.remove();
                }
            }, 2000);
        }

        fetch('https://customprint.deodap.com/api_dropshipper_tracker/plans_complete.php?action=fetch')
            .then(response => {
                console.log('Plans API response status:', response.status);
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                console.log('Plans API response:', data);
                if (data.success && Array.isArray(data.plans)) {
                    // Check if data has actually changed
                    const newDataHash = JSON.stringify(data.plans);
                    const oldDataHash = localStorage.getItem('plansDataHash');

                    if (isAutoUpdate && newDataHash === oldDataHash) {
                        console.log('Plans data unchanged, skipping update');
                        return;
                    }

                    dashboardPlansData = data.plans;
                    localStorage.setItem('plansDataHash', newDataHash);
                    lastUpdateTimestamps.plans = Date.now();

                    updateDashboardStats(data.plans);
                    displayDashboardPlans(data.plans);

                    if (isAutoUpdate) {
                        console.log('Plans auto-updated successfully');
                    }
                } else {
                    console.error('Error loading plans:', data.message || 'Invalid data structure');
                    if (!isAutoUpdate) {
                        container.innerHTML = `
                            <div style="text-align: center; padding: 60px 20px; color: #6b7280;">
                                <i class="fas fa-exclamation-triangle" style="font-size: 48px; margin-bottom: 16px; color: #d1d5db;"></i>
                                <h3 style="font-size: 18px; margin-bottom: 8px; color: #111827;">Error Loading Plans</h3>
                                <p style="margin-bottom: 24px;">${data.message || 'Failed to load plans data'}</p>
                                <button onclick="loadDashboardPlans()" style="background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; border: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; cursor: pointer;">
                                    <i class="fas fa-refresh"></i> Retry
                                </button>
                            </div>
                        `;
                    }
                }
            })
            .catch(error => {
                console.error('Error loading plans:', error);
                if (!isAutoUpdate) {
                    container.innerHTML = `
                        <div style="text-align: center; padding: 60px 20px; color: #6b7280;">
                            <i class="fas fa-wifi" style="font-size: 48px; margin-bottom: 16px; color: #d1d5db;"></i>
                            <h3 style="font-size: 18px; margin-bottom: 8px; color: #111827;">Connection Error</h3>
                            <p style="margin-bottom: 24px;">Failed to connect to the server. Please check your connection.</p>
                            <button onclick="loadDashboardPlans()" style="background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; border: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; cursor: pointer;">
                                <i class="fas fa-refresh"></i> Retry
                            </button>
                        </div>
                    `;
                    document.getElementById('total-plans').textContent = 'Error';
                    document.getElementById('active-plans').textContent = 'Error';
                }
            });
    }

    function updateDashboardStats(plans) {
        const totalPlans = plans.length;
        const activePlans = plans.filter(plan => plan.is_active == 1).length;
        
        document.getElementById('total-plans').textContent = totalPlans;
        document.getElementById('active-plans').textContent = activePlans;
    }

    function displayDashboardPlans(plans) {
        const container = document.getElementById('dashboard-plans-container');
        
        if (plans.length === 0) {
            container.innerHTML = `
                <div style="text-align: center; padding: 60px 20px; color: #6b7280;">
                    <i class="fas fa-clipboard-list" style="font-size: 48px; margin-bottom: 16px; color: #d1d5db;"></i>
                    <h3 style="font-size: 18px; margin-bottom: 8px; color: #111827;">No Plans Found</h3>
                    <p style="margin-bottom: 24px;">Get started by creating your first subscription plan.</p>
                    <a href="plans.php" style="background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; border: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; cursor: pointer; text-decoration: none; display: inline-flex; align-items: center; gap: 8px;">
                        <i class="fas fa-plus"></i> Create First Plan
                    </a>
                </div>
            `;
            return;
        }
        
        // Show only first 6 plans on dashboard
        const displayPlans = plans.slice(0, 6);
        
        let html = '<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 24px;">';
        
        displayPlans.forEach(plan => {
            const status = plan.is_active == 1 ? 'Active' : 'Inactive';
            const statusClass = plan.is_active == 1 ? 'background: #dcfce7; color: #166534;' : 'background: #fee2e2; color: #dc2626;';
            const createdDate = plan.created_at ? new Date(plan.created_at).toLocaleDateString() : 'Unknown';
            const price = parseFloat(plan.price || 0).toFixed(2);
            
            html += `
                <div onclick="openPlanDetail(${plan.id})" style="background: white; padding: 25px; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); border: 1px solid #e5e7eb; cursor: pointer; position: relative; transition: all 0.3s ease;">
                    <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 16px;">
                        <div>
                            <div style="font-size: 18px; font-weight: 700; color: #111827; margin-bottom: 4px;">${plan.name || 'Unnamed Plan'}</div>
                        </div>
                        <div style="font-size: 24px; font-weight: 700; color: #6366f1; text-align: right;">${price}</div>
                    </div>
                    <div style="color: #6b7280; font-size: 14px; margin-bottom: 16px; line-height: 1.5; min-height: 42px;">
                        ${plan.description || 'No description provided'}
                    </div>
                    <div style="display: flex; justify-content: space-between; align-items: center; padding-top: 16px; border-top: 1px solid #e5e7eb;">
                        <span style="padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; ${statusClass}">${status}</span>
                        <span style="font-size: 12px; color: #9ca3af;">${createdDate}</span>
                    </div>
                </div>
            `;
        });
        
        html += '</div>';
        
        // Add "View All" message if there are more plans
        if (plans.length > 6) {
            html += `
                <div style="text-align: center; margin-top: 24px; padding-top: 24px; border-top: 1px solid #e5e7eb;">
                    <p style="color: #6b7280; margin-bottom: 16px;">
                        Showing ${displayPlans.length} of ${plans.length} plans
                    </p>
                    <a href="plans.php" style="background: #6b7280; color: white; border: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; cursor: pointer; text-decoration: none; display: inline-flex; align-items: center; gap: 8px;">
                        <i class="fas fa-eye"></i> View All ${plans.length} Plans
                    </a>
                </div>
            `;
        }
        
        container.innerHTML = html;
        console.log('Plans display completed');
    }

    // Function to handle plan card clicks (future feature)
    function openPlanDetail(planId) {
        const plan = dashboardPlansData.find(p => p.id == planId);
        if (plan) {
            alert(`Plan Detail View Coming Soon!\n\nPlan: ${plan.name}\nPrice: ${parseFloat(plan.price || 0).toFixed(2)}\nStatus: ${plan.is_active == 1 ? 'Active' : 'Inactive'}\n\nThis will show detailed plan analytics, subscribers, and management options.`);
        }
    }

    // Function to handle dropshipper card clicks - redirect to details page
    function openDropshipperDetails(sellerId) {
        window.location.href = `register_dropshipper_details.php?seller_id=${sellerId}`;
    }

    // Mobile responsiveness
    document.addEventListener('click', function(e) {
        const sidebar = document.getElementById('sidebar');
        const mobileBtn = document.querySelector('.mobile-menu-btn');
        
        if (window.innerWidth <= 768 && 
            !sidebar.contains(e.target) && 
            !mobileBtn.contains(e.target) && 
            sidebar.style.transform === 'translateX(0px)') {
            closeSidebar();
        }
    });

    window.addEventListener('resize', function() {
        if (window.innerWidth > 768) {
            const sidebar = document.getElementById('sidebar');
            const overlay = document.querySelector('.sidebar-overlay');
            
            sidebar.style.transform = 'translateX(0px)';
            overlay.style.display = 'none';
        } else {
            // Show mobile menu button on mobile
            document.querySelector('.mobile-menu-btn').style.display = 'block';
            // Adjust main content margin
            document.querySelector('.main').style.marginLeft = '0';
            document.querySelector('.main').style.paddingTop = '80px';
            // Reset sidebar position
            document.getElementById('sidebar').style.transform = 'translateX(-100%)';
        }
    });

    // Handle responsive design on load
    function handleResponsiveDesign() {
        if (window.innerWidth <= 768) {
            document.querySelector('.mobile-menu-btn').style.display = 'block';
            document.querySelector('.main').style.marginLeft = '0';
            document.querySelector('.main').style.paddingTop = '80px';
            document.getElementById('sidebar').style.transform = 'translateX(-100%)';
        }
    }

   
    // Profile Menu Functions
    function toggleProfileMenu() {
        const menu = document.getElementById('profile-menu');
        const toggle = document.getElementById('profile-toggle');
        const icon = toggle.querySelector('i');
        
        if (menu.style.maxHeight === '0px' || menu.style.maxHeight === '') {
            menu.style.maxHeight = '150px';
            icon.className = 'fas fa-chevron-down';
        } else {
            menu.style.maxHeight = '0px';
            icon.className = 'fas fa-chevron-up';
        }
    }

    // Session Timer
    let sessionStartTime = new Date();
    function updateSessionTime() {
        const now = new Date();
        const diff = now - sessionStartTime;
        const hours = Math.floor(diff / (1000 * 60 * 60));
        const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((diff % (1000 * 60)) / 1000);
        
        const timeString = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        const sessionTimeElement = document.getElementById('session-time');
        if (sessionTimeElement) {
            sessionTimeElement.textContent = timeString;
        }
    }

    // Profile Action Functions
    function changePassword() {
        alert('Change Password feature coming soon!\n\nThis will allow you to securely update your password with:\n• Current password verification\n• Strong password requirements\n• Email confirmation');
    }

    function viewActivity() {
        alert('Activity Log feature coming soon!\n\nThis will show:\n• Login history\n• Recent actions\n• System changes\n• Security events');
    }

    function backupData() {
        if (confirm('Create a backup of all system data?\n\nThis will include:\n• Plans data\n• Dropshipper information\n• Comments and feedback\n• System settings')) {
            alert('Backup feature coming soon!\n\nThis will create a complete backup of your system data for safe keeping.');
        }
    }

    function systemHealth() {
        alert('System Health Check\n\n✅ Database: Connected\n✅ API Services: Running\n✅ File System: OK\n✅ Memory Usage: Normal\n✅ Disk Space: Available\n\nAll systems operational!');
    }

    // Initialize everything
    document.addEventListener('DOMContentLoaded', function() {
        console.log('Dashboard initializing...');

        // Handle responsive design
        handleResponsiveDesign();

        // Setup user activity detection for auto-update pause/resume
        setupUserActivityDetection();

        // Load all data
        loadAllDashboardData();

        // Start session timer
        setInterval(updateSessionTime, 1000);
        updateSessionTime();
        
        // Update last updated time periodically
        setInterval(() => {
            const now = new Date();
            const timeString = now.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
            document.getElementById('last-updated').textContent = timeString;
        }, 60000); // Update every minute

        // 
        if ("Notification" in window) {
            Notification.requestPermission().then(permission => {
                if (permission === "granted") {
                    console.log("✅ Notifications allowed!");
                    // Show welcome notification
                    setTimeout(() => {
                        showNotification('Welcome to your dashboard! All systems are running smoothly.', 'success');
                    }, 2000);
                } else {
                    console.log("❌ Notifications blocked.");
                }
            });
        }
        
        // Add keyboard shortcuts
        document.addEventListener('keydown', function(e) {
            // Ctrl/Cmd + R for refresh
            if ((e.ctrlKey || e.metaKey) && e.key === 'r') {
                e.preventDefault();
                refreshDashboard();
            }
            // Ctrl/Cmd + E for export
            if ((e.ctrlKey || e.metaKey) && e.key === 'e') {
                e.preventDefault();
                exportDashboardData();
            }
        });

        console.log('Dashboard initialization complete');
    });
    // Add comprehensive responsive CSS
    const style = document.createElement('style');
    style.textContent = `
        /* Base Styles */
        * {
            box-sizing: border-box;
        }
        
        /* Mobile First - Small devices (320px - 480px) */
        @media (max-width: 480px) {
            .mobile-menu-btn {
                display: block !important;
                position: fixed !important;
                top: 20px !important;
                left: 20px !important;
                z-index: 1002 !important;
                padding: 12px !important;
                font-size: 18px !important;
                background: #6366f1 !important;
                color: white !important;
                border: none !important;
                border-radius: 8px !important;
                box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3) !important;
            }
            
            .main {
                margin-left: 0 !important;
                padding: 80px 15px 15px 15px !important;
                width: 100% !important;
                box-sizing: border-box !important;
            }
            
            .sidebar {
                width: 280px !important;
                transform: translateX(-100%) !important;
                transition: transform 0.3s ease !important;
                position: fixed !important;
                top: 0 !important;
                left: 0 !important;
                height: 100vh !important;
                z-index: 1001 !important;
                background: #ffffff !important;
                box-shadow: 2px 0 15px rgba(0,0,0,0.08) !important;
                border-right: 1px solid #e5e7eb !important;
                overflow-y: auto !important;
            }
            
            .sidebar.open {
                transform: translateX(0) !important;
            }
            
            .sidebar-overlay {
                position: fixed !important;
                top: 0 !important;
                left: 0 !important;
                width: 100% !important;
                height: 100% !important;
                background: rgba(0,0,0,0.5) !important;
                z-index: 1000 !important;
                display: none !important;
            }
            
            .sidebar-overlay.active {
                display: block !important;
            }
            
            /* Dashboard stats grid - single column on small mobile */
            .main > div:nth-child(2) {
                grid-template-columns: 1fr !important;
                gap: 16px !important;
            }
            
            /* Grid containers inside sections */
            .main > div:nth-child(3) > div:nth-child(2) > div,
            .main > div:nth-child(4) > div:nth-child(2) > div {
                grid-template-columns: 1fr !important;
                gap: 20px !important;
            }
        }
        
        /* Mobile devices (481px - 768px) */
        @media (min-width: 481px) and (max-width: 768px) {
            .mobile-menu-btn {
                display: block !important;
                position: fixed !important;
                top: 20px !important;
                left: 20px !important;
                z-index: 1002 !important;
                background: #6366f1 !important;
                color: white !important;
                border: none !important;
                padding: 12px !important;
                border-radius: 8px !important;
                box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3) !important;
            }
            
            .main {
                margin-left: 0 !important;
                padding: 80px 20px 20px 20px !important;
                width: 100% !important;
                box-sizing: border-box !important;
            }
            
            .sidebar {
                width: 280px !important;
                transform: translateX(-100%) !important;
                transition: transform 0.3s ease !important;
                position: fixed !important;
                top: 0 !important;
                left: 0 !important;
                height: 100vh !important;
                z-index: 1001 !important;
                background: #ffffff !important;
                box-shadow: 2px 0 15px rgba(0,0,0,0.08) !important;
                border-right: 1px solid #e5e7eb !important;
                overflow-y: auto !important;
            }
            
            .sidebar.open {
                transform: translateX(0) !important;
            }
            
            .sidebar-overlay {
                position: fixed !important;
                top: 0 !important;
                left: 0 !important;
                width: 100% !important;
                height: 100% !important;
                background: rgba(0,0,0,0.5) !important;
                z-index: 1000 !important;
                display: none !important;
            }
            
            .sidebar-overlay.active {
                display: block !important;
            }
            
            /* Dashboard stats - 2 columns on larger mobile */
            .main > div:nth-child(2) {
                grid-template-columns: repeat(2, 1fr) !important;
                gap: 20px !important;
            }
            
            /* Grid containers */
            .main > div:nth-child(3) > div:nth-child(2) > div,
            .main > div:nth-child(4) > div:nth-child(2) > div {
                grid-template-columns: 1fr !important;
                gap: 24px !important;
            }
        }
        
        /* Tablet devices (769px - 1024px) */
        @media (min-width: 769px) and (max-width: 1024px) {
            .mobile-menu-btn {
                display: none !important;
            }
            
            .sidebar {
                width: 280px !important;
                transform: translateX(0) !important;
                position: fixed !important;
                top: 0 !important;
                left: 0 !important;
                height: 100vh !important;
                background: #ffffff !important;
                box-shadow: 2px 0 15px rgba(0,0,0,0.08) !important;
                border-right: 1px solid #e5e7eb !important;
                overflow-y: auto !important;
                z-index: 1000 !important;
            }
            
            .main {
                margin-left: 280px !important;
                padding: 25px !important;
            }
            
            /* Dashboard stats */
            .main > div:nth-child(2) {
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)) !important;
                gap: 24px !important;
            }
            
            /* Plans and dropshippers grid */
            .main > div:nth-child(3) > div:nth-child(2) > div,
            .main > div:nth-child(4) > div:nth-child(2) > div {
                grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)) !important;
                gap: 24px !important;
            }
        }
        
        /* Desktop devices (1025px - 1440px) */
        @media (min-width: 1025px) and (max-width: 1440px) {
            .mobile-menu-btn {
                display: none !important;
            }
            
            .sidebar {
                width: 280px !important;
                transform: translateX(0) !important;
                position: fixed !important;
                top: 0 !important;
                left: 0 !important;
                height: 100vh !important;
                background: #ffffff !important;
                box-shadow: 2px 0 15px rgba(0,0,0,0.08) !important;
                border-right: 1px solid #e5e7eb !important;
                overflow-y: auto !important;
                z-index: 1000 !important;
            }
            
            .main {
                margin-left: 280px !important;
                padding: 25px !important;
            }
            
            /* Dashboard stats */
            .main > div:nth-child(2) {
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)) !important;
                gap: 24px !important;
            }
            
            /* Plans and dropshippers grid */
            .main > div:nth-child(3) > div:nth-child(2) > div,
            .main > div:nth-child(4) > div:nth-child(2) > div {
                grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)) !important;
                gap: 24px !important;
            }
        }
        
        /* Large desktop (1441px+) */
        @media (min-width: 1441px) {
            .mobile-menu-btn {
                display: none !important;
            }
            
            .sidebar {
                width: 280px !important;
                transform: translateX(0) !important;
                position: fixed !important;
                top: 0 !important;
                left: 0 !important;
                height: 100vh !important;
                background: #ffffff !important;
                box-shadow: 2px 0 15px rgba(0,0,0,0.08) !important;
                border-right: 1px solid #e5e7eb !important;
                overflow-y: auto !important;
                z-index: 1000 !important;
            }
            
            .main {
                margin-left: 280px !important;
                padding: 25px !important;
                max-width: 1600px !important;
            }
            
            /* Dashboard stats */
            .main > div:nth-child(2) {
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)) !important;
                gap: 24px !important;
            }
            
            /* Plans and dropshippers grid */
            .main > div:nth-child(3) > div:nth-child(2) > div,
            .main > div:nth-child(4) > div:nth-child(2) > div {
                grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)) !important;
                gap: 24px !important;
            }
        }
        
        /* Common responsive utilities */
        @media (max-width: 768px) {
            .sidebar-overlay.active {
                display: block !important;
            }
            
            /* Hide text on very small screens, show icons only */
            @media (max-width: 360px) {
                .sidebar nav a span {
                    display: none;
                }
                .sidebar nav a {
                    justify-content: center !important;
                }
            }
        }
        
        /* Sidebar scrollbar */
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
        
        /* Interactive elements */
        .nav-item:hover {
            background-color: #f9fafb !important;
            color: #6366f1 !important;
        }
        
        .stat-card:hover {
            box-shadow: 0 12px 40px rgba(0,0,0,0.15) !important;
            transform: translateY(-4px) scale(1.02);
            transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
        }
        
        .stat-card:active {
            transform: translateY(-2px) scale(1.01);
            transition: all 0.2s ease;
        }
        
        .plan-card:hover, .dropshipper-card:hover {
            box-shadow: 0 8px 40px rgba(0,0,0,0.15) !important;
            transform: translateY(-4px);
            transition: all 0.3s ease;
        }
        
        /* Animations */
        @keyframes spin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
        }
        
        .fa-spin {
            animation: spin 1s linear infinite;
        }
        
        @keyframes shimmer {
            0% { background-position: 100% 50%; }
            100% { background-position: -100% 50%; }
        }
        
        .loading-shimmer {
            background: linear-gradient(90deg, #f0f0f0 25%, transparent 37%, #f0f0f0 63%);
            background-size: 400% 100%;
            animation: shimmer 1.4s ease-in-out infinite;
        }
        
        @keyframes pulse {
            0%, 100% { opacity: 1; transform: scale(1); }
            50% { opacity: 0.7; transform: scale(1.1); }
        }
        
        /* Profile Menu */
        #profile-menu {
            transition: max-height 0.4s cubic-bezier(0.4, 0, 0.2, 1);
        }
        
        .profile-action:hover {
            background-color: #f9fafb !important;
            transform: translateX(4px);
            transition: all 0.3s ease;
        }
        
        .quick-action-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }
        
        /* Touch device optimizations */
        @media (hover: none) and (pointer: coarse) {
            .stat-card:hover,
            .plan-card:hover,
            .dropshipper-card:hover {
                transform: none !important;
            }
            
            .nav-item:hover,
            .profile-action:hover {
                transform: none !important;
            }
        }
    `;
    document.head.appendChild(style);
</script>

<script>
    let lastCheckedTimestamp = Date.now();
    let notifications = [];
    let notificationCheckInterval;
    let commentTimestamps = {}; // Store last update timestamps for each comment

    // Initialize notification system
    function initNotificationSystem() {
        // Load existing notifications from localStorage
        const savedNotifications = localStorage.getItem('notifications');
        if (savedNotifications) {
            notifications = JSON.parse(savedNotifications);
            updateNotificationBadge();
            renderNotifications();
        }

        // Load comment timestamps from localStorage
        const savedTimestamps = localStorage.getItem('commentTimestamps');
        if (savedTimestamps) {
            commentTimestamps = JSON.parse(savedTimestamps);
        }

        // Set up notification check interval (every 5 seconds for faster updates)
        notificationCheckInterval = setInterval(checkForCommentUpdates, 5000);

        // Initial check
        checkForCommentUpdates();
    }

    // Check for new comments and comment updates
    async function checkForCommentUpdates() {
        try {
            const response = await fetch('https://customprint.deodap.com/api_dropshipper_tracker/admin_all_comments.php');
            const data = await response.json();

            if (data.success && data.comments) {
                const newComments = [];
                const updatedComments = [];

                data.comments.forEach(comment => {
                    const commentId = comment.id;
                    const currentTimestamp = new Date(comment.created_at).getTime();
                    const lastTimestamp = commentTimestamps[commentId];

                    if (!lastTimestamp) {
                        // New comment
                        newComments.push(comment);
                    } else if (currentTimestamp > lastTimestamp) {
                        // Comment has been updated
                        updatedComments.push(comment);
                    }

                    // Update stored timestamp
                    commentTimestamps[commentId] = currentTimestamp;
                });

                // Process new comments
                if (newComments.length > 0) {
                    newComments.forEach(comment => {
                        notifications.unshift({
                            id: 'notif-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9),
                            type: 'new_comment',
                            message: `New comment from ${comment.seller_name || 'a seller'}`,
                            comment: comment.comment_text,
                            timestamp: comment.created_at,
                            read: false,
                            sellerId: comment.seller_id
                        });
                    });
                }

                // Process updated comments
                if (updatedComments.length > 0) {
                    updatedComments.forEach(comment => {
                        notifications.unshift({
                            id: 'notif-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9),
                            type: 'updated_comment',
                            message: `Comment updated by ${comment.seller_name || 'a seller'}`,
                            comment: comment.comment_text,
                            timestamp: comment.created_at,
                            read: false,
                            sellerId: comment.seller_id
                        });
                    });
                }

                if (newComments.length > 0 || updatedComments.length > 0) {
                    // Update last checked timestamp
                    lastCheckedTimestamp = Date.now();

                    // Save timestamps to localStorage
                    localStorage.setItem('commentTimestamps', JSON.stringify(commentTimestamps));

                    // Save notifications to localStorage
                    saveNotifications();

                    // Update UI
                    updateNotificationBadge();
                    renderNotifications();

                    // Show browser notification if not on the dashboard
                    if (document.visibilityState !== 'visible') {
                        const totalUpdates = newComments.length + updatedComments.length;
                        const title = totalUpdates === 1
                            ? (newComments.length === 1 ? 'New Comment Added' : 'Comment Updated')
                            : `${totalUpdates} Comment Updates`;

                        let body = '';
                        if (newComments.length === 1) {
                            body = newComments[0].comment_text.substring(0, 100) + '...';
                        } else if (updatedComments.length === 1) {
                            body = `Updated: ${updatedComments[0].comment_text.substring(0, 100)}...`;
                        } else {
                            body = `You have ${totalUpdates} comment updates`;
                        }

                        const notification = new Notification(title, {
                            body: body,
                            icon: 'https://customprint.deodap.com/api_dropshipper_tracker/logo.png',
                            tag: 'comment-update-notification'
                        });

                        notification.onclick = function() {
                            window.focus();
                            window.location.href = 'comments.php';
                        };
                    }
                }
            }
        } catch (error) {
            console.error('Error checking for comment updates:', error);
        }
    }

    // Update notification badge
    function updateNotificationBadge() {
        const unreadCount = notifications.filter(n => !n.read).length;
        const badge = document.getElementById('notificationBadge');
        
        if (unreadCount > 0) {
            badge.textContent = unreadCount > 9 ? '9+' : unreadCount;
            badge.style.display = 'flex';
        } else {
            badge.style.display = 'none';
        }
    }

    // Render notifications in dropdown
    function renderNotifications() {
        const container = document.getElementById('notificationList');
        
        if (notifications.length === 0) {
            container.innerHTML = '<div class="no-notifications">No new notifications</div>';
            return;
        }
        
        container.innerHTML = '';
        
        notifications.forEach(notification => {
            const timeAgo = getTimeAgo(notification.timestamp);
            const notificationElement = document.createElement('div');
            notificationElement.className = `notification-item ${notification.read ? '' : 'unread'}`;
            notificationElement.innerHTML = `
                <div class="notification-message">${notification.message}</div>
                <div class="notification-time">${timeAgo}</div>
            `;
            
            notificationElement.addEventListener('click', () => {
                markNotificationAsRead(notification.id);
                window.location.href = 'comments.php' + (notification.sellerId ? '?seller_id=' + notification.sellerId : '');
            });
            
            container.appendChild(notificationElement);
        });
    }

    // Mark notification as read
    function markNotificationAsRead(notificationId) {
        const notification = notifications.find(n => n.id === notificationId);
        if (notification && !notification.read) {
            notification.read = true;
            saveNotifications();
            updateNotificationBadge();
            renderNotifications();
        }
    }

    // Mark all notifications as read
    function markAllAsRead() {
        let updated = false;
        
        notifications.forEach(notification => {
            if (!notification.read) {
                notification.read = true;
                updated = true;
            }
        });
        
        if (updated) {
            saveNotifications();
            updateNotificationBadge();
            renderNotifications();
        }
    }

    // Save notifications to localStorage
    function saveNotifications() {
        // Keep only the 100 most recent notifications
        if (notifications.length > 100) {
            notifications = notifications.slice(0, 100);
        }
        localStorage.setItem('notifications', JSON.stringify(notifications));
    }

    // Helper function to get time ago
    function getTimeAgo(timestamp) {
        const date = new Date(timestamp);
        const now = new Date();
        const seconds = Math.floor((now - date) / 1000);
        
        let interval = Math.floor(seconds / 31536000);
        if (interval >= 1) return interval + ' year' + (interval === 1 ? '' : 's') + ' ago';
        
        interval = Math.floor(seconds / 2592000);
        if (interval >= 1) return interval + ' month' + (interval === 1 ? '' : 's') + ' ago';
        
        interval = Math.floor(seconds / 86400);
        if (interval >= 1) return interval + ' day' + (interval === 1 ? '' : 's') + ' ago';
        
        interval = Math.floor(seconds / 3600);
        if (interval >= 1) return interval + ' hour' + (interval === 1 ? '' : 's') + ' ago';
        
        interval = Math.floor(seconds / 60);
        if (interval >= 1) return interval + ' minute' + (interval === 1 ? '' : 's') + ' ago';
        
        return 'just now';
    }

    // Event Listeners
    document.addEventListener('DOMContentLoaded', function() {
        // Initialize notification system
        initNotificationSystem();
        
        // Toggle notification dropdown
        const notificationBell = document.getElementById('notificationBell');
        const notificationDropdown = document.getElementById('notificationDropdown');
        
        if (notificationBell && notificationDropdown) {
            notificationBell.addEventListener('click', function(e) {
                e.stopPropagation();
                notificationDropdown.style.display = 
                    notificationDropdown.style.display === 'block' ? 'none' : 'block';
            });
        }
        
        // Close dropdown when clicking outside
        document.addEventListener('click', function() {
            if (notificationDropdown) {
                notificationDropdown.style.display = 'none';
            }
        });
        
        // Mark all as read
        const markAllReadBtn = document.getElementById('markAllRead');
        if (markAllReadBtn) {
            markAllReadBtn.addEventListener('click', function(e) {
                e.stopPropagation();
                markAllAsRead();
            });
        }
        
        // Request notification permission
        if ('Notification' in window) {
            if (Notification.permission !== 'granted' && Notification.permission !== 'denied') {
                Notification.requestPermission();
            }
        }
        
        // Handle page visibility changes
        document.addEventListener('visibilitychange', function() {
            if (document.visibilityState === 'visible') {
                // Page is now visible, check for updates
                checkForNewComments();
            }
        });
    });
</script>

</body>
</html>
