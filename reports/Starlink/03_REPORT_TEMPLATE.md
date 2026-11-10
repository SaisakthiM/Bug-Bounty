# Bug Bounty Report Template — SpaceX / Starlink
# Fill in every section before submitting. Never submit with [PLACEHOLDER] still present.

---

## === CRITICAL FINDING TEMPLATE (P1-P2) ===

```
=== CRITICAL VULNERABILITY ===

Title: [CLEAR_TITLE — e.g. "Unauthenticated API exposes user billing data"]

Asset: [EXACT URL — e.g. https://api.spacex.com/v1/users/profile]

Type: [VULN_TYPE — e.g. Broken Access Control / IDOR / Auth Bypass / SSRF]

Severity: P[1/2]

Discovered: [DATE TIME — e.g. 2026-11-07 09:00 UTC]

---

IMPACT
- [What data is exposed or what action is possible]
- [How many users are affected — e.g. all authenticated users]
- [Business risk — e.g. full account takeover / PII disclosure]

---

REPRODUCTION STEPS

Pre-conditions:
- [What you need — e.g. one registered account / no account required]

Steps:
1. Navigate to [EXACT URL]
2. [EXACT ACTION — e.g. Send the following HTTP request]
3. [EXACT ACTION]
4. Observe: [EXACT RESULT]

Request:
---
[METHOD] [PATH] HTTP/2
Host: [HOST]
Authorization: Bearer [YOUR_TEST_TOKEN_OR_NONE]
Content-Type: application/json

[REQUEST BODY IF ANY]
---

Response:
---
HTTP/2 [STATUS]
Content-Type: application/json

[RESPONSE BODY — truncate if large, show key fields only]
---

---

EVIDENCE
- Screenshot 1: [FILENAME] — [what it shows]
- Screenshot 2: [FILENAME] — [what it shows]
- curl PoC: [paste the exact curl command that reproduces this]

---

BUSINESS IMPACT
[2-3 sentences explaining why this matters to SpaceX specifically.
E.g. "Any unauthenticated attacker can retrieve full billing records for
all 16,523 SpaceX shareholders by iterating user IDs, exposing names,
email addresses, and payment method metadata."]

---

REMEDIATION
1. [Specific fix — e.g. Enforce server-side authorization check on /api/v1/users/:id]
2. [Additional fix if needed]

---

TESTING NOTES
- Tested using: [your own test account / two test accounts / no account]
- No real user data was accessed beyond confirming the vulnerability exists
- Testing was limited to [describe exactly what you did and didn't do]
```

---

## === STANDARD FINDING TEMPLATE (P3-P4) ===

```
Title: [VULNERABILITY NAME]

Severity: P[3/4]

Asset: [AFFECTED URL]

Parameter: [VULNERABLE PARAMETER — e.g. ?id=, Authorization header, body field "userId"]

---

DESCRIPTION
[2-4 sentences of technical description. What is the endpoint, what does it do,
what is the flaw, and why does it exist.]

---

STEPS TO REPRODUCE
1. [Step]
2. [Step]
3. [Step]

Expected Result:
[What should happen — e.g. Server should return 403 Forbidden]

Actual Result:
[What actually happens — e.g. Server returns 200 with another user's profile data]

---

IMPACT
[Security implications — be specific. "Information disclosure" is too vague.
Write: "An authenticated attacker can read the question submission history
of any other voter by substituting their voterId in the query parameter,
exposing which questions they voted on and their shareholderType classification."]

---

EVIDENCE
- curl command: [exact reproducible command]
- Screenshot: [filename]
- Response excerpt: [key fields from response, not full dump]

---

REMEDIATION
[Suggested fix — be specific]

---

TESTING NOTES
- No automated scanning was used for this finding
- Tested with: [own account / no account / two accounts]
```

---

## === INFORMATION DISCLOSURE TEMPLATE ===

```
Title: [e.g. "Unminified JavaScript exposes internal API schema at guest.voyager.spacex.com"]

Severity: P3

Asset: [URL of the JS file or endpoint]

---

DESCRIPTION
[What file is exposed, what it contains, why it shouldn't be public]

---

SENSITIVE CONTENT FOUND
- [specific finding 1 — e.g. API endpoint /api/v1/rooms/code/{code} with full schema]
- [specific finding 2 — e.g. doorCode field returned on successful booking lookup]
- [specific finding 3 — e.g. unlockInstructions and googleMapsEmbedUrl fields exposed]

---

STEPS TO REPRODUCE
1. curl -s [EXACT URL]
2. grep for [PATTERN]
3. Observe: [FINDING]

---

IMPACT
[Why this matters — not just "it's exposed" but what an attacker gains from it]

---

REMEDIATION
1. Minify and obfuscate production JavaScript bundles
2. Remove sensitive field names from client-side code
3. Move API schema documentation behind authentication
```

---

## === CHECKLIST BEFORE SUBMITTING ===

```
Pre-submission checklist:

[ ] Title is specific and clear (not "SQL Injection found")
[ ] Asset URL is exact and correct
[ ] Severity matches Bugcrowd VRT — not inflated
[ ] Steps to reproduce are complete — triager can follow them without asking
[ ] A curl command or HTTP request is included
[ ] At least one screenshot is attached
[ ] Impact section explains business risk, not just technical finding
[ ] I did NOT access real user data beyond confirming the issue
[ ] I did NOT perform any destructive action (delete, modify production data)
[ ] The finding is NOT in the out-of-scope list
[ ] I have checked for duplicates by searching Bugcrowd's known issues
[ ] My test account credentials are NOT included in the report
[ ] All [PLACEHOLDERS] are filled in
```

---

## === FINDING LOG (fill one row per finding) ===

| Date | Target | Endpoint | Type | Severity | Status |
|------|--------|----------|------|----------|--------|
| 2026-11-07 | guest.voyager.spacex.com | /api/v1/rooms/code/{code} | Unauth API + physical door code | P1 | Submitted |
| | | | | | |
| | | | | | |
| | | | | | |
| | | | | | |
