<?php 
// register_dropshipper_details.php
session_start();

// Check if user is logged in
if (!isset($_SESSION['user'])) {
    header("Location: login.php");
    exit();
}

$user = $_SESSION['user'];

// API URL (your backend PHP file)
$apiUrl = "https://customprint.deodap.com/api_dropshipper_tracker/dropshipper_details.php"; // change path accordingly

// Build query parameters with improved handling
$queryParams = [];

// Add dropshipper_id parameter if specified (with validation)
if (isset($_GET['dropshipper_id']) && !empty($_GET['dropshipper_id'])) {
    $dropshipper_id = filter_var($_GET['dropshipper_id'], FILTER_VALIDATE_INT);
    if ($dropshipper_id !== false && $dropshipper_id > 0) {
        $queryParams['dropshipper_id'] = $dropshipper_id;
    }
}

// Add status filter parameter
if (isset($_GET['status']) && !empty($_GET['status'])) {
    $status = filter_var($_GET['status'], FILTER_SANITIZE_STRING);
    if (in_array($status, ['active', 'inactive', 'pending'])) {
        $queryParams['status'] = $status;
    }
}

// Add date filter parameter
if (isset($_GET['date_filter']) && !empty($_GET['date_filter'])) {
    $date_filter = filter_var($_GET['date_filter'], FILTER_SANITIZE_STRING);
    if (in_array($date_filter, ['today', 'week', 'month', 'year'])) {
        $queryParams['date_filter'] = $date_filter;
    }
}

// Add search parameter
if (isset($_GET['search']) && !empty($_GET['search'])) {
    $search = filter_var($_GET['search'], FILTER_SANITIZE_STRING);
    if (strlen($search) >= 2) { // Minimum 2 characters for search
        $queryParams['search'] = $search;
    }
}

// Add pagination parameters
if (isset($_GET['page']) && !empty($_GET['page'])) {
    $page = filter_var($_GET['page'], FILTER_VALIDATE_INT);
    if ($page !== false && $page > 0) {
        $queryParams['page'] = $page;
    }
}

if (isset($_GET['limit']) && !empty($_GET['limit'])) {
    $limit = filter_var($_GET['limit'], FILTER_VALIDATE_INT);
    if ($limit !== false && $limit > 0 && $limit <= 100) { // Max 100 records per page
        $queryParams['limit'] = $limit;
    }
}

// Add sorting parameters
if (isset($_GET['sort_by']) && !empty($_GET['sort_by'])) {
    $sort_by = filter_var($_GET['sort_by'], FILTER_SANITIZE_STRING);
    $allowed_sort_fields = ['id', 'seller_name', 'store_name', 'created_at', 'email'];
    if (in_array($sort_by, $allowed_sort_fields)) {
        $queryParams['sort_by'] = $sort_by;
    }
}

if (isset($_GET['sort_order']) && !empty($_GET['sort_order'])) {
    $sort_order = filter_var($_GET['sort_order'], FILTER_SANITIZE_STRING);
    if (in_array(strtolower($sort_order), ['asc', 'desc'])) {
        $queryParams['sort_order'] = strtolower($sort_order);
    }
}

// Build complete API URL with parameters
if (!empty($queryParams)) {
    $apiUrl .= '?' . http_build_query($queryParams);
}

// Log the API URL for debugging (remove in production)
error_log("API URL: " . $apiUrl);

// Fetch data from API
$response = file_get_contents($apiUrl);
$data = json_decode($response, true);
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
 <link rel="icon" href="assets/favicon.png" />
<title>Dropshipper Details - Admin Portal</title>
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
<style>
:root {
    --primary-color: #6366f1;
    --secondary-color: #4f46e5;
    --accent-color: #10b981;
    --text-primary: #111827;
    --text-secondary: #6b7280;
    --border-color: #e5e7eb;
    --background-light: #f9fafb;
    --success-color: #10b981;
    --warning-color: #f59e0b;
    --error-color: #dc2626;
    --white: #ffffff;
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

/* Sidebar */
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
color: var(--primary-color);
border-right: 3px solid var(--primary-color);
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

/* Overlay for mobile */
.sidebar-overlay {
display: none;
position: fixed;
top: 0;
left: 0;
width: 100%;
height: 100%;
}

/* Main content */
.main {
  margin-left: 280px;
  padding: 30px;
  min-height: 100vh;
  transition: margin-left 0.3s ease;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
}

.header {
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  color: white;
  padding: 30px 40px;
  border-radius: 20px;
  margin-bottom: 30px;
  box-shadow: 0 8px 25px rgba(99, 102, 241, 0.2);
  position: relative;
  overflow: hidden;
}

.header::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(255,255,255,0.05)" stroke-width="1"/></pattern></defs><rect width="100" height="100" fill="url(%23grid)"/></svg>');
  opacity: 0.5;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  position: relative;
  z-index: 1;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 20px;
}

.logo-section {
  position: relative;
}

.header-logo {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  object-fit: contain;
  background: rgba(255,255,255,0.95);
  padding: 8px;
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);
}

.logo-fallback {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  background: rgba(255,255,255,0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  color: white;
}

.header-text h1 {
  font-size: 2.2rem;
  font-weight: 700;
  margin-bottom: 5px;
}

.header-text p {
  font-size: 1rem;
  opacity: 0.9;
  margin: 0;
}

.header-right {
  display: flex;
  align-items: center;
}

.header-actions {
  display: flex;
  gap: 12px;
}

.action-btn {
  background: rgba(255,255,255,0.15);
  color: white;
  border: 1px solid rgba(255,255,255,0.3);
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}

.action-btn:hover {
  background: rgba(255,255,255,0.25);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

.stats-bar {
  background: white;
  border-radius: 16px;
  padding: 25px;
  margin-bottom: 25px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.08);
  display: flex;
  justify-content: space-around;
  flex-wrap: wrap;
  gap: 24px;
  border: 1px solid var(--border-color);
justify-content: space-around;
flex-wrap: wrap;
gap: 24px;
border: 1px solid var(--border-color);
}

.stat-item {
text-align: center;
padding: 15px;
}

.stat-number {
font-size: 2rem;
font-weight: bold;
color: var(--primary-color);
display: block;
}

.stat-label {
color: var(--text-secondary);
font-size: 0.9rem;
margin-top: 5px;
}

.table-container {
background: white;
border-radius: 16px;
box-shadow: 0 4px 20px rgba(0,0,0,0.08);
overflow: hidden;
margin-bottom: 30px;
border: 1px solid var(--border-color);
}

.table-header {
background: var(--primary-color);
color: var(--white);
padding: 25px;
text-align: center;
}

.table-header h2 {
font-size: 1.8rem;
font-weight: 600;
margin-bottom: 10px;
}

/* Enhanced Search and Filter Styles */
.search-filter-container {
padding: 20px;
background: #f8fafc;
border-bottom: 1px solid var(--border-color);
}

.search-section {
margin-bottom: 15px;
}

.search-box-wrapper {
position: relative;
max-width: 500px;
}

.search-box {
width: 100%;
padding: 15px 50px 15px 20px;
border: 2px solid var(--border-color);
border-radius: 12px;
font-size: 16px;
outline: none;
transition: all 0.3s ease;
background: var(--white);
color: var(--text-primary);
box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}

.search-box:focus {
border-color: var(--primary-color);
box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1);
transform: translateY(-2px);
}

.search-icon {
position: absolute;
right: 20px;
top: 50%;
transform: translateY(-50%);
color: var(--text-secondary);
font-size: 18px;
}

.filter-section {
display: flex;
align-items: center;
gap: 20px;
flex-wrap: wrap;
}

.filter-group {
display: flex;
align-items: center;
gap: 8px;
}

.filter-group label {
font-size: 14px;
font-weight: 500;
color: var(--text-primary);
white-space: nowrap;
}

.filter-select {
padding: 8px 12px;
border: 2px solid var(--border-color);
border-radius: 8px;
font-size: 14px;
background: white;
color: var(--text-primary);
cursor: pointer;
transition: all 0.3s ease;
min-width: 120px;
}

.filter-select:focus {
border-color: var(--primary-color);
outline: none;
box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
}

.filter-clear-btn {
background: #ef4444;
color: white;
border: none;
padding: 8px 16px;
border-radius: 8px;
font-size: 14px;
font-weight: 500;
cursor: pointer;
transition: all 0.3s ease;
display: flex;
align-items: center;
gap: 6px;
}

.filter-clear-btn:hover {
background: #dc2626;
transform: translateY(-2px);
box-shadow: 0 4px 12px rgba(239, 68, 68, 0.3);
}

.btn-plan {
background: linear-gradient(135deg, #3b82f6, #1d4ed8);
color: white;
border: none;
padding: 8px 16px;
border-radius: 8px;
font-size: 12px;
font-weight: 600;
cursor: pointer;
transition: all 0.3s ease;
display: inline-flex;
align-items: center;
gap: 6px;
position: relative;
overflow: hidden;
}

.btn-plan::before {
content: '';
position: absolute;
top: 0;
left: -100%;
width: 100%;
height: 100%;
background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
transition: left 0.5s;
}

.btn-plan:hover::before {
left: 100%;
}

.btn-plan:hover {
background: linear-gradient(135deg, #2563eb, #1e40af);
transform: translateY(-2px);
box-shadow: 0 8px 20px rgba(59, 130, 246, 0.4);
}

.id-badge {
text-align: center;
padding: 8px;
}

.id-badge strong {
font-size: 16px;
font-weight: 700;
color: var(--primary-color);
background: rgba(99, 102, 241, 0.1);
padding: 6px 12px;
border-radius: 8px;
border: 1px solid rgba(99, 102, 241, 0.2);
}

.table-wrapper {
overflow-x: auto;
max-height: 600px;
overflow-y: auto;
}

table {
width: 100%;
border-collapse: collapse;
font-size: 14px;
}

th {
background: var(--primary-color);
color: var(--white);
padding: 18px 12px;
text-align: left;
font-weight: 600;
position: sticky;
top: 0;
z-index: 10;
white-space: nowrap;
}

td {
padding: 15px 12px;
border-bottom: 1px solid var(--border-color);
vertical-align: middle;
word-wrap: break-word;
max-width: 200px;
}

tr:hover {
background: var(--background-light);
transition: background 0.2s ease;
}

.seller-info {
display: flex;
align-items: center;
gap: 10px;
}

.seller-avatar {
width: 40px;
height: 40px;
border-radius: 50%;
background: var(--primary-color);
display: flex;
align-items: center;
justify-content: center;
color: var(--white);
font-weight: bold;
font-size: 16px;
}

.seller-details h4 {
color: var(--text-primary);
margin: 0;
font-size: 14px;
}

.seller-details p {
color: var(--text-secondary);
margin: 0;
font-size: 12px;
}

.status-badge {
padding: 6px 12px;
border-radius: 20px;
font-size: 12px;
font-weight: 500;
background: var(--success-color);
color: var(--white);
}

.contact-info {
display: flex;
flex-direction: column;
gap: 4px;
}

.contact-item {
display: flex;
align-items: center;
gap: 8px;
color: var(--text-primary);
font-size: 13px;
}

.contact-item i {
color: var(--text-secondary);
width: 14px;
}

.password-field {
position: relative;
}

.password-toggle {
cursor: pointer;
color: var(--text-secondary);
margin-left: 8px;
transition: color 0.2s ease;
}

.password-toggle:hover {
color: var(--primary-color);
}

.password-hidden {
color: var(--text-secondary);
}

.date-badge {
background: var(--background-light);
color: var(--text-primary);
padding: 4px 8px;
border-radius: 8px;
font-size: 12px;
font-weight: 500;
border: 1px solid var(--border-color);
}

.no-data {
text-align: center;
padding: 60px 20px;
color: var(--text-secondary);
}

.no-data i {
font-size: 4rem;
color: var(--text-secondary);
margin-bottom: 20px;
opacity: 0.5;
}

.no-data h3 {
margin-bottom: 10px;
color: var(--text-primary);
}

.loading {
text-align: center;
padding: 40px;
color: var(--text-secondary);
}

.loading i {
font-size: 2rem;
animation: spin 1s linear infinite;
color: var(--primary-color);
}

@keyframes spin {
from { transform: rotate(0deg); }
to { transform: rotate(360deg); }
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

.main-content {
margin-left: 0;
padding: 80px 20px 20px 20px;
}

.container {
padding: 0;
}

.header h1 {
font-size: 1.8rem;
}

.stats-bar {
flex-direction: column;
text-align: center;
}

.stat-item {
border-bottom: 1px solid #e1e8ed;
padding-bottom: 15px;
}

.stat-item:last-child {
border-bottom: none;
}

table {
font-size: 12px;
}

th, td {
padding: 10px 8px;
}

.seller-info {
flex-direction: column;
text-align: center;
}

.seller-avatar {
align-self: center;
}

.user-profile {
position: relative;
padding: 16px 20px;
}
}

@media (max-width: 480px) {
.header {
padding: 20px;
}

.header h1 {
font-size: 1.5rem;
}

.table-container {
border-radius: 15px;
}

.sidebar {
width: 100%;
}

th, td {
padding: 8px 6px;
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
             <div style="padding: 8px 20px; font-size: 12px; font-weight: 600; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;">DROPSHIPPER</div>
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
            <div style="display: flex; align-items: center; gap: 12px; padding: 12px 20px; color: #2563eb; background-color: #eff6ff; border-right: 3px solid #2563eb; font-size: 14px; font-weight: 500;">
                <i class="fas fa-users" style="width: 20px; text-align: center; font-size: 16px;"></i>
                <span>Dropshippers Details</span>
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
<div class="container">
<!-- Enhanced Header Section -->
<div class="header">
    <div class="header-content">
        <div class="header-left">
            <div class="logo-section">
                <img src="https://dropshipping.deodap.com/images/logo-2.jpg" alt="Company Logo" class="header-logo" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                <div class="logo-fallback" style="display: none;">
                    <i class="fas fa-store"></i>
                </div>
            </div>
            <div class="header-text">
                <h1>Dropshipper Management</h1>
                <p>Monitor and manage your registered dropshippers</p>
            </div>
        </div>
        <div class="header-right">
            <div class="header-actions">
                <button class="action-btn export-btn" onclick="exportData()">
                    <i class="fas fa-download"></i>
                    Export Data
                </button>
                <button class="action-btn refresh-btn" onclick="refreshData()">
                    <i class="fas fa-sync-alt"></i>
                    Refresh
                </button>
            </div>
        </div>
    </div>
</div>

<!-- Stats Bar -->
<div class="stats-bar">
<div class="stat-item">
<span class="stat-number">
<?php echo ($data && $data['success'] && isset($data['dropshippers'])) ? count($data['dropshippers']) : '0'; ?>
</span>
<div class="stat-label">Total Dropshippers</div>
</div>
<div class="stat-item">
<span class="stat-number">
<?php
if ($data && $data['success'] && isset($data['dropshippers'])) {
echo count(array_filter($data['dropshippers'], function($d) {
return !empty($d['created_at']) && strtotime($d['created_at']) > strtotime('-30 days');
}));
} else {
echo '0';
}
?>
</span>
<div class="stat-label">New This Month</div>
</div>
<div class="stat-item">
<span class="stat-number">
<?php
if ($data && $data['success'] && isset($data['dropshippers'])) {
echo count(array_filter($data['dropshippers'], function($d) {
return !empty($d['email']);
}));
} else {
echo '0';
}
?>
</span>
<div class="stat-label">Verified Emails</div>
</div>
</div>

<!-- Table Container -->
<div class="table-container">
<div class="table-header">
<h2><i class="fas fa-users"></i> Registered Dropshippers</h2>
</div>

<!-- Enhanced Search and Filter Section -->
<div class="search-filter-container">
    <div class="search-section">
        <div class="search-box-wrapper">
            <input type="text" class="search-box" id="searchInput" placeholder="Search by name, email, store, or contact...">
            <i class="fas fa-search search-icon"></i>
        </div>
    </div>
    <div class="filter-section">
        <div class="filter-group">
            <label for="statusFilter">Status:</label>
            <select id="statusFilter" class="filter-select">
                <option value="">All Status</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
            </select>
        </div>
        <div class="filter-group">
            <label for="dateFilter">Joined:</label>
            <select id="dateFilter" class="filter-select">
                <option value="">All Time</option>
                <option value="today">Today</option>
                <option value="week">This Week</option>
                <option value="month">This Month</option>
                <option value="year">This Year</option>
            </select>
        </div>
        <button class="filter-clear-btn" onclick="clearFilters()">
            <i class="fas fa-times"></i>
            Clear Filters
        </button>
    </div>
</div>

<!-- Table -->
<div class="table-wrapper">
<?php if ($data && $data['success'] && count($data['dropshippers']) > 0): ?>
<table id="dropshipperTable">
<thead>
<tr>
<th><i class="fas fa-hashtag"></i> ID</th>
<th><i class="fas fa-id-badge"></i> Seller</th>
<th><i class="fas fa-store-alt"></i> Store Info</th>
<th><i class="fas fa-address-book"></i> Contact</th>
<th><i class="fas fa-certificate"></i> CRN</th>
<th><i class="fas fa-user"></i> Login</th>
<th><i class="fas fa-calendar"></i> Joined</th>
<th><i class="fas fa-check-circle"></i> Status</th>
<th><i class="fas fa-tasks"></i> Plans</th>
</tr>
</thead>
<tbody>
<?php foreach ($data['dropshippers'] as $d): ?>
<tr>
<td>
<div class="id-badge">
<strong><?= htmlspecialchars($d['id']); ?></strong>
</div>
</td>
<td>
<div class="seller-info">
<div class="seller-avatar">
<?= strtoupper(substr(htmlspecialchars($d['seller_name']), 0, 1)); ?>
</div>
<div class="seller-details">
<h4><?= htmlspecialchars($d['seller_name']); ?></h4>
<p>ID: <?= htmlspecialchars($d['seller_id']); ?></p>
</div>
</div>
</td>
<td>
<strong><?= htmlspecialchars($d['store_name']); ?></strong>
</td>


<td>
<div class="contact-info">
<div class="contact-item">
<i class="fas fa-phone"></i>
<?= htmlspecialchars($d['contact_number']); ?>
</div>
<div class="contact-item">
<i class="fas fa-envelope"></i>
<?= htmlspecialchars($d['email']); ?>
</div>
</div>
</td>
<td>
<code><?= htmlspecialchars($d['crn']); ?></code>
</td>
<td>
<div class="contact-info">
<div class="contact-item">
<i class="fas fa-user"></i>
<?= htmlspecialchars($d['username']); ?>
</div>
<div class="contact-item password-field">
<i class="fas fa-lock"></i>
<span class="password-hidden">••••••••</span>
<i class="fas fa-eye password-toggle" onclick="togglePassword(this, '<?= htmlspecialchars($d['plain_password']); ?>')"></i>
</div>
</div>
</td>
<td>
<div class="date-badge">
<?= date('M d, Y', strtotime(htmlspecialchars($d['created_at']))); ?>
</div>
</td>
<td>
<span class="status-badge">Active</span>
</td>
<td>
<button class="btn-plan" onclick="viewDropshipperPlans(<?= htmlspecialchars($d['id']); ?>)">
<i class="fas fa-tasks"></i> View Plans
</button>
</td>
</tr>
<?php endforeach; ?>
</tbody>
</table>
<?php else: ?>
<div class="no-data">
<i class="fas fa-inbox"></i>
<h3>No Dropshippers Found</h3>
<p>There are currently no registered dropshippers in the system.</p>
</div>
<?php endif; ?>
</div>
</div>
</div>

<script>
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

// Navigation item click handler - allow normal navigation
document.querySelectorAll('.nav-item').forEach(item => {
item.addEventListener('click', function(e) {
// Only prevent default for items without href or with # href
if (!this.href || this.href.includes('#')) {
e.preventDefault();
}

// Close sidebar on mobile after navigation
if (window.innerWidth <= 768) {
closeSidebar();
}
});
});

// Search functionality
document.getElementById('searchInput').addEventListener('keyup', applyFilters);

// Enhanced search and filter functionality
let allRows = [];

function initializeTable() {
    allRows = Array.from(document.querySelectorAll('#dropshipperTable tbody tr'));
}

function applyFilters() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const statusFilter = document.getElementById('statusFilter').value.toLowerCase();
    const dateFilter = document.getElementById('dateFilter').value;
    
    allRows.forEach(row => {
        const text = row.textContent.toLowerCase();
        const matchesSearch = text.includes(searchTerm);
        
        // Status filter (assuming all are active for now)
        const matchesStatus = !statusFilter || statusFilter === 'active';
        
        // Date filter
        let matchesDate = true;
        if (dateFilter) {
            const dateCell = row.querySelector('td:nth-child(6)'); // Joined date column
            if (dateCell) {
                const rowDate = new Date(dateCell.textContent.trim());
                const now = new Date();
                
                switch(dateFilter) {
                    case 'today':
                        matchesDate = rowDate.toDateString() === now.toDateString();
                        break;
                    case 'week':
                        const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
                        matchesDate = rowDate >= weekAgo;
                        break;
                    case 'month':
                        const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
                        matchesDate = rowDate >= monthAgo;
                        break;
                    case 'year':
                        matchesDate = rowDate.getFullYear() === now.getFullYear();
                        break;
                }
            }
        }
        
        if (matchesSearch && matchesStatus && matchesDate) {
            row.style.display = '';
        } else {
            row.style.display = 'none';
        }
    });
    
    updateResultsCount();
}

function updateResultsCount() {
    const visibleRows = allRows.filter(row => row.style.display !== 'none');
    const totalRows = allRows.length;
    
    // Update table header with results count
    const tableHeader = document.querySelector('.table-header h2');
    if (tableHeader) {
        tableHeader.innerHTML = `<i class="fas fa-users"></i> Registered Dropshippers (${visibleRows.length} of ${totalRows})`;
    }
}

function clearFilters() {
    document.getElementById('searchInput').value = '';
    document.getElementById('statusFilter').value = '';
    document.getElementById('dateFilter').value = '';
    applyFilters();
}

function exportData() {
    const visibleRows = allRows.filter(row => row.style.display !== 'none');
    
    if (visibleRows.length === 0) {
        alert('No data to export');
        return;
    }
    
    let csvContent = "Seller Name,Store Name,Contact Number,Email,CRN,Username,Joined Date\n";
    
    visibleRows.forEach(row => {
        const cells = row.querySelectorAll('td');
        const sellerName = cells[0].querySelector('.seller-details h4').textContent;
        const storeName = cells[1].textContent.trim();
        const contactNumber = cells[2].querySelector('.contact-item:first-child').textContent.replace(/\s+/g, ' ').trim();
        const email = cells[2].querySelector('.contact-item:last-child').textContent.replace(/\s+/g, ' ').trim();
        const crn = cells[3].textContent.trim();
        const username = cells[4].querySelector('.contact-item:first-child').textContent.replace(/\s+/g, ' ').trim();
        const joinedDate = cells[5].textContent.trim();
        
        csvContent += `"${sellerName}","${storeName}","${contactNumber}","${email}","${crn}","${username}","${joinedDate}"\n`;
    });
    
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `dropshippers_${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
}

function refreshData() {
    const refreshBtn = document.querySelector('.refresh-btn');
    const icon = refreshBtn.querySelector('i');
    
    icon.classList.add('fa-spin');
    refreshBtn.disabled = true;
    
    setTimeout(() => {
        location.reload();
    }, 1000);
}

// Event listeners
document.getElementById('searchInput').addEventListener('keyup', applyFilters);
document.getElementById('statusFilter').addEventListener('change', applyFilters);
document.getElementById('dateFilter').addEventListener('change', applyFilters);

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    initializeTable();
    updateResultsCount();
});

// Password toggle functionality
function togglePassword(element, actualPassword) {
const passwordSpan = element.previousElementSibling;
const isHidden = passwordSpan.classList.contains('password-hidden');

if (isHidden) {
passwordSpan.textContent = actualPassword;
passwordSpan.classList.remove('password-hidden');
element.classList.remove('fa-eye');
element.classList.add('fa-eye-slash');
} else {
passwordSpan.textContent = '••••••••';
passwordSpan.classList.add('password-hidden');
element.classList.remove('fa-eye-slash');
element.classList.add('fa-eye');
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

// Simple page load handler
document.addEventListener('DOMContentLoaded', function() {
// Page is ready - no heavy animations needed
console.log('Dropshipper details page loaded');
})

// View dropshipper plans function
function viewDropshipperPlans(dropshipperId) {
    // Navigate to the dropshipper_wise_plan.php page with the dropshipper ID in the same tab
    window.location.href = `dropshipper_wise_plan.php?dropshipper_id=${dropshipperId}`;
}
</script>
</body>
</html>
