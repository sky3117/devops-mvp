export const metadata = {
  title: "TaskManager",
  description: "DevOps MVP demo app",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body style={{ fontFamily: "system-ui, sans-serif", margin: 0, background: "#0f172a", color: "#e2e8f0" }}>
        {children}
      </body>
    </html>
  );
}
