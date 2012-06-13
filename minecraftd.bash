#!/bin/bash

. /etc/rc.conf
. /etc/rc.d/functions

DAEMON=minecraftd
USER=luke
SERVER_LOCATION=/home/luke/.minecraft/minecraft_server.jar
SERVER_NAME=`echo $SERVER_LOCATION | sed 's/.*\///'`
SERVER_DIR=`echo $SERVER_LOCATION | sed "s/\/$SERVER_NAME//"`
MEMORY_START=32M
MEMORY_MAX=64M
BACKUP_DIR=/home/luke/.minecraft/backups
MAX_BACKUPS=5
WORLD_NAME=world
WORLD_DIR=$SERVER_DIR/$WORLD_NAME

# Source configuration directory
# Note configuration file is REQUIRED
# because it includes path to Minecraft server file
#if [[ -e /etc/conf.d/$DAEMON ]]; then
#    . /etc/conf.d/$DAEMON
#else
#    echo "Configuration file /etc/conf.d/$DAEMON does not exist. This file is required. You may have to re-install the package to get it back."
#    exit 1
#fi

function run_as_user {
    result=`su -c "$1" $USER`
    echo $result
}

function server_running() {
    result=`run_as_user "tmux list-sessions | grep $DAEMON"`
    if [[ "$result" != '' ]]; then
        echo 1
    else
        echo 0
    fi
}

function start_server() {
    run_command="cd $SERVER_DIR && java -Xms$MEMORY_START -Xmx$MEMORY_MAX -jar $SERVER_LOCATION nogui"
    run_as_user "tmux new-session -d -s $DAEMON \"$run_command\"" $stdout>/dev/null
}

function send_command() {
    run_as_user "tmux send-keys -t $DAEMON:0.0 \"$1\"" $stdout>/dev/null
    run_as_user "tmux send-keys -t $DAEMON:0.0 \"Enter\"" $stdout>/dev/null
}

function stop_server() {
    send_command "stop"
}

case $1 in
    start)
        stat_busy "Starting $DAEMON"
        running=`server_running`
        if [[ $running == 1 ]]; then
            stat_fail
            exit 1
        else
            start_server
            stat_done
        fi
        ;;
    stop)
        stat_busy "Stopping $DAEMON"
        running=`server_running`
        if [[ $running == 1 ]]; then
            stop_server
            stat_done
        else
            stat_fail
            exit 1
        fi
        ;;
    restart)
        stat_busy "Stopping $DAEMON"
        running=`server_running`
        if [[ $running == 1 ]]; then
            stop_server
            stat_done
        else
            stat_fail
            exit 1
        fi
        stat_busy "Starting $DAEMON"
        running=`server_running`
        if [[ $running == 1 ]]; then
            start_server
            stat_done
        else
            stat_fail
            exit 1
        fi
        ;;
    status)
        running=`server_running`
        if [[ $running == 1 ]]; then
            echo "$DAEMON Running"
        else
            echo "$DAEMON Stopped"
        fi
        ;;
    backup)
        stat_busy "Backing Up World"
        num_backups=`ls $BACKUP_DIR | wc -l`
        if [[ $num_backups > $MAX_BACKUPS ]]; then
            ls -t $BACKUP_DIR | head -n 1 | xargs rm # is xargs really needed?
        fi
        running=`server_running`
        if [[ $running == 1 ]]; then
            send_command "save-all"
            sleep 3
        fi
        cp -r $WORLD_DIR $BACKUP_DIR/`date +%F-%H-%M-%S.backup.d`
        stat_done
        ;;
    send)
        stat_busy "Sending command"
        running=`server_running`
        if [[ $running == 1 ]]; then
            send_command "$2"
            stat_done
        else
            echo "Server not running"
            stat_fail
            exit 1
        fi
        ;;
esac
