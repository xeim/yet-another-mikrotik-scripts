#!/bin/sh

CAMERA=rtsp://...
DURATION=20
RECORD=`mktemp --dry-run record-XXXXXXXXXX.mp4`
ffmpeg -t $DURATION -loglevel fatal -i $CAMERA -vcodec copy $RECORD


BOT="botNNNNNNNNN:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
CHAT="NNNNNNNNN"
curl \
    --request POST \
    --form chat_id=$CHAT \
    --form video=@$RECORD \
    --form disable_notification=true \
    --output /dev/null \
    --silent \
    https://api.telegram.org/$BOT/sendVideo

rm $RECORD 2>/dev/null
