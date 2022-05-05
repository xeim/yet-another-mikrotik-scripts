#!/bin/sh

CAMERA=rtsp://url
DURATION=1801
SAVE=33d

REMOTE=yandex:/rec
BASE=`date +%Y`/`date +%Y-%m`/`date +%F`
RECORD=/tmp/`date +%H%M_%m%d`

ffmpeg -t $DURATION -loglevel error -i $CAMERA -vcodec copy $RECORD.mp4
mv $RECORD.mp4 $RECORD
rclone move $RECORD $REMOTE/$BASE --create-empty-src-dirs

rclone --min-age $SAVE delete $REMOTE --rmdirs
