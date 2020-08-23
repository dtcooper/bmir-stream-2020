#!/bin/bash

cd "$(dirname "$0")"

dotenv () {
  set -a
  source "$1"
  set +a
}

if [ "$(uname -s)" = 'Darwin' ]; then
    USE_DOCKER=1
fi

if [ "$USE_DOCKER" -a ! -f /.dockerenv ]; then
    CONTAINER=bmir-harbor

    if echo "$@" | fgrep -q -- '--build' && shift \
            || [ -z "$(docker images -q "$CONTAINER" 2> /dev/null)" ]; then
        docker build -t "$CONTAINER" .
    fi

    # --cap-add=SYS_ADMIN for Chrome
    docker run --cap-add=SYS_ADMIN --init --rm -it -v "$PWD:/mnt" \
        -p 80:80 -p 1234:1234 -p 5900:5900 -p 8000:8000 -p 8001:8001 "$CONTAINER" $@
else
    dotenv env.vars.default

    if [ "$ENVFILE" ]; then
        dotenv "$ENVFILE"
    elif [ -f env.vars ]; then
        dotenv env.vars
    fi

    SCRIPT="$1"
    if [ "$SCRIPT" ]; then
        shift 1
    else
        SCRIPT=harbor.liq
    fi

    liquidsoap "$SCRIPT" -- $@
fi
