<?php
session_start();

// Check if user is logged in
if (!isset($_SESSION['user'])) {
    header("Location: login.php");
    exit();
}

// Get employee details from session
$emp_id = $_SESSION['user']['id'] ?? '';

// If no employee ID in session, redirect to login
if (empty($emp_id)) {
    header("Location: login.php");
    exit();
}
?>


<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Plan Step Chat - White Theme</title>

 <link rel="icon" href="assets/favicon.png" />
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    :root {
      --primary-color: #2563eb;
      --primary-dark: #1d4ed8;
      --primary-light: #dbeafe;
      --secondary-color: #6b7280;
      --accent-color: #10b981;
      --text-primary: #111827;
      --text-secondary: #6b7280;
      --text-muted: #9ca3af;
      --bg-primary: #ffffff;
      --bg-secondary: #f9fafb;
      --bg-tertiary: #f3f4f6;
      --bg-chat: #ffffff;
      --border-color: #e5e7eb;
      --border-light: #f3f4f6;
      --shadow-light: 0 1px 3px rgba(0,0,0,0.05);
      --shadow-medium: 0 4px 16px rgba(0,0,0,0.08);
      --shadow-heavy: 0 10px 40px rgba(0,0,0,0.12);
      --radius-sm: 8px;
      --radius-md: 12px;
      --radius-lg: 16px;
      --radius-xl: 20px;
    }

    body {
      font-family: 'Inter', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
      color: var(--text-primary);
    }

    .whatsapp-container {
      width: 100%;
      max-width: 1000px;
      height: 95vh;
      min-height: 600px;
      background: var(--bg-primary);
      border-radius: var(--radius-xl);
      box-shadow: var(--shadow-heavy);
      display: flex;
      flex-direction: column;
      overflow: hidden;
      border: 1px solid var(--border-color);
    }

    /* White Theme Chat Header */
    .chat-header {
      background: var(--bg-primary);
      color: var(--text-primary);
      padding: 24px 32px;
      display: flex;
      align-items: center;
      gap: 20px;
      border-bottom: 1px solid var(--border-color);
      position: relative;
    }

    .back-button {
      color: var(--text-secondary);
      cursor: pointer;
      padding: 12px;
      border-radius: 50%;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      font-size: 18px;
    }

    .back-button:hover {
      background-color: var(--bg-secondary);
      color: var(--primary-color);
      transform: scale(1.05);
    }

    .chat-profile-pic {
      width: 56px;
      height: 56px;
      border-radius: 50%;
      background: linear-gradient(135deg, var(--primary-light), var(--bg-secondary));
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--primary-color);
      font-size: 24px;
      position: relative;
      box-shadow: var(--shadow-light);
      border: 2px solid var(--border-light);
    }

    .chat-info {
      flex: 1;
    }

    .chat-info h4 {
      margin: 0;
      font-size: 20px;
      font-weight: 600;
      margin-bottom: 6px;
      color: var(--text-primary);
    }

    .chat-info p {
      margin: 0;
      font-size: 14px;
      color: var(--text-secondary);
      font-weight: 400;
    }

    .chat-actions {
      display: flex;
      gap: 8px;
      align-items: center;
    }

    .chat-actions i {
      color: var(--text-secondary);
      cursor: pointer;
      padding: 12px;
      border-radius: 50%;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      font-size: 16px;
    }

    .chat-actions i:hover {
      background-color: var(--bg-secondary);
      color: var(--primary-color);
      transform: scale(1.05);
    }

    .search-container {
      display: none;
      position: absolute;
      top: 100%;
      left: 0;
      right: 0;
      background: var(--bg-primary);
      padding: 20px;
      box-shadow: var(--shadow-medium);
      border-bottom: 1px solid var(--border-color);
      z-index: 1000;
    }

    .search-input {
      width: 100%;
      padding: 14px 20px;
      border: 2px solid var(--border-color);
      border-radius: var(--radius-lg);
      font-size: 15px;
      outline: none;
      transition: all 0.3s ease;
      font-family: inherit;
      background: var(--bg-secondary);
    }

    .search-input:focus {
      border-color: var(--primary-color);
      box-shadow: 0 0 0 4px var(--primary-light);
      background: var(--bg-primary);
    }

    .search-results {
      margin-top: 12px;
      font-size: 13px;
      color: var(--text-secondary);
    }

    /* White Theme Connection Status */
    .connection-status {
      background: var(--bg-secondary);
      color: var(--accent-color);
      padding: 12px 32px;
      text-align: center;
      font-size: 13px;
      font-weight: 500;
      border-bottom: 1px solid var(--border-color);
      transition: all 0.3s ease;
    }

    .connection-status.offline {
      background: #fef2f2;
      color: #dc2626;
    }

    .connection-status.connecting {
      background: #fffbeb;
      color: #d97706;
    }

    /* White Theme Messages Area */
    .messages-container {
      flex: 1;
      background: var(--bg-chat);
      overflow-y: auto;
      padding: 32px;
      position: relative;
      scroll-behavior: smooth;
    }

    .message {
      margin-bottom: 24px;
      display: flex;
      animation: messageSlideIn 0.4s cubic-bezier(0.4, 0, 0.2, 1);
      position: relative;
    }

    @keyframes messageSlideIn {
      from { 
        opacity: 0; 
        transform: translateY(20px) scale(0.95); 
      }
      to { 
        opacity: 1; 
        transform: translateY(0) scale(1); 
      }
    }

    .message-bubble {
      max-width: 70%;
      padding: 16px 20px;
      border-radius: var(--radius-lg);
      position: relative;
      word-wrap: break-word;
      box-shadow: var(--shadow-light);
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      border: 1px solid var(--border-color);
    }

    .message-bubble:hover {
      transform: translateY(-1px);
      box-shadow: var(--shadow-medium);
    }

    .message.employee {
      justify-content: flex-end;
    }

    .message.employee .message-bubble {
      background: var(--primary-light);
      border-bottom-right-radius: 6px;
      border-color: rgba(37, 99, 235, 0.2);
      max-width: 70%;
    }

    .message.employee .message-bubble::before {
      content: '';
      position: absolute;
      bottom: 0;

      width: 0;
      height: 0;
      border: 10px solid transparent;
      border-bottom-color: var(--primary-light);
      border-right: 0;
    }

    .message.dropshipper .message-bubble {
      background: var(--bg-tertiary);
      border-bottom-right-radius: 6px;
      border-color: var(--border-light);
    }

    .message.dropshipper .message-bubble::before {
      content: '';
      position: absolute;
      bottom: 0;
      right: -10px;
      width: 0;
      height: 0;
      border: 10px solid transparent;
      border-bottom-color: var(--bg-tertiary);
      border-right: 0;
    }

    .message.admin {
      justify-content: flex-start;
    }

    .message.admin .message-bubble {
      background: var(--bg-secondary);
      border-bottom-left-radius: 6px;
      max-width: 75%;
      border-color: var(--border-light);
    }

    .message.admin .message-bubble::before {
      content: '';
      position: absolute;
      bottom: 0;
      left: -10px;
      width: 0;
      height: 0;
      border: 10px solid transparent;
      border-bottom-color: var(--bg-secondary);
      border-left: 0;
    }
    .message-text {
      margin-bottom: 10px;
      line-height: 1.6;
      font-size: 15px;
      color: var(--text-primary);
      font-weight: 400;
    }

    .message-time {
      font-size: 11px;
      color: var(--text-muted);
      text-align: right;
      display: flex;
      align-items: center;
      justify-content: flex-end;
      gap: 6px;
      margin-top: 6px;
      font-weight: 500;
    }

    .message.employee .message-time {
      color: var(--text-muted);
    }

    .message.admin .message-time {
      justify-content: center;
      color: var(--text-muted);
    }

    /* White Theme Input Area */
    .input-area {
      background: var(--bg-primary);
      padding: 24px 32px;
      display: flex;
      align-items: flex-end;
      gap: 16px;
      border-top: 1px solid var(--border-color);
    }

    .input-container {
      flex: 1;
      display: flex;
      align-items: flex-end;
      background: var(--bg-secondary);
      border-radius: var(--radius-lg);
      padding: 14px 20px;
      box-shadow: var(--shadow-light);
      border: 2px solid var(--border-color);
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .input-container:focus-within {
      border-color: var(--primary-color);
      box-shadow: 0 0 0 4px var(--primary-light);
      background: var(--bg-primary);
    }

    .message-input {
      flex: 1;
      border: none;
      outline: none;
      font-size: 15px;
      resize: none;
      min-height: 24px;
      max-height: 120px;
      padding: 8px 0;
      background: transparent;
      font-family: inherit;
      line-height: 1.5;
      color: var(--text-primary);
    }

    .message-input::placeholder {
      color: var(--text-muted);
    }

    .emoji-button {
      color: var(--text-muted);
      cursor: pointer;
      margin-right: 12px;
      padding: 8px;
      border-radius: 50%;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      font-size: 18px;
    }

    .emoji-button:hover {
      color: var(--primary-color);
      background: var(--primary-light);
      transform: scale(1.1);
    }

    .send-button {
      width: 60px;
      height: 60px;
      border-radius: 50%;
      background: linear-gradient(135deg, var(--primary-color), var(--primary-dark));
      border: none;
      color: white;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      font-size: 18px;
      box-shadow: var(--shadow-medium);
    }

    .send-button:hover {
      transform: scale(1.05);
      box-shadow: var(--shadow-heavy);
    }

    .send-button:active {
      transform: scale(0.95);
    }

    .send-button:disabled {
      background: linear-gradient(135deg, #d1d5db, #9ca3af);
      cursor: not-allowed;
      transform: none;
      box-shadow: var(--shadow-light);
    }

    /* White Theme Typing Indicator */
    .typing-indicator {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 16px 20px;
      background: var(--bg-secondary);
      border-radius: var(--radius-lg);
      max-width: 140px;
      margin-left: 0;
      box-shadow: var(--shadow-light);
      border: 1px solid var(--border-color);
    }

    .typing-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--text-muted);
      animation: typing 1.4s infinite ease-in-out;
    }

    .typing-dot:nth-child(1) { animation-delay: 0s; }
    .typing-dot:nth-child(2) { animation-delay: 0.2s; }
    .typing-dot:nth-child(3) { animation-delay: 0.4s; }

    @keyframes typing {
      0%, 60%, 100% { 
        transform: translateY(0);
        opacity: 0.4;
      }
      30% { 
        transform: translateY(-12px);
        opacity: 1;
      }
    }

    /* White Theme Notification */
    .notification {
      position: fixed;
      top: 30px;
      right: 30px;
      background: var(--bg-primary);
      color: var(--text-primary);
      padding: 18px 28px;
      border-radius: var(--radius-md);
      box-shadow: var(--shadow-heavy);
      transform: translateX(400px);
      transition: all 0.4s cubic-bezier(0.68, -0.55, 0.265, 1.55);
      z-index: 1000;
      font-weight: 500;
      display: flex;
      align-items: center;
      gap: 12px;
      border: 1px solid var(--border-color);
    }

    .notification.show {
      transform: translateX(0);
    }

    .notification.error {
      background: #fef2f2;
      color: #dc2626;
      border-color: #fecaca;
    }

    .notification i {
      font-size: 18px;
      color: var(--accent-color);
    }

    .notification.error i {
      color: #dc2626;
    }

    /* White Theme Custom Scrollbar */
    .messages-container::-webkit-scrollbar {
      width: 6px;
    }

    .messages-container::-webkit-scrollbar-track {
      background: var(--bg-secondary);
      border-radius: 3px;
    }

    .messages-container::-webkit-scrollbar-thumb {
      background: var(--border-color);
      border-radius: 3px;
      transition: background 0.3s ease;
    }

    .messages-container::-webkit-scrollbar-thumb:hover {
      background: var(--text-muted);
    }

    /* White Theme Online indicator */
    .online-indicator {
      width: 14px;
      height: 14px;
      background: var(--accent-color);
      border: 3px solid white;
      border-radius: 50%;
      position: absolute;
      bottom: -2px;
      right: -2px;
      animation: pulse 2s infinite;
      box-shadow: var(--shadow-light);
    }

    @keyframes pulse {
      0% { 
        box-shadow: var(--shadow-light), 0 0 0 0 rgba(16, 185, 129, 0.7);
      }
      70% { 
        box-shadow: var(--shadow-light), 0 0 0 15px rgba(16, 185, 129, 0);
      }
      100% { 
        box-shadow: var(--shadow-light), 0 0 0 0 rgba(16, 185, 129, 0);
      }
    }

    /* Loading animation */
    .loading-messages {
      display: flex;
      justify-content: center;
      align-items: center;
      height: 120px;
      color: var(--text-secondary);
      font-style: italic;
      flex-direction: column;
      gap: 16px;
    }

    .loading-spinner {
      animation: spin 1s linear infinite;
      font-size: 24px;
      color: var(--primary-color);
    }

    @keyframes spin {
      from { transform: rotate(0deg); }
      to { transform: rotate(360deg); }
    }

    /* Enhanced Responsive Design */
    @media (max-width: 768px) {
      body {
        padding: 0;
      }
      
      .whatsapp-container {
        width: 100%;
        height: 100vh;
        border-radius: 0;
        max-width: none;
      }
      
      .chat-header {
        padding: 16px 20px;
      }
      
      .chat-profile-pic {
        width: 48px;
        height: 48px;
        font-size: 20px;
      }
      
      .chat-info h4 {
        font-size: 18px;
      }
      
      .messages-container {
        padding: 24px 16px;
      }
      
      .input-area {
        padding: 16px 20px;
        gap: 12px;
      }
      
      .message-bubble {
        max-width: 85%;
        padding: 14px 16px;
      }

      .send-button {
        width: 52px;
        height: 52px;
        font-size: 16px;
      }

      .notification {
        top: 20px;
        right: 20px;
        left: 20px;
        transform: translateY(-100px);
        padding: 16px 20px;
      }

      .notification.show {
        transform: translateY(0);
      }
    }

    @media (max-width: 480px) {
      .chat-header {
        padding: 14px 16px;
        gap: 16px;
      }

      .chat-profile-pic {
        width: 44px;
        height: 44px;
        font-size: 18px;
      }

      .chat-info h4 {
        font-size: 16px;
      }

      .chat-info p {
        font-size: 13px;
      }

      .message-bubble {
        max-width: 90%;
        font-size: 14px;
        padding: 12px 14px;
      }

      .input-area {
        padding: 14px 16px;
      }

      .send-button {
        width: 48px;
        height: 48px;
        font-size: 15px;
      }
    }

    /* Search highlight */
    .message.highlight {
      background: rgba(37, 99, 235, 0.1) !important;
      border-radius: var(--radius-md) !important;
      padding: 4px !important;
      margin: 2px 0 !important;
    }

    /* Status indicators */
    .status-sent { color: var(--text-muted); }
    .status-delivered { color: var(--text-muted); }
    .status-read { color: var(--primary-color); }
    .status-sending { color: var(--text-muted); animation: pulse-opacity 1s infinite; }

    @keyframes pulse-opacity {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.5; }
    }
  </style>
</head>
<body>
  <!-- WhatsApp Container -->
  <div class="whatsapp-container">
    <!-- Chat Header -->
    <div class="chat-header">
      <i class="fas fa-arrow-left back-button" onclick="goBack()" title="Back"></i>
      <div class="chat-profile-pic">
        <i class="fas fa-comments"></i>
        <div class="online-indicator"></div>
      </div>
      <div class="chat-info">
        <h4 id="chatTitle">Plan Step Chat</h4>
        <p id="chatSubtitle">Dropshipper Communication Channel</p>
      </div>
      <div class="chat-actions">
        <i class="fas fa-sync-alt" title="Refresh Messages" onclick="loadMessages()"></i>
        <i class="fas fa-search" title="Search Messages" onclick="toggleSearch()"></i>
        <i class="fas fa-ellipsis-v" title="More Options"></i>
      </div>
      <div class="search-container" id="searchContainer">
        <input type="text" class="search-input" id="searchInput" placeholder="Search messages..." oninput="performSearch()">
        <div class="search-results" id="searchResults"></div>
      </div>
    </div>

    <!-- Connection Status -->
    <div class="connection-status" id="connectionStatus">
      <i class="fas fa-circle" style="font-size: 8px; margin-right: 8px;"></i>
      Connected and ready
    </div>

    <!-- Messages -->
    <div class="messages-container" id="messagesContainer">
      <div class="loading-messages">
        <i class="fas fa-spinner loading-spinner"></i>
        <span>Loading messages...</span>
      </div>
    </div>

    <!-- Input Area -->
    <div class="input-area">
      <div class="input-container">
        <i class="fas fa-smile emoji-button" title="Add emoji"></i>
        <textarea 
          class="message-input" 
          id="messageInput" 
          placeholder="Type a message..."
          rows="1"
          onkeypress="handleKeyPress(event)"
          oninput="autoResize(this)"
        ></textarea>
      </div>
      <button class="send-button" onclick="sendMessage()" id="sendButton" title="Send message">
        <i class="fas fa-paper-plane"></i>
      </button>
    </div>
  </div>

  <!-- Notification -->
  <div class="notification" id="notification">
    <i class="fas fa-check-circle"></i>
    <span id="notificationText"></span>
  </div>

  <script>
    const API_BASE = "https://customprint.deodap.com/api_dropshipper_tracker";
    let isLoading = false;
    let lastMessageCount = 0;
    let autoRefreshInterval = null;
    let chatConfig = {
      plan_step_id: null,
      emp_id: '<?php echo htmlspecialchars($emp_id, ENT_QUOTES, "UTF-8"); ?>',
      sender_type: 'employee',
      stepStatus: 'Unknown'
    };

    // Initialize app
    document.addEventListener('DOMContentLoaded', function() {
      initializeFromURL();
      document.getElementById("messageInput").focus();
    });

    async function initializeFromURL() {
      const urlParams = new URLSearchParams(window.location.search);
      const dropshipperId = urlParams.get('dropshipper_id');
      const planStepId = urlParams.get('plan_step_id');
      const empId = urlParams.get('emp_id');

      if (!dropshipperId || !planStepId) {
        showNotification('Missing required URL parameters: dropshipper_id and plan_step_id. Please provide valid values in the URL.', 'error');
        updateConnectionStatus('offline');
        return;
      }

      chatConfig.dropshipper_id = dropshipperId;
      chatConfig.plan_step_id = planStepId;
      if (empId) chatConfig.emp_id = empId;

      // Update chat header with basic info first
      document.getElementById('chatTitle').textContent = `Plan Step #${chatConfig.plan_step_id} Chat`;

      // Fetch and update with detailed information
      await loadStepAndDropshipperDetails();
      loadMessages();
      startAutoRefresh();
    }

    async function loadStepAndDropshipperDetails() {
      try {
        updateConnectionStatus('connecting');

        // Fetch dropshipper details
        let dropshipperName = 'Unknown Dropshipper';
        try {
          const dropshipperRes = await fetch(`${API_BASE}/one_dropshipper_details.php?dropshipper_id=${chatConfig.dropshipper_id}`);
          const dropshipperData = await dropshipperRes.json();
          if (dropshipperData.success && dropshipperData.dropshipper) {
            dropshipperName = dropshipperData.dropshipper.seller_name || dropshipperData.dropshipper.store_name || 'Unknown Dropshipper';
          }
        } catch (err) {
          console.warn('Failed to fetch dropshipper details:', err);
        }

        // Fetch step details from the plan data
        let stepName = `Step ${chatConfig.plan_step_id}`;
        let stepStatus = 'Unknown';
        try {
          const planRes = await fetch(`${API_BASE}/one_dropshipper_plan.php?dropshipper_id=${chatConfig.dropshipper_id}`);
          const planData = await planRes.json();
          // Find the step across all plans
          for (const plan of planData.plans) {
            const step = plan.steps.find(s => s.step_id == chatConfig.plan_step_id);
            if (step) {
              stepName = step.step_description || `Step ${step.step_id}`;
              stepStatus = step.status || 'Unknown';
              break;
            }
          }
        } catch (err) {
          console.warn('Failed to fetch step details:', err);
        }

        // Save stepStatus in chatConfig for later use
        chatConfig.stepStatus = stepStatus;

        // Update chat header with detailed information
        document.getElementById('chatTitle').textContent = `${stepName} - ${dropshipperName}`;
        document.getElementById('chatSubtitle').textContent = `Plan Step #${chatConfig.plan_step_id} • Status: ${stepStatus} • Communication Channel`;
        updateConnectionStatus('connected');

      } catch (err) {
        console.error('Failed to load step and dropshipper details:', err);
        updateConnectionStatus('offline');
        document.getElementById('chatSubtitle').textContent = 'Dropshipper Communication Channel';
      }
    }

    function startAutoRefresh() {
      if (autoRefreshInterval) clearInterval(autoRefreshInterval);
      autoRefreshInterval = setInterval(() => {
        if (!isLoading && document.visibilityState === 'visible') {
          loadMessages();
        }
      }, 3000);
    }

    function autoResize(textarea) {
      textarea.style.height = 'auto';
      textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px';
    }

    function handleKeyPress(event) {
      if (event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        sendMessage();
      }
    }

    async function loadMessages() {
      if (isLoading) return;

      try {
        isLoading = true;
        updateConnectionStatus('connecting');

        const res = await fetch(`${API_BASE}/get_chat_history.php?plan_step_id=${chatConfig.plan_step_id}&dropshipper_id=${chatConfig.dropshipper_id}`);
        const json = await res.json();

        const container = document.getElementById("messagesContainer");

        if (json.success && json.messages) {
          if (json.messages.length !== lastMessageCount) {
            container.innerHTML = "";
            if (json.messages.length === 0) {
              addMessageToChat({sender_type: 'admin', message: 'No messages yet. Start the conversation!', created_at: 'Now', status: 'sent'});
            } else {
              json.messages.forEach(message => {
                message.status = 'sent';
                if (message.sender_type !== chatConfig.sender_type) {
                  message.status = 'read';
                }
                addMessageToChat(message);
              });
            }
            lastMessageCount = json.messages.length;
          }
          updateConnectionStatus('connected');
        } else {
          if (lastMessageCount === 0) {
            container.innerHTML = "";
            addMessageToChat({sender_type: 'admin', message: 'Ready to start chatting! Send your first message.', created_at: 'Now'});
          }
          updateConnectionStatus('connected');
        }
      } catch (err) {
        updateConnectionStatus('offline');
        if (lastMessageCount === 0) {
          const container = document.getElementById("messagesContainer");
          container.innerHTML = "";
          addMessageToChat({sender_type: 'admin', message: 'Connection error. Please check your internet and try again.', created_at: 'Now'});
        }
        console.error('Failed to load messages:', err);
      } finally {
        isLoading = false;
      }
    }

    function updateConnectionStatus(status) {
      const statusEl = document.getElementById('connectionStatus');
      statusEl.className = 'connection-status';

      switch(status) {
        case 'connecting':
          statusEl.classList.add('connecting');
          statusEl.innerHTML = '<i class="fas fa-spinner fa-spin" style="font-size: 8px; margin-right: 8px;"></i>Connecting...';
          break;
        case 'connected':
          statusEl.innerHTML = '<i class="fas fa-circle" style="font-size: 8px; margin-right: 8px; color: #10b981;"></i>Connected and ready';
          break;
        case 'offline':
          statusEl.classList.add('offline');
          statusEl.innerHTML = '<i class="fas fa-exclamation-triangle" style="font-size: 8px; margin-right: 8px;"></i>Connection lost';
          break;
      }
    }

    async function sendMessage() {
      const messageInput = document.getElementById("messageInput");
      const sendButton = document.getElementById("sendButton");
      const message = messageInput.value.trim();

      // Check if status is pending or completed
      if (chatConfig.stepStatus) {
        const status = chatConfig.stepStatus.toLowerCase();

        if (status === 'pending') {
          showNotification('Cannot send message: This step is still pending.', 'error');
          return;
        }

        if (status === 'completed') {
          showNotification('Cannot send message: This step has already been completed.', 'error');
          return;
        }
      }

      const data = {
        plan_step_id: chatConfig.plan_step_id,
        emp_id: chatConfig.emp_id,
        dropshipper_id: chatConfig.dropshipper_id,
        sender_type: chatConfig.sender_type,
        message: message
      };

      // Disable input
      sendButton.disabled = true;
      messageInput.disabled = true;

      // Add message immediately to UI
      addMessageToChat({sender_type: data.sender_type, message: data.message, created_at: "Now", status: 'sending'});
      messageInput.value = "";
      messageInput.style.height = 'auto';

      setTimeout(() => showTypingIndicator('receiver'), 500);

      try {
        updateConnectionStatus('connecting');
        const res = await fetch(`${API_BASE}/chatt.php`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(data)
        });

        const json = await res.json();

        if (json.success) {
          updateConnectionStatus('connected');
          showNotification('Message sent successfully!');
          setTimeout(() => loadMessages(), 1000);
        } else {
          addMessageToChat({sender_type: 'admin', message: `Error: ${json.message || 'Failed to send message'}`, created_at: 'Now'});
          showNotification(`Error: ${json.message || 'Failed to send message'}`, 'error');
        }
      } catch (err) {
        addMessageToChat({sender_type: 'admin', message: 'Network error. Please check your connection and try again.', created_at: 'Now'});
        showNotification('Network error. Please try again.', 'error');
        updateConnectionStatus('offline');
        console.error('Send message error:', err);
      } finally {
        sendButton.disabled = false;
        messageInput.disabled = false;
        messageInput.focus();
      }
    }

    function addMessageToChat(message) {
      let senderType, messageText, timestamp, status;
      if (typeof message === 'object') {
        senderType = message.sender_type;
        messageText = message.message;
        timestamp = message.created_at;
        status = message.status || 'sent';
      } else {
        senderType = arguments[0];
        messageText = arguments[1];
        timestamp = arguments[2];
        status = 'delivered';
      }

      const container = document.getElementById("messagesContainer");

      const messageDiv = document.createElement("div");
      let cssClass = '';
      if (senderType === 'admin') {
        cssClass = 'admin';
      } else if (senderType === 'employee' || senderType === 'dropshipper') {
        cssClass = 'employee';
      } else {
        cssClass = senderType;
      }
      messageDiv.className = `message ${cssClass}`;

      const bubble = document.createElement("div");
      bubble.className = "message-bubble";

      const textDiv = document.createElement("div");
      textDiv.className = "message-text";
      textDiv.textContent = messageText;

      const timeDiv = document.createElement("div");
      timeDiv.className = "message-time";

      const time = formatTime(timestamp);
      let statusIcon = '';
      if (senderType === 'employee' || senderType === 'admin') {
        if (status === 'sending') {
          statusIcon = ' <i class="fas fa-clock status-sending" title="Sending"></i>';
        } else if (status === 'sent') {
          statusIcon = ' <i class="fas fa-check status-sent" title="Sent"></i>';
        } else if (status === 'delivered') {
          statusIcon = ' <i class="fas fa-check-double status-delivered" title="Delivered"></i>';
        } else if (status === 'read') {
          statusIcon = ' <i class="fas fa-check-double status-read" title="Read"></i>';
        }
      }

      timeDiv.innerHTML = `<span>${time}</span>${statusIcon}`;

      bubble.appendChild(textDiv);
      bubble.appendChild(timeDiv);
      messageDiv.appendChild(bubble);
      container.appendChild(messageDiv);

      // Scroll to bottom smoothly
      requestAnimationFrame(() => {
        container.scrollTop = container.scrollHeight;
      });
    }

    function formatTime(timestamp) {
      if (timestamp === 'Now' || timestamp === 'Just now') return 'Now';

      try {
        const date = new Date(timestamp);
        const now = new Date();

        if (date.toDateString() === now.toDateString()) {
          return date.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: false
          });
        } else {
          return date.toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: false
          });
        }
      } catch {
        return timestamp;
      }
    }

    function showTypingIndicator(typingSide = 'sender') {
      const subtitleEl = document.getElementById("chatSubtitle");
      const originalText = subtitleEl.textContent;

      subtitleEl.textContent = "Typing...";
      subtitleEl.style.fontStyle = "italic";
      subtitleEl.style.color = "var(--primary-color)";

      setTimeout(() => {
        subtitleEl.textContent = originalText;
        subtitleEl.style.fontStyle = "";
        subtitleEl.style.color = "";
      }, 2500);
    }

    function showNotification(message, type = 'success') {
      const notification = document.getElementById('notification');
      const notificationText = document.getElementById('notificationText');
      const icon = notification.querySelector('i');

      notificationText.textContent = message;

      if (type === 'error') {
        notification.className = 'notification error';
        icon.className = 'fas fa-exclamation-circle';
      } else {
        notification.className = 'notification';
        icon.className = 'fas fa-check-circle';
      }

      notification.classList.add('show');

      setTimeout(() => {
        notification.classList.remove('show');
      }, 4000);
    }

    function goBack() {
      if (document.referrer) {
        window.history.back();
      } else {
        window.location.href = 'dashboard.php';
      }
    }

    // Enhanced emoji functionality
    document.querySelector('.emoji-button').addEventListener('click', function() {
      const input = document.getElementById('messageInput');
      const emojis = ['😊', '👍', '❤️', '😄', '🎉', '✅', '👋', '🔥', '💼', '📦', '🚀', '⭐'];
      const randomEmoji = emojis[Math.floor(Math.random() * emojis.length)];
      input.value += randomEmoji;
      input.focus();
      autoResize(input);
    });

    // Handle page unload
    window.addEventListener('beforeunload', function() {
      if (autoRefreshInterval) {
        clearInterval(autoRefreshInterval);
      }
    });

    // Handle visibility change for efficient polling
    document.addEventListener('visibilitychange', function() {
      if (document.visibilityState === 'visible') {
        loadMessages();
      }
    });

    // Enhanced search functionality
    function toggleSearch() {
      const searchContainer = document.getElementById('searchContainer');
      const searchInput = document.getElementById('searchInput');
      const searchResults = document.getElementById('searchResults');

      if (searchContainer.style.display === 'none' || searchContainer.style.display === '') {
        searchContainer.style.display = 'block';
        searchInput.focus();
      } else {
        searchContainer.style.display = 'none';
        searchResults.innerHTML = '';
        // Clear highlights
        document.querySelectorAll('.message').forEach(message => {
          message.classList.remove('highlight');
        });
      }
    }

    function performSearch() {
      const searchInput = document.getElementById('searchInput');
      const searchResults = document.getElementById('searchResults');
      const query = searchInput.value.toLowerCase().trim();

      // Clear previous highlights
      document.querySelectorAll('.message').forEach(message => {
        message.classList.remove('highlight');
      });

      if (!query) {
        searchResults.innerHTML = '';
        return;
      }

      const messages = document.querySelectorAll('.message');
      let matchCount = 0;
      let firstMatch = null;

      messages.forEach((message, index) => {
        const messageText = message.querySelector('.message-text').textContent.toLowerCase();

        if (messageText.includes(query)) {
          matchCount++;
          if (!firstMatch) {
            firstMatch = message;
          }

          message.classList.add('highlight');
        }
      });

      if (matchCount > 0) {
        searchResults.innerHTML = `<div style="color: var(--primary-color); font-weight: 600;">Found ${matchCount} message${matchCount > 1 ? 's' : ''} containing "${query}"</div>`;
        if (firstMatch) {
          firstMatch.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      } else {
        searchResults.innerHTML = `<div style="color: var(--text-secondary);">No messages found for "${query}"</div>`;
      }
    }

    // Close search when clicking outside
    document.addEventListener('click', function(event) {
      const searchContainer = document.getElementById('searchContainer');
      const searchIcon = document.querySelector('.fa-search');

      if (!searchContainer.contains(event.target) && event.target !== searchIcon) {
        searchContainer.style.display = 'none';
        document.getElementById('searchInput').value = '';
        document.getElementById('searchResults').innerHTML = '';
        // Clear highlights
        document.querySelectorAll('.message').forEach(message => {
          message.classList.remove('highlight');
        });
      }
    });
  </script>
    const API_BASE = "https://customprint.deodap.com/api_dropshipper_tracker";
    let isLoading = false;
    let lastMessageCount = 0;
    let autoRefreshInterval = null;
    let chatConfig = {
      plan_step_id: null,
      emp_id: '<?php echo htmlspecialchars($emp_id, ENT_QUOTES, "UTF-8"); ?>',

      sender_type: 'employee',
      stepStatus: 'Unknown'
    };

    // Initialize app
    document.addEventListener('DOMContentLoaded', function() {
      initializeFromURL();
      document.getElementById("messageInput").focus();
    });

    async function initializeFromURL() {
      const urlParams = new URLSearchParams(window.location.search);
      const dropshipperId = urlParams.get('dropshipper_id');
    async function loadStepAndDropshipperDetails() {
      try {
    function startAutoRefresh() {

        // Fetch dropshipper details
        let dropshipperName = 'Unknown Dropshipper';
        try {
          const dropshipperRes = await fetch(`${API_BASE}/one_dropshipper_details.php?dropshipper_id=${chatConfig.dropshipper_id}`);
          const dropshipperData = await dropshipperRes.json();
          if (dropshipperData.success && dropshipperData.dropshipper) {
            dropshipperName = dropshipperData.dropshipper.seller_name || dropshipperData.dropshipper.store_name || 'Unknown Dropshipper';
          }
        } catch (err) {
          console.warn('Failed to fetch dropshipper details:', err);
        }

        // Fetch step details from the plan data
        let stepName = `Step ${chatConfig.plan_step_id}`;
        let stepStatus = 'Unknown';
        try {
          const planRes = await fetch(`${API_BASE}/one_dropshipper_plan.php?dropshipper_id=${chatConfig.dropshipper_id}`);
          const planData = await planRes.json();
          // Find the step across all plans
          for (const plan of planData.plans) {
            const step = plan.steps.find(s => s.step_id == chatConfig.plan_step_id);
            if (step) {
              stepName = step.step_description || `Step ${step.step_id}`;
              stepStatus = step.status || 'Unknown';
      if (autoRefreshInterval) clearInterval(autoRefreshInterval);
            }
          }
        } catch (err) {
          console.warn('Failed to fetch step details:', err);
        }

        // Save stepStatus in chatConfig for later use
        chatConfig.stepStatus = stepStatus;

        // Update chat header with detailed information
        document.getElementById('chatTitle').textContent = `${stepName} - ${dropshipperName}`;
        document.getElementById('chatSubtitle').textContent = `Plan Step #${chatConfig.plan_step_id} • Status: ${stepStatus} • Communication Channel`;
        updateConnectionStatus('connected');

      } catch (err) {
        console.error('Failed to load step and dropshipper details:', err);
        updateConnectionStatus('offline');

        document.getElementById('chatSubtitle').textContent = 'Dropshipper Communication Channel';
      }
    }
      autoRefreshInterval = setInterval(() => {
        if (!isLoading && document.visibilityState === 'visible') {
          loadMessages();
        }
      }, 3000);
    }

    function autoResize(textarea) {
      textarea.style.height = 'auto';
      textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px';
    }

    function handleKeyPress(event) {
      if (event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        sendMessage();
      }
    }

    async function loadMessages() {
      if (isLoading) return;

      try {
        isLoading = true;
        updateConnectionStatus('connecting');
        
        const res = await fetch(`${API_BASE}/get_chat_history.php?plan_step_id=${chatConfig.plan_step_id}&dropshipper_id=${chatConfig.dropshipper_id}`);
        const json = await res.json();

        const container = document.getElementById("messagesContainer");
        
        if (json.success && json.messages) {
          if (json.messages.length !== lastMessageCount) {
            container.innerHTML = "";
            if (json.messages.length === 0) {
              addMessageToChat({sender_type: 'admin', message: 'No messages yet. Start the conversation!', created_at: 'Now', status: 'sent'});
            } else {
              json.messages.forEach(message => {
                message.status = 'sent';
                if (message.sender_type !== chatConfig.sender_type) {
                  message.status = 'read';
                }
                addMessageToChat(message);
              });
            }
            lastMessageCount = json.messages.length;
          }
          updateConnectionStatus('connected');
        } else {
          if (lastMessageCount === 0) {
            container.innerHTML = "";
            addMessageToChat({sender_type: 'admin', message: 'Ready to start chatting! Send your first message.', created_at: 'Now'});
          }
          updateConnectionStatus('connected');
        }
      } catch (err) {
        updateConnectionStatus('offline');
        if (lastMessageCount === 0) {
          const container = document.getElementById("messagesContainer");
          container.innerHTML = "";
          addMessageToChat({sender_type: 'admin', message: 'Connection error. Please check your internet and try again.', created_at: 'Now'});
        }
        console.error('Failed to load messages:', err);
      } finally {
        isLoading = false;
      }
    }

    function updateConnectionStatus(status) {
      const statusEl = document.getElementById('connectionStatus');
      statusEl.className = 'connection-status';
      
      switch(status) {
        case 'connecting':
          statusEl.classList.add('connecting');
          statusEl.innerHTML = '<i class="fas fa-spinner fa-spin" style="font-size: 8px; margin-right: 8px;"></i>Connecting...';
          break;
        case 'connected':
          statusEl.innerHTML = '<i class="fas fa-circle" style="font-size: 8px; margin-right: 8px; color: #10b981;"></i>Connected and ready';
          break;
        case 'offline':
          statusEl.classList.add('offline');
          statusEl.innerHTML = '<i class="fas fa-exclamation-triangle" style="font-size: 8px; margin-right: 8px;"></i>Connection lost';
          break;
      }
    }

    async function sendMessage() {
      const messageInput = document.getElementById("messageInput");
      const sendButton = document.getElementById("sendButton");
      const message = messageInput.value.trim();

// Check if status is pending or completed
if (chatConfig.stepStatus) {
  const status = chatConfig.stepStatus.toLowerCase();

  if (status === 'pending') {
    showNotification('Cannot send message: This step is still pending.', 'error');
    return;
  }

  if (status === 'completed') {
    showNotification('Cannot send message: This step has already been completed.', 'error');
    return;
  }
}


      const data = {
        plan_step_id: chatConfig.plan_step_id,
        emp_id: chatConfig.emp_id,
        dropshipper_id: chatConfig.dropshipper_id,
        sender_type: chatConfig.sender_type,
        message: message
      };

      // Disable input
      sendButton.disabled = true;
      messageInput.disabled = true;

      // Add message immediately to UI
      addMessageToChat({sender_type: data.sender_type, message: data.message, created_at: "Now", status: 'sending'});
      messageInput.value = "";
      messageInput.style.height = 'auto';

      setTimeout(() => showTypingIndicator('receiver'), 500);

      try {
        updateConnectionStatus('connecting');
        const res = await fetch(`${API_BASE}/chatt.php`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(data)
        });

        const json = await res.json();

        if (json.success) {
          updateConnectionStatus('connected');
          showNotification('Message sent successfully!');
          setTimeout(() => loadMessages(), 1000);
        } else {
          addMessageToChat({sender_type: 'admin', message: `Error: ${json.message || 'Failed to send message'}`, created_at: 'Now'});
          showNotification(`Error: ${json.message || 'Failed to send message'}`, 'error');
        }
      } catch (err) {
        addMessageToChat({sender_type: 'admin', message: 'Network error. Please check your connection and try again.', created_at: 'Now'});
        showNotification('Network error. Please try again.', 'error');
        updateConnectionStatus('offline');
        console.error('Send message error:', err);
      } finally {
        sendButton.disabled = false;
        messageInput.disabled = false;
        messageInput.focus();
      }
    }

    function addMessageToChat(message) {
      let senderType, messageText, timestamp, status;
      if (typeof message === 'object') {
        senderType = message.sender_type;
        messageText = message.message;
        timestamp = message.created_at;
        status = message.status || 'sent';
      } else {
        senderType = arguments[0];
        messageText = arguments[1];
        timestamp = arguments[2];
        status = 'delivered';
      }

      const container = document.getElementById("messagesContainer");

      const messageDiv = document.createElement("div");
      let cssClass = '';
      if (senderType === 'admin') {
        cssClass = 'admin';
      } else if (senderType === 'employee' || senderType === 'dropshipper') {
        cssClass = 'employee';
      } else {
        cssClass = senderType;
      }
      messageDiv.className = `message ${cssClass}`;

      const bubble = document.createElement("div");
      bubble.className = "message-bubble";

      const textDiv = document.createElement("div");
      textDiv.className = "message-text";
      textDiv.textContent = messageText;

      const timeDiv = document.createElement("div");
      timeDiv.className = "message-time";

      const time = formatTime(timestamp);
      let statusIcon = '';
      if (senderType === 'employee' || senderType === 'admin') {
        if (status === 'sending') {
          statusIcon = ' <i class="fas fa-clock status-sending" title="Sending"></i>';
        } else if (status === 'sent') {
          statusIcon = ' <i class="fas fa-check status-sent" title="Sent"></i>';
        } else if (status === 'delivered') {
          statusIcon = ' <i class="fas fa-check-double status-delivered" title="Delivered"></i>';
        } else if (status === 'read') {
          statusIcon = ' <i class="fas fa-check-double status-read" title="Read"></i>';
        }
      }

      timeDiv.innerHTML = `<span>${time}</span>${statusIcon}`;

      bubble.appendChild(textDiv);
      bubble.appendChild(timeDiv);
      messageDiv.appendChild(bubble);
      container.appendChild(messageDiv);

      // Scroll to bottom smoothly
      requestAnimationFrame(() => {
        container.scrollTop = container.scrollHeight;
      });
    }

    function formatTime(timestamp) {
      if (timestamp === 'Now' || timestamp === 'Just now') return 'Now';

      try {
        const date = new Date(timestamp);
        const now = new Date();

        if (date.toDateString() === now.toDateString()) {
          return date.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: false
          });
        } else {
          return date.toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: false
          });
        }
      } catch {
        return timestamp;
      }
    }

    function showTypingIndicator(typingSide = 'sender') {
      const subtitleEl = document.getElementById("chatSubtitle");
      const originalText = subtitleEl.textContent;

      subtitleEl.textContent = "Typing...";
      subtitleEl.style.fontStyle = "italic";
      subtitleEl.style.color = "var(--primary-color)";

      setTimeout(() => {
        subtitleEl.textContent = originalText;
        subtitleEl.style.fontStyle = "";
        subtitleEl.style.color = "";
      }, 2500);
    }

    function showNotification(message, type = 'success') {
      const notification = document.getElementById('notification');
      const notificationText = document.getElementById('notificationText');
      const icon = notification.querySelector('i');

      notificationText.textContent = message;

      if (type === 'error') {
        notification.className = 'notification error';
        icon.className = 'fas fa-exclamation-circle';
      } else {
        notification.className = 'notification';
        icon.className = 'fas fa-check-circle';
      }

      notification.classList.add('show');

      setTimeout(() => {
        notification.classList.remove('show');
      }, 4000);
    }

    function goBack() {
      if (document.referrer) {
        window.history.back();
      } else {
        window.location.href = 'dashboard.php';
      }
    }

    // Enhanced emoji functionality
    document.querySelector('.emoji-button').addEventListener('click', function() {
      const input = document.getElementById('messageInput');
      const emojis = ['😊', '👍', '❤️', '😄', '🎉', '✅', '👋', '🔥', '💼', '📦', '🚀', '⭐'];
      const randomEmoji = emojis[Math.floor(Math.random() * emojis.length)];
      input.value += randomEmoji;
      input.focus();
      autoResize(input);
    });

    // Handle page unload
    window.addEventListener('beforeunload', function() {
      if (autoRefreshInterval) {
        clearInterval(autoRefreshInterval);
      }
    });

    // Handle visibility change for efficient polling
    document.addEventListener('visibilitychange', function() {
      if (document.visibilityState === 'visible') {
        loadMessages();
      }
    });

    // Enhanced search functionality
    function toggleSearch() {
      const searchContainer = document.getElementById('searchContainer');
      const searchInput = document.getElementById('searchInput');
      const searchResults = document.getElementById('searchResults');

      if (searchContainer.style.display === 'none' || searchContainer.style.display === '') {
        searchContainer.style.display = 'block';
        searchInput.focus();
      } else {
        searchContainer.style.display = 'none';
        searchResults.innerHTML = '';
        // Clear highlights
        document.querySelectorAll('.message').forEach(message => {
          message.classList.remove('highlight');
        });
      }
    }

    function performSearch() {
      const searchInput = document.getElementById('searchInput');
      const searchResults = document.getElementById('searchResults');
      const query = searchInput.value.toLowerCase().trim();

      // Clear previous highlights
      document.querySelectorAll('.message').forEach(message => {
        message.classList.remove('highlight');
      });

      if (!query) {
        searchResults.innerHTML = '';
        return;
      }

      const messages = document.querySelectorAll('.message');
      let matchCount = 0;
      let firstMatch = null;

      messages.forEach((message, index) => {
        const messageText = message.querySelector('.message-text').textContent.toLowerCase();

        if (messageText.includes(query)) {
          matchCount++;
          if (!firstMatch) {
            firstMatch = message;
          }

          message.classList.add('highlight');
        }
      });

      if (matchCount > 0) {
        searchResults.innerHTML = `<div style="color: var(--primary-color); font-weight: 600;">Found ${matchCount} message${matchCount > 1 ? 's' : ''} containing "${query}"</div>`;
        if (firstMatch) {
          firstMatch.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      } else {
        searchResults.innerHTML = `<div style="color: var(--text-secondary);">No messages found for "${query}"</div>`;
      }
    }

    // Close search when clicking outside
    document.addEventListener('click', function(event) {
      const searchContainer = document.getElementById('searchContainer');
      const searchIcon = document.querySelector('.fa-search');

      if (!searchContainer.contains(event.target) && event.target !== searchIcon) {
        searchContainer.style.display = 'none';
        document.getElementById('searchInput').value = '';
        document.getElementById('searchResults').innerHTML = '';
        // Clear highlights
        document.querySelectorAll('.message').forEach(message => {
          message.classList.remove('highlight');
        });
      }
    });
  </script>
</body>
</html>
    // Close search when clicking outside
    document.addEventListener('click', function(event) {
      const searchContainer = document.getElementById('searchContainer');
      const searchIcon = document.querySelector('.fa-search');

      if (!searchContainer.contains(event.target) && event.target !== searchIcon) {
        searchContainer.style.display = 'none';
        document.getElementById('searchInput').value = '';
        document.getElementById('searchResults').innerHTML = '';
        // Clear highlights
        document.querySelectorAll('.message').forEach(message => {
          message.classList.remove('highlight');
        });
      }
    });
  </script>
</body>
</html>
