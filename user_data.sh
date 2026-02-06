#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install dependencies
apt-get install -y curl wget git software-properties-common

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start and configure Tailscale
# Using the auth key passed from Terraform
tailscale up --authkey="${tailscale_auth_key}" --accept-routes --advertise-exit-node

# Create directory for OpenClaw
mkdir -p /opt/openclaw
cd /opt/openclaw

# Create OpenClaw configuration file
cat > /opt/openclaw/config.json <<'EOF'
${openclaw_config}
EOF

# Create docker-compose file for OpenClaw
# Note: Adjust this based on OpenClaw's actual Docker setup
cat > /opt/openclaw/docker-compose.yml <<'EOF'
version: '3.8'

services:
  openclaw:
    image: openclaw/openclaw:latest
    container_name: openclaw
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./config.json:/app/config.json
      - openclaw-data:/app/data
    environment:
      - CONFIG_FILE=/app/config.json
    networks:
      - openclaw-network

volumes:
  openclaw-data:

networks:
  openclaw-network:
    driver: bridge
EOF

# Start OpenClaw
docker-compose up -d

# Enable IP forwarding for Tailscale exit node (if needed)
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# Create a systemd service to ensure everything starts on boot
cat > /etc/systemd/system/openclaw.service <<'EOF'
[Unit]
Description=OpenClaw AI Assistant
After=docker.service tailscaled.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/openclaw
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openclaw.service

# Log completion
echo "OpenClaw with Tailscale setup completed at $(date)" >> /var/log/openclaw-setup.log
