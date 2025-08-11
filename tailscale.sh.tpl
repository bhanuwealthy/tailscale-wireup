#!/bin/bash
set -ex

# Wait for network
sleep 5
yum update -y

sudo tee /etc/sysctl.d/99-tailscale.conf > /dev/null <<'EOF'
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF

sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://pkgs.tailscale.com/stable/amazon-linux/2023/tailscale.repo
sudo yum install -y tailscale
sudo systemctl enable --now tailscaled

TF_REGION="${TF_REGION}"
export TF_REGION

tailscale up --hostname=$TF_REGION --operator=ec2-user --advertise-exit-node \
    --auth-key=${TS_AUTH_KEY}
