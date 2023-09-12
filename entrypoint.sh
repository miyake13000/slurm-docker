#!/bin/bash

if ! sudo -u munge -g munge /usr/sbin/munged; then
    echo "Failed to invoke munge"
    exit 1
fi
/usr/local/sbin/slurmctld -D > /home/slurm/workdir/log/slurmctld.log 2>&1 &
/usr/local/sbin/slurmd -D > /home/slurm/workdir/log/slurmd.log 2>&1 &
exec bash
