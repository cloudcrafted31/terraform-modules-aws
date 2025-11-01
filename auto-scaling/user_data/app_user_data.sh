#!/bin/bash
# Application Tier User Data Script
# This script sets up a basic application server

# Update system
yum update -y

# Install required packages
yum install -y java-11-amazon-corretto aws-cli amazon-cloudwatch-agent

# Configure CloudWatch agent with additional metrics
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": ["tcp_established", "tcp_time_wait"],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/application.log",
                        "log_group_name": "/aws/ec2/${project}-${environment}-app",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Create a simple Spring Boot-like health endpoint
cat > /opt/app/app.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
import os
from datetime import datetime

class HealthHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health' or self.path == '/actuator/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            health_data = {
                "status": "UP",
                "timestamp": datetime.now().isoformat(),
                "environment": "${environment}",
                "instance": os.uname().nodename,
                "database": "${db_endpoint}" if "${db_endpoint}" else "not_configured"
            }
            
            self.wfile.write(json.dumps(health_data).encode())
        else:
            self.send_response(404)
            self.end_headers()

PORT = 8080
with socketserver.TCPServer(("", PORT), HealthHandler) as httpd:
    print(f"Application server running on port {PORT}")
    httpd.serve_forever()
EOF

# Make the app executable
chmod +x /opt/app/app.py

# Create systemd service
cat > /etc/systemd/system/app.service << 'EOF'
[Unit]
Description=Application Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/app
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the application
systemctl daemon-reload
systemctl enable app
systemctl start app

# Configure log rotation
cat > /etc/logrotate.d/application << 'EOF'
/var/log/application.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 644 ec2-user ec2-user
    postrotate
        systemctl reload app
    endscript
}
EOF

# Signal that the instance is ready
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region} || true