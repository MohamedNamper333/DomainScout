# DomainScout

[![ShellCheck](https://github.com/MohamedNamper333/DomainScout/actions/workflows/lint.yml/badge.svg)](https://github.com/MohamedNamper333/DomainScout/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

**DomainScout** — subdomain enumeration and an advanced Nmap scanning tool written in Bash.

---

## ⚠️ Legal & Ethical Notice
Do **NOT** use this tool on networks, hosts, or systems you do not own or do not have explicit written permission to test. The author is **not responsible** for misuse. Always obtain authorization before scanning.

---

## Overview
DomainScout extracts hostnames (subdomains) from a target’s web page, checks which hosts respond to `ping`, resolves IPv4 addresses, and performs advanced Nmap scans, including:

- TCP SYN scan (`-sS`)
- Port scanning (all ports `-p-`)
- Service/version detection (`-sV`)
- OS detection (`-O`)
- Safe NSE scripts (`--script=default, safe`)
- Skips host discovery (`-Pn`)

Results are saved to structured output files for easy review.

---

## Requirements
- Linux or WSL (Windows)
- Bash
- `curl`, `grep`, `awk`, `sort`, `uniq`
- `dig` or `host` (for DNS lookups)
- `nmap` (recommended to run with `sudo` for SYN scans & OS detection)

---

## Installation
Make the script executable:

```bash
chmod +x domainscout.sh
