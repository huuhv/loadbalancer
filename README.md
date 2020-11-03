# Loadbalancer
Demo load balancing with Apache, Nginx, HAproxy, AWS Elastic Load Balancing

# Install project

## Requirements

## Server Requirements
- PHP >= 7.1.3
- OpenSSL PHP Extension
- PDO PHP Extension
- Mbstring PHP Extension
- Tokenizer PHP Extension
- XML PHP Extension
- Ctype PHP Extension
- JSON PHP Extension
- Node >= 8.12.0 / npm >= 6.4.1

## Install without Docker

- Clone the repo ( chosse branch that you want to deploy). Can use `GIT` or `Download sourcode`.
- Make sure that you have moved the directory containing the sourcecode. Example: `cd /var/www/html/loadbalancer/`
- `composer install --no-scripts`
- Add permission to folder `sudo chmod 777 -R storage`, `sudo chmod 777 -R bootstrap/cache`
- `cp .env.example .env`
- `php artisan key:generate`
- `sudo vim .env` config file `.env` fill in a value in the environment variable.
    + Add config connect to DB
        ```
        DB_HOST=
        DB_PORT=
        DB_DATABASE=
        DB_USERNAME=
        DB_PASSWORD=
        ```
- After you edit the file you need to run 2 commands:

    + `php artisan config:cache`
    + `php artisan config:clear`

    --> Noted: Every time that you edit this file `.env` you need to run commands 2 above.
- Install node modules : `npm install`
- Run webpack :
    + if enviroment is production: `npm run production`
    + if enviroment is development: `npm run dev`
- Config VirtualHost with port: 8081 or 8082 or 8083
    ```
    <VirtualHost *:8080>
        DocumentRoot /var/www/html/public
        SetEnv HTTPS on
        ServerName $DOMAIN
        ErrorLog /var/log/httpd/error.log
        CustomLog /var/log/httpd/access.log combinedcustomized
        <Directory "/var/www/html/public">
            Options -Indexes
            AllowOverride All

            Order allow,deny
            allow from all
        </Directory>
    </VirtualHost>
    ```

## Install with Docker

- `cp .env.example env.docker`, and add config to env.docker
- Step 1: Build image
    + `sudo docker build -t loadbalancing -f build/Dockerfile .`
- Step 2: Run 2 or than 3 containers with same docker image
    + `sudo docker run -d --name "cms-load-balancing-01" --env-file env.docker  -p "8080":"80" loadbalancing`
    + `sudo docker run -d --name "cms-load-balancing-02" --env-file env.docker  -p "8081":"80" loadbalancing`


## Config Load Balancing in Apache

Using Apache as HTTP Load Balancer (Reverse Proxy)

Command on Ubuntu

- Step 1 - Install Apache
```
sudo apt-get install apache2
```

- Step 2 — Enabling Necessary Apache Modules
    ```
    sudo a2enmod proxy
    sudo a2enmod proxy_http
    sudo a2enmod proxy_balancer
    sudo a2enmod lbmethod_byrequests
    ```
    Restart Apache to apply
    `sudo systemctl restart apache2`

- Step 3 — Creating Backend Test Servers

    Use config with VirtualHost or run by with port = 8080 or 8081

- Step 4 — Modifying the Default Configuration to Enable Reverse Proxy

```
sudo nano /etc/apache2/sites-available/000-default.conf
```

Reverse Proxying a Single Backend Server
```
<VirtualHost *:80>
    ProxyPreserveHost On

    ProxyPass / http://127.0.0.1:8080/
    ProxyPassReverse / http://127.0.0.1:8080/
</VirtualHost>
```
    
Load Balancing Across Multiple Backend Servers
```
<VirtualHost *:80>
    <Proxy balancer://mycluster>
        BalancerMember http://127.0.0.1:8080
        BalancerMember http://127.0.0.1:8081
    </Proxy>

    ProxyPreserveHost On

    ProxyPass / balancer://mycluster/
    ProxyPassReverse / balancer://mycluster/
</VirtualHost>
```
```
sudo systemctl restart apache2
```

## Config Load Balancing in Nginx

Using nginx as HTTP Load Balancer (Reverse proxy)

Command on Ubuntu

- Step 1 — Install nginx
```
sudo apt-get install nginx
```
- Step 2 — Creating Backend Test Servers

    Use config with VirtualHost or run by with port = 8080 or 8081 or 8082

- Step 3 — Modifying the Default Configuration to Enable Reverse Proxy

```
sudo nano /etc/nginx/sites-available/default
```
Add code below to apply
```
upstream backend  {
  server backend1.example.com;
  server backend2.example.com;
  server backend3.example.com;
}

server {
  location / {
    proxy_pass  http://backend;
  }
}
```

Example:
```
upstream localhost {
    server 127.0.0.1:8080 weight=1;
    server 127.0.0.1:8081 weight=2;
    server 127.0.0.1:8082 weight=3;
}
server {
    listen 80;
    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://localhost;
    }
}
```

Restart nginx

```
sudo service nginx restart
```


## Config Load Balancing with HAProxy

- Step 1 - Install HAProxy

`sudo apt-get install haproxy`

- Step 2 - Configuration

```
sudo nano /etc/haproxy/haproxy.cfg
```

Add code below to apply

```
frontend haproxynode
    bind *:80
    mode http
    default_backend backendnodes
```

```
backend backendnodes
    balance roundrobin
    option forwardfor
    http-request set-header X-Forwarded-Port %[dst_port]
    http-request add-header X-Forwarded-Proto https if { ssl_fc }
    option httpchk HEAD / HTTP/1.1\r\nHost:localhost
    server node1 192.168.1.3:8080 check
    server node2 192.168.1.4:8081 check
```
Example:

```
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2 debug

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    # stats socket /var/lib/haproxy/stats
    ssl-server-verify none

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

#---------------------------------------------------------------------
# main frontend which proxys to the backends
#---------------------------------------------------------------------

frontend web
    bind *:80
    mode http
    default_backend app_web

frontend api
    bind *:81
    default_backend app_api

#---------------------------------------------------------------------
# round robin balancing between the various backends
#---------------------------------------------------------------------

backend app_web
    balance roundrobin
    option forwardfor
    http-request set-header X-Forwarded-Port %[dst_port]
    http-request add-header X-Forwarded-Proto https if { ssl_fc }
    option httpchk HEAD / HTTP/1.1\r\nHost:localhost
    server server1 127.0.0.1:8080 check
    server server2 127.0.0.1:8081 check
    server server3 127.0.0.1:8082 check

backend app_api
    balance roundrobin
    option forwardfor
    http-request set-header X-Forwarded-Port %[dst_port]
    http-request add-header X-Forwarded-Proto https if { ssl_fc }
    option httpchk HEAD / HTTP/1.1\r\nHost:localhost
    server server1 127.0.0.1:8001 check
    server server2 127.0.0.1:8002 check
    server server3 127.0.0.1:8003 check

listen stats #statistic times access to application
    bind *:8000
    stats enable
    stats uri /
    stats hide-version
    stats auth username:password

```

Restart HAProxy

    ```
    sudo service haproxy restart
    ```


## AWS Elastic Load Balancing




#### Reference
- https://www.digitalocean.com/community/tutorials/how-to-use-apache-as-a-reverse-proxy-with-mod_proxy-on-ubuntu-16-04
- https://www.digitalocean.com/community/tutorials/how-to-set-up-nginx-load-balancing
- https://www.linode.com/docs/guides/how-to-use-haproxy-for-load-balancing/
- https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html
