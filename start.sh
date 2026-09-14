#!/usr/bin/env bash
set -e

echo "======================================================================"
echo "   PlannerBot - Sovereign Cognitive Engine (v0.3.0)"
echo "   100% Offline, Air-Gapped AI Daily Planner & Focus Coach"
echo "======================================================================"
echo ""

MODEL_DIR="$HOME/.local/share/planner_bot/models"
MODEL_FILE="$MODEL_DIR/qwen2.5-0.5b-instruct-q4_k_m.gguf"
MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf"

mkdir -p "$MODEL_DIR"

if [ ! -f "$MODEL_FILE" ]; then
    echo "[*] Downloading Qwen2.5-0.5B Instruct GGUF (~398MB)..."
    curl -L -o "$MODEL_FILE" "$MODEL_URL"
fi

if [ ! -f "./PlannerBot" ]; then
    echo "[*] Compiling PlannerBot binary..."
    go build -o PlannerBot ./cmd/planner
fi

echo "[*] Starting PlannerBot..."
./PlannerBot &
PID=$!

echo "[*] Waiting for engine..."
for i in {1..30}; do
    if curl -s http://127.0.0.1:8088/api/status | grep -q '"ai_online":true'; then
        echo "[*] Engine online!"
        break
    fi
    sleep 1
done

if which xdg-open > /dev/null; then
    xdg-open http://127.0.0.1:8088
elif which open > /dev/null; then
    open http://127.0.0.1:8088
fi

echo "PlannerBot is running at http://127.0.0.1:8088"
wait $PID
