#!/bin/bash

INPUT="etoro_subs.txt"
OUTPUT="hosts_8080.txt"
> $OUTPUT

echo "[*] Finding subdomains with 8080 open..."

# httpx is faster than nmap for this
cat "$INPUT" | httpx -ports 8080 -silent -o "$OUTPUT"

echo "[*] Found $(wc -l < $OUTPUT) hosts with 8080 open"
echo "[*] Results saved to $OUTPUT"
