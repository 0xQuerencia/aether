#!/usr/bin/env bash

nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi list 2>/dev/null | \
awk -F: '
{
    ssid=$1; signal=$2; security=$3; inuse=$4
    if (ssid == "") next
    # escape quotes in ssid
    gsub(/"/, "\\\"", ssid)
    gsub(/"/, "\\\"", security)
    locked = (security != "" && security != "--") ? "true" : "false"
    active = (inuse == "*") ? "true" : "false"
    printf "{\"ssid\":\"%s\",\"signal\":%s,\"locked\":%s,\"active\":%s}\n", ssid, signal, locked, active
}' | \

awk '!seen[$0]++' | \
python3 -c "
import sys, json
lines = [l.strip() for l in sys.stdin if l.strip()]
seen = {}
out = []
for l in lines:
    try:
        o = json.loads(l)
        if o['ssid'] not in seen:
            seen[o['ssid']] = True
            out.append(o)
    except: pass
print(json.dumps(out))
"
