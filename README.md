
🧩 Mittwald DNS Updater (IPv4 only)

A super-lightweight dynamic DNS updater for Mittwald’s DNS API v2
.
It runs in a small Alpine container, checks your public IPv4 every few minutes, compares it with the DNS record, and only updates when needed.

🚀 Features

✅ Updates A records (IPv4 only) on Mittwald

✅ Uses Mittwald API v2 with PUT /v2/dns-zones/{zoneId}/record-sets/a

✅ No unnecessary API calls — only updates on change

✅ Minimal: uses only curl, dig, and jq

✅ Runs standalone or in Docker Compose

✅ Persists last-known IP to avoid redundant checks

📦 Quick Start
1. Clone repository
git clone https://github.com/<yourname>/mittwald-dnsupdater.git
cd mittwald-dnsupdater

2. Configure environment

Copy and edit .env:

cp .env.example .env


Fill it with your values:
```
MITTWALD_API_TOKEN=your_mittwald_token
DNS_ZONE_ID=<zone_id_of_subdomain>
FQDN=<your-subdomain>.example.com
RECORD_SET=a
POLL_INTERVAL=300
TTL_AUTO=true
TTL_SECONDS=300
STATE_FILE=/data/last_ip.json
```

🧠 You can create an API token in your Mittwald customer account
.

3. Run with Docker Compose
```
docker-compose up -d --build
```

Check logs:
```
docker-compose logs -f
```

Example output:
```
2025-10-15 23:10:01 Starting Mittwald IPv4 DNS updater (interval 300s) for <your-subdomain>.example.com
2025-10-15 23:10:01 Public IPv4: 203.0.113.42 | DNS IPv4: 203.0.113.10
2025-10-15 23:10:01 Detected IPv4 change – updating DNS.
2025-10-15 23:10:02 ✅ Mittwald update OK
```

⚙️ Configuration
Variable	Description	Default / Example
MITTWALD_API_TOKEN	Mittwald API Bearer token	(required)
DNS_ZONE_ID	UUID of your DNS zone	(required)
FQDN	Fully qualified domain name to update	(required)
RECORD_SET	DNS record set (usually a)	a
POLL_INTERVAL	Seconds between IP checks	300
TTL_AUTO	true for automatic TTL	true
TTL_SECONDS	TTL if auto is disabled	300
STATE_FILE	Path to store last IP	/data/last_ip.json

🐋 Docker setup

Dockerfile
```
FROM alpine:3.20
RUN apk add --no-cache curl bind-tools jq
COPY dnsupdater.sh /usr/local/bin/dnsupdater
ENTRYPOINT ["sh", "/usr/local/bin/dnsupdater"]
```

docker-compose.yml
```
services:
  dnsupdater:
    build: .
    container_name: dnsupdater
    restart: always
    env_file:
      - .env
```

🧠 How it works

Fetches current public IPv4 via https://api.ipify.org.

Resolves the domain’s existing DNS A record using dig.

Compares both — if unchanged, nothing happens.

If changed, sends a PUT request to Mittwald’s API:

PUT /v2/dns-zones/{zoneId}/record-sets/a
Authorization: Bearer <token>
Content-Type: application/json


Example payload:
```
{
  "a": ["203.0.113.42"],
  "settings": { "ttl": { "auto": true } }
}
```

Saves the new IP to STATE_FILE and sleeps until the next cycle.

🧰 Troubleshooting

Invalid token or zone ID → check .env values

Rate limited → API returns 429, increase interval

No IP found → container can’t reach IP detection service

Check container logs:

docker logs dnsupdater

🧱 Build locally (optional)
docker build -t mittwald-dnsupdater .
docker run --rm --env-file .env -v $(pwd)/data:/data mittwald-dnsupdater

📄 License

MIT License © 2025 [unclesamwk@googlemail.com]