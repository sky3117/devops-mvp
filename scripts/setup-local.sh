#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Setting up TaskManager locally..."

if [ ! -f backend/.env ]; then
  cp backend/.env.example backend/.env
  echo "✅ Created backend/.env"
fi

docker compose up --build -d

echo ""
echo "✅ Stack is starting up. Give it ~30s, then visit:"
echo "   Frontend:   http://localhost:3000"
echo "   API docs:   http://localhost:8000/docs"
echo "   Prometheus: http://localhost:9090"
echo "   Grafana:    http://localhost:3001 (admin/admin)"
