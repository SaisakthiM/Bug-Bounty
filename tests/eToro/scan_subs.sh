#!/bin/bash

INPUT="etoro_subs.txt"
OUTPUT="interesting_8080.txt"
> $OUTPUT

echo "[*] Scanning for open 8080/8443 ports..."

while read -r subdomain; do
    # Quick port check with nmap
    result=$(nmap -p 8080,8443 --open -T4 "$subdomain" 2>/dev/null | grep "open")
    
    if [ -n "$result" ]; then
        echo "[+] $subdomain has open ports:"
        echo "$result"
        
        # Try HTTP on 8080
        response=$(curl -s -o /dev/null -w "%{http_code}" \
            --connect-timeout 5 --max-time 10 \
            -H "X-Bug-Bounty: Saisakthi" \
            "http://$subdomain:8080/api/status" 2>/dev/null)
        
        if [ "$response" = "200" ]; then
            echo "[!!!] 200 on http://$subdomain:8080/api/status" | tee -a $OUTPUT
        fi

        # Try /api/ping too
        response2=$(curl -s -o /dev/null -w "%{http_code}" \
            --connect-timeout 5 --max-time 10 \
            -H "X-Bug-Bounty: Saisakthi" \
            "http://$subdomain:8080/api/ping" 2>/dev/null)
        
        if [ "$response2" = "200" ]; then
            echo "[!!!] 200 on http://$subdomain:8080/api/ping" | tee -a $OUTPUT
        fi
    fi
done < "$INPUT"

echo "[*] Done. Results saved to $OUTPUT"
