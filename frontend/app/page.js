"use client";
import { useState } from "react";
import { login, fetchTasks, createTask } from "../lib/api";

export default function Home() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [token, setToken] = useState(null);
  const [tasks, setTasks] = useState([]);
  const [newTitle, setNewTitle] = useState("");
  const [error, setError] = useState("");

  const handleLogin = async (e) => {
    e.preventDefault();
    setError("");
    try {
      const { access_token } = await login(email, password);
      setToken(access_token);
      const t = await fetchTasks(access_token);
      setTasks(t);
    } catch (err) {
      setError(err.message);
    }
  };

  const handleAddTask = async (e) => {
    e.preventDefault();
    if (!newTitle.trim()) return;
    const task = await createTask(token, { title: newTitle });
    setTasks([task, ...tasks]);
    setNewTitle("");
  };

  const card = { background: "#1e293b", padding: 24, borderRadius: 12, maxWidth: 480, margin: "60px auto" };
  const input = { width: "100%", padding: 10, marginBottom: 12, borderRadius: 6, border: "1px solid #334155", background: "#0f172a", color: "#e2e8f0" };
  const button = { padding: "10px 16px", borderRadius: 6, border: "none", background: "#6366f1", color: "white", cursor: "pointer" };

  if (!token) {
    return (
      <div style={card}>
        <h2>🚀 TaskManager Login</h2>
        <form onSubmit={handleLogin}>
          <input style={input} placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} />
          <input style={input} placeholder="Password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
          <button style={button} type="submit">Login</button>
        </form>
        {error && <p style={{ color: "#f87171" }}>{error}</p>}
      </div>
    );
  }

  return (
    <div style={card}>
      <h2>📋 My Tasks</h2>
      <form onSubmit={handleAddTask} style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        <input style={{ ...input, marginBottom: 0 }} placeholder="New task title" value={newTitle} onChange={(e) => setNewTitle(e.target.value)} />
        <button style={button} type="submit">Add</button>
      </form>
      <ul style={{ listStyle: "none", padding: 0 }}>
        {tasks.map((t) => (
          <li key={t.id} style={{ padding: 10, borderBottom: "1px solid #334155" }}>
            <strong>{t.title}</strong> — <span style={{ opacity: 0.7 }}>{t.status}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}
