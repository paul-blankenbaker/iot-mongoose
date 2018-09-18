#!/bin/bash
#
#  Simple test script that grabs the JSON status information from the
#  garage door opener, uses jq to insert a couple of additional fields
#  for identity and time.
#
#  Resulting output can be directed to a JSON log file for later post
#  processing.
#
#  Example Invocation:
#
#  id=jalapeno; ./json-log.bash ${id} 10.8.68.2 60

declare id="${1}";
declare ip="${2}";
declare -i secsBetween=${3:-60};
declare logDir="${4:-${HOME}/log/enviro}";

show_usage() {
  echo -e "
Usage:

  $(basename $0) ID IP [SECS [[DIR]]

Where:

  ID   - ID to include in each JSON output record.
  IP   - IP address or host name to get JSON status from.
  SECS - Number of seconds to wait between requests (defaults to 60).
  DIR  - Directory to write daily files to (defaults to ${HOME}/log/enviro).

Examples:

  ./json-log.bash jalapeno 10.8.68.2 &

  ./json-log.bash queso 10.8.68.3 300 ${HOME}/log/temphumid &

";
}

if [ "${2}" == "" ]; then
  show_usage;
  exit 1;
fi

# require CMD [VAR_NAME [PKG]]
#
#   Lookws for CMD in PATH and standard bin directories, if found sets
#   VAR_NAME to full path of command (VAR_NAME defaults to __${CMD} if
#   omitted). If not found recommends PKG to try installing (PKG
#   defaults to ${CMD} if omitted).

require() {
  declare cmd="${1}";
  declare var="${2:-__${cmd}}";
  declare pkg="${3:-${cmd}}";

  for d in ${PATH//:/ } /bin /usr/bin /sbin /usr/sbin; do
    if [ -x "${d}/${cmd}" ]; then
      eval "${var}=${d}/${cmd}";
      return 0;
    fi
  done
  echo -e "
***ERROR*** Failed to find \"${cmd}\" in PATH or standard directories.

Try: sudo dnf install ${pkg}
 Or: sudo dnf whatprovides ${cmd}
";
  exit 1;
}

# Make sure necessary commands are installed
require curl
require date __date coreutils;
require jq;
require install __install coreutils;
require sleep __sleep coreutils;

# Check/create output directory for log files
if [ ! -d "${logDir}" ] && ! ${__install} -D -d ${logDir}; then
  echo "***ERROR*** Failed to create log directory: ${logDir}";
fi

# Periodically fetch JSON record from device and use jq to insert some
# more information and log to flat file one JSON record per line

declare lastLogFile="";

while true; do
  declare -i now="$(${__date} +%s)";
  declare logFile="${logDir}/${id}-$(${__date} --date=@${now} +"%Y%m%d").log";
  if [ "${logFile}" != "${lastLogFile}" ]; then
    echo "Logging data from ${ip} to: ${logFile}";
    lastLogFile="${logFile}";
  fi
  
  ${__curl} -s "http://${ip}/Rpc/Get.Status" | \
    ${__jq} -c --arg dt "$(${__date} --date=@${now} --iso-8601=seconds)" --arg id "${id}" '. + {timestamp: $dt, id: $id}' >> ${logFile};

  # Pick a sleep time likely to end up on a "nice" boundary
  # for interval (so if multiple sensors are being queried the
  # readings will be done at roughly the same time)
  declare -i nextTime=$((now - (now % secsBetween) + secsBetween));
  declare -i sleepSecs=$((nextTime - now));
  if ((sleepSecs <= 0)); then
    sleepSecs=${secsBetween};
  fi
  ${__sleep} ${sleepSecs};
done
