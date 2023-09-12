#!/bin/bash

#This script only works under below conditions
# 1. Docker is installed

# default value
DEFAULT_COMMAND="" # command which execute in container
                   # using default entrypoint of image, specify ""

# constant value
#IMAGE_NAME=slurm:$(git rev-parse HEAD | head -c 10)
IMAGE_NAME=slurm:HEAD
CONTAINER_NAME=slurm
SCRIPT_NAME=launch.sh

function print_usage(){
    cat <<_EOT_
$SCRIPT_NAME

Usage:
    $SCRIPT_NAME SubCommand

Description:
    start and stop $IMAGE_NAME on container

SubCommands:
    start    start $IMAGE_NAME container
             for more details, run '$SCRIPT_NAME start -h'
    stop     stop $IMAGE_NAME container
             for more details, run '$SCRIPT_NAME stop -h'
    status   show conditions of $IMAGE_NAME container
    restart  restart $IMAGE_NAME container
             for more details, run '$SCRIPT_NAME restart -h'
    help     show this usage
_EOT_
}

function print_start_usage(){
    cat <<_EOT_
Usage:
    $SCRIPT_NAME start [OPTION] [COMMAND]

Description:
    run $IMAGE_NAME container
    if COMMAND is specified, run COMMAND instead of dafault entrypoint

Options:
    -h         help: show this usage
_EOT_
}

function print_stop_usage(){
    cat <<_EOT_
Usage:
    $SCRIPT_NAME stop

Description:
    stop $IMAGE_NAME container
_EOT_
}

function print_restart_usage(){
    cat <<_EOT_
Usage:
    $SCRIPT_NAME restart [CONTAINER]

Description:
    restart $IMAGE_NAME container
_EOT_
}

function main(){
    if ! user_belongs_dockergroup; then
        echo "$(whoami) must belong 'docker' group"
        exit 1
    fi

    cd "$(dirname "$0")" || exit 1

    subcommand=$1
    shift

    case $subcommand in
        start)
            start "$@"
            ;;
        stop)
            stop
            ;;
        status)
            status
            ;;
        restart)
            restart
            ;;
        help)
            print_usage
            ;;
        "")
            print_usage
            ;;
        *)
            echo "Invalid option: '$1'"
            exit 1
            ;;
    esac
    return 0
}

function start(){
    COMMAND=$DEFAULT_COMMAND
    set_start_options "$@"

    if container_is_running $CONTAINER_NAME; then
        echo "$CONTAINER_NAME is already runnning"
        exit 1
    fi

    if ! image_exists; then
        echo "docker image not found: $IMAGE_NAME"
        echo "build container image from Dockerfile"
        exit 1
    fi

    echo "starting $CONTAINER_NAME"
    docker run \
        -it \
        --net=host \
        --rm \
        -v $PWD/slurm.conf:/usr/local/etc/slurm.conf \
        -v $PWD/munge.key:/etc/munge/munge.key \
        -v $PWD:/home/slurm/workdir \
        --name $CONTAINER_NAME \
        --hostname=$(hostname) \
        $IMAGE_NAME $COMMAND
}

function set_start_options(){
    while getopts h OPT; do
        case $OPT in
            h)
                print_start_usage
                exit 0
                ;;
            *)
                echo "Invalid option: $OPT"
                exit 1
                ;;
        esac
    done
    COMMAND=${@:$OPTIND}
}

function stop(){
    if ! container_is_running $CONTAINER_NAME; then
        echo "$CONTAINER_NAME is not running"
        exit 1
    fi

    echo -n "trying to stop $CONTAINER_NAME... "
    docker stop $CONTAINER_NAME > /dev/null && \
        echo "done."
}

function status(){
    if container_is_running $CONTAINER_NAME; then
       echo "$CONTAINER_NAME is running"
    else
       echo "$CONTAINER_NAME is not running"
    fi
}

function restart(){
    if ! container_is_running $CONTAINER_NAME; then
        echo "$CONTAINER_NAME is not running"
        exit 1
    fi

    if [ $(docker inspect --format='{{.Config.AttachStdin}}' $CONTAINER_NAME) == "true" ]; then
        ATTACH_OPTION=a
    else
        ATTACH_OPTION=d
    fi

    stop
    start -p $PORT -$ATTACH_OPTION
}


function user_belongs_dockergroup(){
    if [ $(groups | grep -c -e docker -e root) = 0 ]; then
        return 1
    else
        return 0
    fi
}

function container_is_running(){
    if [ $(docker ps --format "table {{.Names}}" | grep -cx $1) = 0 ]; then
        return 1
    else
        return 0
    fi
}

function image_exists(){
    if [ $(docker images $IMAGE_NAME | wc -l) = 1 ]; then
        return 1
    else
        return 0
    fi
}

main "$@"
