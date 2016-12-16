#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- haproxy "$@"
fi

if [ "$1" = 'haproxy' ]; then
	shift # "haproxy"

	if [ -z "$HAPROXY_NO_SYSLOG" ] && [ ! -e /dev/log ]; then
		mkdir -p /docker-s6/haproxy/.args
		num=0
		for arg; do
			echo "$arg" > "/docker-s6/haproxy/.args/$(( num++ ))"
		done
		set -- s6-svscan -s /docker-s6
	else
		rm -rf /docker-s6/haproxy/.args
		set -- /docker-s6/haproxy/run "$@"
	fi
fi

exec "$@"
