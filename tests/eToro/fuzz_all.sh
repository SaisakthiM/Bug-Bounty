#!/bin/bash

INPUT="hosts_8080.txt"
WORDLIST="/usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt"

while read -r url; do
    # Clean hostname for output filename
    name=$(echo "$url" | sed 's/https\?:\/\///' | sed 's/:8080//' | sed 's/\//_/g')
    outfile="ffuf_${name}.txt"
    
    echo "[*] Fuzzing $url -> $outfile"
    
    ffuf -u "${url}/FUZZ" \
        -w "$WORDLIST" \
        -mc 200,201,301,302,403 \
        -t 5 -p 0.2 \
        -H "X-Bug-Bounty: Saisakthi" \
        -o "$outfile" \
        -of json \
        -s 2>/dev/null
    
    # Show only 200s immediately
    if [ -f "$outfile" ]; then
        hits=$(cat "$outfile" | python3 -c "
import json,sys
data=json.load(sys.stdin)
for r in data.get('results',[]):
    if r['status']==200:
        print(f\"[200] {r['url']}\")
" 2>/dev/null)
        if [ -n "$hits" ]; then
            echo "[!!!] 200s found on $url:"
            echo "$hits"
        fi
    fi
    
done < "$INPUT"

echo "[*] Done"
