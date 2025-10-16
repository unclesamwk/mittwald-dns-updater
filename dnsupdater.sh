#!/bin/sh
# Simple Mittwald DNS updater (IPv4 only)
# Requirements: curl, dig, jq

set -eu

# --- Configuration via environment ---
MITTWALD_API_TOKEN="${MITTWALD_API_TOKEN:?missing token}"
DNS_ZONE_ID="${DNS_ZONE_ID:?missing zone id}"
FQDN="${FQDN:?missing fqdn}"          # e.g. "home.example.com"
RECORD_SET="${RECORD_SET:-a}"         # default: 'a'
POLL_INTERVAL="${POLL_INTERVAL:-300}" # seconds between checks
TTL_AUTO="${TTL_AUTO:-true}"          # true/false
TTL_SECONDS="${TTL_SECONDS:-300}"     # used if TTL_AUTO=false
STATE_FILE="${STATE_FILE:-/tmp/last_ip.json}"
API_BASE="https://api.mittwald.de/v2"
IPV4_SRC="${IPV4_SRC:-https://api.ipify.org}"

log() { printf '%s %s\n' "$(date +'%F %T')" "$*"; }

get_public_ip4() {
	curl -fsS "$IPV4_SRC" | tr -d '[:space:]'
}

get_dns_ip4() {
	dig +short A "$FQDN" | head -n1 | tr -d '[:space:]'
}

update_mittwald() {
	ipv4="$1"
	log "→ Updating Mittwald A record for zone $DNS_ZONE_ID to $ipv4"

	payload="$(jq -nc \
		--arg v4 "$ipv4" \
		--argjson auto $([ "$TTL_AUTO" = true ] && echo true || echo false) \
		--arg ttl "$TTL_SECONDS" \
		'{a: [$v4], settings: {ttl: ( $auto | if . then {auto:true} else {auto:false, seconds:($ttl|tonumber)} end )}}')"

	curl --fail -sS -X PUT \
		-H "Authorization: Bearer ${MITTWALD_API_TOKEN}" \
		-H "Content-Type: application/json" \
		-d "$payload" \
		"${API_BASE}/dns-zones/${DNS_ZONE_ID}/record-sets/${RECORD_SET}" >/dev/null
}

# Read last known IP if any
[ -f "$STATE_FILE" ] && last_v4="$(jq -r .v4 "$STATE_FILE" 2>/dev/null || true)" || last_v4=""

log "Starting Mittwald IPv4 DNS updater (interval ${POLL_INTERVAL}s) for $FQDN"

while :; do
	v4="$(get_public_ip4 2>/dev/null || true)"
	dns4="$(get_dns_ip4 2>/dev/null || true)"

	log "Public IPv4: $v4 | DNS IPv4: $dns4"

	if [ -z "$v4" ]; then
		log "⚠️  Could not get public IPv4 address."
	elif [ "$v4" = "$dns4" ]; then
		log "No change – skipping update."
	else
		log "Detected IPv4 change – updating DNS."
		if update_mittwald "$v4"; then
			log "✅ Mittwald update OK"
			echo "{\"v4\":\"$v4\"}" >"$STATE_FILE"
		else
			log "❌ Update failed!"
		fi
	fi

	sleep "$POLL_INTERVAL" || break
done
