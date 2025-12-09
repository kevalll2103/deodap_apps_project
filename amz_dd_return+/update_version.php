<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once('db.php');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $role = $_POST['role'] ?? 'admin';
    $version = $_POST['version'] ?? '';
    $imageUrl = $_POST['image_url'] ?? null;
    $downloadUrl = $_POST['download_url'] ?? '';
    
    if (empty($version) || empty($downloadUrl)) {
        echo json_encode(['status' => 'error', 'message' => 'Version and download URL are required']);
        exit();
    }
    
    try {
        $stmt = $conn->prepare("INSERT INTO app_update (role, version, image_url, download_url) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("ssss", $role, $version, $imageUrl, $downloadUrl);
        $stmt->execute();
        
        echo json_encode([
            'status' => 'success',
            'message' => 'Version updated successfully',
            'id' => $conn->insert_id
        ]);
        
        $stmt->close();
        
    } catch (Exception $e) {
        echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
    }
    
} else {
    try {
        $result = $conn->query("SELECT * FROM app_update ORDER BY id DESC");
        $versions = [];
        
        while ($row = $result->fetch_assoc()) {
            $versions[] = $row;
        }
        
        echo json_encode([
            'status' => 'success',
            'versions' => $versions
        ]);
        
    } catch (Exception $e) {
        echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
    }
}

$conn->close();
?>

<!DOCTYPE html>
<html>
<head>
    <title>App Version Manager</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .form-group { margin: 15px 0; }
        label { display: block; margin-bottom: 5px; font-weight: bold; color: #333; }
        input, select { width: 100%; padding: 12px; margin-bottom: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px; }
        button { background: #007cba; color: white; padding: 12px 24px; border: none; cursor: pointer; border-radius: 5px; font-size: 16px; }
        button:hover { background: #005a87; }
        .version-list { margin-top: 40px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #f8f9fa; font-weight: bold; }
        .badge { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
        .badge-admin { background: #e3f2fd; color: #1976d2; }
        .badge-dropshipper { background: #f3e5f5; color: #7b1fa2; }
        h1 { color: #333; text-align: center; }
        h2 { color: #555; border-bottom: 2px solid #007cba; padding-bottom: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 App Version Manager</h1>
        
        <form method="POST">
            <div class="form-group">
                <label>Role:</label>
                <select name="role" required>
                    <option value="admin">Admin</option>
                    <option value="dropshipper">Dropshipper</option>
                </select>
            </div>
            
            <div class="form-group">
                <label>Version (e.g., 1.1.3):</label>
                <input type="text" name="version" placeholder="1.1.3" required>
            </div>
            
            <div class="form-group">
                <label>Image URL (optional):</label>
                <input type="url" name="image_url" placeholder="https://example.com/update-image.png">
            </div>
            
            <div class="form-group">
                <label>Download URL:</label>
                <input type="url" name="download_url" placeholder="https://drive.google.com/..." required>
            </div>
            
            <button type="submit">Add New Version</button>
        </form>
        
        <div class="version-list">
            <h2>📱 Current Versions</h2>
            <div id="versions"></div>
        </div>
    </div>
    
    <script>
        fetch(window.location.href)
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success' && data.versions) {
                    let html = '<table><tr><th>ID</th><th>Role</th><th>Version</th><th>Download URL</th><th>Actions</th></tr>';
                    data.versions.forEach(version => {
                        const badgeClass = version.role === 'admin' ? 'badge-admin' : 'badge-dropshipper';
                        html += `<tr>
                            <td>${version.id}</td>
                            <td><span class="badge ${badgeClass}">${version.role}</span></td>
                            <td><strong>${version.version}</strong></td>
                            <td><a href="${version.download_url}" target="_blank" style="color: #007cba;">Download APK</a></td>
                            <td><button onclick="copyUrl('${version.download_url}')" style="padding: 4px 8px; font-size: 12px;">Copy URL</button></td>
                        </tr>`;
                    });
                    html += '</table>';
                    document.getElementById('versions').innerHTML = html;
                }
            });
            
        function copyUrl(url) {
            navigator.clipboard.writeText(url).then(() => {
                alert('URL copied to clipboard!');
            });
        }
    </script>
</body>
</html>