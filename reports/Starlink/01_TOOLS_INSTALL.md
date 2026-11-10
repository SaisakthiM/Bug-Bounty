# Tool Installation Guide — SpaceX/Starlink Bug Bounty
# Arch Linux / Fish Shell

---

## Step 1 — System packages

```bash
sudo pacman -S --needed nmap ffuf gobuster feroxbuster jq curl wget git openssl python3 python-pip
```

---

## Step 2 — AUR tools (via yay)

```bash
yay -S burpsuite
```

---

## Step 3 — Go tools (all at once)

```bash
# Install Go if not already there
sudo pacman -S go

# Add Go bin to PATH permanently (fish)
fish_add_path (go env GOPATH)/bin

# Install all tools
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/projectdiscovery/katana/cmd/katana@latest
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/anew@latest
go install github.com/tomnomnom/gf@latest
go install github.com/tomnomnom/qsreplace@latest
go install github.com/hakluke/hakrawler@latest

# Verify installs
which subfinder httpx nuclei katana dnsx gau waybackurls
```

---

## Step 4 — Wordlists (SecLists)

```bash
yay -S seclists
# Files land in /usr/share/seclists/

# Most useful paths:
# /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt
# /usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt
# /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt
```

---

## Step 5 — Python tools

```bash
pip install --break-system-packages arjun  # parameter discovery
```

---

## Step 6 — Burp Suite setup

1. Launch: `burpsuite &`
2. Go to Proxy → Proxy settings → Proxy listeners → ensure `127.0.0.1:8080`
3. Install Burp CA cert in Firefox:
   - Browse to `http://burpsuite` while proxied → Download CA
   - Firefox → Settings → Certificates → Import
4. Install FoxyProxy extension in Firefox
5. Create a profile: `127.0.0.1:8080`, name it `Burp`

---

## Step 7 — Workspace folders

```bash
mkdir -p ~/bugbounty/spacex/{recon,scans,findings,reports,screenshots,js-analysis}
cd ~/bugbounty/spacex
```

---

## Tool reference card

| Tool | Purpose |
|------|---------|
| subfinder | Subdomain enumeration |
| httpx | Probe live hosts, detect tech, status |
| dnsx | DNS resolution and brute force |
| nuclei | Template-based vulnerability scanner |
| katana | JavaScript-aware web crawler |
| gau / waybackurls | Historical URL discovery |
| ffuf | Directory/parameter fuzzing |
| feroxbuster | Recursive directory brute force |
| arjun | Hidden parameter discovery |
| gf | Pattern matching on URLs |
| Burp Suite | Manual proxy testing, Repeater, Intruder |
| nmap | Port and service discovery (use carefully, see scope) |
| jq | JSON parsing from API responses |
