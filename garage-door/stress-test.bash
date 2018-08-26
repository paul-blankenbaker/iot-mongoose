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
declare urlStatus="${urlMain}Rpc/Get.Status";

declare -i mainOk=0;
declare -i statusOk=0;
declare -i openOk=0;
declare -i openReq=0;
declare -i lastRep=$(date +"%s");
declare -i freeRamMin=-1;
declare curlOpts="--silent --connect-timeout 2.0";
declare -i upTime="";

echo "Starting request loop of: ${urlMain}";

getJson() {
  declare url="${1}";
  declare json="$(curl ${curlOpts} "${url}" 2> /dev/null)";
  if ((PIPESTATUS[0] != 0)); then
    echo "[ERROR] got: ${json}";
    return 1;
  fi
    
  declare -i freeRam="$(echo "${json}" | jq .freeRam)";
  if ((freeRam > 0)) && ( ((freeRamMin == -1)) || ((freeRam < freeRamMin)) ); then
    freeRamMin=${freeRam};
  elif ((freeRam == 0)); then
    echo "[ERROR] bad JSON: ${json}";
    return 1;
  fi
  upTime="$(echo "${json}" | jq '.upTime | floor')";
  return 0;
}

for ((i=0; i < 100000; i++)); do
  # Request main page
  curl ${curlOpts} "${urlMain}" > /dev/null && mainOk=$((mainOk + 1));
  ((openFreq >= 0)) && getJson "${urlStatus}" && statusOk=$((statusOk + 1));
  
  # If enabled and cycle count is appropriate, trigger action
  if ((openFreq > 0)) && (((i % openFreq) == 0)); then
    openReq=$((openReq + 1));
    getJson "${urlOpen}" && openOk=$((openOk + 1));
  fi

  # Periodically dump a report of how we are doing
  declare -i now=$(date +"%s");
  if (((now - lastRep) >= 10)); then
    lastRep=${now};
    if ((openFreq >= 0)); then
      printf "%s  Main:%5d fail:%5d  Status:%5d fail:%5d  Open:%5d fail:%5d  free:%6d  up:%6d\n" \
             "$(date -Iseconds)" \
             $((mainOk)) $((i + 1 - mainOk)) \
             $((statusOk)) $((i + 1 - statusOk)) \
             $((openOk)) $((openReq - openOk)) \
             $((freeRamMin)) "${upTime}";
    else
      printf "%s  Main:%5d fail:%5d\n" \
             "$(date -Iseconds)" \
             $((mainOk)) $((i + 1 - mainOk));
    fi
  fi
  sleep ${sleepSecs};
done
