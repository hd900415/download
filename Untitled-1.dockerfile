FROM php:7.4.21-fpm
# Version
ENV PHPREDIS_VERSION 5.3.4
ENV SWOOLE_VERSION 4.6.7
# Timezone
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
&& echo 'Asia/Shanghai'>/etc/timezone
# Libs
RUN apt-get -y update \
&& apt-get install -y \
    curl \
    wget \
    git \
    zip \
    libz-dev \
    libssl-dev \
    libnghttp2-dev \
    libpcre3-dev \
    librabbitmq-dev \
    unzip \
    apt-utils  \
&& apt-get clean 
# Composer
# RUN curl -sS https://getcomposer.org/installer | php \
# && mv composer.phar /usr/local/bin/composer \
# && composer self-update --clean-backups
# backup-composer install 
RUN wget --prefer-family=IPv4 --no-check-certificate -T 120 -t3 https://soft.vpser.net/web/php/composer/composer.phar -O /usr/local/bin/composer
# PDO extension
RUN docker-php-ext-install pdo_mysql 
# Bcmath extension
RUN docker-php-ext-install bcmath 
# amqp extension
RUN pecl install amqp && docker-php-ext-enable amqp
# echo "extension=/www/server/php/72/lib/php/extensions/no-debug-non-zts-20170718/amqp.so" >>/usr/local/php/etc/php.ini
# rabbitmq-c extension
# Redis extension
RUN wget http://pecl.php.net/get/redis-${PHPREDIS_VERSION}.tgz -O /tmp/redis.tar.tgz \
&& pecl install /tmp/redis.tar.tgz \
&& rm -rf /tmp/redis.tar.tgz \
&& docker-php-ext-enable redis
# Swoole extension
RUN wget https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz -O swoole.tar.gz \
&& mkdir -p swoole \
&& tar -xf swoole.tar.gz -C swoole --strip-components=1 \
&& rm swoole.tar.gz \
&&( \
    cd swoole \
&& phpize \
&&./configure --enable-async-redis --enable-mysqlnd --enable-openssl --enable-http2 --enable-amqp\
&& make -j$(nproc) \
&& make install \
) \
&& rm -r swoole \
&& docker-php-ext-enable swoole

RUN wget -O async-ext.zip http://dl.appleasp.com/lnmp/src/async-ext.zip \
&& unzip async-ext.zip  \
&& rm async-ext.zip  && cd async-ext \
&& /usr/local/bin/phpize \
&& chmod +x configure \
&& ./configure   --with-php-config=/usr/local/bin/php-config \
&& make -j  && make install && cd ../ && rm -r async-ext \
&& docker-php-ext-enable swoole_async 

WORKDIR /var/www/html

EXPOSE 9000
ENTRYPOINT ["php-fpm","-y","/usr/local/etc/php-fpm.conf"]