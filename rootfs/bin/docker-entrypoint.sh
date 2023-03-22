#!/bin/sh

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

# JH addded on 19.03.2023
# ========= Start ==========

# Set options into custom.ini
echo ""
echo -n "Setting \"date.timezone\" into custom.ini...      "
sed -i -e '/date.timezone=/c\date.timezone="'${TZ}'"' /etc/php81/conf.d/custom.ini
echo "[done]"

echo -n "Setting \"date.timezone\" into php.ini...         "
sed -i -e '/;date.timezone =/c\date.timezone = '${TZ}'' /etc/php81/php.ini
echo "[done]"

echo -n "Setting \"upload_max_filesize\" into custom.ini..."
sed -i -e '/upload_max_filesize= /c\upload_max_filesize= '${UPLOAD_MAX_FILESIZE}'' /etc/php81/conf.d/custom.ini
echo "[done]"

echo -n "Setting \"post_max_size\" into custom.ini...      "
sed -i -e '/post_max_size= /c\post_max_size= '${POST_MAX_SIZE}'' /etc/php81/conf.d/custom.ini
echo "[done]"
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
