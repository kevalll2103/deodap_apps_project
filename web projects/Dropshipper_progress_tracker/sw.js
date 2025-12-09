// sw.js (Service Worker)

// When push notification is received
self.addEventListener("push", event => {
  let data = {};
  try {
    data = event.data.json();
  } catch (e) {
    data = { title: "Notification", body: event.data.text() };
  }

  const options = {
    body: data.body || "You have a new message.",
    icon: data.icon || "/icon.png",      // app icon
    badge: data.badge || "/badge.png",   // small badge icon (optional)
    data: data.url || "/http://localhost/Dropshipper_progress_tracker/comments.php"                // link to open on click
  };

  event.waitUntil(
    self.registration.showNotification(data.title || "New Notification", options)
  );
});

// When notification is clicked
self.addEventListener("notificationclick", event => {
  event.notification.close();

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then(clientList => {
      for (const client of clientList) {
        // If tab already open → focus
        if (client.url === event.notification.data && "focus" in client) {
          return client.focus();
        }
      }
      // Else → open new tab
      if (clients.openWindow) {
        return clients.openWindow(event.notification.data);
      }
    })
  );
});

// On service worker install
self.addEventListener("install", event => {
  console.log("✅ Service Worker installed");
  self.skipWaiting();
});

// On service worker activate
self.addEventListener("activate", event => {
  console.log("✅ Service Worker activated");
});
