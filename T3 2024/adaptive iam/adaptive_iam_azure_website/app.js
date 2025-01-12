const API_BASE_URL = "https://<your-azure-function-app>.azurewebsites.net/api";

// Handle Login
document.getElementById("loginForm")?.addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = document.getElementById("email").value;
  const password = document.getElementById("password").value;

  const response = await fetch(`${API_BASE_URL}/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });

  const data = await response.json();

  if (data.success) {
    localStorage.setItem("userInfo", JSON.stringify(data));
    window.location.href = "dashboard.html";
  } else {
    document.getElementById("errorMsg").textContent = "Invalid credentials or suspicious activity.";
  }
});

// Load Dashboard
if (window.location.pathname.endsWith("dashboard.html")) {
  const userInfo = JSON.parse(localStorage.getItem("userInfo"));

  if (userInfo) {
    document.getElementById("userInfo").textContent = `Logged in as: ${userInfo.email}`;
    const permissionsList = document.getElementById("permissionsList");
    userInfo.roles.forEach((role) => {
      permissionsList.innerHTML += `<li>${role}</li>`;
    });
  } else {
    window.location.href = "index.html";
  }
}
