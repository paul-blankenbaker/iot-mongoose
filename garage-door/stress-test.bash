#!/bin/bash
#
#   Test script to repeatedly make web requests to the embedded device
#   to make sure it behaves/recovers reasonably in a bad situation.

declare ip="${1}";
declare sleepSecs="${2:-0.1}";
declare -i openFreq="${3:-0}";

if [ "${ip}" == "" ] || [ "${ip}" == "-h" ] || [ "${ip}" == "--help" ]; then
  echo -e "
Usage:

  ${0} IP_ADDRESS|-h|--help [SLEEP [OPEN_FREQ]]

Where:

  IP_ADDRESS
    IPv4 address or host name of relay device on network (use -h or
    --help to show this help).

  SLEEP
    Number of seconds between each request (default is 0.1 seconds).

  OPEN_FREQ

    Frequency (how often) a 'open the door' request should be
    made after requesting the main page (0 disables and is the
    default, 1 means after every main page request, 10 means after
    every 10 page requests, and so on).
";
  exit;
fi

declare urlMain="http://${ip}/";
declare urlOpen="${urlMain}Rpc/Press.Button";

declare -i mainOk=0;
declare -i openOk=0;
declare -i openReq=0;
declare -i lastRep=$(date +"%s");
declare curlOpts="--silent --connect-timeout 2.0";

echo "Starting request loop of: ${urlMain}";

for ((i=0; i < 100000; i++)); do
  # Request main page
  curl ${curlOpts} "${urlMain}" > /dev/null && mainOk=$((mainOk + 1));

  # If enabled and cycle count is appropriate, trigger action
  if ((openFreq > 0)) && (((i % openFreq) == 0)); then
    openReq=$((openReq + 1));
    curl ${curlOpts} "${urlOpen}" > /dev/null && openOk=$((openOk + 1));
  fi

  # Periodically dump a report of how we are doing
  declare -i now=$(date +"%s");
  if (((now - lastRep) >= 10)); then
    lastRep=${now};
    printf "%s  Main ok:%5d  fail:%5d  Open ok:%5d  fail:%5d\n" \
           "$(date -Iseconds)" $((mainOk)) $((i + 1 - mainOk)) \
           $((openOk)) $((openReq - openOk));
  fi
  sleep ${sleepSecs};
done
