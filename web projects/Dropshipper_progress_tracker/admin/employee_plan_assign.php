<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Employee Plan Manager</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
  <div class="container py-5">
    <h2 class="mb-4 text-center">Employee Plan Manager</h2>

    <!-- Employee Selection -->
    <div class="card mb-4 shadow-sm">
      <div class="card-body">
        <h5 class="card-title">Select Employee</h5>
        <select id="employeeSelect" class="form-select"></select>
      </div>
    </div>

    <!-- Available Plans -->
    <div class="card mb-4 shadow-sm">
      <div class="card-body">
        <h5 class="card-title">Available Plans</h5>
        <div id="plansList" class="row gy-3"></div>
      </div>
    </div>

    <!-- Assigned Plans -->
    <div class="card shadow-sm">
      <div class="card-body">
        <h5 class="card-title">Employee's Assigned Plans</h5>
        <ul id="assignedPlans" class="list-group"></ul>
      </div>
    </div>
  </div>

  <script>
    const API_URL = "plans.php"; // adjust path if needed

    async function callApi(data) {
      const res = await fetch(API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data)
      });
      return res.json();
    }

    async function loadEmployees() {
      const data = await callApi({ action: "get_employees" });
      const select = document.getElementById("employeeSelect");
      select.innerHTML = "";
      if (data.success) {
        data.employees.forEach(emp => {
          let opt = document.createElement("option");
          opt.value = emp.emp_id;
          opt.textContent = `${emp.emp_name} (${emp.emp_code})`;
          select.appendChild(opt);
        });
        if (data.employees.length > 0) {
          loadAssignedPlans(select.value);
        }
      }
    }

    async function loadPlans() {
      const data = await callApi({ action: "get_plans" });
      const container = document.getElementById("plansList");
      container.innerHTML = "";
      if (data.success) {
        data.plans.forEach(plan => {
          let div = document.createElement("div");
          div.className = "col-md-4";
          div.innerHTML = `
            <div class="card h-100">
              <div class="card-body">
                <h6 class="card-title">${plan.name}</h6>
                <p>${plan.description}</p>
                <p><b>₹${plan.price}</b></p>
                <button class="btn btn-sm btn-primary" onclick="assignPlan(${plan.id})">Assign</button>
              </div>
            </div>
          `;
          container.appendChild(div);
        });
      }
    }

    async function loadAssignedPlans(empId) {
      const data = await callApi({ action: "get_employee_plans", emp_id: empId });
      const list = document.getElementById("assignedPlans");
      list.innerHTML = "";
      if (data.success) {
        data.plans.forEach(plan => {
          let li = document.createElement("li");
          li.className = "list-group-item d-flex justify-content-between align-items-center";
          li.innerHTML = `
            ${plan.name} - ₹${plan.price}
            <button class="btn btn-sm btn-danger" onclick="deletePlan(${plan.id})">Delete</button>
          `;
          list.appendChild(li);
        });
      }
    }

    async function assignPlan(planId) {
      const empId = document.getElementById("employeeSelect").value;
      if (!empId) return alert("Select employee first");
      const data = await callApi({ action: "add_plan", emp_id: empId, plan_id: planId, plan_source: "plans_php" });
      alert(data.message);
      loadAssignedPlans(empId);
    }

    async function deletePlan(planId) {
      const empId = document.getElementById("employeeSelect").value;
      const data = await callApi({ action: "delete_plan", emp_id: empId, plan_id: planId });
      alert(data.message);
      loadAssignedPlans(empId);
    }

    document.getElementById("employeeSelect").addEventListener("change", e => {
      loadAssignedPlans(e.target.value);
    });

    // Initial load
    loadEmployees();
    loadPlans();
  </script>
</body>
</html>
