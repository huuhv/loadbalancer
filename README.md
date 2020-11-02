# loadbalancer
Demo load balancing with Apache, Nginx, HAproxy

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
    - Make sure that you have moved the directory containing the sourcecode. Example: `cd /var/www/html/gu-ambassador-admin/`
    - `composer install --no-scripts`
    - Add permission to folder `sudo chmod 777 -R storage`, `sudo chmod 777 -R bootstrap/cache`
    - `cp .env.example .env`
    - `php artisan key:generate`
    -  `sudo vim .env` config file `.env` fill in a value in the environment variable.
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
        <VirtualHost *:80>
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
        + `docker build -t loadbalancing -f build/Dockerfile .`
    - Step 2: Run 2 or than 3 containers with same docker image
        + `docker run -d --name "cms-load-balancing-011" --env-file env.docker  -p "8080":"80" loadbalancing`
        + `docker run -d --name "cms-load-balancing-02" --env-file env.docker  -p "8081":"80" loadbalancing`


## Config Load Balancing in Apache

    Using Apache as HTTP Load Balancer (Reverse Proxy)


## Config Load Balancing in Nginx

    Using nginx as HTTP Load Balancer (Reverse proxy)


## Config Load Balancing with HAProxy


## AWS Elastic Load Balancing
    https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html


