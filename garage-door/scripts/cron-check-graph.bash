#!/bin/bash
#
#  Intended to be run as a cronjob (maybe once an hour)
#
#  1. Verifies loggers are running, starts if not.
#  2. Generates SVG charts
#
#  You can either edit the variables at the start of this script
#  or create a ${HOME}/.local/etc/cron-check-graph.conf configuration
#  file that overrides them.
#
#  To install:
#
#  1. Copy all of the scripts in this directory to a directory (~/.local/bin)
#
#  2. Create a ~/.local/etc/cron-check-graph.conf file to set the
#     sensors, svgDir and logDir (copy variables below to config file).
#
#  3. Run the script once to start up the loggers (pgrep json-log.bash to find them).
#
#  4. Add a cronjob (maybe once an hour) to verify loggers are running
#     and produce CSV/SVG files from logged data. Something like:
#
#     7 * * * * $HOME/.local/bin/cron-check-graph.bash &>/dev/null

declare -a sensors=(
  bedroom 10.8.68.250
  garage 10.8.68.251
);

declare svgDir="/var/www/html/sensor-reports";
declare logDir="${svgDir}/data";

declare -i tempMin=55;
declare -i tempMax=85;
declare -i secsBetween=60;

#
# You should not need to change below here
#

declare confFile="${HOME}/.local/etc/cron-check-graph.conf";

if [ -f "${confFile}" ] ;then
  source "${confFile}";
fi

declare cmdDir="$(dirname "${0}")";

for d in "${logDir}" "${svgDir}"; do
  if [ ! -w "${d}" ]; then
    echo "***ERROR*** Unable to write to directory ${d}";
    break;
  fi
done

check_command() {
  declare vName="${1}";
  declare name="${2}";
  declare cmd="${cmdDir}/${name}";
  if [ ! -x "${cmd}" ]; then
    cmd="$(/usr/bin/which ${name} 2>/dev/null)";
  fi
  
  if [ -x "${cmd}" ]; then
    eval "declare -g ${vName}=${cmd}";
    return 0;
  fi
  
  echo "***ERROR*** ${name} command not found, terminating";
  exit 1;
}

check_command __basename basename;
check_command __curl curl;
check_command __date date;
check_command __dirname dirname;
check_command __gnuplot gnuplot;
check_command __install install;
check_command __jq jq;
check_command __json_log json-log.bash;
check_command __ln ln;
check_command __log_to_csv log-to-csv.js;
check_command __log_to_svg log-to-svg.bash;
check_command __node node;
check_command __pgrep pgrep;
check_command __rm rm;
check_command __sleep sleep;

get_sensor_pid() {
  declare name="${1}";
  ${__pgrep} -f "${__json-log.bash} ${name}";
}

check_sensor() {
  declare name="${1}";
  declare ip="${2}";
  declare pid;
  declare running=true;
  
  if ! get_sensor_pid ${name} &>/dev/null; then
    echo "Warning: ${name} logger not running, attempting to start";
    ${__json_log} ${name} ${ip} ${secsBetween} ${logDir} &>/dev/null & disown;
    ${__sleep} 3;
    if ! get_sensor_pid ${name} &>/dev/null; then
      running=false;
      echo "***ERROR***: ${name} logger FAILED to start";
    fi
  fi

  declare date;
  declare dateFmt="%Y%m%d";

  for dateArg in "--date=yesterday" "--date=today"; do
    declare date="$(${__date} ${dateArg} +"${dateFmt}")";
    declare logFile="${logDir}/${name}-${date}.log";
    if [ -f "${logFile}" ]; then
      declare nameDir="${svgDir}/${name}";
      ${__log_to_svg} "${logFile}" ${name} ${tempMin} ${tempMax} ${date} "${nameDir}";
      ${__ln} "${nameDir}/${name}.svg" "${nameDir}/${name}-${date}.svg";
      ${__ln} "${nameDir}/${name}.csv" "${nameDir}/${name}-${date}.csv";
    fi
  done
}

check_sensors() {
  while true; do
    declare name="${1}";
    shift;
    declare ip="${1}";
    shift;
    if [ "${ip}" == "" ]; then
      break;
    fi
    check_sensor "${name}" "${ip}";
  done
}

check_sensors "${sensors[@]}";
