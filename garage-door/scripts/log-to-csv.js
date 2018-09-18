#!/usr/bin/node

/*
 * Reads JSON objects line by line created by json-log.bash and writes
 * out a CSV file having time, temperature and humidity columns.
 *
 * Example:
 *
 *    cat $HOME/log/enviro/queso-20180918.log | \
 *       ./log-to-csv.js >| $HOME/log/enviro/queso-20180918.csv
 */

const readline = require('readline');
const fs = require('fs');
const process = require('process');

console.log("Time,TempF,Humidity");

const rl = readline.createInterface({
  input: process.stdin, /* fs.createReadStream(process.stdin), */
  crlfDelay: Infinity
});
 
rl.on('line', (line) => {
  let record = JSON.parse(line);
  let tempF = record["tempF"].toFixed(1);
  let timestamp = record["timestamp"];
  let humidity = record["humidity"].toFixed(1);
  console.log(`${timestamp},${tempF},${humidity}`);
});
