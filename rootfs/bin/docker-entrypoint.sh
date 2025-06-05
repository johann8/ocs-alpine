#!/bin/sh
#
#PHP_VERSION=82
PHP_VERSION=83
#PHP_VERSION=84

shutdown() {
  echo "shutting down container"

  # first shutdown any service started by runit
  for _srv in $(ls -1 /etc/service); do
    sv force-stop $_srv
  done

  # shutdown runsvdir command
  kill -HUP $RUNSVDIR
  wait $RUNSVDIR

  # give processes time to stop
  sleep 0.5

  # kill any other processes still running in the container
  for _pid  in $(ps -eo pid | grep -v PID  | tr -d ' ' | grep -v '^1$' | head -n -6); do
    timeout -t 5 /bin/sh -c "kill $_pid && wait $_pid || kill -9 $_pid"
  done
  exit
}

echo "Starting startup scripts in /docker-entrypoint-init.d ..."

for script in $(find /docker-entrypoint-init.d/ -executable -type f | sort); do

    echo >&2 "*** Running: $script"
    #chmod a+x $script
    #ls -la $script
    #echo "$script"
    $script
    retval=$?
    if [ $retval != 0 ];
    then
        echo >&2 "*** Failed with return value: $?"
        exit $retval
    fi

done
echo "Finished startup scripts in /docker-entrypoint-init.d"

# JH changed on 04.07.2024
# ========= Start ==========

# Set options into custom.ini
echo ""
echo -n "Setting \"date.timezone\" into custom.ini...      "
sed -i -e '/date.timezone=/c\date.timezone="'${TZ}'"' /etc/php${PHP_VERSION}/conf.d/custom.ini
echo "[done]"

echo -n "Setting \"date.timezone\" into php.ini...         "
sed -i -e '/;date.timezone =/c\date.timezone = '${TZ}'' /etc/php${PHP_VERSION}/php.ini
echo "[done]"

echo -n "Setting \"upload_max_filesize\" into custom.ini..."
sed -i -e '/upload_max_filesize= /c\upload_max_filesize= '${UPLOAD_MAX_FILESIZE}'' /etc/php${PHP_VERSION}/conf.d/custom.ini
echo "[done]"

echo -n "Setting \"post_max_size\" into custom.ini...      "
sed -i -e '/post_max_size= /c\post_max_size= '${POST_MAX_SIZE}'' /etc/php${PHP_VERSION}/conf.d/custom.ini
echo "[done]"

# If exists file php81-module.conf, then remove
if [[ -f /etc/apache2/conf.d/php81-module.conf ]] && [[ ${PHP_VERSION} –ne 81 ]]; then
   echo -n "Removing php81 config file...                  "
   rm -rf /etc/apache2/conf.d/php81-module.conf
   echo "[done]"
fi

# If exists file php82-module.conf, then remove
if [[ -f /etc/apache2/conf.d/php82-module.conf ]] && [[ ${PHP_VERSION} –ne 82 ]]; then
   echo -n "Removing php82 config file...                  "
   rm -rf /etc/apache2/conf.d/php82-module.conf
   echo "[done]"
fi

# If exists file php83-module.conf, then remove
if [[ -f /etc/apache2/conf.d/php83-module.conf ]] && [[ ${PHP_VERSION} –ne 83 ]]; then
   echo -n "Removing php83 config file...                  "
   rm -rf /etc/apache2/conf.d/php83-module.conf
   echo "[done]"
fi

# If exists file php84-module.conf, then remove
if [[ -f /etc/apache2/conf.d/php84-module.conf ]] && [[ ${PHP_VERSION} –ne 84 ]]; then
   echo -n "Removing php84 config file...                  "
   rm -rf /etc/apache2/conf.d/php84-module.conf
   echo "[done]"
fi

# Copy apache2 config file
if [[ -f /apache-conf-dir.tgz ]]; then
   echo -n "Moving Apache config file...                    "
   (
   mkdir /tmp/33
   tar -xzvf /apache-conf-dir.tgz -C /tmp/33/ > /dev/null 2>&1
   mv -f /tmp/33/etc/apache2/conf.d/* /etc/apache2/conf.d/
   mv -f /tmp/33/etc/apache2/conf.d/.htpasswd-ocsapi /etc/apache2/conf.d/
   rm -rf /tmp/33
   )
   echo "[done]"
fi

echo ""
# ========== END ==========

echo "Starting runit..."
exec runsvdir -P /etc/service &

RUNSVDIR=$!
echo "Started runsvdir, PID is $RUNSVDIR"
echo "wait for processes to start...."

sleep 5
for _srv in $(ls -1 /etc/service); do
    sv status $_srv
done

# catch shutdown signals
trap shutdown SIGTERM SIGHUP SIGQUIT SIGINT
wait $RUNSVDIR

shutdown
