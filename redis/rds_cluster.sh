#!/bin/bash

REDIS_CONFIG_PATH=/etc/rds_cluster
REDIS_DB_PATH=/opt/rds_cluster
REDIS_LOG_PATH=/var/log/rds_cluster
REDIS_DAEMON="/usr/local/bin/redis-server"
REDIS_CLUSTER_NAME="rds_cluster"

start() {
    [ -d ${REDIS_CONFIG_PATH} ] || exit 1
    [ -d ${REDIS_DB_PATH} ] || exit 1
    [ -x $REDIS_DAEMON ] || exit 1
    echo "Starting ${REDIS_CLUSTER_NAME} ..."
    
    for processpath in $(find ${REDIS_CONFIG_PATH} -maxdepth 1 -mindepth 1 -type d); do
        local daemon_opts="${processpath}/redis.conf"
        [ -f "${processpath}/redis.conf" ] || continue
        process="process_""`basename ${processpath}`"
        pidfile="`cat ${processpath}/redis.conf | grep pidfile | awk '{print $2}'`"
        echo -n $"Starting ${process} "
        start-stop-daemon --start --background --pidfile ${pidfile} --startas ${REDIS_DAEMON} -- ${daemon_opts}
        echo
    done
}

stop () {
    echo "Stopping ${REDIS_CLUSTER_NAME} ..."
    for processpath in $(find ${REDIS_CONFIG_PATH} -maxdepth 1 -mindepth 1 -type d); do
        [ -f "${processpath}/redis.conf" ] || continue
        process="process_""`basename ${processpath}`"
        pidfile="`cat ${processpath}/redis.conf | grep pidfile | awk '{print $2}'`"
        if [ -f ${pidfile} ]; then
            echo -n $"Stopping ${process}"
            start-stop-daemon --stop --oknodo --pidfile ${pidfile} --retry 5
            echo
        fi
    done
}

restart() {
    stop
    sleep 2
    start
}

status() {
    echo "${REDIS_CLUSTER_NAME} status ..."
    for processpath in $(find ${REDIS_CONFIG_PATH} -maxdepth 1 -mindepth 1 -type d); do
        [ -f "${processpath}/redis.conf" ] || continue
        process="process_""`basename ${processpath}`"
        pidfile="`cat ${processpath}/redis.conf | grep pidfile | awk '{print $2}'`"
        start-stop-daemon --status --pidfile ${pidfile}
    done
}

case "$1" in
    start)
        $1
        ;;
    stop)
        $1
        ;;
    restart)
        $1
        ;;
    status)
        $1
        ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart}"
        exit 2
esac
exit $?

