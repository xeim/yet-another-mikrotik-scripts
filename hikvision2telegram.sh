#!/bin/sh

# get picture from hikvision camera
CAMERA="ip.ip.ip.ip"
USER="some_user"
PASS="some_pass"
PIC=`tempfile -p campic`
curl \
    --digest --user $USER:$PASS \
    --output $PIC \
    --silent \
    http://$CAMERA/Streaming/channels/101/picture

# send picture to Telegram chat
BOT="botNNNNNNNNN:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
CHAT="NNNNNNNNN"
curl \
    --request POST \
    --form chat_id=$CHAT \
    --form photo=@$PIC \
    --output /dev/null \
    --silent \
    https://api.telegram.org/$BOT/sendPhoto

# remove picture
rm $PIC
