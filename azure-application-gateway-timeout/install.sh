#!/bin/bash
set -e

echo "Starting installation script..."

# Update system
sudo apt-get update -y

# Install Python and pip
sudo apt-get install -y python3 python3-pip nginx

# Install Flask
pip3 install flask

# Stop nginx to configure it
sudo systemctl stop nginx || true

# Configure nginx to listen on port 999
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOF_NGINX
server {
    listen 999;
    listen [::]:999;
    
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    
    server_name _;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF_NGINX

# Create a simple HTML page
sudo tee /var/www/html/index.html > /dev/null <<EOF_HTML
<!DOCTYPE html>
<html>
<head>
    <title>Server VM</title>
</head>
<body>
    <h1>Welcome to Server VM!</h1>
    <p>Nginx is running on port 999</p>
</body>
</html>
EOF_HTML

# Start and enable nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Create Flask application (listening on port 8080)
sudo mkdir -p /opt/webserver
sudo tee /opt/webserver/app.py > /dev/null <<EOF_APP
from flask import Flask
import time

app = Flask(__name__)

DELAY_SECONDS = 450 

@app.route('/')
def delayed_response():
    print(f"Request received. Delaying for {DELAY_SECONDS} seconds...")
    time.sleep(DELAY_SECONDS) 
    print("Delay finished. Sending response.")
    return "Delayed response after 450 seconds."

if __name__ == '__main__':
    # Flask runs on port 8080, nginx will proxy to port 80
    app.run(host='0.0.0.0', port=8080, debug=False)
EOF_APP

# Change ownership
sudo chown -R gergo:gergo /opt/webserver

# Create systemd service for Flask app
sudo tee /etc/systemd/system/flask-app.service > /dev/null <<EOF_SERVICE
[Unit]
Description=Flask Web Server
After=network.target

[Service]
Type=simple
User=gergo
WorkingDirectory=/opt/webserver
ExecStart=/usr/bin/python3 /opt/webserver/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF_SERVICE

# Configure nginx to proxy Flask app on port 80
sudo tee /etc/nginx/conf.d/flask.conf > /dev/null <<EOF_NGINX_FLASK
server {
    listen 80;
    listen [::]:80;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Extend timeouts for the delayed response
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
        send_timeout 600s;
    }
}
EOF_NGINX_FLASK

# Test nginx configuration
sudo nginx -t

# Start and enable Flask app
sudo systemctl daemon-reload
sudo systemctl start flask-app
sudo systemctl enable flask-app

# Restart nginx to pick up new configuration
sudo systemctl restart nginx

echo "Installation completed successfully!"

