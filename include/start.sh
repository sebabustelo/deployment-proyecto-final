#!/bin/sh

echo ""
echo "Start container web server..."

echo "domain: $DOMAIN"
echo "document root: $DOCUMENT_ROOT"

# check if we should expose nginx to host
# /docker/etc/ must be set in docker-compose
if [ -d /docker/etc/ ];
then
    echo "Expose nginx to host..."
    sleep 3

    # check if config backup exists
    if [ ! -d /etc/nginx.bak/ ];
    then
        # create config backup
        echo "Expose nginx to host - backup container config"
        cp -r /etc/nginx/ /etc/nginx.bak/
    fi

    # check if config exists on host
    if [ -z "$(ls -A /docker/etc/nginx/ 2> /dev/null)" ];
    then
        # config doesn't exist on host
        echo "Expose nginx to host - no host config"

        # check if config backup exists
        if [ -d /etc/nginx.bak/ ];
        then
            # restore config from backup
            echo "Expose nginx to host - restore config from backup"
            rm /etc/nginx/ 2> /dev/null
            cp -r /etc/nginx.bak/ /etc/nginx/
        fi

        # copy config to host
        echo "Expose nginx to host - copy config to host"
        cp -r /etc/nginx/ /docker/etc/
    else
        echo "Expose nginx to host - config exists on host"
    fi

    # create symbolic link so host config is used
    echo "Expose nginx to host - create symlink"
    rm -rf /etc/nginx/ 2> /dev/null
    ln -s /docker/etc/nginx /etc/nginx

    echo "Expose nginx to host - OK"
fi




# check if we should expose php to host
if [ -d /docker/etc/ ];
then
    echo "Expose php to host..."
    sleep 3

    # check if config backup exists
    if [ ! -d /etc/php82.bak/ ];
    then
        # create config backup
        echo "Expose php to host - backup container config"
        cp -r /etc/php82/ /etc/php82.bak/
    fi

    # check if php config exists on host
    if [ -z "$(ls -A /docker/etc/php82/ 2> /dev/null)" ];
    then
        # config doesn't exist on host
        echo "Expose php to host - no host config"

        # check if config backup exists
        if [ -d /etc/php82.bak/ ];
        then
            # restore config from backup
            echo "Expose php to host - restore config from backup"
            rm /etc/php82/ 2> /dev/null
            cp -r /etc/php82.bak/ /etc/php82/
        fi

        # copy config to host
        echo "Expose php to host - copy config to host"
        cp -r /etc/php82/ /docker/etc/
    else
        echo "Expose php to host - config exists on host"
    fi

    # create symbolic link so host config is used
    echo "Expose php to host - create symlink"
    rm -rf /etc/php82/ 2> /dev/null
    ln -s /docker/etc/php82 /etc/php82

    echo "Expose php to host - OK"
fi

# clean log files
truncate -s 0 /var/log/nginx/access.log 2> /dev/null
truncate -s 0 /var/log/nginx/error.log 2> /dev/null


# start php-fpm
php-fpm82

# sleep
sleep 2

# check if php-fpm is running
if pgrep -x php-fpm82 > /dev/null
then
    echo "Start php-fpm - OK"
else
    echo "Start php-fpm - FAILED"
    exit
fi

echo "-------------------------------------------------------"

# start nginx
/usr/sbin/nginx -c /etc/nginx/nginx.conf

# check if nginx is running
if pidof nginx > /dev/null
then
    echo "Start container web server - OK - ready for connections"
else
    echo "Start container web server - FAILED"
    exit
fi

echo "-------------------------------------------------------"

stop_container()
{
    echo ""
    echo "Stop container web server... - received SIGTERM signal"
    echo "Stop container web server - OK"
    exit
}

# catch termination signals
# https://unix.stackexchange.com/questions/317492/list-of-kill-signals
trap stop_container SIGTERM

restart_processes()
{
    sleep 0.5

    # test php-fpm config
    if php-fpm82 -t
    then
        # restart php-fpm
        echo "Restart php-fpm..."
        killall php-fpm82 > /dev/null
        php-fpm82

        # check if php-fpm is running
        if pgrep -x php-fpm82 > /dev/null
        then
            echo "Restart php-fpm - OK"
        else
            echo "Restart php-fpm - FAILED"
        fi
    else
        echo "Restart php-fpm - FAILED - syntax error"
    fi

    # test nginx config
    if nginx -t
    then
        # restart nginx
        echo "Restart nginx..."
        nginx -s reload

        # check if nginx is running
        if pgrep -x nginx > /dev/null
        then
            echo "Restart nginx - OK"
        else
            echo "Restart nginx - FAILED"
        fi
    else
        echo "Restart nginx - FAILED - syntax error"
    fi
    
}

# infinite loop, will only stop on termination signal
while true; do
    # restart nginx and php-fpm if any file in /etc/nginx or /etc/php82 changes
    inotifywait --quiet --event modify,create,delete --timeout 60 --recursive /etc/nginx/ /etc/php82/ && restart_processes
done
