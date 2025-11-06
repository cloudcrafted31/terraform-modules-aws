#!/bin/bash
# Web Tier User Data Script
# This script sets up a basic web server

# Update system
yum update -y

# Install required packages
yum install -y httpd aws-cli amazon-cloudwatch-agent

# Configure CloudWatch agent
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
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Create a simple health check page
cat > /var/www/html/health << 'EOF'
OK
EOF

# Create index page with environment info
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>${project} - ${environment}</title>
</head>
<body>
    <h1>Welcome to ${project}</h1>
    <p>Environment: ${environment}</p>
    <p>Server: $(hostname)</p>
    <p>Time: $(date)</p>
</body>
</html>
EOF

# Configure httpd
systemctl enable httpd
systemctl start httpd

# Configure log rotation
cat > /etc/logrotate.d/httpd << 'EOF'
/var/log/httpd/*log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 apache apache
    postrotate
        systemctl reload httpd
    endscript
}
EOF

# Signal that the instance is ready
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region} || true