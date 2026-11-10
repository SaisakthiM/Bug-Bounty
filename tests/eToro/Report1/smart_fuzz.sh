#!/bin/bash

WORDLIST="/usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt"
RESULTS_DIR="smart_results"
mkdir -p "$RESULTS_DIR"

# Your confirmed live hosts
HOSTS=(
    "http://push-demo-lightstreamer.cloud.etoro.com:8080"
    "http://push-lightstreamer.cloud.etoro.com:8080"
    "http://push-w-hap-ls-lb.cloud.etoro.com:8080"
    "http://push-n-hap-ls-lb.cloud.etoro.com:8080"
    "https://agent.public-api.etoro.com"
    "https://mcp.public-api.etoro.com"
    "https://mcp-readonly.public-api.etoro.com"
    "https://oauth.wallet.etoro.com"
    "https://kyc.etoro.com"
    "https://customersupportapi.etoro.com"
    "https://view.connect.etoro.com"
    "https://view.connect.dev.etoro.com"
    "https://userstatsapi.etoro.com"
    "https://stg-go.etoro.com"
    "http://stg-space2-go.etoro.com"
)

for host in "${HOSTS[@]}"; do
    name=$(echo "$host" | sed 's/https\?:\/\///' | sed 's/:8080//' | sed 's/\//_/g')
    echo ""
    echo "========================================"
    echo "[*] Fuzzing: $host"
    echo "========================================"

    json_out="$RESULTS_DIR/${name}.json"

    # Run ffuf catching 200s and 405s
    ffuf -u "${host}/FUZZ" \
        -w "$WORDLIST" \
        -mc 200,201,202,405 \
        -t 5 -p 0.2 \
        -H "X-Bug-Bounty: Saisakthi" \
        -o "$json_out" \
        -of json \
        -s 2>/dev/null

    [ ! -f "$json_out" ] && echo "  [-] No results" && continue

    # Parse results
    python3 << PYEOF
import json, subprocess, sys

with open("$json_out") as f:
    data = json.load(f)

results = data.get("results", [])
s200 = [r for r in results if r["status"] in [200,201,202]]
s405 = [r for r in results if r["status"] == 405]

if not results:
    print("  [-] Nothing found")
    sys.exit()

# Show 200s and curl them
if s200:
    print(f"\n  [200s] {len(s200)} found:")
    for r in s200:
        print(f"    {r['status']} {r['url']} (size:{r['length']})")
        print("    --- Response ---")
        result = subprocess.run(
            ["curl", "-s", r["url"], "-H", "X-Bug-Bounty: Saisakthi"],
            capture_output=True, text=True, timeout=10
        )
        try:
            parsed = json.loads(result.stdout)
            print("    " + json.dumps(parsed, indent=2)[:500])
        except:
            print("    " + result.stdout[:300])
        print()

# Show 405s and try POST on them
if s405:
    print(f"\n  [405s] {len(s405)} found — trying POST:")
    for r in s405:
        print(f"    {r['url']}")
        result = subprocess.run(
            ["curl", "-s", "-X", "POST", r["url"],
             "-H", "X-Bug-Bounty: Saisakthi",
             "-H", "Content-Type: application/json",
             "-d", "{}",
             "-w", "\n  HTTP: %{http_code}"],
            capture_output=True, text=True, timeout=10
        )
        print("    " + result.stdout[:400])
        print()
PYEOF

done

echo ""
echo "[*] All done. Raw JSON in $RESULTS_DIR/"
