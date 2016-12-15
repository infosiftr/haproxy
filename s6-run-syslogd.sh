#!/bin/bash
set -e

# -n       Run in foreground
# -O FILE  Log to FILE (default: /var/log/messages, stdout if -)
# -S       Smaller output

exec syslogd -n -O /dev/stdout -S
