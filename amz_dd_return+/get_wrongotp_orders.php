<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
date_default_timezone_set('Asia/Kolkata');

require_once('db.php');
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(['success' => false, 'message' => 'Only GET method is allowed']);
    exit;
}

try {
    if (!$conn) {
        throw new Exception("Database connection failed: " . mysqli_connect_error());
    }

    // ✅ Check if seller_id is provided
    if (!isset($_GET['seller_id'])) {
        throw new Exception("Missing required parameter: seller_id");
    }

    $seller_id = trim($_GET['seller_id']);
    $date_filter = isset($_GET['date_filter']) ? trim($_GET['date_filter']) : null;

    // ✅ Check if seller exists in `dropshippers`
    $stmt_seller = $conn->prepare("SELECT id FROM dropshippers WHERE id = ? LIMIT 1");
    if (!$stmt_seller) {
        throw new Exception("SQL Error (Seller Check): " . $conn->error);
    }
    $stmt_seller->bind_param("i", $seller_id);
    $stmt_seller->execute();
    $result_seller = $stmt_seller->get_result();

    if ($result_seller->num_rows === 0) {
        throw new Exception("Seller not found");
    }

    // ✅ Base query for dropshipper's "wrong otp" orders
    $query = "
        SELECT id, 
               COALESCE(amazon_order_id, 'null') AS amazon_order_id, 
               COALESCE(return_tracking_id, 'null') AS return_tracking_id, 
               COALESCE(otp, 'null') AS otp,
               COALESCE(entered_otp, 'null') AS entered_otp,
               COALESCE(correct_otp, 'null') AS correct_otp,
               COALESCE(attempt_count, 0) AS attempt_count,
               COALESCE(images, '') AS images,
               created_at
        FROM order_tracking 
        WHERE seller_id = ? 
        AND status = 'wrongotp'
    ";

    // ✅ Date filter conditions
    if ($date_filter === 'today') {
        $query .= " AND DATE(created_at) = CURDATE()";
    } elseif ($date_filter === 'last_week') {
        $query .= " AND created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
    } elseif ($date_filter === 'last_month') {
        $query .= " AND created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)";
    }

    $query .= " ORDER BY created_at DESC";

    $stmt = $conn->prepare($query);

    if (!$stmt) {
        throw new Exception("SQL Error: " . $conn->error);
    }

    $stmt->bind_param("i", $seller_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $orders = [];

    while ($row = $result->fetch_assoc()) {
        // Process images field
        $row['images'] = !empty($row['images']) ? explode(',', $row['images']) : [];
        $orders[] = $row;
    }

    // ✅ Return data (even if empty)
    echo json_encode(['success' => true, 'data' => $orders], JSON_PRETTY_PRINT);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>