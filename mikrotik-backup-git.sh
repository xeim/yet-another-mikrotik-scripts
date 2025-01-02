#!/bin/bash

GITDIR=/srv/git/mikrotik/mikrotik-backup
DIFFFILE=/tmp/mikrotik_diff.txt
MAILTO=somebody@example.com

# get text backups from devices
ssh -p 5022 backup@192.168.219.11 export show-sensitive > $GITDIR/router.rsc
ssh         backup@192.168.219.14 export show-sensitive > $GITDIR/wifi.rsc

# remove date from first line
sed -i "1 s/\# .\+ by/\# by/" $GITDIR/*.rsc

# get config diff in file
git -C $GITDIR diff --unified=1 --no-color | tail -n +3 | grep -v "^@@ " > $DIFFFILE

if [ -s $DIFFFILE ]; then
    # mail diff
    echo "" | s-nail -a $DIFFFILE -s "mikrotik config diff" $MAILTO
    # commit diff
    git -C $GITDIR commit -m "`date --iso-8601`" *.rsc > /dev/null
fi

rm $DIFFFILE
