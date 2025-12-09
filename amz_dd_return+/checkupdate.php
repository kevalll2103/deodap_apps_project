<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

require_once('db.php');

// Get JSON input (for JSON requests) or POST data (for form requests)
$input = json_decode(file_get_contents("php://input"), true);
if (!$input) {
    // Fallback to POST data if JSON parsing fails
    $input = $_POST;
}

$role = trim($input['role'] ?? '');
$app_version = trim($input['version'] ?? '');

if (empty($role) || empty($app_version)) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Missing version or role.'
    ]);
    exit;
}

// Validate role
if (!in_array($role, ['admin', 'dropshipper'])) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid role. Use admin or dropshipper.'
    ]);
    exit;
}

try {
    // Get latest version from database for the specific role
    $stmt = $conn->prepare("SELECT version, image_url, download_url FROM app_update WHERE role = ? ORDER BY id DESC LIMIT 1");
    $stmt->bind_param("s", $role);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($row = $result->fetch_assoc()) {
        $latest_version = $row['version'];
        $image_url = $row['image_url'];
        $download_url = $row['download_url'];
        
        // Compare versions using version_compare function
        $needsUpdate = version_compare($app_version, $latest_version, '<');
        
        if ($needsUpdate) {
            // Update available - return success status to trigger update dialog
            echo json_encode([
                'status' => 'success', // This triggers the update dialog in Flutter
                'message' => 'Update available',
                'current_version' => $app_version,
                'latest_version' => $latest_version,
                'image_url' => $image_url,
                'apk_url' => $download_url,
                'download_url' => $download_url,
                'is_mandatory' => true,
                'update_title' => 'New Update Available! 🚀',
                'update_description' => 'A new version of the app is available with exciting features and improvements.',
                'release_notes' => generateReleaseNotes($app_version, $latest_version),
                'role' => $role
            ]);
        } else {
            // App is up to date
            echo json_encode([
                'status' => 'up_to_date',
                'message' => 'App is up to date',
                'current_version' => $app_version,
                'latest_version' => $latest_version,
                'role' => $role
            ]);
        }
    } else {
        echo json_encode([
            'status' => 'error',
            'message' => 'No version found for this role.'
        ]);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}

$stmt->close();
$conn->close();

/**
 * Generate release notes based on version difference
 */
function generateReleaseNotes($currentVersion, $latestVersion) {
    $releaseNotes = [];
    
    // Parse version numbers
    $currentParts = explode('.', $currentVersion);
    $latestParts = explode('.', $latestVersion);
    
    // Major version change (1.x.x -> 2.x.x)
    if (isset($currentParts[0], $latestParts[0]) && $currentParts[0] < $latestParts[0]) {
        $releaseNotes[] = "🎉 Major update with new features";
        $releaseNotes[] = "🔧 Complete UI/UX redesign";
        $releaseNotes[] = "⚡ Significant performance improvements";
        $releaseNotes[] = "🔒 Enhanced security features";
    }
    // Minor version change (1.1.x -> 1.2.x)
    elseif (isset($currentParts[1], $latestParts[1]) && $currentParts[1] < $latestParts[1]) {
        $releaseNotes[] = "✨ New features and enhancements";
        $releaseNotes[] = "🐛 Bug fixes and stability improvements";
        $releaseNotes[] = "🚀 Performance optimizations";
        $releaseNotes[] = "📱 Improved user experience";
    }
    // Patch version change (1.1.1 -> 1.1.2)
    else {
        $releaseNotes[] = "🐛 Critical bug fixes";
        $releaseNotes[] = "🔒 Security improvements";
        $releaseNotes[] = "⚡ Minor performance enhancements";
        $releaseNotes[] = "🔧 Stability improvements";
    }
    
    return implode("\n", $releaseNotes);
}

exit;
?>