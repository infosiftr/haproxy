#!/bin/bash
set -eo pipefail
shopt -s nullglob

dir="$(dirname "$BASH_SOURCE")"
if [ -d "$dir/.args" ]; then
	set --
	for arg in "$dir/.args/"*; do
		set -- "$@" "$(< "$arg")"
	done
fi
rm -f '/docker-s6/haproxy/.exit-code'

# let's use "haproxy-systemd-wrapper" instead so we can have proper reloadability implemented by upstream
if command -v haproxy-systemd-wrapper &> /dev/null; then
	set -- "$(which haproxy-systemd-wrapper)" -p /run/haproxy.pid "$@"
else
	set -- haproxy "$@"
fi

exec "$@"
