#!/usr/bin/env bash
set -u

usage() {
  echo "Usage: $0 <domain>"
  echo "Example: $0 www.example.com"
  exit 1
}

[[ $# -ne 1 ]] && usage
domain="$1"

for cmd in curl grep awk sort uniq ping host dig nmap; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Error: required command '$cmd' not found in PATH." >&2
    exit 2
  }
done

if [[ $EUID -ne 0 ]]; then
  echo "[!] Warning: not running as root. Some nmap features may be limited." >&2
fi

tmpdir=$(mktemp -d -t domainscout.XXXX)
trap 'rm -rf "$tmpdir"' EXIT

out_subs="subdomains.txt"
out_alive="alive.txt"
out_ips="ips.txt"
out_nmap="nmap_sub.txt"
out_dir_nmap="nmap_results"

mkdir -p "$out_dir_nmap"
: > "$out_subs"
: > "$out_alive"
: > "$out_ips"
: > "$out_nmap"

NMAP_OPTS=("-sS" "-p-" "-O" "-sV" "--script=default,safe" "--reason" "-Pn")

echo "[*] Fetching page for: $domain"
if [[ "$domain" =~ ^https?:// ]]; then
  url="$domain"
else
  url="http://$domain"
fi

curl -L -s --max-time 15 "$url" -o "$tmpdir/index.html" || {
  echo "[!] curl failed to fetch $url (continuing, may still parse cached or partial data)"
}

grep -Eio '(href|src)=[\"'"'"']?[^\"'"'"' >]+' "$tmpdir/index.html" 2>/dev/null \
  | sed -E 's/^(href|src)=[\"'"'"']?//' \
  | awk -F/ '{print $3 ? $3 : $1}' \
  | sed -E 's/:[0-9]+$//' \
  > "$tmpdir/hosts_raw.txt"

grep -Eo '([a-zA-Z0-9_-]+\.)+[a-zA-Z]{2,}' "$tmpdir/index.html" 2>/dev/null >> "$tmpdir/hosts_raw.txt" || true

cat "$tmpdir/hosts_raw.txt" \
  | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' \
  | grep -E -v '^(javascript:|mailto:|#|data:|about:)' \
  | grep -Eo '([a-zA-Z0-9_-]+\.)+[a-zA-Z]{2,}' \
  | grep -E '\.' \
  | sort -u \
  > "$out_subs"

echo "[+] found $(wc -l < "$out_subs") potential host(s) -> $out_subs"

echo "[*] checking which hosts respond to ping..."
while IFS= read -r host_entry; do
  [[ -z "$host_entry" ]] && continue
  if ping -c 1 -W 1 "$host_entry" >/dev/null 2>&1; then
    echo "$host_entry" | tee -a "$out_alive"
    echo "[OK] $host_entry"
  else
    echo "[--] $host_entry (no ping)"
  fi
done < "$out_subs"

echo "[+] alive hosts saved to $out_alive ($(wc -l < "$out_alive") )"

echo "[*] resolving IPv4 addresses for alive hosts..."
while IFS= read -r alive; do
  [[ -z "$alive" ]] && continue
  ips=$(dig +short A "$alive" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' || true)
  if [[ -n "$ips" ]]; then
    while IFS= read -r ip; do
      echo "$alive $ip" >> "$out_ips"
    done <<< "$ips"
    echo "[IP] $alive -> $(echo "$ips" | tr '\n' ' ' )"
  else
    echo "[IP?] no A record for $alive"
  fi
done < "$out_alive"

if [[ -s "$out_ips" ]]; then
  sort -u "$out_ips" -o "$out_ips"
  echo "[+] resolved IPs saved to $out_ips (unique)"
else
  echo "[!] no IPs resolved"
fi

scan_targets_file="$tmpdir/targets_to_scan.txt"
cat "$out_alive" > "$scan_targets_file"
grep -xvFf "$out_alive" "$out_subs" >> "$scan_targets_file" || true
sort -u "$scan_targets_file" -o "$scan_targets_file"

if [[ ! -s "$scan_targets_file" ]]; then
  echo "[!] No targets found to scan. Exiting."; exit 0
fi

echo "[*] Starting nmap scans for targets listed in $scan_targets_file"

NMAP_CMD_OPTS="${NMAP_OPTS[*]}"

while IFS= read -r target; do
  [[ -z "$target" ]] && continue
  safe_name=$(echo "$target" | tr '/:' '_' )
  perfile="$out_dir_nmap/${safe_name}_nmap.txt"
  echo -e "\n### Nmap scan for: $target ($(date -u +'%Y-%m-%dT%H:%M:%SZ'))\n" | tee -a "$out_nmap" > "$perfile"

  echo "[nmap] Scanning $target -> output: $perfile"
  nmap ${NMAP_OPTS[*]} "$target" -oN - >> "$perfile" 2>&1 || echo "[!] nmap returned non-zero for $target" >> "$perfile"

  cat "$perfile" >> "$out_nmap"
  echo "[nmap] appended $perfile -> $out_nmap"
done < "$scan_targets_file"

echo "[+] nmap scans complete. Combined file: $out_nmap ; per-host in $out_dir_nmap/"

echo "DONE."
echo "Results:"
echo " - All hosts: $out_subs"
echo " - Alive hosts: $out_alive"
echo " - Resolved IPs: $out_ips"
echo " - Combined nmap output: $out_nmap"
echo " - Per-host nmap dir: $out_dir_nmap"
