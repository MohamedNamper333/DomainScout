# DomainScout

**DomainScout** — subdomain enumeration and advanced Nmap scanning tool.

> **Legal & Ethical Notice**  
> Do **NOT** use this tool on networks, hosts, or systems you do not own or do not have explicit written permission to test. The author is not responsible for misuse. Always obtain authorization before scanning.

## Overview
DomainScout extracts hostnames (subdomains) from a target's web page, checks which hosts respond to `ping`, resolves IPv4 addresses, and performs advanced Nmap scans (ports, service/version detection, OS detection, and selected NSE scripts). Results are saved to structured output files for later review.

## Requirements
- Linux (or WSL on Windows)
- `bash`, `curl`, `grep`, `awk`, `sort`, `uniq`
- `dig` (or `host`) — for DNS A record lookups
- `nmap` — for port/service scans and NSE scripts  
> Recommended: run the script with `sudo` to enable SYN scans and accurate OS detection.

## Installation
1. Make the script executable:
```bash
chmod +x domainscout.sh
