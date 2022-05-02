#!/bin/sh

CAMERA=url
DURATION=1801
SAVE=22

BASE=yandex:/rec/`date +%Y`/`date +%Y-%m`/`date +%F`
RECORD=/tmp/`date +%H%M_%m%d`

ffmpeg -t $DURATION -loglevel error -i $CAMERA -vcodec copy $RECORD.mp4
mv $RECORD.mp4 $RECORD

rclone move $RECORD $BASE --create-empty-src-dirs
