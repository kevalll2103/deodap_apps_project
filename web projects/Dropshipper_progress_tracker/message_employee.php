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
  <title>Plan Step Chat - Employee</title>
  <link rel="icon" href="assets/favicon.png" />
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <style>
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

    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
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

    /* Chat Header */
    .chat-header {
      background: var(--bg-primary);
      color: var(--text-primary);
      padding: 20px 24px;
      display: flex;
      align-items: center;
      gap: 16px;
      border-bottom: 1px solid var(--border-color);
    }

    .back-button {
      cursor: pointer;
      padding: 8px;
      border-radius: 50%;
      transition: all 0.2s ease;
      color: var(--text-secondary);
    }

    .back-button:hover {
      background-color: var(--bg-secondary);
      color: var(--primary-color);
    }

    .chat-profile-pic {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      background: linear-gradient(135deg, var(--primary-light), var(--bg-secondary));
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--primary-color);
      font-size: 20px;
      box-shadow: var(--shadow-light);
      border: 2px solid var(--border-light);
      position: relative;
    }

    .online-indicator {
      position: absolute;
      bottom: 2px;
      right: 2px;
      width: 12px;
      height: 12px;
      background: var(--accent-color);
      border-radius: 50%;
      border: 2px solid white;
    }

    .chat-info {
      flex: 1;
    }

    .chat-info h4 {
      margin: 0;
      font-size: 18px;
      font-weight: 600;
      margin-bottom: 4px;
      color: var(--text-primary);
    }

    .chat-info p {
      margin: 0;
      font-size: 13px;
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
      padding: 8px;
      border-radius: 50%;
      transition: all 0.2s ease;
      font-size: 16px;
    }

    .chat-actions i:hover {
      background-color: var(--bg-secondary);
      color: var(--primary-color);
    }

    .search-container {
      position: absolute;
      top: 100%;
      left: 0;
      right: 0;
      background: white;
      border: 1px solid var(--border-color);
      border-top: none;
      padding: 12px;
      display: none;
      z-index: 1000;
    }

    .search-input {
      width: 100%;
      padding: 8px 12px;
      border: 1px solid var(--border-color);
      border-radius: var(--radius-sm);
      font-size: 14px;
      outline: none;
    }

    .search-input:focus {
      border-color: var(--primary-color);
    }

    /* Messages Container */
    .messages-container {
      flex: 1;
      padding: 20px;
      overflow-y: auto;
      background: var(--bg-chat);
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    /* Message Styling */
    .message {
      display: flex;
      max-width: 80%;
      animation: messageIn 0.3s ease-out;
    }

    .message.employee {
      margin-left: auto;
      flex-direction: row-reverse;
    }

    .message.dropshipper {
      margin-right: auto;
    }

    .message.admin {
      margin: 0 auto;
      max-width: 90%;
    }

    .message-bubble {
      padding: 12px 16px;
      border-radius: var(--radius-lg);
      font-size: 14px;
      line-height: 1.5;
      position: relative;
      max-width: 100%;
      word-wrap: break-word;
      box-shadow: var(--shadow-light);
    }

    .employee .message-bubble {
      background: var(--primary-color);
      color: white;
      border-top-right-radius: 4px;
    }

    .dropshipper .message-bubble {
      background: var(--bg-secondary);
      color: var(--text-primary);
      border-top-left-radius: 4px;
    }

    .admin .message-bubble {
      background: var(--bg-tertiary);
      color: var(--text-secondary);
      text-align: center;
      border-radius: var(--radius-md);
    }
        /* Add this to your existing styles */
.status-message {
  background: #f8f9fa;
  color: #6c757d;
  padding: 8px 16px;
  border-radius: 8px;
  margin-bottom: 12px;
  font-size: 14px;
  text-align: center;
  border: 1px solid #e9ecef;
}

.message-input:disabled {
  background-color: #f8f9fa;
  cursor: not-allowed;
  opacity: 0.7;
}
    .message-time {
      font-size: 11px;
      color: var(--text-muted);
      margin-top: 4px;
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .employee .message-time {
      color: rgba(255, 255, 255, 0.8);
      justify-content: flex-end;
    }

    /* Input Area */
    .input-area {
      padding: 16px;
      background: var(--bg-primary);
      border-top: 1px solid var(--border-color);
      display: flex;
      align-items: flex-end;
      gap: 12px;
    }

    .input-container {
      flex: 1;
      position: relative;
      background: var(--bg-secondary);
      border-radius: var(--radius-lg);
      padding: 8px 16px;
      min-height: 44px;
      display: flex;
      align-items: center;
    }

    .message-input {
      width: 100%;
      border: none;
      background: transparent;
      outline: none;
      resize: none;
      font-family: inherit;
      font-size: 14px;
      color: var(--text-primary);
      max-height: 120px;
      line-height: 1.5;
      padding: 8px 0;
    }

    .message-input::placeholder {
      color: var(--text-muted);
    }

    .message-input:disabled {
      color: var(--text-muted);
      cursor: not-allowed;
    }

    .send-button {
      width: 44px;
      height: 44px;
      border-radius: 50%;
      background: var(--primary-color);
      color: white;
      border: none;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: all 0.2s ease;
      flex-shrink: 0;
    }

    .send-button:hover:not(:disabled) {
      background: var(--primary-dark);
      transform: translateY(-1px);
    }

    .send-button:active:not(:disabled) {
      transform: scale(0.95);
    }

    .send-button:disabled {
      background: var(--text-muted);
      cursor: not-allowed;
      opacity: 0.5;
    }

    /* Status indicator styles */
    .status-disabled {
      background: #fef2f2 !important;
      border: 1px solid #fecaca !important;
    }

    .status-enabled {
      background: #f0fdf4 !important;
      border: 1px solid #bbf7d0 !important;
    }

    /* Animations */
    @keyframes messageIn {
      from {
        opacity: 0;
        transform: translateY(10px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    /* Scrollbar */
    ::-webkit-scrollbar {
      width: 6px;
      height: 6px;
    }

    ::-webkit-scrollbar-track {
      background: var(--bg-secondary);
    }

    ::-webkit-scrollbar-thumb {
      background: var(--secondary-color);
      border-radius: 3px;
    }

    ::-webkit-scrollbar-thumb:hover {
      background: var(--text-muted);
    }

    /* Responsive */
    @media (max-width: 768px) {
      .whatsapp-container {
        height: 100vh;
        border-radius: 0;
      }

      .message {
        max-width: 90%;
      }

      .chat-header {
        padding: 12px 16px;
      }

      .chat-profile-pic {
        width: 40px;
        height: 40px;
        font-size: 18px;
      }

      .search-container {
        padding: 8px 16px;
      }

      .search-input {
        padding: 10px 12px;
        font-size: 13px;
      }
    }
  </style>
</head>
<body>
  <!-- WhatsApp Container -->
  <div class="whatsapp-container">
    <!-- Hidden input fields for parameters -->
    <input type="hidden" id="plan_step_id" value="<?php echo htmlspecialchars($_GET['step_id'] ?? ''); ?>">
    <input type="hidden" id="dropshipper_id" value="<?php echo htmlspecialchars($_GET['dropshipper_id'] ?? ''); ?>">
    <input type="hidden" id="emp_id" value="<?php echo htmlspecialchars($emp_id); ?>">
    <input type="hidden" id="sender_type" value="employee">
    
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

    <!-- Messages Container -->
    <div class="messages-container" id="messagesContainer">
      <div class="message admin">
        <div class="message-bubble">
          <div class="message-text">Welcome to the chat. How can I help you?</div>
          <div class="message-time">Just now</div>
        </div>
      </div>
    </div>

    <!-- Input Area -->
    <div class="input-area" id="inputArea">
      <div class="input-container" id="inputContainer">
        <textarea 
          class="message-input" 
          id="messageInput" 
          placeholder="Type a message..."
          rows="1"
          onkeypress="handleKeyPress(event)"
          oninput="autoResize(this)"
        ></textarea>
      </div>
      <input type="text" id="messageInput" class="message-input" placeholder="Type a message...">
  <button id="sendButton">Send</button>
    </div>
  </div>

  <script>
    const API_BASE = "https://customprint.deodap.com/api_dropshipper_tracker";
    let isLoading = false;
    let lastMessageCount = 0;
    let autoRefreshInterval = null;
    let chatConfig = {
      plan_step_id: 1,
      emp_id: 'EMP123',
      dropshipper_id: 1,
      sender_type: 'employee',
      stepStatus: 'Unknown'
    };

    // Function to get URL parameters
    function getUrlParameter(name) {
      name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
      const regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
      const results = regex.exec(location.search);
      return results === null ? '' : decodeURIComponent(results[1].replace(/\+/g, ' '));
    }

    // Initialize page with URL parameters
    async function initializePage() {
      const urlPlanStepId = getUrlParameter('step_id');
      const urlDropshipperId = getUrlParameter('dropshipper_id');
      const urlStatus = getUrlParameter('status');
      const empId = document.getElementById('emp_id').value;

      // Set required parameters from URL
      if (!urlPlanStepId || !urlDropshipperId) {

        return;
      }

      document.getElementById('plan_step_id').value = urlPlanStepId;
      document.getElementById('dropshipper_id').value = urlDropshipperId;
    // Function to fetch dropshipper details and update header
      // Update chatConfig with URL parameters
      chatConfig.plan_step_id = urlPlanStepId;
      chatConfig.dropshipper_id = urlDropshipperId;
      chatConfig.emp_id = empId;

      // Set status from URL parameter if provided, otherwise default to 'pending'
      if (urlStatus) {
        const validStatuses = ['pending', 'in process', 'completed', 'open'];
        if (validStatuses.includes(urlStatus)) {
          chatConfig.stepStatus = urlStatus;
          console.log('Using status from URL:', urlStatus);
        } else {
          console.warn(`Invalid status in URL: "${urlStatus}". Using default 'pending'`);
          chatConfig.stepStatus = 'pending';
        }
      } else {
        console.log('No status in URL, will fetch from API');
        chatConfig.stepStatus = 'pending'; // Default while loading
      }

      // Initialize UI with current status
      updateUIForStepStatus(chatConfig.stepStatus);

      // Fetch dropshipper name and update header
      await loadDropshipperDetails(urlDropshipperId, urlPlanStepId, empId);

      // Only fetch step status from API if not provided in URL
      if (!urlStatus) {
        await loadStepStatus(urlDropshipperId, urlPlanStepId);
      }



      // Load messages with the parameters
      loadMessages();

      // Focus the input only if chat is enabled
      if (chatConfig.stepStatus === 'in process') {
        document.getElementById("messageInput").focus();
      }


      // Check if status is pending or completed
if (chatConfig.stepStatus) {
  const status = chatConfig.stepStatus.toLowerCase();
  const messageInput = document.getElementById('messageInput');
  const sendButton = document.getElementById('sendButton');
  const inputContainer = document.querySelector('.input-container');
  let statusMessage = document.querySelector('.status-message');
  
  if (status === 'pending' || status === 'completed') {
    // Disable input and show message
    messageInput.disabled = true;
    messageInput.placeholder = status === 'pending' 
      ? 'Messaging disabled - This step is pending' 
      : 'Messaging disabled - This step is completed';
    sendButton.disabled = true;
    
    // Add status message if not already added
    if (!statusMessage) {
      statusMessage = document.createElement('div');
      statusMessage.className = 'status-message';
      statusMessage.textContent = status === 'pending'
        ? 'Messaging is disabled because this step is pending.'
        : 'Messaging is disabled because this step has been completed.';
      inputContainer.prepend(statusMessage);
    }
  } else {
    // Enable input and remove status message if it exists
    messageInput.disabled = false;
    messageInput.placeholder = 'Type a message...';
    sendButton.disabled = false;
    if (statusMessage) {
      statusMessage.remove();
    }
  }
}

    // Function to fetch dropshipper details and update header
    async function loadDropshipperDetails(dropshipperId, planStepId, empId) {
      try {
        const response = await fetch(`${API_BASE}/one_dropshipper_details.php?dropshipper_id=${dropshipperId}`);
        const data = await response.json();
        let dropshipperName = `Dropshipper #${dropshipperId}`;
        if (data.success && data.dropshipper) {
          dropshipperName = data.dropshipper.seller_name || data.dropshipper.store_name || dropshipperName;
        }
        // Update chat header with dropshipper name
        document.querySelector('.chat-info h4').textContent = `Chat with ${dropshipperName}`;
        document.querySelector('.chat-info p').textContent = `Step ID: ${planStepId} | Emp ID: ${empId}`;
      } catch (error) {
        console.error('Failed to fetch dropshipper details:', error);
        // Fallback to original display
        document.querySelector('.chat-info h4').textContent = 'Employee Chat';
        document.querySelector('.chat-info p').textContent = `Dropshipper #${dropshipperId} | Step ID: ${planStepId} | Emp ID: ${empId}`;
      }
    }
    // Function to fetch plan step status with retry logic
    async function loadStepStatus(dropshipperId, planStepId, retryCount = 0) {
      const maxRetries = 3;
      const retryDelay = 1000 * (retryCount + 1);

      try {
        console.log(`Fetching step status for:`, { dropshipperId, planStepId, attempt: retryCount + 1 });

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 10000);

        // Fetch the step status from one_dropshipper_plan.php
        const response = await fetch(`${API_BASE}/one_dropshipper_plan.php?dropshipper_id=${dropshipperId}`, {
          signal: controller.signal
        });

        clearTimeout(timeoutId);

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();
        console.log('Step status response:', data);

        let status = 'pending';
        
        // Find the step in the response
        if (data.plans && data.plans.length > 0) {
          // Find the step in the plans array
          for (const plan of data.plans) {
            if (plan.steps) {
              const step = plan.steps.find(s => s.step_id == planStepId);
              if (step && step.status) {
                status = step.status.trim().toLowerCase();
                console.log('Found step status:', status);
                break;
              }
            }
          }
        }

        // Normalize the status
        if (status === 'in_progress' || status === 'in-process' || status === 'inprocess' || status === 'processing') {
          status = 'in process';
        } else if (status === 'done' || status === 'finished' || status === 'complete' || status === 'completed') {
          status = 'completed';
        } else if (status === 'active' || status === 'started') {
          status = 'open';
        } else {
          status = 'pending';
        }

        console.log('Final normalized status:', status);
        
        // Update the chat configuration and UI
        chatConfig.stepStatus = status;
        updateUIForStepStatus(status);
        
        // Save to localStorage for offline use
        localStorage.setItem(`step_status_${planStepId}`, status);
        
        return true;

      } catch (error) {
        console.error(`Error loading step status (attempt ${retryCount + 1}):`, error);

        if (retryCount < maxRetries) {
          console.log(`Retrying in ${retryDelay}ms...`);
          await new Promise(resolve => setTimeout(resolve, retryDelay));
          return loadStepStatus(dropshipperId, planStepId, retryCount + 1);
        } else {
          console.error('Max retries reached, using cached status');
          const cachedStatus = localStorage.getItem(`step_status_${planStepId}`) || 'pending';
          chatConfig.stepStatus = cachedStatus;
          updateUIForStepStatus(cachedStatus);
          return false;
        }
      }
    }

    function updateUIForStepStatus(status) {
      const messageInput = document.getElementById('messageInput');
      const sendButton = document.getElementById('sendButton');
      const subtitle = document.getElementById('chatSubtitle');
      const inputContainer = document.getElementById('inputContainer');

      console.log('Updating UI for status:', status);

      // Reset all states first
      messageInput.disabled = false;
      sendButton.disabled = false;
      sendButton.style.opacity = '1';
      inputContainer.classList.remove('status-disabled', 'status-enabled');

      if (status === 'completed') {
        // DISABLE chat for completed status
        messageInput.placeholder = 'Chat disabled - Step is completed';
        messageInput.disabled = true;
        sendButton.disabled = true;
        sendButton.style.opacity = '0.5';
        subtitle.textContent = 'Step Completed - Chat Disabled';
        subtitle.style.color = '#dc2626';
        inputContainer.classList.add('status-disabled');

      } else if (status === 'pending') {
        // DISABLE chat for pending status
        messageInput.placeholder = 'Chat disabled - Step is pending';
        messageInput.disabled = true;
        sendButton.disabled = true;
        sendButton.style.opacity = '0.5';
        subtitle.textContent = 'Step Pending - Chat Disabled';
        subtitle.style.color = '#f59e0b';
        inputContainer.classList.add('status-disabled');

      } else if (status === 'in process') {
        // ENABLE chat only for 'in process' status
        messageInput.placeholder = 'Type a message...';
        messageInput.disabled = false;
        sendButton.disabled = false;
        sendButton.style.opacity = '1';
        subtitle.textContent = 'Step In Process - Chat Enabled';
        subtitle.style.color = '#10b981';
        inputContainer.classList.add('status-enabled');

      } else {
        // DEFAULT: DISABLE chat for any unknown status
        messageInput.placeholder = 'Chat disabled - Unknown step status';
        messageInput.disabled = true;
        sendButton.disabled = true;
        sendButton.style.opacity = '0.5';
        subtitle.textContent = 'Chat Status Unknown - Disabled';
        subtitle.style.color = '#6b7280';
        inputContainer.classList.add('status-disabled');
      }
    }
    // Call initializePage when the page loads
    document.addEventListener('DOMContentLoaded', initializePage);

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

    function goBack() {
      if (document.referrer) {
        window.history.back();
      } else {
        window.location.href = 'employee_dashboard.php';
      }
    }

    function toggleSearch() {
      const searchContainer = document.getElementById('searchContainer');
      if (searchContainer.style.display === 'block') {
        searchContainer.style.display = 'none';
      } else {
        searchContainer.style.display = 'block';
        document.getElementById('searchInput').focus();
      }
    }

    function performSearch() {
      const searchTerm = document.getElementById('searchInput').value.toLowerCase();
      const messages = document.querySelectorAll('.message');
      
      messages.forEach(message => {
        const messageText = message.querySelector('.message-text');
        if (messageText) {
          const text = messageText.textContent.toLowerCase();
          if (searchTerm === '' || text.includes(searchTerm)) {
            message.style.display = 'flex';
          } else {
            message.style.display = 'none';
          }
        }
      });
    }

    async function loadMessages() {
      if (isLoading) return;
      
      const plan_step_id = document.getElementById("plan_step_id").value;
      const dropshipper_id = document.getElementById("dropshipper_id").value;

      try {
        isLoading = true;
        
        const res = await fetch(`${API_BASE}/get_chat_history.php?plan_step_id=${plan_step_id}&dropshipper_id=${dropshipper_id}`);
        const json = await res.json();

        const container = document.getElementById("messagesContainer");
        
        if (json.success && json.messages) {
          // Only update if message count changed
          if (json.messages.length !== lastMessageCount) {
            container.innerHTML = "";
            json.messages.forEach(message => {
              addMessageToChat(message.sender_type, message.message, message.created_at);
            });
            lastMessageCount = json.messages.length;
          }
        } else {
          if (lastMessageCount === 0) {
            container.innerHTML = "";
            addMessageToChat('admin', 'No messages found. Start the conversation when step is in process!', 'Now');
          }
        }
      } catch (err) {
        console.error('Error loading messages:', err);
        if (lastMessageCount === 0) {
          addMessageToChat('admin', 'Error loading messages. Please check your connection.', 'Now');
        }
      } finally {
        isLoading = false;
      }
    }

    async function sendMessage() {
      const messageInput = document.getElementById("messageInput");
      const sendButton = document.getElementById("sendButton");
      const message = messageInput.value.trim();

      if (!message) return;

      // STRICT CHECK: Only allow sending if status is exactly 'in process'
      if (chatConfig.stepStatus !== 'in process') {
        let statusMessage = '';
        
        if (chatConfig.stepStatus === 'pending') {
          statusMessage = 'Cannot send message: Step is currently pending. Chat will be enabled when step is in process.';
        } else if (chatConfig.stepStatus === 'completed') {
          statusMessage = 'Cannot send message: Step has been completed. Chat is permanently disabled for completed steps.';
        } else {
          statusMessage = `Cannot send message: Step status is "${chatConfig.stepStatus}". Chat is only available when step is "in process".`;
        }
        
        // Show error message in chat
        addMessageToChat('admin', statusMessage, 'Now');
        messageInput.value = '';
        return;
      }

      // Get all required values
      const plan_step_id = document.getElementById("plan_step_id").value;
      const dropshipper_id = document.getElementById("dropshipper_id").value;
      const emp_id = document.getElementById("emp_id").value;
      const sender_type = 'employee';

      // Validate required fields
      if (!plan_step_id || !dropshipper_id || !emp_id) {
        addMessageToChat('admin', 'Error: Missing required parameters', 'Now');
        return;
      }

      const data = {
        plan_step_id: plan_step_id,
        emp_id: emp_id,
        dropshipper_id: dropshipper_id,
        sender_type: sender_type,
        message: message
      };

      // Disable input temporarily
      sendButton.disabled = true;
      messageInput.disabled = true;

      // Add message immediately to UI
      addMessageToChat(sender_type, message, "Now");
      messageInput.value = "";
      messageInput.style.height = 'auto';

      try {
        const res = await fetch(`${API_BASE}/chatt.php`, {
          method: "POST",
          headers: { 
            "Content-Type": "application/json",
            "Accept": "application/json"
          },
          body: JSON.stringify(data)
        });

        const json = await res.json();

        if (!json.success) {
          addMessageToChat('admin', `Error: ${json.message || 'Failed to send message'}`, 'Now');
        }
      } catch (err) {
        console.error('Error sending message:', err);
        addMessageToChat('admin', 'Error: Failed to send message. Please check your connection.', 'Now');
      } finally {
        // Re-enable input only if status is still 'in process'
        if (chatConfig.stepStatus === 'in process') {
          sendButton.disabled = false;
          messageInput.disabled = false;
          messageInput.focus();
        } else {
          // If status changed during sending, update UI
          updateUIForStepStatus(chatConfig.stepStatus);
        }
        
        // Reload messages to get the latest
        setTimeout(loadMessages, 500);
      }
    }

    function addMessageToChat(senderType, messageText, timestamp) {
      const container = document.getElementById("messagesContainer");
      
      const messageDiv = document.createElement("div");
      messageDiv.className = `message ${senderType}`;

      const bubble = document.createElement("div");
      bubble.className = "message-bubble";

      const textDiv = document.createElement("div");
      textDiv.className = "message-text";
      textDiv.textContent = messageText;

      const timeDiv = document.createElement("div");
      timeDiv.className = "message-time";
      
      const time = formatTime(timestamp);
      timeDiv.innerHTML = `<span>${time}</span>`;

      bubble.appendChild(textDiv);
      bubble.appendChild(timeDiv);
      messageDiv.appendChild(bubble);
      container.appendChild(messageDiv);

      // Scroll to bottom
      container.scrollTop = container.scrollHeight;
    }

    function formatTime(timestamp) {
      if (timestamp === 'Now' || timestamp === 'Just now') return 'Just now';
      
      try {
        const date = new Date(timestamp);
        const now = new Date();
        
        if (date.toDateString() === now.toDateString()) {
          // Today - show time
          return date.toLocaleTimeString('en-US', { 
            hour: '2-digit', 
            minute: '2-digit',
            hour12: true 
          });
        } else {
          // Another day - show date and time
          return date.toLocaleString('en-US', { 
            month: 'short', 
            day: 'numeric',
            hour: '2-digit', 
            minute: '2-digit' 
          });
        }
      } catch {
        return timestamp;
      }
    }

    // Auto-refresh messages every 5 seconds (and check status)
    setInterval(() => {
      loadMessages();
      // Also refresh step status periodically
      if (chatConfig.plan_step_id && chatConfig.dropshipper_id) {
        loadStepStatus(chatConfig.dropshipper_id, chatConfig.plan_step_id);
      }
    }, 5000);
  </script>
</body>
</html>
