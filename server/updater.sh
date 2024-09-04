#!/bin/bash

sync_interval=10
pid=-1

while [[ 1 ]] ; do
    curl -L https://raw.githubusercontent.com/mar511n/SnakePro/main/version.txt -o version.txt
    read nv < version.txt
    read cv < cversion.txt

    echo "current version is $cv"
    echo "new version is     $nv"

    if [[ "$cv" != "$nv" ]];
    then
        if ! kill $pid > /dev/null 2>&1; then
            echo "Could not send SIGTERM to process $pid" >&2
        fi
        
        echo "downloading new .pck file..."
        curl -L https://github.com/mar511n/SnakePro/raw/main/executables/SnakePro_server.pck -o SnakePro_server.pck
        echo "updating cversion.txt"
        echo "$nv" > cversion.txt
        echo "restarting the server..."
        ./SnakePro_server.x86_64 > /dev/null 2>&1 &
        pid=$!
        echo "new process id is $pid, waiting for next sync..."
    else
        echo "versions match, current process is $pid, waiting for next sync..."
    fi
    sleep $sync_interval
done
