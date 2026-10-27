#!/bin/sh
LOCK=/var/lock/d3bol-split.lock
T=5
[ "$(grep -c ^processor /proc/cpuinfo)" -le 2 ] && T=10
while :; do
if lock -n $LOCK 2>/dev/null; then
/usr/sbin/d3bol-split tick >/dev/null 2>&1
lock -u $LOCK
fi
sleep $T
done
