<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// Database configuration
$host = 'localhost';
$dbname = 'your_database_name';
$username = 'your_db_username';
$password = 'your_db_password';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode([
        'status' => 'error',
        'msg' => 'Database connection failed'
    ]);
    exit;
}

// Get the action parameter
$action = $_POST['action'] ?? '';

switch($action) {
    case 'add_device':
        addDevice($pdo);
        break;
    case 'list':
        listWarehouses($pdo);
        break;
    default:
        echo json_encode([
            'status' => 'error',
            'msg' => 'Invalid action'
        ]);
        break;
}

function addDevice($pdo) {
    // Validate required fields
    $required_fields = ['warehouse', 'device_number', 'user_name', 'fcm_token', 'selected_sim'];
    foreach($required_fields as $field) {
        if(empty($_POST[$field])) {
            echo json_encode([
                'status' => 'error',
                'msg' => "Missing required field: $field"
            ]);
            return;
        }
    }
    
    $warehouse = $_POST['warehouse'];
    $device_number = $_POST['device_number'];
    $user_name = $_POST['user_name'];
    $fcm_token = $_POST['fcm_token'];
    $selected_sim = $_POST['selected_sim'];
    
    // Validate mobile number format (Indian mobile number)
    if(!preg_match('/^[6-9][0-9]{9}$/', $device_number)) {
        echo json_encode([
            'status' => 'error',
            'msg' => 'Invalid mobile number format'
        ]);
        return;
    }
    
    // Validate warehouse ID (1-194)
    if(!is_numeric($warehouse) || $warehouse < 1 || $warehouse > 194) {
        echo json_encode([
            'status' => 'error',
            'msg' => 'Invalid warehouse ID'
        ]);
        return;
    }
    
    // Validate SIM selection
    if(!in_array($selected_sim, ['SIM1', 'SIM2'])) {
        echo json_encode([
            'status' => 'error',
            'msg' => 'Invalid SIM selection'
        ]);
        return;
    }
    
    try {
        // Check if device already exists
        $stmt = $pdo->prepare("SELECT id FROM devices WHERE device_number = ?");
        $stmt->execute([$device_number]);
        
        if($stmt->rowCount() > 0) {
            // Update existing device
            $stmt = $pdo->prepare("
                UPDATE devices 
                SET warehouse_id = ?, user_name = ?, fcm_token = ?, selected_sim = ?, updated_at = NOW()
                WHERE device_number = ?
            ");
            $stmt->execute([$warehouse, $user_name, $fcm_token, $selected_sim, $device_number]);
            
            // Get updated device info
            $stmt = $pdo->prepare("SELECT * FROM devices WHERE device_number = ?");
            $stmt->execute([$device_number]);
            $device = $stmt->fetch(PDO::FETCH_ASSOC);
            
            echo json_encode([
                'status' => 'ok',
                'msg' => 'Device updated successfully',
                'data' => [
                    'id' => $device['id'],
                    'warehouse_id' => $device['warehouse_id'],
                    'warehouse_label' => 'L' . str_pad($device['warehouse_id'], 3, '0', STR_PAD_LEFT),
                    'device_number' => $device['device_number'],
                    'user_name' => $device['user_name'],
                    'selected_sim' => $device['selected_sim'],
                    'status' => 'active'
                ]
            ]);
        } else {
            // Insert new device
            $stmt = $pdo->prepare("
                INSERT INTO devices (warehouse_id, device_number, user_name, fcm_token, selected_sim, status, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, 'active', NOW(), NOW())
            ");
            $stmt->execute([$warehouse, $device_number, $user_name, $fcm_token, $selected_sim]);
            
            $device_id = $pdo->lastInsertId();
            
            echo json_encode([
                'status' => 'ok',
                'msg' => 'Device registered successfully',
                'data' => [
                    'id' => $device_id,
                    'warehouse_id' => $warehouse,
                    'warehouse_label' => 'L' . str_pad($warehouse, 3, '0', STR_PAD_LEFT),
                    'device_number' => $device_number,
                    'user_name' => $user_name,
                    'selected_sim' => $selected_sim,
                    'status' => 'active'
                ]
            ]);
        }
        
    } catch(PDOException $e) {
        echo json_encode([
            'status' => 'error',
            'msg' => 'Database error: ' . $e->getMessage()
        ]);
    }
}

function listWarehouses($pdo) {
    $warehouses = [];
    
    // Generate warehouse list (L001 to L194)
    for($i = 1; $i <= 194; $i++) {
        $warehouses[] = [
            'id' => $i,
            'label' => 'L' . str_pad($i, 3, '0', STR_PAD_LEFT),
            'code' => 'L' . str_pad($i, 3, '0', STR_PAD_LEFT)
        ];
    }
    
    echo json_encode([
        'status' => 'ok',
        'msg' => 'Warehouses retrieved successfully',
        'data' => $warehouses
    ]);
}

// Create devices table if it doesn't exist
function createDevicesTable($pdo) {
    $sql = "
    CREATE TABLE IF NOT EXISTS devices (
        id INT AUTO_INCREMENT PRIMARY KEY,
        warehouse_id INT NOT NULL,
        device_number VARCHAR(15) NOT NULL UNIQUE,
        user_name VARCHAR(100) NOT NULL,
        fcm_token TEXT,
        selected_sim ENUM('SIM1', 'SIM2') NOT NULL,
        status ENUM('active', 'inactive') DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_warehouse (warehouse_id),
        INDEX idx_device_number (device_number),
        INDEX idx_status (status)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ";
    
    try {
        $pdo->exec($sql);
    } catch(PDOException $e) {
        error_log("Error creating devices table: " . $e->getMessage());
    }
}

// Uncomment the line below to create the table on first run
// createDevicesTable($pdo);
?>