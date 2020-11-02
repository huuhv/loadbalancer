FROM amazonlinux:2

# `sudo` is for script install td-agent
RUN yum update -y && yum install -y \
sudo \
&& sudo amazon-linux-extras install php7.3

RUN yum update -y && yum install -y \
    system-lsb \
    httpd \
    mod_php \
    gcc \
    openssl-devel \
    php-bcmath \
    php-cli \
    php-common \
    php-dba \
    php-dbg \
    php-devel \
    php-enchant \
    php-fpm \
    php-gd \
    php-gmp \
    php-imap \
    php-intl \
    php-json \
    php-ldap \
    php-mbstring \
    php-mcrypt \
    php-mysqlnd \
    php-odbc \
    php-opcache \
    php-pdo \
    php-pdo-dblib \
    php-pecl-igbinary \
    php-pecl-imagick \
    php-pecl-oauth \
    php-pecl-ssh2 \
    php-pecl-uuid \
    php-pecl-yaml \
    php-pgsql \
    php-process \
    php-pspell \
    php-recode \
    php-snmp \
    php-soap \
    php-tidy \
    php-xml \
    php-xmlrpc \
    php-zip \
    php-pear \
    vim \
    nano \
    man \
    git \
    && yum clean all \
    && rm -rf /var/cache/yum

# Composerインストール
RUN curl -sS https://getcomposer.org/installer | \
    php -- --install-dir=/usr/local/bin/ --filename=composer

# Install Nodejs
RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash - \
    && yum install -y nodejs

ADD ./ /var/www/html/
RUN composer install --no-scripts --no-autoloader --no-ansi --no-interaction --working-dir=/var/www/html/

# configure application
RUN sed -i -e "s/memory_limit = 128M/memory_limit = 512M/" /etc/php.ini

RUN chmod 777 -R /var/www/html/storage
RUN chmod 777 -R /var/www/html/bootstrap/cache

WORKDIR /var/www/html
RUN composer install --no-scripts
RUN npm install
RUN npm run dev

#Config Httpd
ADD ./conf.d/loadbalancing.conf.template /etc/httpd/conf.d/loadbalancing.conf
RUN touch public/status.html
RUN ln -sf /dev/stdout /var/log/httpd/access_admin80.log \
    && ln -sf /dev/stderr /var/log/httpd/error_admin80.log

EXPOSE 80

COPY build/docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/usr/sbin/httpd", "-DFOREGROUND"]
