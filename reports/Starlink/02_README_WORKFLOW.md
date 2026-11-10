# SpaceX / Starlink Bug Bounty — Hunting Workflow
# Follow this top to bottom. Never skip phases.

---

## ⚠️ READ BEFORE TOUCHING ANYTHING

### In Scope
- `*.spacex.com` — except `shop.spacex.com`
- `*.starlink.com` — except `gear.starlink.com` and `customer.*.isp.starlink.com`
- Official Starlink iOS and Android apps
- IP ranges in the brief (192.31.242.0/23, 199.175.188.0/24, etc.)
- `*.starlinkisp.net` — except `customer.*.pop.starlinkisp.net`
### Explicitly Out of Scope (save time, skip these)
- Lack of MFA
- Open redirects
- Internal IP address disclosure
- Missing security headers
- TLS/SSL issues
- Rate limiting absence
- Clickjacking
- Self XSS
- Username enumeration via error messages
- CORS without demonstrated impact
- Known CVEs without proven exploitation
- Descriptive error messages / stack traces
- environment.js exposure (intentionally public)
- DoS attacks
- Out-of-date software (unless exploitable with PoC)

### Report destinations
- Web/network findings → Bugcrowd submission form
- Product/infrastructure findings → vulnerabilityreporting@spacex.com (GPG encrypted)

---

## Phase 1 — Subdomain Enumeration

```bash
cd ~/bugbounty/spacex/recon

# Enumerate subdomains for both root domains
subfinder -d spacex.com -silent -o spacex_subs.txt
subfinder -d starlink.com -silent -o starlink_subs.txt

# Combine
cat spacex_subs.txt starlink_subs.txt | sort -u > all_subs.txt
wc -l all_subs.txt
```

---

## Phase 2 — Probe Live Hosts

```bash
# Check which are alive, grab title, tech stack, status code
cat all_subs.txt | httpx -silent -title -tech-detect -status-code -content-length \
  -o live_hosts.txt

# View results
cat live_hosts.txt | sort -t '[' -k2

# Filter to 200s only
grep "\[200\]" live_hosts.txt > live_200.txt

# Filter out known out-of-scope
grep -v "shop.spacex.com\|gear.starlink.com\|customer\." live_200.txt > live_in_scope.txt
```

---

## Phase 3 — Historical URL Discovery

```bash
# Pull historical URLs from Wayback + other sources
cat live_in_scope.txt | awk '{print $1}' | gau | sort -u > historical_urls.txt
cat live_in_scope.txt | awk '{print $1}' | waybackurls | sort -u >> historical_urls.txt
sort -u historical_urls.txt -o historical_urls.txt

# Extract interesting patterns
cat historical_urls.txt | grep -E "\?|\.php|\.json|/api/|/admin|/v[0-9]" > interesting_urls.txt
wc -l interesting_urls.txt
```

---

## Phase 4 — JavaScript Analysis

```bash
# Crawl JS-heavy apps to find API routes
# Pick one interesting target at a time from live_in_scope.txt

TARGET="https://example.spacex.com"
katana -u $TARGET -jc -d 3 -o katana_${TARGET//[^a-zA-Z0-9]/_}.txt

# Extract JS files
grep "\.js" katana_${TARGET//[^a-zA-Z0-9]/_}.txt | sort -u > js_files.txt

# Download and grep JS for endpoints, keys, secrets
while read url; do
  curl -s "$url" | grep -oE '"(/api[^"]{2,100})"' | sort -u
done < js_files.txt | sort -u > api_endpoints.txt

# Check for hardcoded secrets
while read url; do
  curl -s "$url" | grep -iE '(key|secret|token|password|auth|bearer|apikey)["\s]*[:=]["\s]*[A-Za-z0-9+/]{16,}'
done < js_files.txt
```

---

## Phase 5 — Directory & File Discovery

```bash
TARGET="https://example.spacex.com"

# Directory brute force
ffuf -u ${TARGET}/FUZZ \
  -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt \
  -mc 200,201,204,301,302,403 \
  -o ffuf_dirs.json -of json \
  -t 30 -rate 50

# File discovery
ffuf -u ${TARGET}/FUZZ \
  -w /usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt \
  -mc 200,201,204,403 \
  -t 30 -rate 50
```

---

## Phase 6 — Parameter Discovery

```bash
TARGET="https://example.spacex.com/some-endpoint"

# Find hidden GET parameters
arjun -u $TARGET -m GET -o arjun_results.json

# Find hidden POST parameters
arjun -u $TARGET -m POST -o arjun_post_results.json
```

---

## Phase 7 — Manual Testing in Burp

For every interesting endpoint found in phases 1-6:

1. Open in Firefox with Burp proxy on
2. Browse through every feature: login, signup, profile, file upload, API calls
3. In Burp HTTP history, right-click interesting requests → Send to Repeater
4. Test these in order:

### IDOR checklist
- [ ] Find any numeric or UUID ID in URL or request body
- [ ] Create two accounts (Account A and Account B)
- [ ] While logged in as Account A, replace your ID with Account B's resource ID
- [ ] If response returns Account B's data → IDOR confirmed

### Auth checklist
- [ ] Does removing the auth token return data? → Missing auth
- [ ] Does changing the token to `null` / `undefined` return data? → Missing auth
- [ ] Can you access `/api/admin/...` endpoints as a regular user? → Privilege escalation
- [ ] Does the password reset token expire? Is it guessable? → Reset flaw

### API checklist
- [ ] Try `GET /api/v1/users` — does it list all users?
- [ ] Try HTTP method switching: if endpoint is POST, try GET, PUT, DELETE
- [ ] Try adding `?debug=true`, `?admin=true`, `?test=1` to any endpoint
- [ ] Check if API version switching works: `/api/v2/` → try `/api/v1/` for older, less-secure version

### File upload checklist (if applicable)
- [ ] Upload an SVG with XSS payload
- [ ] Upload a file with double extension: `shell.php.jpg`
- [ ] Check if uploaded file is accessible via a predictable URL

---

## Phase 8 — Nuclei Scan (last, targeted)

```bash
# Update templates first
nuclei -update-templates

# Run against in-scope live hosts — use specific tags, not everything
cat live_in_scope.txt | awk '{print $1}' | \
  nuclei -tags auth,exposure,misconfig,takeover \
  -severity medium,high,critical \
  -o nuclei_findings.txt \
  -rate-limit 10

# Review output
cat nuclei_findings.txt
```

---

## Daily routine

```
Morning (30 min):
  - Review live_in_scope.txt for new targets
  - Check if any new subdomains appeared (re-run subfinder)
  - Pick ONE target for the day

Core hunt (4-6 hours):
  - Run phases 3-7 on chosen target
  - Every interesting find → document immediately in findings/ folder

Evening (30 min):
  - Fill in a report template for anything found
  - Screenshot all evidence
  - Back up findings/ folder
```

---

## Evidence to always collect

Before writing a report, have all of these:

- [ ] Exact URL of vulnerable endpoint
- [ ] Full HTTP request (copy from Burp → "Copy as curl")
- [ ] Full HTTP response showing impact
- [ ] Screenshot of the issue
- [ ] What data is exposed / what action was performed
- [ ] Proof this is your own test account's data or a clearly invalid/test input

---

## Findings severity guide (Bugcrowd VRT)

| Finding | Likely severity |
|---------|----------------|
| Unauthenticated access to private data | P1-P2 |
| IDOR exposing other users' data | P2-P3 |
| Auth bypass | P1-P2 |
| Stored XSS | P2-P3 |
| Reflected XSS | P3-P4 |
| Sensitive data in JS source | P3-P4 |
| Subdomain takeover | P2-P3 |
| SSRF | P2-P3 |
| Open redirect | Out of scope |
| Missing headers | Out of scope |
| Rate limiting | Out of scope |
