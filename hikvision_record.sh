#!/bin/sh

CAMERA="ip.ip.ip.ip"
USER="some_user"
PASS="some_pass"
DURATION=300
SAVE=40

BASE=/srv/rec
ROOT=$BASE/`date +%Y`/`date +%Y-%m`/`date +%F`
mkdir -p $ROOT
RECORD=$ROOT/`date +%H%M_%m%d`.mp4

cvlc \
    rtsp://$USER:$PASS@$CAMERA:554/Streaming/Channels/102 \
    --sout='#transcode{vcodec=mjpg,fps=8,scale=1}:std{access=file,mux=mp4,dst='$RECORD'}' \
    --run-time=$DURATION --stop-time=$DURATION vlc://quit 2>/dev/null

find $BASE/ -type f -mtime +$SAVE -delete
find $BASE/ -type d -empty -delete
