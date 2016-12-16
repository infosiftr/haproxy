#!/bin/bash
set -e

name="$(basename "$0")"
dir="$(readlink -f "$(dirname "$0")")"
case "$dir/$name" in
	*/SIGHUP)
		exec s6-svc -h '/docker-s6/haproxy'
		;;

	*/SIGUSR1)
		exec s6-svc -1 '/docker-s6/haproxy'
		;;

	*/SIGUSR2)
		exec s6-svc -2 '/docker-s6/haproxy'
		;;

	*/SIGINT)
		for svc in /docker-s6/*; do
			if s6-svstat "$svc" &> /dev/null; then
				s6-svc -O "$svc"
				s6-svc -i "$svc"
				s6-svc -wd "$svc"
			fi
		done
		exec s6-svscanctl -q '/docker-s6'
		;;

	*/haproxy/finish)
		exitCode="$1"
		if [ "$exitCode" = '256' ]; then
			# killed by signal
			signal="$2"
			# http://www.tldp.org/LDP/abs/html/exitcodes.html
			# "128+n" = Fatal error signal "n"
			exitCode="$(( 128 + signal ))"
		fi
		echo "$exitCode" > '/docker-s6/haproxy/.exit-code'
		exec s6-svscanctl -q '/docker-s6'
		;;

	*/SIGTERM)
		exec s6-svscanctl -q '/docker-s6'
		;;

	*/finish)
		if [ -e '/docker-s6/haproxy/.exit-code' ]; then
			exit "$(< '/docker-s6/haproxy/.exit-code')"
		fi
		# TODO does "0" really make sense here?  this is kind of an exceptional case
		exit 0
		;;

	*)
		echo >&2 'unknown command: "'"$name"'"'
		;;
esac
