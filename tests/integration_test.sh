#!/usr/bin/env bash
set -euo pipefail

ROUTER="http://localhost:13003"
PASS=0
FAIL=0

check() {
    local desc="$1" expected="$2" actual="$3"
    if echo "$actual" | grep -q "$expected"; then
        echo "  PASS: $desc"
        ((PASS++)) || true
    else
        echo "  FAIL: $desc — expected '$expected' in: $actual"
        ((FAIL++)) || true
    fi
}

echo "Waiting for router..."
for i in $(seq 1 15); do
    curl -sf "$ROUTER/ping" > /dev/null 2>&1 && break
    sleep 1
done

echo ""
echo "=== Integration Tests ==="

echo ""
echo "-- Health endpoints --"
check "GET / returns Immich ML message" \
    '"message"' \
    "$(curl -sf "$ROUTER/")"

check "GET /ping returns pong" \
    "pong" \
    "$(curl -sf "$ROUTER/ping")"

echo ""
echo "-- Routing --"
check "CLIP request routes to remote backend (PC online)" \
    '"backend":"remote"' \
    "$(curl -sf -X POST "$ROUTER/predict" \
        -F 'entries={"clip":{"textual":{"modelName":"test","options":{}}}}' \
        -F 'text=dog in snow')"

check "facial-recognition request routes to remote backend" \
    '"backend":"remote"' \
    "$(curl -sf -X POST "$ROUTER/predict" \
        -F 'entries={"facial-recognition":{"detection":{"modelName":"antelopev2"}}}' \
        -F 'image=;type=image/jpeg')"

check "OCR request routes to remote backend" \
    '"backend":"remote"' \
    "$(curl -sf -X POST "$ROUTER/predict" \
        -F 'entries={"ocr":{"detection":{"modelName":"PP-OCRv5_server"}}}' \
        -F 'image=;type=image/jpeg')"

check "clip + facial-recognition routes to remote backend" \
    '"backend":"remote"' \
    "$(curl -sf -X POST "$ROUTER/predict" \
        -F 'entries={"clip":{},"facial-recognition":{}}' \
        -F 'text=test')"

echo ""
if [ "$FAIL" -eq 0 ]; then
    echo "All $PASS tests passed."
else
    echo "$PASS passed, $FAIL failed."
    exit 1
fi
