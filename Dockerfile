FROM php:7.4-fpm-alpine
# add packages
RUN set -xe \
 && apk add --update  icu \
 && apk add --no-cache --virtual .php-deps make \
 && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
        curl-dev \
        openssl-dev \
        pcre-dev \
        pcre2-dev \
        zlib-dev \
        tzdata \
        rabbitmq-c-dev \
        curl \
        wget \
        unzip  \
        libpng-dev \
        gcc \
        g++ \
        gettext-dev \
	php7-dev \
        icu-dev \
	git \
	libxml2-dev \
	libxslt \
	libxslt-dev \
	libzip \
	libzip-dev \
	libstdc++ \
	gcompat

RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
 && echo 'Asia/Shanghai'>/etc/timezone

# Composer
RUN wget --prefer-family=IPv4 --no-check-certificate -T 120 -t3 https://soft.vpser.net/web/php/composer/composer.phar -O /usr/local/bin/composer \
 && chmod +x /usr/local/bin/composer \
 && composer self-update --clean-backups

# extension
RUN docker-php-ext-install pdo_mysql \
 && docker-php-ext-install bcmath \
 && docker-php-ext-install gd \
 && docker-php-ext-install exif \
 && docker-php-ext-install gettext \
 && docker-php-ext-install iconv \
 && docker-php-ext-install sockets \
 && docker-php-ext-install intl \
 && docker-php-ext-install mysqli \
 && docker-php-ext-install soap \
 && docker-php-ext-install sysvsem \
 && docker-php-ext-install xmlrpc \
 && docker-php-ext-install pcntl \
 && docker-php-ext-install xsl \
 && docker-php-ext-install zip 
# rabbitmq-c extension
RUN wget https://github.com/alanxz/rabbitmq-c/releases/download/v0.7.1/rabbitmq-c-0.7.1.tar.gz\
 &&  tar xf rabbitmq-c-0.7.1.tar.gz \
 && cd rabbitmq-c-0.7.1 \
 && ./configure --prefix=/usr/local/rabbitmq-c \
 && make \
 && make install && cd ../ rm -r rabbitmq-c-0.7.1

# amqp extension
RUN wget http://pecl.php.net/get/amqp-1.10.2.tgz \
 && tar xf amqp-1.10.2.tgz \
 && cd amqp-1.10.2 && phpize && ./configure  --with-amqp --with-librabbitmq-dir=/usr/local/rabbitmq-c/ \
 && make && make install && cd ../ && rm -r amqp-1.10.2 

# Redis extension
RUN wget http://pecl.php.net/get/redis-5.3.4.tgz -O /tmp/redis.tar.tgz \
 && pecl install /tmp/redis.tar.tgz \
 && rm -rf /tmp/redis.tar.tgz \
 && docker-php-ext-enable redis
# Swoole extension
#-----------------------------------------------------------------------------------------------
RUN wget https://github.com/swoole/swoole-src/archive/v4.6.7.tar.gz -O swoole.tar.gz \
 && mkdir -p swoole \
 && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
 && rm swoole.tar.gz \
 && cd swoole \
 && phpize \
 && ./configure  --enable-mysqlnd --enable-openssl --enable-http2 \
 && make  \
 && make install && cd ../ \
 && rm -r swoole \
 && docker-php-ext-enable swoole
## Swoole_async extension
RUN wget -O async-ext.zip https://github.com/hd900415/download/raw/master/async-ext.zip \
 && unzip async-ext.zip \
 && rm async-ext.zip  && cd async-ext \
 && phpize \
 && chmod +x configure \
 && ./configure \
 && make -j  && make install && cd ../ && rm -r async-ext \
 && docker-php-ext-enable swoole_async \
 && docker-php-source  delete 
#-----------------------------------------------------------------------------------------------
# ADD conf  
# RUN echo "[global]" >> /usr/local/etc/php-fpm.conf \
#     && echo "include=etc/php-fpm.d/*.conf" > /usr/local/etc/php-fpm.conf \
#     && echo "pid = /var/run/php-fpm.pid" >> /usr/local/etc/php-fpm.conf \
#     && echo "error_log = /var/log/php-fpm.log" >> /usr/local/etc/php-fpm.conf \
#     && echo "log_level = notice" >> /usr/local/etc/php-fpm.conf \
#     && echo "[www]" >> /usr/local/etc/php-fpm.conf \
#     && echo "listen = /tmp/php-cgi.sock" >> /usr/local/etc/php-fpm.conf  \
#     && echo "listen.backlog = -1" >> /usr/local/etc/php-fpm.conf  \
#     && echo "listen.allowed_clients = 127.0.0.1:9050" >> /usr/local/etc/php-fpm.conf  \
#     && echo "listen.owner = www-data" >> /usr/local/etc/php-fpm.conf \
#     && echo "listen.group = www-data" >> /usr/local/etc/php-fpm.conf  \
#     && echo "pm = dynamic" >> /usr/local/etc/php-fpm.conf  \
#     && echo "pm.max_children = 100" >> /usr/local/etc/php-fpm.conf  \
#     && echo "pm.start_servers = 10" >> /usr/local/etc/php-fpm.conf  \
#     && echo "pm.min_spare_servers = 10" >> /usr/local/etc/php-fpm.conf  \
#     && echo "pm.max_spare_servers = 20" >> /usr/local/etc/php-fpm.conf  \
#     && echo "pm.max_requests = 1024" >> /usr/local/etc/php-fpm.conf  \
#     && echo "pm.process_idle_timeout = 10s" >> /usr/local/etc/php-fpm.conf  \
#     && echo "request_terminate_timeout = 100" >> /usr/local/etc/php-fpm.conf \
#     && echo "request_slowlog_timeout = 0" >> /usr/local/etc/php-fpm.conf  \
#     && echo "slowlog = /var/log/slow.log" >> /usr/local/etc/php-fpm.conf 

# RUN cat << EOF >> /usr/local/etc/php-fpm.conf \
# [global] \
# pid = /var/run/php-fpm.pid \
# error_log = /var/log/php-fpm.log \
# log_level = notice \
# [www] \
# listen = /tmp/php-cgi.sock \
# listen.backlog = -1 \
# listen.allowed_clients = 127.0.0.1 \
# listen.owner = www-data \
# listen.group = www-data \
# listen.mode = 0666 \
# user = www-data \
# group = www-data \
# pm = dynamic \
# pm.max_children = 100 \
# pm.start_servers = 10 \
# pm.min_spare_servers = 10 \
# pm.max_spare_servers = 20 \
# pm.max_requests = 1024 \
# pm.process_idle_timeout = 10s \
# request_terminate_timeout = 100 \
# request_slowlog_timeout = 0 \
# slowlog = /var/log/slow.log \
# EOF 

WORKDIR /var/www/html

EXPOSE 9000
ENTRYPOINT ["php-fpm","-y","/usr/local/etc/php-fpm.conf"]
