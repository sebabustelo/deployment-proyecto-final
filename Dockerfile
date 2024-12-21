FROM alpine:3.18.4

#ENV http_proxy "http://www-proxy.mrec.ar:8080"
#ENV https_proxy "http://www-proxy.mrec.ar:8080"

#RUN printenv | grep -i proxy

# expose ports
EXPOSE 80/tcp
EXPOSE 443/tcp

# update apk repositories
RUN apk update

RUN apk add nginx \
    #&& adduser -D  -g 'www' www  \
    && (addgroup -S www-data || true) \
    && (adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G www-data www-data || true) \
    && mkdir -p /run/nginx \
    && mkdir /www \
    && chown -R www-data:www-data /var/lib/nginx \
    && chown -R www-data:www-data /var/lib/nginx/tmp/ \
    && chown -R www-data:www-data /var/www \
    && rm -rf /etc/nginx/nginx.conf

ENV PHP_FPM_USER="www-data"
ENV PHP_FPM_GROUP="www-data"
ENV PHP_FPM_LISTEN_MODE="0666"
ENV PHP_MEMORY_LIMIT="256M"
ENV PHP_MAX_UPLOAD="10M"
ENV PHP_MAX_FILE_UPLOAD="20"
ENV PHP_MAX_POST="10M"
ENV PHP_DISPLAY_ERRORS="On"
ENV PHP_DISPLAY_STARTUP_ERRORS="On"
ENV PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR"
ENV PHP_CGI_FIX_PATHINFO=0

# install console tools
RUN apk add \
    inotify-tools

# install php
RUN apk add \
    #imagick \
    php82-pecl-imagick \
    curl \ 
    icu-dev \
    icu-libs \
    icu-data-full \
    imagemagick \    
    libintl \
    php82 \
    php82-bcmath \
    php82-common \
    php82-ctype \
    php82-curl \
    php82-dom \
    php82-fileinfo \
    php82-fpm \
    php82-gd \
    php82-gettext \
    php82-json \
    php82-iconv \
    php82-imap \
    php82-intl \
    php82-ldap \
    php82-mbstring \
    php82-mysqli \
    php82-opcache \
    php82-openssl \
    php82-phar \
    php82-pecl-redis \
    php82-pdo \
    php82-pdo_mysql \
    php82-pdo_sqlite \
    php82-phar \
    php82-posix \
    php82-session  \
    php82-simplexml \
    php82-sodium \
    php82-tokenizer \
    php82-xml \
    php82-xmlreader \
    php82-xmlwriter \
    php82-zip \
    php82-pecl-xdebug 


# INSTALL COMPOSER
RUN ln -s /usr/bin/php82 /usr/bin/php

# Installing composer

RUN curl -sS https://getcomposer.org/installer -o composer-setup.php \
    && php82 composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm -rf composer-setup.php \
    && curl -sS https://getcomposer.org/installer | php82

#RUN sed -i 's/include\ \=\ \/etc\/php82\/fpm.d\/\*.conf/\;include\ \=\ \/etc\/php82\/fpm.d\/\*.conf/g' /etc/php82/php-fpm.conf
    

#RUN sed -i "s|display_errors\s*=\s*Off|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php82/php.ini \
#    && sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php82/php.ini \
#    && sed -i "s|error_reporting\s*=\s*E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php82/php.ini 

# Configurar Xdebug en php.ini
RUN echo "zend_extension=xdebug.so" >> /etc/php82/conf.d/00_xdebug.ini \
    && echo "xdebug.mode=debug" >> /etc/php82/conf.d/00_xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> /etc/php82/conf.d/00_xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /etc/php82/conf.d/00_xdebug.ini \
    && echo "xdebug.client_port=9003" >> /etc/php82/conf.d/00_xdebug.ini \
    && echo "xdebug.log_level=0" >> /etc/php82/conf.d/00_xdebug.ini

RUN  sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php82/php.ini \
    && sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php82/php.ini \
    && sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php82/php.ini \
    && sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php82/php.ini \
    && sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php82/php.ini \
    && sed -i 's/smtp_port\ =\ 25/smtp_port\ =\ 81/g' /etc/php82/php.ini \
    && sed -i 's/SMTP\ =\ localhost/SMTP\ =\ mail.bekkersolutions.com/g' /etc/php82/php.ini \
    && sed -i 's/;sendmail_path\ =/sendmail_path\ =\ \/usr\/sbin\/sendmail\ -t/g' /etc/php82/php.ini


#COPY nginx.conf /etc/nginx/http.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf
#RUN sed -i "s|sendfile on\+|sendfile off|" /etc/nginx/nginx.conf  
RUN sed -i "s|include = /etc/php82/fpm.d/*.conf\+|#include = /etc/php82/fpm.d/*.conf|" /etc/php82/php-fpm.conf

# set working dir
WORKDIR /var/www/

# add entry point script
ADD --chown=root:root include/start.sh /tmp/start.sh

# make entry point script executable
RUN chmod +x /tmp/start.sh


# set entrypoint
ENTRYPOINT ["/tmp/start.sh"]