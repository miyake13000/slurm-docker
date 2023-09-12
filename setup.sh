#!/bin/bash

function print_usage(){
    cat <<_EOT_
setup.sh

Usage:
    setup.sh SubCommand

Description:
    Setup slurmd and slurmctld container
_EOT_
}

function main(){
    cd "$(dirname "$0")" || exit 1

    print_usage

    docker build -t slurm:$(git rev-parse HEAD | head -c 10) .
    if [ ! -e munge.key ]; then
        cat /dev/urandom | fold -w 50 | head -n 1 > munge.key
    fi
}

main "$@"
