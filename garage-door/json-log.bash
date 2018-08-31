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
#  id=jalapeno; ./json-log.bash ${id} 10.8.68.2 60 | tee ~/Downloads/${id}.json

declare id="${1}";
declare ip="${2}";
declare -i secsBetween=${3:-60};

show_usage() {
  echo -e "
Usage:

  $(basename $0) ID IP [SECS]

Where:

  ID   - ID to include in each JSON output record.
  IP   - IP address or host name to get JSON status from.
  SECS - Number of seconds to wait between requests (defaults to 60).

Example:

  id=jalapeno; ./json-log.bash ${id} 10.8.68.2 60 | tee ~/Downloads/${id}.json

";
}

if [ "${2}" == "" ]; then
  show_usage;
  exit 1;
fi

while true; do
  curl -s "http://${ip}/Rpc/Get.Status" | \
    jq -c --arg dt "$(date --iso-8601=seconds)" --arg id "${id}" '. + {timestamp: $dt, id: $id}';
  sleep ${secsBetween};
done

