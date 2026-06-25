#!/bin/bash
# Home-side SRTLA-over-IPv6 receiver (irl-srt-server / srt_server).
# Edit SRT_SERVER to point at your built binary (irl-srt-server/build/bin/srt_server).
SRT_SERVER="${SRT_SERVER:-./srt_server}"
export PATH=/usr/local/bin:$PATH
ldconfig 2>/dev/null
pkill -9 -x srt_server 2>/dev/null
rm -f /tmp/sls/sls.pid
mkdir -p logs /tmp/sls
exec "$SRT_SERVER" -c "$(dirname "$0")/sls.conf"
