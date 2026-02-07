#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install dependencies
apt-get install -y curl wget git software-properties-common zsh

# Install Oh My Zsh for ubuntu user
sudo -u ubuntu sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install zsh-autosuggestions plugin
sudo -u ubuntu git clone https://github.com/zsh-users/zsh-autosuggestions /home/ubuntu/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# Install zsh-syntax-highlighting plugin
sudo -u ubuntu git clone https://github.com/zsh-users/zsh-syntax-highlighting /home/ubuntu/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Configure Oh My Zsh plugins
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker docker-compose)/' /home/ubuntu/.zshrc

# Set zsh as default shell for ubuntu user
chsh -s $(which zsh) ubuntu

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

# Clone OpenClaw repository
git clone https://github.com/openclaw/openclaw.git .

# Create OpenClaw configuration file
cat > /opt/openclaw/openclaw.json <<'EOF'
${openclaw_config}
EOF

# Create OpenClaw directories with correct permissions for node user (UID 1000)
mkdir -p /opt/openclaw/config/agents/main/agent
mkdir -p /opt/openclaw/config/credentials
mkdir -p /opt/openclaw/workspace
mkdir -p /opt/openclaw/.openclaw

# Set ownership to node user (UID 1000 in the container)
chown -R 1000:1000 /opt/openclaw/config
chown -R 1000:1000 /opt/openclaw/workspace
chown -R 1000:1000 /opt/openclaw/.openclaw

# Create .env file for docker-compose
cat > /opt/openclaw/.env <<ENVEOF
OPENCLAW_CONFIG_DIR=/opt/openclaw/config
OPENCLAW_WORKSPACE_DIR=/opt/openclaw/workspace
OPENCLAW_HOME=/opt/openclaw/.openclaw
OPENCLAW_GATEWAY_TOKEN=${openclaw_gateway_token}
MOONSHOT_API_KEY=${moonshot_api_key}
MOONSHOT_MODEL=${moonshot_model}
LLM_PROVIDER=moonshot
# Set empty values to silence Claude warnings (not using Claude)
CLAUDE_AI_SESSION_KEY=
CLAUDE_WEB_SESSION_KEY=
CLAUDE_WEB_COOKIE=
ENVEOF

# Set correct ownership for .env and all openclaw files
chown -R 1000:1000 /opt/openclaw/.env
chown -R 1000:1000 /opt/openclaw

# Run the docker setup script from the repo
chmod +x ./docker-setup.sh
./docker-setup.sh

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
