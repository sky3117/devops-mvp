const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

export async function login(email, password) {
  const body = new URLSearchParams({ username: email, password });
  const res = await fetch(`${API_URL}/api/v1/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });
  if (!res.ok) throw new Error("Login failed");
  return res.json();
}

export async function fetchTasks(token) {
  const res = await fetch(`${API_URL}/api/v1/tasks`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) throw new Error("Could not fetch tasks");
  return res.json();
}

export async function createTask(token, task) {
  const res = await fetch(`${API_URL}/api/v1/tasks`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
    body: JSON.stringify(task),
  });
  if (!res.ok) throw new Error("Could not create task");
  return res.json();
}
