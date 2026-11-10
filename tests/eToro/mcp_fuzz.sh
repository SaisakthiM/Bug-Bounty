#!/bin/bash

HOST="https://agent.public-api.etoro.com"
HEADER="X-Bug-Bounty: Saisakthi"
OUT="mcp_results.txt"
> "$OUT"

echo "[*] Testing MCP endpoints on $HOST"
echo ""

# MCP specific paths
PATHS=(
    "/"
    "/mcp"
    "/mcp/v1"
    "/sse"
    "/mcp/sse"
    "/api/mcp"
    "/api/mcp/v1"
    "/api/sse"
    "/rpc"
    "/jsonrpc"
    "/api/rpc"
    "/api/jsonrpc"
    "/v1/mcp"
    "/v1/sse"
    "/v1/rpc"
    "/tools"
    "/tools/list"
    "/api/tools"
    "/api/tools/list"
    "/resources"
    "/resources/list"
    "/api/resources"
    "/prompts"
    "/prompts/list"
    "/api/prompts"
    "/initialize"
    "/api/initialize"
    "/manifest"
    "/api/manifest"
    "/.well-known/mcp"
    "/.well-known/ai-plugin.json"
    "/.well-known/openapi.json"
)

# MCP JSON-RPC payloads
declare -A PAYLOADS
PAYLOADS["initialize"]='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}'
PAYLOADS["tools/list"]='{"jsonrpc":"2.0","method":"tools/list","params":{},"id":2}'
PAYLOADS["resources/list"]='{"jsonrpc":"2.0","method":"resources/list","params":{},"id":3}'
PAYLOADS["prompts/list"]='{"jsonrpc":"2.0","method":"prompts/list","params":{},"id":4}'

echo "=== Phase 1: GET path discovery (non-empty responses only) ==="
for path in "${PATHS[@]}"; do
    response=$(curl -s -w "\n%{http_code}" \
        --connect-timeout 5 --max-time 10 \
        -H "$HEADER" \
        "${HOST}${path}" 2>/dev/null)
    
    code=$(echo "$response" | tail -1)
    body=$(echo "$response" | head -n -1)
    size=${#body}
    
    # Skip empty bodies
    if [ "$size" -gt 0 ] && [ "$code" != "000" ]; then
        echo "  [$code] ${HOST}${path} (${size} bytes)"
        echo "  Body: ${body:0:300}"
        echo ""
        echo "[$code] ${HOST}${path} | ${body:0:200}" >> "$OUT"
    fi
done

echo ""
echo "=== Phase 2: POST JSON-RPC (non-empty responses only) ==="
for path in "/" "/mcp" "/mcp/v1" "/api/mcp" "/rpc" "/sse" "/api/sse" "/v1/mcp"; do
    for method in "${!PAYLOADS[@]}"; do
        payload="${PAYLOADS[$method]}"
        
        response=$(curl -s -w "\n%{http_code}" \
            -X POST \
            --connect-timeout 5 --max-time 10 \
            -H "$HEADER" \
            -H "Content-Type: application/json" \
            -d "$payload" \
            "${HOST}${path}" 2>/dev/null)
        
        code=$(echo "$response" | tail -1)
        body=$(echo "$response" | head -n -1)
        size=${#body}
        
        # Only show non-empty responses
        if [ "$size" -gt 0 ] && [ "$code" != "000" ]; then
            echo "  [POST $code] ${HOST}${path} (method: $method, ${size} bytes)"
            echo "  Body: ${body:0:400}"
            echo ""
            echo "[POST $code] ${HOST}${path} | $method | ${body:0:300}" >> "$OUT"
        fi
    done
done

echo ""
echo "=== Phase 3: SSE connection test ==="
# MCP servers often use SSE for streaming
curl -s --max-time 5 \
    -H "$HEADER" \
    -H "Accept: text/event-stream" \
    "${HOST}/sse" &
curl -s --max-time 5 \
    -H "$HEADER" \
    -H "Accept: text/event-stream" \
    "${HOST}/mcp/sse" &
wait

echo ""
echo "[*] Done. Results in $OUT"
