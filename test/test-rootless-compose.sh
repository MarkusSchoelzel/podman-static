#!/bin/sh

echo
echo TEST DOCKER-COMPOSE IN PODMAN
echo

set -eu

cat <<EOF > /tmp/docker-compose.yml
version: "3"

services:
  reverse-proxy:
    image: traefik:v2.4
    command: --api.insecure=true --providers.docker
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /tmp/podman.sock:/var/run/docker.sock

  whoami:
    image: traefik/whoami
    labels:
      - "traefik.http.routers.whoami.rule=Host(\`whoami.docker.localhost\`)"
      - "traefik.http.services.whoami.loadbalancer.server.port=80"
EOF

podman system service --time 0 unix:///tmp/podman.sock &
sleep 5
docker-compose -H unix:///tmp/podman.sock -f /tmp/docker-compose.yml up -d
sleep 5
curl -H "Host:whoami.docker.localhost" http://127.0.0.1
