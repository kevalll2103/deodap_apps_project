<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Push Notification Demo</title>
</head>
<body>
  <h2>Push Notification Test</h2>
  <button id="subscribeBtn">Subscribe</button>

  <script>
    // ✅ Register Service Worker
    async function registerServiceWorker() {
      if ("serviceWorker" in navigator) {
        return await navigator.serviceWorker.register("/sw.js");
      }
      throw new Error("Service workers are not supported in this browser");
    }

    // ✅ Subscribe User
    async function subscribeUser() {
      const reg = await navigator.serviceWorker.ready;
      const sub = await reg.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(
          "BHeuIMIEtAji1gDeffk7E-dz1vtLabt_SXpPd9T7azYNDmef7GhCVV7n771raDREtX3HrMWKfhaa1OoLg6_z524"
        )
      });

      console.log("Subscription object:", sub);

      // DB માં save કરો
      await fetch("https://customprint.deodap.com/api_dropshipper_tracker/save_subscription.php", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          seller_id: "DS001",
          subscription: sub
        })
      });
      alert("Subscribed successfully!");
    }

    // ✅ Convert VAPID key (base64 → Uint8Array)
    function urlBase64ToUint8Array(base64String) {
      const padding = "=".repeat((4 - base64String.length % 4) % 4);
      const base64 = (base64String + padding)
        .replace(/-/g, "+")
        .replace(/_/g, "/");

      const rawData = window.atob(base64);
      const outputArray = new Uint8Array(rawData.length);

      for (let i = 0; i < rawData.length; ++i) {
        outputArray[i] = rawData.charCodeAt(i);
      }
      return outputArray;
    }

    document.getElementById("subscribeBtn").addEventListener("click", async () => {
      await registerServiceWorker();
      await subscribeUser();
    });
  </script>
</body>
</html>
