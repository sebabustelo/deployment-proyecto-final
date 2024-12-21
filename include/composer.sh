#!/bin/sh

EXPECTED_CHECKSUM="$(php-fpm82 -r 'copy("https://composer.github.io/installer.sig", "php-fpm://stdout");')"
php-fpm82 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php-fpm82 -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
then
    >&2 echo 'ERROR: Invalid installer checksum'
    rm composer-setup.php
    exit 1
fi

php-fpm82 composer-setup.php --quiet
RESULT=$?
rm composer-setup.php
exit $RESULT
