#!/bin/bash
#
# Converts JSON log file created by log-json.bash to a SVG plot.
#

declare jsonLog="${1}";

if [ ! -f "${jsonLog}" ]; then
  echo -e "
Usage:

  ${0} JSON_LOG

Where:

  JSON_LOG

     Is name of log file (or joined log files) created by json-log.bash.

Examples:

  ${0} ${HOME}/log/enviro/queso-20180918.log
           
";
  exit 1;
fi

declare scriptDir="$(dirname "${0}")";

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

  for d in ${scriptDir} ${execDir} ${PATH//:/ } /bin /usr/bin /sbin /usr/sbin; do
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
require basename __basename coreutils;
require dirname __dirname coreutils;
require date __date coreutils;
require rm __rm coreutils;
require gnuplot;
require log-to-csv.js __log_to_csv;

# Required by supporting scripts - check them now
require jq;
require node __node nodejs;
require install __install coreutils;

declare -i timetNow=$(${__date} +%s);
declare -i timetYesterday=$(( timetNow - (24 * 60 * 60) ));
declare dateStampDef="$(${__date} --date=@${timetYesterday} +"%Y-%m-%d")";

declare name="${2:-$(${__basename} "${jsonLog}" .json)}";
declare tempMin="${3:-55}";
declare tempMax="${4:-85}";
declare dateStamp="${5:-${dateStampDef}}";

declare dataTitle="Temperature/Humidity (${name})";

# Output directory and files to store here on web server
declare outDir="${6:-${HOME}/public_html/temperature}";
declare nameDir="${outDir}/${name}";
declare csvFile="${nameDir}/${name}-${dateStamp}.csv";
declare csvCur="${outDir}/${name}.csv";
declare svgFile="${csvFile//.csv/.svg}";
declare svgCur="${csvCur//.csv/.svg}";

# Remote to post results to
declare remoteDir="data-publisher:public_html";

# ssh key which we can use on BBB to access without providing password
declare sshIdFile="${HOME}/.ssh/id_datalog";

# Create output directory if necessary
[ -d "${nameDir}" ] || mkdir -p "${nameDir}" || exit 1;

echo -e "
$(${__date}): Generating CSV file: ${csvCur}
";

${__log_to_csv} < ${jsonLog} >| ${csvCur} || exit 1;

# Create gnuplot using data file

echo -e "
$(${__date}): Generating SVG file: ${svgCur} via gnuplot
";

${__rm} -f "${svgCur}";

${__gnuplot} <<EOF
set term svg enhanced mouse size 1000,800
set output "${svgCur}";
#reset;
#clear;
set datafile separator ",";
set xdata time;
#set yrange [${tempMin}:${tempMax}];
set timefmt "%Y-%m-%dT%H:%M:%S";
#set timefmt "%s";
set format x "%d %I:%M%p";
#set format x "%I:%M";
set title "${dataTitle}";
set xlabel "Time";
set ylabel "Fahrenheit";
set ytics 5 nomirror;
set y2label "Percent";
set y2tics 10 nomirror;
plot "${csvCur}" using 1:2 with lines title "Tempererature", "${csvCur}" using 1:3 with lines title "Humidity" axes x1y2;
EOF

echo -e "
$(${__date}): Finished
";
exit 0;
