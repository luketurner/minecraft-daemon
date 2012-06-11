#!/bin/bash

. /etc/rc.conf
. /etc/rc.d/functions

DAEMON=minecraftd
USER=luke
SERVER_LOCATION=~/.minecraft/minecraft_server.jar
SERVER_NAME=`echo $SERVER_LOCATION | sed 's/.*\///'`
MEMORY_START=1G
MEMORY_MAX=1G
BACKUP_DIR=~/.minecraft/backups
MAX_BACKUPS=5
WORLD_NAME=world
WORLD_DIR=$SERVER_LOCATION/$WORLD_NAME

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
    su -c "$1" $USER
    return $?
}


function server_running() {
    running=`run_as_user "tmux list-sessions | grep $DAEMON"`
    if [[ running != '' ]]; then
        return 1
    else
        return 0
    fi
}

function start_server() {
    run_command="java -Xms$MEMORY_START -Xmx$MEMORY_MAX -jar $SERVER_LOCATION nogui"
    run_as_user "tmux new-session -d -s $DAEMON $run_command"
    return $?
}

function send_command() {
    if server_running; then
        run_as_user "tmux send-keys -t $DAEMON:0.0 \"$1\""
        run_as_user "tmux send-keys -t $DAEMON:0.0 \"Enter\""
        return 1
    else
        return 0
    fi
}

function stop_server() {
    send_command "stop"
    return $?
}

#allows for tilde prefix use in directories

SERVER_LOCATION=`echo $SERVER_LOCATION | sed "s/~/~$USER/"`
BACKUP_DIR=`echo $BACKUP_DIR | sed "s/~/~$USER/"`
WORLD_DIR=`echo $WORLD_DIR | sed "s/~/~$USER/"`


case $1 in
    start)
        stat_busy "Starting $DAEMON"
        if server_running; then
            stat_fail
            exit 1
        else
            if start_server; then
                stat_done
            else
                stat_fail
                exit 1
            fi
        fi
        ;;
    stop)
        stat_busy "Stopping $DAEMON"
        if stop_server; then
            stat_done
        else
            stat_fail
            exit 1
        fi
        ;;
    restart)
        stat_busy "Stopping $DAEMON"
        if stop_server; then
            stat_done
        else
            stat_fail
            exit 1
        fi
        if start_server; then
            stat_done
        else
            stat_fail
            exit 1
        fi
        ;;
    backup)
        stat_busy "Backing Up World"
        num_backups=`ls $BACKUP_DIR | wc -l`
        if [[ $num_backups > $MAX_BACKUPS ]]; then
            ls -t $BACKUP_DIR | head -n 1 | xargs rm # is xargs really needed?
        fi
        if [[ ! `send_command "save-all"` ]]; then
            stat_fail
            exit 1
        fi
        cp $WORLD_DIR $BACKUP_DIR/`date +%F-%H-%M-%S.backup.d`
        stat_done
        ;;
    send)
        stat_busy "Sending command"
        if send_command $2; then
            stat_done
        else
            stat_fail
            exit 1
        fi
        ;;
esac
