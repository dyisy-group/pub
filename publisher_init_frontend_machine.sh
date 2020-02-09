#!/bin/bash

# enable nginx to write files
sudo setenforce 0

# set up public html dir and dir for ssl files
sudo mkdir /var/www
sudo mkdir /var/www/html
sudo mkdir /etc/ssl
sudo mkdir /etc/ssl/server

# enable epel
sudo yum install -y epel-release

# update latest yum
sudo rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

# install php on nginx
sudo yum install -y git vim htop nginx php70w php70w-bcmath php70w-cli php70w-common php70w-fpm php70w-mbstring php70w-mcrypt php70w-mysql php70w-xml unzip wget p7zip sysstat

# configure nginx conf file
sudo rm /etc/nginx/nginx.conf
sudo rm /etc/nginx/conf.d/localhost_https.conf.disabled

sudo cat >>/etc/nginx/nginx.conf<<EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /var/run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # insert here nfs location for conf files
    include /etc/nginx/conf.d/*.conf;

}
EOF

sudo chmod 644 /etc/nginx/nginx.conf

# configure php-fpm conf file
sudo sed -i 's/user \= apache/user \= nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i 's/group \= apache/group \= nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i 's/listen \= 127.0.0.1:9000/listen \= \/var\/run\/php-fpm\/php-fpm.sock/g' /etc/php-fpm.d/www.conf
sudo sed -i 's/;listen.owner \= nobody/listen.owner \= nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i 's/;listen.group \= nobody/listen.group \= nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i 's/;listen.mode \= 0660/listen.mode \= 0664/g' /etc/php-fpm.d/www.conf

# set up creds
sudo chmod 775 /var/www/html
sudo chown nginx:nginx /var/lib/php/session

# open http/https ports on firewall
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --reload

# start the webserver
sudo service nginx start
sudo service php-fpm start 
sudo service sysstat restart

# start service on reboot
sudo chkconfig nginx on
sudo chkconfig php-fpm on
sudo chkconfig sysstat on

# fix nginx creds
sudo chown -R nginx:nginx /var/www/html

# update os to latest kernel
sudo yum update -y

# enable nginx to write files
sudo setenforce 0


