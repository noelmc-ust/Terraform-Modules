#!/bin/bash
# Stop script execution immediately if any command fails
set -e


sudo apt update -y
sudo apt install nginx npm git -y


cd /var/www/html
git clone https://github.com/noelmc-ust/organic-ghee
sudo chmod -R 777 /var/www/html/organic-ghee
sudo rm -f /var/www/html/index.nginx-debian.html


sudo cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name _; # Accept any incoming public IP traffic via Load Balancer

    location /static/ {
        alias /var/www/html/organic-ghee/public/;
        expires 30d;
    }

    location / {
        proxy_pass http://127.0.0.1:5656;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade; # Escaped here safely because of cat <<EOF limits
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

sudo systemctl restart nginx
cd /var/www/html/organic-ghee
npm install
npm install -g pm2
pm2 start src/app.js --name "organic"
pm2 save
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u noelmc --hp /home/noelmc