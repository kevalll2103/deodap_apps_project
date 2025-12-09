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
    <title>Employee Plan Management</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        body {
            background-color: #f8f9fa;
        }
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .btn-custom {
            border-radius: 25px;
            padding: 8px 20px;
        }
        .plan-card {
            border-left: 4px solid #007bff;
        }
        .employee-card {
            border-left: 4px solid #28a745;
        }
        .loading {
            display: none;
        }
        .alert {
            border-radius: 10px;
        }
        .table {
            border-radius: 10px;
            overflow: hidden;
        }
        .nav-pills .nav-link.active {
            background-color: #007bff;
            border-radius: 25px;
        }
        .nav-pills .nav-link {
            border-radius: 25px;
            margin: 0 5px;
        }
        .step-item {
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 10px;
            margin-bottom: 10px;
            background-color: #f8f9fa;
        }
        .status-badge {
            font-size: 0.75em;
        }
        .steps-container {
            /* Removed max-height and overflow to make all steps properly visible without scrolling */
        }
        .plan-steps-section {
            background-color: #fff;
            border-radius: 8px;
            padding: 15px;
            margin-top: 15px;
        }
    </style>
</head>
<body>
    <div class="container-fluid mt-4">
        <div class="row">
            <div class="col-12">
                <div class="card mb-4">
                    <div class="card-body">
                        <h1 class="card-title text-center">
                            <i class="bi bi-people-fill text-primary"></i>
                            Employee Plan Management System
                        </h1>
                        <p class="text-center text-muted">Manage employee plans and assignments</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Navigation Tabs -->
        <ul class="nav nav-pills justify-content-center mb-4" id="mainTabs" role="tablist">
            <li class="nav-item">
                <a class="nav-link active" id="dashboard-tab" data-bs-toggle="pill" href="#dashboard" role="tab">
                    <i class="bi bi-speedometer2"></i> Dashboard
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link" id="assign-tab" data-bs-toggle="pill" href="#assign" role="tab">
                    <i class="bi bi-plus-circle"></i> Assign Plan
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link" id="employees-tab" data-bs-toggle="pill" href="#employees" role="tab">
                    <i class="bi bi-people"></i> Employees
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link" id="plans-tab" data-bs-toggle="pill" href="#plans" role="tab">
                    <i class="bi bi-card-list"></i> All Plans
                </a>
            </li>
        </ul>

        <div class="tab-content" id="mainTabsContent">
            <!-- Dashboard Tab -->
            <div class="tab-pane fade show active" id="dashboard" role="tabpanel">
                <div class="row">
                    <div class="col-md-6 mb-4">
                        <div class="card employee-card">
                            <div class="card-body">
                                <h5 class="card-title">
                                    <i class="bi bi-person-check"></i> Employee Lookup
                                </h5>
                                <div class="mb-3">
                                    <label for="employeeSelect" class="form-label">Select Employee</label>
                                    <select class="form-select" id="employeeSelect">
                                        <option value="">Choose an employee...</option>
                                    </select>
                                </div>
                                <button class="btn btn-primary btn-custom" onclick="loadEmployeePlans()">
                                    <i class="bi bi-search"></i> View Plans
                                </button>
                                <button class="btn btn-outline-info btn-custom ms-2" onclick="loadEmployeeDetailedPlans()">
                                    <i class="bi bi-list-task"></i> View Steps
                                </button>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6 mb-4">
                        <div class="card plan-card">
                            <div class="card-body">
                                <h5 class="card-title">
                                    <i class="bi bi-graph-up"></i> Quick Stats
                                </h5>
                                <div id="statsContainer">
                                    <div class="row text-center">
                                        <div class="col-6">
                                            <h3 class="text-primary" id="totalEmployees">-</h3>
                                            <small class="text-muted">Total Employees</small>
                                        </div>
                                        <div class="col-6">
                                            <h3 class="text-success" id="totalPlans">-</h3>
                                            <small class="text-muted">Available Plans</small>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Employee Plans Display -->
                <div class="row" id="employeePlansContainer" style="display: none;">
                    <div class="col-12">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="mb-0">
                                    <i class="bi bi-person-badge"></i> 
                                    Employee Plans: <span id="selectedEmployeeName"></span>
                                </h5>
                            </div>
                            <div class="card-body">
                                <div id="employeePlansTable"></div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Employee Detailed Plans with Steps -->
                <div class="row" id="employeeDetailedPlansContainer" style="display: none;">
                    <div class="col-12">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="mb-0">
                                    <i class="bi bi-list-task"></i> 
                                    Employee Plan Steps: <span id="selectedEmployeeDetailName"></span>
                                </h5>
                            </div>
                            <div class="card-body">
                                <div id="employeeDetailedPlansContent"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Assign Plan Tab -->
            <div class="tab-pane fade" id="assign" role="tabpanel">
                <div class="row justify-content-center">
                    <div class="col-md-10">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="mb-0">
                                    <i class="bi bi-plus-circle-fill"></i> Assign Plan to Employee
                                </h5>
                            </div>
                            <div class="card-body">
                                <form id="assignPlanForm">
                                    <div class="row">
                                        <div class="col-md-6 mb-3">
                                            <label for="assignEmployeeSelect" class="form-label">Employee</label>
                                            <select class="form-select" id="assignEmployeeSelect" required>
                                                <option value="">Select Employee...</option>
                                            </select>
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label for="assignPlanSelect" class="form-label">Plan</label>
                                            <select class="form-select" id="assignPlanSelect" required>
                                                <option value="">Select Plan...</option>
                                            </select>
                                        </div>
                                    </div>
                                    
                                    <!-- Available Steps Section -->
                                    <div id="availableStepsContainer" style="display: none;">
                                        <div class="plan-steps-section">
                                            <h6 class="mb-3">
                                                <i class="bi bi-list-check"></i> Available Plan Steps
                                            </h6>
                                            <div class="row mb-3">
                                                <div class="col-md-6">
                                                    <button type="button" class="btn btn-sm btn-outline-success" onclick="selectAllSteps()">
                                                        <i class="bi bi-check-all"></i> Select All
                                                    </button>
                                                    <button type="button" class="btn btn-sm btn-outline-warning ms-2" onclick="deselectAllSteps()">
                                                        <i class="bi bi-x-square"></i> Deselect All
                                                    </button>
                                                </div>
                                            </div>
                                            <div id="availableStepsList" class="steps-container"></div>
                                        </div>
                                    </div>
                                    
                                    <button type="submit" class="btn btn-success btn-custom mt-3">
                                        <i class="bi bi-check-circle"></i> Assign Selected Steps
                                    </button>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Employees Tab -->
            <div class="tab-pane fade" id="employees" role="tabpanel">
                <div class="card">
                    <div class="card-header">
                        <h5 class="mb-0">
                            <i class="bi bi-people-fill"></i> All Employees
                        </h5>
                    </div>
                    <div class="card-body">
                        <div id="employeesTable"></div>
                    </div>
                </div>
            </div>

            <!-- Plans Tab -->
            <div class="tab-pane fade" id="plans" role="tabpanel">
                <div class="card">
                    <div class="card-header">
                        <h5 class="mb-0">
                            <i class="bi bi-card-list"></i> Available Plans
                        </h5>
                    </div>
                    <div class="card-body">
                        <div id="plansTable"></div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Alert Container -->
        <div id="alertContainer" class="position-fixed" style="top: 20px; right: 20px; z-index: 1050;"></div>

        <!-- Loading Overlay -->
        <div id="loadingOverlay" class="loading position-fixed top-0 start-0 w-100 h-100" style="background: rgba(0,0,0,0.5); z-index: 1060;">
            <div class="d-flex justify-content-center align-items-center h-100">
                <div class="text-center text-white">
                    <div class="spinner-border" role="status">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                    <div class="mt-2">Loading...</div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // API Configuration
        const API_URL = 'https://customprint.deodap.com/api_dropshipper_tracker/emp_plan_step.php';

        // Global variables
        let employees = [];
        let plans = [];
        let availableSteps = [];

        // Initialize page
        document.addEventListener('DOMContentLoaded', function() {
            loadEmployees();
            loadPlans();
            setupEventListeners();
            handleUrlParameters();
        });

        // Setup event listeners
        function setupEventListeners() {
            document.getElementById('assignPlanForm').addEventListener('submit', handleAssignPlan);
            document.getElementById('assignPlanSelect').addEventListener('change', loadAvailableSteps);

            // Tab change events
            document.querySelectorAll('a[data-bs-toggle="pill"]').forEach(tab => {
                tab.addEventListener('shown.bs.tab', function(event) {
                    const target = event.target.getAttribute('href');
                    if (target === '#employees') {
                        displayEmployeesTable();
                    } else if (target === '#plans') {
                        displayPlansTable();
                    }
                });
            });
        }

        // API request function
        async function apiRequest(data) {
            showLoading(true);
            try {
                const response = await fetch(API_URL, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(data)
                });
                
                const result = await response.json();
                showLoading(false);
                return result;
            } catch (error) {
                showLoading(false);
                showAlert('Error connecting to server', 'danger');
                console.error('API Error:', error);
                return null;
            }
        }

        // Load employees
        async function loadEmployees() {
            const result = await apiRequest({ action: 'get_employees' });
            if (result && result.success) {
                employees = result.employees;
                populateEmployeeSelects();
                updateStats();
            } else {
                showAlert('Failed to load employees', 'warning');
            }
        }

        // Load plans
        async function loadPlans() {
            const result = await apiRequest({ action: 'get_plans' });
            if (result && result.success) {
                plans = result.plans;
                populatePlanSelects();
                updateStats();
            } else {
                showAlert('Failed to load plans', 'warning');
            }
        }

        // Populate employee select elements
        function populateEmployeeSelects() {
            const selects = ['employeeSelect', 'assignEmployeeSelect'];
            selects.forEach(selectId => {
                const select = document.getElementById(selectId);
                select.innerHTML = '<option value="">Choose an employee...</option>';
                employees.forEach(emp => {
                    select.innerHTML += `<option value="${emp.emp_id}">${emp.emp_name} (${emp.emp_code})</option>`;
                });
            });
        }

        // Populate plan select elements
        function populatePlanSelects() {
            const select = document.getElementById('assignPlanSelect');
            select.innerHTML = '<option value="">Select Plan...</option>';
            plans.forEach(plan => {
                select.innerHTML += `<option value="${plan.id}">${plan.name} - $${plan.price}</option>`;
            });
        }

        // Load employee plans (basic)
        async function loadEmployeePlans() {
            const empId = document.getElementById('employeeSelect').value;
            if (!empId) {
                showAlert('Please select an employee', 'warning');
                return;
            }

            const result = await apiRequest({ 
                action: 'get_employee_plans', 
                emp_id: parseInt(empId) 
            });

            if (result && result.success) {
                displayEmployeePlans(result.plans, empId);
                document.getElementById('employeeDetailedPlansContainer').style.display = 'none';
            } else {
                showAlert('Failed to load employee plans', 'danger');
            }
        }

        // Load employee plans with detailed steps
        async function loadEmployeeDetailedPlans() {
            const empId = document.getElementById('employeeSelect').value;
            if (!empId) {
                showAlert('Please select an employee', 'warning');
                return;
            }

            const result = await apiRequest({ 
                action: 'get_employee_plan_steps', 
                emp_id: parseInt(empId) 
            });

            if (result && result.success) {
                displayEmployeeDetailedPlans(result.plans_with_steps, empId);
                document.getElementById('employeePlansContainer').style.display = 'none';
            } else {
                showAlert('Failed to load employee plan steps', 'danger');
            }
        }

        // Display employee plans (basic)
        function displayEmployeePlans(employeePlans, empId) {
            const employee = employees.find(emp => emp.emp_id == empId);
            const container = document.getElementById('employeePlansContainer');
            const nameSpan = document.getElementById('selectedEmployeeName');
            const tableDiv = document.getElementById('employeePlansTable');

            nameSpan.textContent = employee ? `${employee.emp_name} (${employee.emp_code})` : 'Unknown';

            if (employeePlans.length === 0) {
                tableDiv.innerHTML = '<div class="alert alert-info"><i class="bi bi-info-circle"></i> No plans assigned to this employee.</div>';
            } else {
                let tableHTML = `
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead class="table-dark">
                                <tr>
                                    <th>Plan ID</th>
                                    <th>Plan Name</th>
                                    <th>Description</th>
                                    <th>Price</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody>
                `;

                employeePlans.forEach(plan => {
                    tableHTML += `
                        <tr>
                            <td>${plan.id}</td>
                            <td>${plan.name}</td>
                            <td>${plan.description || 'N/A'}</td>
                            <td>$${plan.price}</td>
                            <td>
                                <button class="btn btn-sm btn-outline-danger" onclick="deletePlan(${empId}, ${plan.id})">
                                    <i class="bi bi-trash"></i> Remove
                                </button>
                            </td>
                        </tr>
                    `;
                });

                tableHTML += '</tbody></table></div>';
                tableDiv.innerHTML = tableHTML;
            }

            container.style.display = 'block';
        }

        // Display employee detailed plans with steps
        function displayEmployeeDetailedPlans(plansWithSteps, empId) {
            const employee = employees.find(emp => emp.emp_id == empId);
            const container = document.getElementById('employeeDetailedPlansContainer');
            const nameSpan = document.getElementById('selectedEmployeeDetailName');
            const contentDiv = document.getElementById('employeeDetailedPlansContent');

            nameSpan.textContent = employee ? `${employee.emp_name} (${employee.emp_code})` : 'Unknown';

            if (plansWithSteps.length === 0) {
                contentDiv.innerHTML = '<div class="alert alert-info"><i class="bi bi-info-circle"></i> No plan steps assigned to this employee.</div>';
            } else {
                let contentHTML = '';

                plansWithSteps.forEach(planData => {
                    contentHTML += `
                        <div class="card mb-4">
                            <div class="card-header">
                                <h6 class="mb-0">
                                    <i class="bi bi-diagram-3"></i> ${planData.plan_name} 
                                    <span class="badge bg-primary ms-2">$${planData.plan_price}</span>
                                </h6>
                                <small class="text-muted">${planData.plan_description || 'No description'}</small>
                            </div>
                            <div class="card-body">
                                <div class="row">
                    `;

                    planData.steps.forEach(step => {
                        const statusBadge = getStatusBadge(step.status);
                        contentHTML += `
                            <div class="col-md-6 mb-3">
                                <div class="step-item">
                                    <div class="d-flex justify-content-between align-items-start">
                                        <div class="flex-grow-1">
                                            <h6 class="mb-1">Step ${step.step_number || 'N/A'}</h6>
                                            <p class="mb-2 text-muted">${step.step_description}</p>
                                            ${step.custom_description ? `<p class="mb-2 text-info"><small><strong>Custom:</strong> ${step.custom_description}</small></p>` : ''}
                                            <small class="text-muted">Updated: ${formatDate(step.updated_at)}</small>
                                        </div>
                                        <div class="ms-2">
                                            ${statusBadge}
                                            <div class="dropdown mt-1">
                                                <button class="btn btn-sm btn-outline-secondary dropdown-toggle" type="button" data-bs-toggle="dropdown">
                                                    <i class="bi bi-three-dots"></i>
                                                </button>
                                                <ul class="dropdown-menu">
                                                    <li><a class="dropdown-item" href="#" onclick="updateStepStatus(${step.employee_plan_step_id}, 'pending')">
                                                        <i class="bi bi-clock"></i> Pending
                                                    </a></li>
                                                    <li><a class="dropdown-item" href="#" onclick="updateStepStatus(${step.employee_plan_step_id}, 'in_progress')">
                                                        <i class="bi bi-play-circle"></i> In Progress
                                                    </a></li>
                                                    <li><a class="dropdown-item" href="#" onclick="updateStepStatus(${step.employee_plan_step_id}, 'completed')">
                                                        <i class="bi bi-check-circle"></i> Completed
                                                    </a></li>
                                                    <li><hr class="dropdown-divider"></li>
                                                    <li><a class="dropdown-item text-danger" href="#" onclick="deleteEmployeeStep(${step.employee_plan_step_id})">
                                                        <i class="bi bi-trash"></i> Delete Step
                                                    </a></li>
                                                </ul>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        `;
                    });

                    contentHTML += `
                                </div>
                            </div>
                        </div>
                    `;
                });

                contentDiv.innerHTML = contentHTML;
            }

            container.style.display = 'block';
        }

        // Load available steps for selected plan and employee
        async function loadAvailableSteps() {
            const empId = document.getElementById('assignEmployeeSelect').value;
            const planId = document.getElementById('assignPlanSelect').value;
            const container = document.getElementById('availableStepsContainer');
            const listDiv = document.getElementById('availableStepsList');

            if (!empId || !planId) {
                container.style.display = 'none';
                return;
            }

            const result = await apiRequest({
                action: 'get_available_plan_steps',
                emp_id: parseInt(empId),
                plan_id: parseInt(planId)
            });

            if (result && result.success) {
                availableSteps = result.available_steps;
                let stepsHTML = '';
                
                if (availableSteps.length === 0) {
                    stepsHTML = '<div class="alert alert-warning">All steps from this plan are already assigned to this employee.</div>';
                } else {
                    availableSteps.forEach(step => {
                        stepsHTML += `
                            <div class="form-check step-item">
                                <input class="form-check-input" type="checkbox" value="${step.step_id}" id="step_${step.step_id}" checked>
                                <label class="form-check-label" for="step_${step.step_id}">
                                    <div class="d-flex justify-content-between align-items-start w-100">
                                        <div>
                                            <strong>Step ${step.step_number}</strong>
                                            <p class="mb-1 text-muted">${step.step_description}</p>
                                            ${step.step_image ? `<small class="text-info"><i class="bi bi-image"></i> Has image</small>` : ''}
                                        </div>
                                        <span class="badge bg-secondary">${step.status}</span>
                                    </div>
                                </label>
                            </div>
                        `;
                    });
                }
                
                listDiv.innerHTML = stepsHTML;
                container.style.display = 'block';
            } else {
                showAlert('Failed to load available steps', 'warning');
                container.style.display = 'none';
            }
        }

        // Handle assign plan form submission
        async function handleAssignPlan(event) {
            event.preventDefault();

            const empId = document.getElementById('assignEmployeeSelect').value;
            const planId = document.getElementById('assignPlanSelect').value;

            if (!empId || !planId) {
                showAlert('Please select both employee and plan', 'warning');
                return;
            }

            // Collect selected step IDs
            const selectedSteps = [];
            const stepCheckboxes = document.querySelectorAll('#availableStepsList input[type="checkbox"]:checked');
            stepCheckboxes.forEach(checkbox => {
                selectedSteps.push(parseInt(checkbox.value));
            });

            if (selectedSteps.length === 0) {
                showAlert('Please select at least one step', 'warning');
                return;
            }

            const result = await apiRequest({
                action: 'add_plan',
                emp_id: parseInt(empId),
                plan_id: parseInt(planId),
                step_ids: selectedSteps
            });

            if (result && result.success) {
                showAlert('Selected steps assigned successfully!', 'success');
                document.getElementById('assignPlanForm').reset();
                document.getElementById('availableStepsContainer').style.display = 'none';
            } else {
                showAlert(result ? result.message : 'Failed to assign steps', 'danger');
            }
        }

        // Select/Deselect all steps
        function selectAllSteps() {
            const checkboxes = document.querySelectorAll('#availableStepsList input[type="checkbox"]');
            checkboxes.forEach(checkbox => checkbox.checked = true);
        }

        function deselectAllSteps() {
            const checkboxes = document.querySelectorAll('#availableStepsList input[type="checkbox"]');
            checkboxes.forEach(checkbox => checkbox.checked = false);
        }

        // Update step status
        async function updateStepStatus(employeePlanStepId, newStatus) {
            const result = await apiRequest({
                action: 'update_step_status',
                employee_plan_step_id: employeePlanStepId,
                status: newStatus
            });

            if (result && result.success) {
                showAlert('Step status updated successfully!', 'success');
                loadEmployeeDetailedPlans(); // Refresh the detailed view
            } else {
                showAlert(result ? result.message : 'Failed to update step status', 'danger');
            }
        }

        // Delete employee step
        async function deleteEmployeeStep(employeePlanStepId) {
            if (!confirm('Are you sure you want to delete this step from the employee?')) {
                return;
            }

            const result = await apiRequest({
                action: 'delete_employee_step',
                employee_plan_step_id: employeePlanStepId
            });

            if (result && result.success) {
                showAlert('Step deleted successfully!', 'success');
                loadEmployeeDetailedPlans(); // Refresh the detailed view
            } else {
                showAlert(result ? result.message : 'Failed to delete step', 'danger');
            }
        }

        // Delete plan
        async function deletePlan(empId, planId) {
            if (!confirm('Are you sure you want to remove this plan from the employee?')) {
                return;
            }

            const result = await apiRequest({
                action: 'delete_plan',
                emp_id: empId,
                plan_id: planId
            });

            if (result && result.success) {
                showAlert('Plan removed successfully!', 'success');
                loadEmployeePlans(); // Reload the current employee's plans
            } else {
                showAlert(result ? result.message : 'Failed to remove plan', 'danger');
            }
        }

        // Display employees table
        function displayEmployeesTable() {
            const tableDiv = document.getElementById('employeesTable');
            
            if (employees.length === 0) {
                tableDiv.innerHTML = '<div class="alert alert-info">No employees found.</div>';
                return;
            }

            let tableHTML = `
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead class="table-dark">
                            <tr>
                                <th>Employee ID</th>
                                <th>Name</th>
                                <th>Code</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
            `;

            employees.forEach(emp => {
                tableHTML += `
                    <tr>
                        <td>${emp.emp_id}</td>
                        <td>${emp.emp_name}</td>
                        <td><span class="badge bg-secondary">${emp.emp_code}</span></td>
                        <td>
                            <button class="btn btn-sm btn-outline-primary" onclick="viewEmployeePlans(${emp.emp_id})">
                                <i class="bi bi-eye"></i> View Plans
                            </button>
                        </td>
                    </tr>
                `;
            });

            tableHTML += '</tbody></table></div>';
            tableDiv.innerHTML = tableHTML;
        }

        // Display plans table
        function displayPlansTable() {
            const tableDiv = document.getElementById('plansTable');
            
            if (plans.length === 0) {
                tableDiv.innerHTML = '<div class="alert alert-info">No plans available.</div>';
                return;
            }

            let tableHTML = `
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead class="table-dark">
                            <tr>
                                <th>Plan ID</th>
                                <th>Name</th>
                                <th>Description</th>
                                <th>Price</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
            `;

            plans.forEach(plan => {
                tableHTML += `
                    <tr>
                        <td>${plan.id}</td>
                        <td><strong>${plan.name}</strong></td>
                        <td>${plan.description || 'N/A'}</td>
                        <td><span class="badge bg-success">${plan.price}</span></td>
                        <td>
                            <button class="btn btn-sm btn-outline-info" onclick="viewPlanSteps(${plan.id})">
                                <i class="bi bi-list-task"></i> View Steps
                            </button>
                        </td>
                    </tr>
                `;
            });

            tableHTML += '</tbody></table></div>';
            tableDiv.innerHTML = tableHTML;
        }

        // View plan steps
        async function viewPlanSteps(planId) {
            const result = await apiRequest({
                action: 'get_plan_steps',
                plan_id: planId
            });

            if (result && result.success) {
                let stepsHTML = `
                    <div class="modal fade" id="planStepsModal" tabindex="-1">
                        <div class="modal-dialog modal-lg">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <h5 class="modal-title">
                                        <i class="bi bi-list-task"></i> Steps for ${result.plan_name}
                                    </h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body">
                                    <div class="row">
                `;

                result.steps.forEach(step => {
                    stepsHTML += `
                        <div class="col-md-6 mb-3">
                            <div class="step-item">
                                <h6>Step ${step.step_number}</h6>
                                <p class="mb-2">${step.step_description}</p>
                                ${step.step_image ? `<small class="text-info"><i class="bi bi-image"></i> Has image</small><br>` : ''}
                                <span class="badge bg-secondary">${step.status}</span>
                            </div>
                        </div>
                    `;
                });

                stepsHTML += `
                                    </div>
                                </div>
                                <div class="modal-footer">
                                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                                </div>
                            </div>
                        </div>
                    </div>
                `;

                // Remove existing modal if present
                const existingModal = document.getElementById('planStepsModal');
                if (existingModal) {
                    existingModal.remove();
                }

                // Add modal to DOM
                document.body.insertAdjacentHTML('beforeend', stepsHTML);
                
                // Show modal
                const modal = new bootstrap.Modal(document.getElementById('planStepsModal'));
                modal.show();
            } else {
                showAlert('Failed to load plan steps', 'danger');
            }
        }

        // View employee plans (from employees table)
        function viewEmployeePlans(empId) {
            document.getElementById('employeeSelect').value = empId;
            
            // Switch to dashboard tab
            const dashboardTab = new bootstrap.Tab(document.getElementById('dashboard-tab'));
            dashboardTab.show();
            
            // Load plans for selected employee
            setTimeout(() => {
                loadEmployeePlans();
            }, 100);
        }

        // Update stats
        function updateStats() {
            document.getElementById('totalEmployees').textContent = employees.length;
            document.getElementById('totalPlans').textContent = plans.length;
        }

        // Show/hide loading
        function showLoading(show) {
            const overlay = document.getElementById('loadingOverlay');
            overlay.style.display = show ? 'block' : 'none';
        }

        // Show alert
        function showAlert(message, type = 'info') {
            const alertContainer = document.getElementById('alertContainer');
            const alertId = 'alert_' + Date.now();
            
            const alertHTML = `
                <div id="${alertId}" class="alert alert-${type} alert-dismissible fade show" role="alert">
                    <i class="bi bi-${getAlertIcon(type)}"></i> ${message}
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            `;
            
            alertContainer.innerHTML += alertHTML;
            
            // Auto remove after 5 seconds
            setTimeout(() => {
                const alert = document.getElementById(alertId);
                if (alert) {
                    alert.remove();
                }
            }, 5000);
        }

        // Handle URL parameters
        function handleUrlParameters() {
            const urlParams = new URLSearchParams(window.location.search);
            const empId = urlParams.get('emp_id');

            if (empId) {
                // Wait for employees to load, then select the employee
                const checkEmployeesLoaded = setInterval(() => {
                    if (employees.length > 0) {
                        clearInterval(checkEmployeesLoaded);
                        document.getElementById('employeeSelect').value = empId;
                        loadEmployeePlans();
                    }
                }, 100);
            }
        }

        // Get status badge
        function getStatusBadge(status) {
            const badges = {
                'pending': '<span class="badge bg-warning status-badge">Pending</span>',
                'in_progress': '<span class="badge bg-info status-badge">In Progress</span>',
                'completed': '<span class="badge bg-success status-badge">Completed</span>',
                'cancelled': '<span class="badge bg-danger status-badge">Cancelled</span>'
            };
            return badges[status] || '<span class="badge bg-secondary status-badge">Unknown</span>';
        }

        // Format date
        function formatDate(dateString) {
            if (!dateString) return 'N/A';
            const date = new Date(dateString);
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
        }

        // Get alert icon based on type
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