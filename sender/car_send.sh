#!/bin/bash
# RUN ON THE SENDER (car). srtla_send bonds the encoder's SRT over the uplinks in
# bind_ips.txt and ships it via SRTLA-over-IPv6 to the home receiver.
#
# Your encoder must send SRT to:  srt://127.0.0.1:7000?streamid=publish/live/bond
#
RECEIVER_IPV6="${RECEIVER_IPV6:-YOUR_RECEIVER_IPV6}"   # host running srt_server (irl-srt-server)
SRTLA_PORT="${SRTLA_PORT:-4002}"
LOCAL_SRT_PORT="${LOCAL_SRT_PORT:-7000}"
IPS="$(dirname "$0")/bind_ips.txt"
SRTLA_SEND="${SRTLA_SEND:-srtla_send}"                 # path to built srtla_send

exec "$SRTLA_SEND" "$LOCAL_SRT_PORT" "$RECEIVER_IPV6" "$SRTLA_PORT" "$IPS"
