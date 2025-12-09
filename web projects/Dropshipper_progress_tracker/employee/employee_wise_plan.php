<?php 
// dashboard.php (Admin Dashboard)
session_start();

// Check if user is logged in
if (!isset($_SESSION['user'])) {
    header("Location: login.php");
    exit();
}

$user = $_SESSION['user'];
$emp_id = $user['emp_id'] ?? null;

// Get employee ID from URL parameter if available
$url_emp_id = $_GET['emp_id'] ?? $emp_id;

// Role check (only admin allowed)
if (!isset($user['role']) || $user['role'] !== 'admin') {
    header("Location: employee_dashboard.php");
    exit();
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Employee Plan Management</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            --success-gradient: linear-gradient(135deg, #84fab0 0%, #8fd3f4 100%);
            --info-gradient: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%);
            --warning-gradient: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%);
            --card-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
            --card-hover-shadow: 0 15px 40px rgba(0, 0, 0, 0.15);
        }

        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            min-height: 100vh;
        }

        .main-header {
            background: var(--primary-gradient);
            color: white;
            border-radius: 20px;
            padding: 2rem;
            margin-bottom: 2rem;
            box-shadow: var(--card-shadow);
        }

        .main-header h1 {
            font-weight: 700;
            margin: 0;
        }

        .main-header p {
            margin: 0.5rem 0 0;
            opacity: 0.9;
        }

        .card {
            border: none;
            border-radius: 20px;
            box-shadow: var(--card-shadow);
            transition: all 0.3s ease;
            overflow: hidden;
        }

        .card:hover {
            transform: translateY(-5px);
            box-shadow: var(--card-hover-shadow);
        }

        .employee-info-card {
            background: var(--success-gradient);
            color: white;
        }

        .employee-info-card .card-body {
            padding: 2rem;
        }

        .stats-card {
            background: var(--info-gradient);
            color: #2c3e50;
        }

        .btn-custom {
            border-radius: 50px;
            padding: 12px 30px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            transition: all 0.3s ease;
        }

        .btn-custom:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2);
        }

        .btn-primary.btn-custom {
            background: var(--primary-gradient);
            border: none;
        }

        .btn-success.btn-custom {
            background: var(--success-gradient);
            border: none;
        }

        .nav-tabs {
            border-bottom: none;
            gap: 10px;
            margin-bottom: 2rem;
        }

        .nav-tabs .nav-link {
            border: none;
            border-radius: 50px;
            background: white;
            color: #6c757d;
            font-weight: 600;
            padding: 15px 25px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
            transition: all 0.3s ease;
        }

        .nav-tabs .nav-link:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
        }

        .nav-tabs .nav-link.active {
            background: var(--primary-gradient);
            color: white;
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
        }

        .employee-avatar {
            width: 80px;
            height: 80px;
            background: rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 2rem;
            font-weight: bold;
            margin-right: 1.5rem;
        }

        .step-card {
            border-left: 4px solid #17a2b8;
            transition: all 0.3s ease;
        }

        .step-card:hover {
            border-left-color: #007bff;
        }

        .step-image {
            max-width: 100px;
            max-height: 100px;
            object-fit: cover;
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
        }

        .accordion-button:not(.collapsed) {
            color: white;
            background: var(--primary-gradient);
            border-color: transparent;
        }

        .accordion-button {
            border-radius: 15px 15px 0 0;
            font-weight: 600;
        }

        .accordion-item {
            border: none;
            border-radius: 15px;
            overflow: hidden;
            box-shadow: var(--card-shadow);
            margin-bottom: 1rem;
        }

        .badge {
            font-size: 0.85em;
            padding: 8px 12px;
            border-radius: 50px;
        }

        .alert {
            border: none;
            border-radius: 15px;
            box-shadow: var(--card-shadow);
        }

        .table {
            border-radius: 15px;
            overflow: hidden;
            box-shadow: var(--card-shadow);
        }

        .table thead th {
            background: var(--primary-gradient);
            color: white;
            font-weight: 600;
            border: none;
        }

        .loading {
            display: none;
        }

        .dropdown-menu {
            border: none;
            border-radius: 15px;
            box-shadow: var(--card-shadow);
        }

        .dropdown-item:hover {
            background: var(--primary-gradient);
            color: white;
            border-radius: 10px;
            margin: 2px;
        }

        .form-select, .form-control {
            border-radius: 15px;
            border: 2px solid #e9ecef;
            padding: 12px 15px;
        }

        .form-select:focus, .form-control:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);
        }

        .stat-number {
            font-size: 3rem;
            font-weight: 700;
            margin-bottom: 0;
        }

        .stat-label {
            font-size: 0.9rem;
            font-weight: 500;
            opacity: 0.8;
        }

        @media (max-width: 768px) {
            .main-header {
                padding: 1.5rem;
                text-align: center;
            }
            
            .employee-avatar {
                margin: 0 0 1rem 0;
            }
            
            .nav-tabs {
                flex-direction: column;
            }
        }

        .pulse {
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
        }
    </style>
</head>
<body>
    <div class="container-fluid mt-4 px-4">
        <!-- Main Header -->
        <div class="main-header text-center">
            <h1><i class="bi bi-people-fill me-3"></i>Employee Plan Management System</h1>
            <p class="mb-0">Advanced plan tracking and assignment dashboard</p>
        </div>

        <!-- Employee Info Section (Always Visible) -->
        <div class="row mb-4" id="employeeInfoSection">
            <div class="col-md-8 mb-4">
                <div class="card employee-info-card h-100">
                    <div class="card-body d-flex align-items-center">
                        <div class="employee-avatar" id="employeeAvatar">
                            <i class="bi bi-person"></i>
                        </div>
                        <div class="flex-grow-1">
                            <h3 class="mb-1" id="employeeName">Loading...</h3>
                            <p class="mb-2 opacity-75" id="employeeCode">Employee Code: ---</p>
                            <div class="d-flex gap-2 flex-wrap">
                                <span class="badge bg-light text-dark" id="employeeId">ID: ---</span>
                                <span class="badge bg-warning text-dark" id="totalAssignedPlans">Plans: 0</span>
                                <span class="badge bg-info text-dark" id="completedStepsCount">Completed: 0</span>
                            </div>
                        </div>
                        <div class="text-end">
                            <button class="btn btn-light btn-custom pulse" onclick="loadEmployeePlans()">
                                <i class="bi bi-arrow-clockwise me-2"></i>Refresh Plans
                            </button>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-4 mb-4">
                <div class="card stats-card h-100">
                    <div class="card-body text-center">
                        <h5 class="card-title mb-3">
                            <i class="bi bi-graph-up me-2"></i>System Stats
                        </h5>
                        <div class="row">
                            <div class="col-6">
                                <div class="stat-number text-primary" id="totalEmployees">-</div>
                                <div class="stat-label">Employees</div>
                            </div>
                            <div class="col-6">
                                <div class="stat-number text-success" id="totalPlans">-</div>
                                <div class="stat-label">Plans</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Navigation Tabs -->
        <ul class="nav nav-tabs justify-content-center" id="mainTabs" role="tablist">
            <li class="nav-item" role="presentation">
                <button class="nav-link active" id="dashboard-tab" data-bs-toggle="tab" data-bs-target="#dashboard" type="button" role="tab" aria-controls="dashboard" aria-selected="true">
                    <i class="bi bi-speedometer2 me-2"></i>Employee Plans
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="assign-tab" data-bs-toggle="tab" data-bs-target="#assign" type="button" role="tab" aria-controls="assign" aria-selected="false">
                    <i class="bi bi-plus-circle-fill me-2"></i>Assign New Plan
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="plans-tab" data-bs-toggle="tab" data-bs-target="#plans" type="button" role="tab" aria-controls="plans" aria-selected="false">
                    <i class="bi bi-card-list me-2"></i>Available Plans
                </button>
            </li>
        </ul>

        <!-- Tab Content -->
        <div class="tab-content" id="mainTabsContent">
            <!-- Employee Plans Tab -->
            <div class="tab-pane fade show active" id="dashboard" role="tabpanel">
                <div class="row">
                    <div class="col-12">
                        <div class="card">
                            <div class="card-header" style="background: var(--primary-gradient); color: white;">
                                <h5 class="mb-0">
                                    <i class="bi bi-person-badge me-2"></i>
                                    Assigned Plans & Progress
                                </h5>
                            </div>
                            <div class="card-body">
                                <div id="employeePlansTable">
                                    <div class="text-center py-5">
                                        <div class="spinner-border text-primary" role="status">
                                            <span class="visually-hidden">Loading...</span>
                                        </div>
                                        <p class="mt-3">Loading employee plans...</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Assign Plan Tab -->
            <div class="tab-pane fade" id="assign" role="tabpanel">
                <div class="row justify-content-center">
                    <div class="col-lg-8">
                        <div class="card">
                            <div class="card-header" style="background: var(--success-gradient); color: white;">
                                <h5 class="mb-0">
                                    <i class="bi bi-plus-circle-fill me-2"></i>Assign Plan Steps
                                </h5>
                            </div>
                            <div class="card-body">
                                <form id="assignPlanForm">
                                    <input type="hidden" id="assignEmployeeId" value="<?php echo htmlspecialchars($url_emp_id); ?>">
                                    
                                    <div class="mb-4">
                                        <label for="assignPlanSelect" class="form-label fw-bold">Select Plan</label>
                                        <select class="form-select" id="assignPlanSelect" required onchange="loadPlanStepsForAssignment()">
                                            <option value="">Choose a plan to assign...</option>
                                        </select>
                                    </div>

                                    <div id="planStepsSelection" style="display: none;" class="mb-4">
                                        <label class="form-label fw-bold">Select Steps to Assign:</label>
                                        <div id="availableSteps" class="border rounded p-3" style="max-height: 400px; overflow-y: auto; background: #f8f9fa;">
                                            <!-- Steps will be loaded here -->
                                        </div>
                                    </div>

                                    <div class="text-center">
                                        <button type="submit" class="btn btn-success btn-custom">
                                            <i class="bi bi-check-circle me-2"></i>Assign Selected Steps
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Plans Tab -->
            <div class="tab-pane fade" id="plans" role="tabpanel">
                <div class="card">
                    <div class="card-header" style="background: var(--info-gradient); color: #2c3e50;">
                        <h5 class="mb-0">
                            <i class="bi bi-card-list me-2"></i>Available Plans Library
                        </h5>
                    </div>
                    <div class="card-body">
                        <div id="plansTable">
                            <div class="text-center py-5">
                                <div class="spinner-border text-info" role="status">
                                    <span class="visually-hidden">Loading...</span>
                                </div>
                                <p class="mt-3">Loading available plans...</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Alert Container -->
        <div id="alertContainer" class="position-fixed" style="top: 20px; right: 20px; z-index: 1050; max-width: 400px;"></div>

        <!-- Loading Overlay -->
        <div id="loadingOverlay" class="loading position-fixed top-0 start-0 w-100 h-100" style="background: rgba(0,0,0,0.7); z-index: 1060;">
            <div class="d-flex justify-content-center align-items-center h-100">
                <div class="text-center text-white">
                    <div class="spinner-border mb-3" role="status" style="width: 3rem; height: 3rem;">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                    <h5>Processing...</h5>
                    <p>Please wait while we load your data</p>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // API Configuration
        const API_URL = 'https://customprint.deodap.com/api_dropshipper_tracker/emp_plan_step.php';
        const currentEmpId = <?php echo json_encode($url_emp_id); ?>;

        // Global variables
        let employees = [];
        let plans = [];
        let currentEmployeeData = null;

        // Initialize page
        document.addEventListener('DOMContentLoaded', function() {
            console.log('DOM loaded, current employee ID:', currentEmpId);
            
            // Restore active tab from localStorage
            const activeTab = localStorage.getItem('activeTab');
            if (activeTab) {
                const tabButton = document.querySelector(`button[data-bs-target="${activeTab}"]`);
                if (tabButton) {
                    const tab = new bootstrap.Tab(tabButton);
                    tab.show();
                }
            }
            
            // Save tab state on change
            document.querySelectorAll('button[data-bs-toggle="tab"]').forEach(tab => {
                tab.addEventListener('shown.bs.tab', function(event) {
                    const target = event.target.getAttribute('data-bs-target');
                    localStorage.setItem('activeTab', target);
                    
                    // Load content based on active tab
                    if (target === '#plans') {
                        displayPlansTable();
                    }
                });
            });
            
            // Initialize with error handling
            initializeData().catch(error => {
                console.error('Initialization failed:', error);
                showAlert('Failed to initialize dashboard: ' + error.message, 'danger');
            });
        });

        // Initialize data
        async function initializeData() {
            showLoading(true);
            try {
                await loadEmployees();
                await loadPlans();
                await loadCurrentEmployeeInfo();
                await loadEmployeePlans();
                updateStats();
                setupEventListeners();
            } finally {
                showLoading(false);
            }
        }

        // Setup event listeners
        function setupEventListeners() {
            document.getElementById('assignPlanForm').addEventListener('submit', handleAssignPlan);
        }

        // Load current employee information
        async function loadCurrentEmployeeInfo() {
            if (!currentEmpId) {
                showAlert('No employee ID provided', 'warning');
                return;
            }

            try {
                const result = await apiRequest({ 
                    action: 'get_employee_info', 
                    emp_id: parseInt(currentEmpId) 
                });

                if (result && result.success && result.employee) {
                    currentEmployeeData = result.employee;
                    displayEmployeeInfo(currentEmployeeData);
                } else {
                    // Fallback to find employee in the loaded employees array
                    const employee = employees.find(emp => emp.emp_id == currentEmpId);
                    if (employee) {
                        currentEmployeeData = employee;
                        displayEmployeeInfo(employee);
                    } else {
                        showAlert('Employee not found', 'danger');
                    }
                }
            } catch (error) {
                console.error('Error loading employee info:', error);
                showAlert('Failed to load employee information', 'danger');
            }
        }

        // Display employee information
        function displayEmployeeInfo(employee) {
            const nameEl = document.getElementById('employeeName');
            const codeEl = document.getElementById('employeeCode');
            const idEl = document.getElementById('employeeId');
            const avatarEl = document.getElementById('employeeAvatar');

            if (nameEl) nameEl.textContent = employee.emp_name || 'Unknown Employee';
            if (codeEl) codeEl.textContent = `Employee Code: ${employee.emp_code || '---'}`;
            if (idEl) idEl.textContent = `ID: ${employee.emp_id || '---'}`;
            
            // Set avatar with first letter of name
            if (avatarEl && employee.emp_name) {
                avatarEl.innerHTML = employee.emp_name.charAt(0).toUpperCase();
            }
        }

        // API request function
        async function apiRequest(data) {
            try {
                console.log('API Request:', data);
                const response = await fetch(API_URL, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(data)
                });

                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }

                const result = await response.json();
                console.log('API Response:', result);
                return result;
            } catch (error) {
                console.error('API request failed:', error);
                throw error;
            }
        }

        // Load employees
        async function loadEmployees() {
            try {
                const result = await apiRequest({ action: 'get_employees' });
                if (result && result.success) {
                    employees = result.employees || [];
                }
            } catch (error) {
                console.error('Error loading employees:', error);
            }
        }

        // Load plans
        async function loadPlans() {
            try {
                const result = await apiRequest({ action: 'get_plans' });
                if (result && result.success) {
                    plans = result.plans || [];
                    populatePlanSelects();
                }
            } catch (error) {
                console.error('Error loading plans:', error);
            }
        }

        // Populate plan selects
        function populatePlanSelects() {
            const select = document.getElementById('assignPlanSelect');
            if (select) {
                select.innerHTML = '<option value="">Choose a plan to assign...</option>';
                plans.forEach(plan => {
                    select.innerHTML += `<option value="${plan.id}">${plan.name} - $${plan.price}</option>`;
                });
            }
        }

        // Load employee plans
        async function loadEmployeePlans() {
            if (!currentEmpId) return;

            try {
                const result = await apiRequest({ 
                    action: 'get_employee_plan_steps', 
                    emp_id: parseInt(currentEmpId) 
                });

                if (result && result.success) {
                    displayEmployeePlansWithSteps(result.plans_with_steps);
                    updateEmployeeStats(result.plans_with_steps);
                }
            } catch (error) {
                console.error('Error loading employee plans:', error);
                document.getElementById('employeePlansTable').innerHTML = 
                    '<div class="alert alert-danger"><i class="bi bi-exclamation-triangle"></i> Failed to load plans</div>';
            }
        }

        // Update employee stats
        function updateEmployeeStats(plansWithSteps) {
            const totalPlansEl = document.getElementById('totalAssignedPlans');
            const completedStepsEl = document.getElementById('completedStepsCount');

            let totalCompleted = 0;
            plansWithSteps.forEach(plan => {
                totalCompleted += plan.steps.filter(step => step.status === 'completed').length;
            });

            if (totalPlansEl) totalPlansEl.textContent = `Plans: ${plansWithSteps.length}`;
            if (completedStepsEl) completedStepsEl.textContent = `Completed: ${totalCompleted}`;
        }

        // Display employee plans with steps
        function displayEmployeePlansWithSteps(plansWithSteps) {
            const tableDiv = document.getElementById('employeePlansTable');

            if (plansWithSteps.length === 0) {
                tableDiv.innerHTML = `
                    <div class="text-center py-5">
                        <i class="bi bi-inbox display-1 text-muted"></i>
                        <h4 class="text-muted mt-3">No Plans Assigned</h4>
                        <p class="text-muted">This employee doesn't have any plans assigned yet.</p>
                        <button class="btn btn-primary btn-custom" onclick="switchToAssignTab()">
                            <i class="bi bi-plus-circle me-2"></i>Assign First Plan
                        </button>
                    </div>
                `;
                return;
            }

            let html = '<div class="accordion" id="plansAccordion">';

            plansWithSteps.forEach((plan, planIndex) => {
                const collapseId = `collapse-${plan.plan_id}`;
                const headingId = `heading-${plan.plan_id}`;
                
                const completedSteps = plan.steps.filter(step => step.status === 'completed').length;
                const pendingSteps = plan.steps.filter(step => step.status === 'pending').length;
                const inProgressSteps = plan.steps.filter(step => step.status === 'in_progress').length;
                const progressPercent = plan.steps.length > 0 ? Math.round((completedSteps / plan.steps.length) * 100) : 0;
                
                html += `
                    <div class="accordion-item mb-3">
                        <h2 class="accordion-header" id="${headingId}">
                            <button class="accordion-button ${planIndex === 0 ? '' : 'collapsed'}" type="button" 
                                    data-bs-toggle="collapse" data-bs-target="#${collapseId}" 
                                    aria-expanded="${planIndex === 0 ? 'true' : 'false'}" aria-controls="${collapseId}">
                                <div class="d-flex justify-content-between align-items-center w-100 me-3">
                                    <div>
                                        <strong>${plan.plan_name}</strong>
                                        <small class="d-block opacity-75">${plan.plan_description || 'No description'}</small>
                                        <div class="progress mt-2" style="height: 6px; width: 200px;">
                                            <div class="progress-bar" role="progressbar" style="width: ${progressPercent}%" aria-valuenow="${progressPercent}" aria-valuemin="0" aria-valuemax="100"></div>
                                        </div>
                                    </div>
                                    <div class="text-end">
                                        <span class="badge bg-light text-dark">$${plan.plan_price}</span>
                                        <div class="mt-1">
                                            <small class="badge bg-primary">${plan.steps.length} total</small>
                                            <small class="badge bg-success">${completedSteps} done</small>
                                            <small class="badge bg-warning text-dark">${inProgressSteps} active</small>
                                            <small class="badge bg-secondary">${pendingSteps} pending</small>
                                        </div>
                                    </div>
                                </div>
                            </button>
                        </h2>
                        <div id="${collapseId}" class="accordion-collapse collapse ${planIndex === 0 ? 'show' : ''}" 
                             aria-labelledby="${headingId}" data-bs-parent="#plansAccordion">
                            <div class="accordion-body">
                                <div class="d-flex justify-content-between align-items-center mb-3">
                                    <div>
                                        <span class="text-muted">Progress: ${progressPercent}% completed</span>
                                    </div>
                                    <button class="btn btn-outline-danger btn-sm" onclick="deletePlan(${currentEmpId}, ${plan.plan_id})">
                                        <i class="bi bi-trash me-1"></i>Remove Plan
                                    </button>
                                </div>
                                ${displayPlanSteps(plan.steps)}
                            </div>
                        </div>
                    </div>
                `;
            });

            html += '</div>';
            tableDiv.innerHTML = html;
        }

        // Display plan steps
        function displayPlanSteps(steps) {
            if (steps.length === 0) {
                return '<div class="alert alert-info">No steps assigned for this plan.</div>';
            }

            let html = '<div class="row">';
            
            steps.forEach(step => {
                const statusClass = getStatusClass(step.status);
                const statusIcon = getStatusIcon(step.status);
                
                html += `
                    <div class="col-lg-4 col-md-6 mb-3">
                        <div class="card step-card h-100">
                            <div class="card-body">
                                <div class="d-flex justify-content-between align-items-start mb-2">
                                    <h6 class="card-title">Step ${step.step_number}</h6>
                                    <div class="dropdown">
                                        <button class="btn btn-sm btn-outline-secondary dropdown-toggle" type="button" data-bs-toggle="dropdown">
                                            <i class="bi bi-gear"></i>
                                        </button>
                                        <ul class="dropdown-menu">
                                            <li><a class="dropdown-item" onclick="updateStepStatus(${step.employee_plan_step_id}, 'pending')">
                                                <i class="bi bi-clock me-2"></i>Mark Pending</a></li>
                                            <li><a class="dropdown-item" onclick="updateStepStatus(${step.employee_plan_step_id}, 'in_progress')">
                                                <i class="bi bi-play-circle me-2"></i>Mark In Progress</a></li>
                                            <li><a class="dropdown-item" onclick="updateStepStatus(${step.employee_plan_step_id}, 'completed')">
                                                <i class="bi bi-check-circle me-2"></i>Mark Completed</a></li>
                                            <li><hr class="dropdown-divider"></li>
                                            <li><a class="dropdown-item text-danger" onclick="deleteEmployeeStep(${step.employee_plan_step_id})">
                                                <i class="bi bi-trash me-2"></i>Remove Step</a></li>
                                        </ul>
                                    </div>
                                </div>
                                
                                <p class="card-text small mb-3">${step.step_description}</p>
                                
                                ${step.custom_description ? `
                                    <div class="mb-3">
                                        <small class="text-muted fw-bold">Custom Description:</small>
                                        <p class="small bg-light p-2 rounded mt-1">${step.custom_description}</p>
                                    </div>
                                ` : ''}
                                
                                ${step.step_image ? `
                                    <div class="mb-3 text-center">
                                        <small class="text-muted d-block mb-2">Step Image:</small>
                                        <img src="${step.step_image}" class="step-image" alt="Step image" onclick="showImageModal('${step.step_image}', 'Step ${step.step_number} Image')">
                                    </div>
                                ` : ''}
                                
                                ${step.custom_image ? `
                                    <div class="mb-3 text-center">
                                        <small class="text-muted d-block mb-2">Custom Image:</small>
                                        <img src="${step.custom_image}" class="step-image" alt="Custom step image" onclick="showImageModal('${step.custom_image}', 'Step ${step.step_number} Custom Image')">
                                    </div>
                                ` : ''}
                                
                                <div class="d-flex justify-content-between align-items-end">
                                    <span class="badge ${statusClass}">
                                        <i class="bi ${statusIcon} me-1"></i>${step.status.replace('_', ' ').toUpperCase()}
                                    </span>
                                    <small class="text-muted">${formatDate(step.updated_at)}</small>
                                </div>
                            </div>
                        </div>
                    </div>
                `;
            });
            
            html += '</div>';
            return html;
        }

        // Switch to assign tab
        function switchToAssignTab() {
            const assignTab = new bootstrap.Tab(document.getElementById('assign-tab'));
            assignTab.show();
        }

        // Load plan steps for assignment
        async function loadPlanStepsForAssignment() {
            const planId = document.getElementById('assignPlanSelect').value;
            
            if (!planId || !currentEmpId) {
                document.getElementById('planStepsSelection').style.display = 'none';
                return;
            }

            try {
                const result = await apiRequest({
                    action: 'get_available_plan_steps',
                    emp_id: parseInt(currentEmpId),
                    plan_id: parseInt(planId)
                });

                if (result && result.success) {
                    displayAvailableSteps(result.available_steps);
                    document.getElementById('planStepsSelection').style.display = 'block';
                } else {
                    document.getElementById('planStepsSelection').style.display = 'none';
                    showAlert('No available steps for this plan', 'info');
                }
            } catch (error) {
                console.error('Error loading plan steps:', error);
            }
        }

        // Display available steps for assignment
        function displayAvailableSteps(steps) {
            const container = document.getElementById('availableSteps');
            
            if (steps.length === 0) {
                container.innerHTML = `
                    <div class="alert alert-info text-center">
                        <i class="bi bi-info-circle me-2"></i>
                        All steps are already assigned to this employee.
                    </div>
                `;
                return;
            }

            let html = '';
            steps.forEach(step => {
                html += `
                    <div class="form-check mb-3 p-3 border rounded" style="background: white;">
                        <input class="form-check-input" type="checkbox" value="${step.step_id}" id="step_${step.step_id}" name="step_ids[]">
                        <label class="form-check-label d-flex align-items-start w-100" for="step_${step.step_id}">
                            <div class="flex-grow-1 ms-2">
                                <div class="fw-bold text-primary">Step ${step.step_number}</div>
                                <div class="text-muted">${step.step_description}</div>
                                ${step.step_image ? `
                                    <div class="mt-2">
                                        <span class="badge bg-light text-dark">
                                            <i class="bi bi-image me-1"></i>Has Image
                                        </span>
                                    </div>
                                ` : ''}
                            </div>
                        </label>
                    </div>
                `;
            });

            container.innerHTML = html;
        }

        // Handle assign plan form submission
        async function handleAssignPlan(event) {
            event.preventDefault();
            
            const planId = document.getElementById('assignPlanSelect').value;
            const selectedSteps = [];
            const checkboxes = document.querySelectorAll('input[name="step_ids[]"]:checked');
            
            checkboxes.forEach(checkbox => {
                selectedSteps.push(parseInt(checkbox.value));
            });

            if (!planId) {
                showAlert('Please select a plan', 'warning');
                return;
            }

            if (selectedSteps.length === 0) {
                showAlert('Please select at least one step to assign', 'warning');
                return;
            }

            try {
                showLoading(true);
                const result = await apiRequest({
                    action: 'add_plan',
                    emp_id: parseInt(currentEmpId),
                    plan_id: parseInt(planId),
                    step_ids: selectedSteps
                });

                if (result && result.success) {
                    showAlert('Selected steps assigned successfully!', 'success');
                    document.getElementById('assignPlanForm').reset();
                    document.getElementById('planStepsSelection').style.display = 'none';
                    
                    // Switch back to dashboard and reload plans
                    setTimeout(() => {
                        const dashboardTab = new bootstrap.Tab(document.getElementById('dashboard-tab'));
                        dashboardTab.show();
                        loadEmployeePlans();
                    }, 1500);
                } else {
                    showAlert(result ? result.message : 'Failed to assign steps', 'danger');
                }
            } catch (error) {
                showAlert('Error assigning steps: ' + error.message, 'danger');
            } finally {
                showLoading(false);
            }
        }

        // Update step status
        async function updateStepStatus(employeePlanStepId, newStatus) {
            try {
                showLoading(true);
                const result = await apiRequest({
                    action: 'update_step_status',
                    employee_plan_step_id: employeePlanStepId,
                    status: newStatus
                });

                if (result && result.success) {
                    showAlert(`Step status updated to ${newStatus.replace('_', ' ')}!`, 'success');
                    loadEmployeePlans();
                } else {
                    showAlert(result ? result.message : 'Failed to update step status', 'danger');
                }
            } catch (error) {
                showAlert('Error updating status: ' + error.message, 'danger');
            } finally {
                showLoading(false);
            }
        }

        // Delete employee step
        async function deleteEmployeeStep(employeePlanStepId) {
            if (!confirm('Are you sure you want to remove this step from the employee?')) {
                return;
            }

            try {
                showLoading(true);
                const result = await apiRequest({
                    action: 'delete_employee_step',
                    employee_plan_step_id: employeePlanStepId
                });

                if (result && result.success) {
                    showAlert('Step removed successfully!', 'success');
                    loadEmployeePlans();
                } else {
                    showAlert(result ? result.message : 'Failed to remove step', 'danger');
                }
            } catch (error) {
                showAlert('Error removing step: ' + error.message, 'danger');
            } finally {
                showLoading(false);
            }
        }

        // Delete plan from employee
        async function deletePlan(empId, planId) {
            if (!confirm('Are you sure you want to remove this entire plan from the employee? This will remove all associated steps.')) {
                return;
            }

            try {
                showLoading(true);
                const result = await apiRequest({
                    action: 'delete_plan',
                    emp_id: empId,
                    plan_id: planId
                });

                if (result && result.success) {
                    showAlert('Plan removed successfully!', 'success');
                    loadEmployeePlans();
                } else {
                    showAlert(result ? result.message : 'Failed to remove plan', 'danger');
                }
            } catch (error) {
                showAlert('Error removing plan: ' + error.message, 'danger');
            } finally {
                showLoading(false);
            }
        }

        // Display plans table
        function displayPlansTable() {
            const tableDiv = document.getElementById('plansTable');
            
            if (plans.length === 0) {
                tableDiv.innerHTML = `
                    <div class="text-center py-5">
                        <i class="bi bi-card-list display-1 text-muted"></i>
                        <h4 class="text-muted mt-3">No Plans Available</h4>
                        <p class="text-muted">No plans have been created yet.</p>
                    </div>
                `;
                return;
            }

            let html = `
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Plan ID</th>
                                <th>Name</th>
                                <th>Description</th>
                                <th>Price</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
            `;

            plans.forEach(plan => {
                html += `
                    <tr>
                        <td><span class="badge bg-primary">#${plan.id}</span></td>
                        <td><strong>${plan.name}</strong></td>
                        <td>${plan.description || 'No description available'}</td>
                        <td><span class="badge bg-success">${plan.price}</span></td>
                        <td>
                            <button class="btn btn-sm btn-outline-info" onclick="viewPlanSteps(${plan.id}, '${plan.name}')">
                                <i class="bi bi-list-check me-1"></i>View Steps
                            </button>
                        </td>
                    </tr>
                `;
            });

            html += '</tbody></table></div>';
            tableDiv.innerHTML = html;
        }

        // View plan steps
        async function viewPlanSteps(planId, planName) {
            try {
                showLoading(true);
                const result = await apiRequest({
                    action: 'get_plan_steps',
                    plan_id: planId
                });

                if (result && result.success) {
                    displayPlanStepsModal(result.steps, planName);
                } else {
                    showAlert('Failed to load plan steps', 'danger');
                }
            } catch (error) {
                showAlert('Error loading plan steps: ' + error.message, 'danger');
            } finally {
                showLoading(false);
            }
        }

        // Display plan steps in modal
        function displayPlanStepsModal(steps, planName) {
            let modal = document.getElementById('planStepsModal');
            if (!modal) {
                const modalHTML = `
                    <div class="modal fade" id="planStepsModal" tabindex="-1">
                        <div class="modal-dialog modal-lg">
                            <div class="modal-content">
                                <div class="modal-header" style="background: var(--primary-gradient); color: white;">
                                    <h5 class="modal-title">Plan Steps</h5>
                                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body" id="planStepsModalBody">
                                </div>
                            </div>
                        </div>
                    </div>
                `;
                document.body.insertAdjacentHTML('beforeend', modalHTML);
                modal = document.getElementById('planStepsModal');
            }

            const modalTitle = modal.querySelector('.modal-title');
            const modalBody = document.getElementById('planStepsModalBody');

            modalTitle.textContent = `Steps for ${planName}`;

            if (steps.length === 0) {
                modalBody.innerHTML = `
                    <div class="alert alert-info text-center">
                        <i class="bi bi-info-circle me-2"></i>
                        No steps defined for this plan.
                    </div>
                `;
            } else {
                let html = '<div class="row">';
                steps.forEach((step, index) => {
                    html += `
                        <div class="col-md-6 mb-3">
                            <div class="card">
                                <div class="card-body">
                                    <div class="d-flex justify-content-between align-items-start mb-2">
                                        <h6 class="card-title text-primary">Step ${step.step_number}</h6>
                                        <span class="badge bg-secondary">${step.status || 'Active'}</span>
                                    </div>
                                    <p class="card-text small">${step.step_description}</p>
                                    ${step.step_image ? `
                                        <div class="text-center mt-2">
                                            <img src="${step.step_image}" class="step-image" alt="Step image" onclick="showImageModal('${step.step_image}', 'Step ${step.step_number} Image')">
                                        </div>
                                    ` : ''}
                                </div>
                            </div>
                        </div>
                    `;
                });
                html += '</div>';
                modalBody.innerHTML = html;
            }

            const bootstrapModal = new bootstrap.Modal(modal);
            bootstrapModal.show();
        }

        // Show image modal
        function showImageModal(imageSrc, title) {
            let modal = document.getElementById('imageModal');
            if (!modal) {
                const modalHTML = `
                    <div class="modal fade" id="imageModal" tabindex="-1">
                        <div class="modal-dialog modal-dialog-centered">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <h5 class="modal-title">Image Preview</h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body text-center">
                                    <img id="modalImage" src="" class="img-fluid" alt="Preview">
                                </div>
                            </div>
                        </div>
                    </div>
                `;
                document.body.insertAdjacentHTML('beforeend', modalHTML);
                modal = document.getElementById('imageModal');
            }

            modal.querySelector('.modal-title').textContent = title;
            document.getElementById('modalImage').src = imageSrc;

            const bootstrapModal = new bootstrap.Modal(modal);
            bootstrapModal.show();
        }

        // Update stats
        function updateStats() {
            document.getElementById('totalEmployees').textContent = employees.length;
            document.getElementById('totalPlans').textContent = plans.length;
        }

        // Utility functions
        function getStatusClass(status) {
            const statusClasses = {
                'pending': 'bg-secondary',
                'in_progress': 'bg-warning text-dark',
                'completed': 'bg-success',
                'cancelled': 'bg-danger'
            };
            return statusClasses[status] || 'bg-secondary';
        }

        function getStatusIcon(status) {
            const statusIcons = {
                'pending': 'bi-clock',
                'in_progress': 'bi-play-circle-fill',
                'completed': 'bi-check-circle-fill',
                'cancelled': 'bi-x-circle-fill'
            };
            return statusIcons[status] || 'bi-clock';
        }

        function formatDate(dateString) {
            if (!dateString) return 'N/A';
            const date = new Date(dateString);
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
        }

        function showLoading(show) {
            const overlay = document.getElementById('loadingOverlay');
            if (overlay) {
                overlay.style.display = show ? 'block' : 'none';
            }
        }

        function showAlert(message, type = 'info') {
            const alertContainer = document.getElementById('alertContainer');
            const alertId = 'alert_' + Date.now();
            
            const alertHTML = `
                <div id="${alertId}" class="alert alert-${type} alert-dismissible fade show shadow" role="alert">
                    <i class="bi bi-${getAlertIcon(type)} me-2"></i>
                    <strong>${message}</strong>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            `;
            
            alertContainer.innerHTML += alertHTML;
            
            setTimeout(() => {
                const alert = document.getElementById(alertId);
                if (alert) {
                    alert.remove();
                }
            }, 5000);
        }

        function getAlertIcon(type) {
            const icons = {
                'success': 'check-circle-fill',
                'danger': 'exclamation-triangle-fill',
                'warning': 'exclamation-triangle-fill',
                'info': 'info-circle-fill'
            };
            return icons[type] || 'info-circle-fill';
        }
    </script>
</body>
</html>