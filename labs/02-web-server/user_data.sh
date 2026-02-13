#!/bin/bash
# ============================================================================
# User Data Script: Install and configure nginx on Amazon Linux 2023
# This script runs on first boot of each EC2 instance
# ============================================================================

set -euxo pipefail

# Install nginx
dnf install -y nginx

# Get instance metadata (IMDSv2)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

AVAILABILITY_ZONE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)

# Create custom HTML page showing instance information
cat > /usr/share/nginx/html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AWS Lab - Web Server</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #232f3e 0%, #37475a 100%);
            color: white;
        }
        .container {
            text-align: center;
            padding: 40px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 16px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        h1 { color: #ff9900; margin-bottom: 30px; }
        .info { margin: 15px 0; font-size: 1.1em; }
        .label { color: #ff9900; font-weight: bold; }
        .value {
            background: rgba(255, 153, 0, 0.2);
            padding: 4px 12px;
            border-radius: 4px;
            font-family: monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>AWS Solutions Architect Lab</h1>
        <h2>Web Server - Lab 02</h2>
        <div class="info">
            <span class="label">Instance ID:</span>
            <span class="value">${INSTANCE_ID}</span>
        </div>
        <div class="info">
            <span class="label">Availability Zone:</span>
            <span class="value">${AVAILABILITY_ZONE}</span>
        </div>
        <div class="info">
            <span class="label">Private IP:</span>
            <span class="value">${PRIVATE_IP}</span>
        </div>
        <div class="info" style="margin-top: 30px; font-size: 0.9em; color: #aaa;">
            Refresh the page to see load balancing in action
        </div>
    </div>
</body>
</html>
EOF

# Enable and start nginx
systemctl enable nginx
systemctl start nginx
