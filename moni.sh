#!/bin/bash

ACCESS_KEY=""
RECIPIENTS=""
ORIGINATOR=""
MESSAGE=""

SLEEP_TIME_SECONDS=300
MAX_DELTA_SECONDS=1200

ts_last_message=0

function read_config() {
  log "Reading configuration at $1"
  configuration_path=$1 
  ACCESS_KEY=`cat $configuration_path | jq ".ACCESS_KEY"`
  RECIPIENTS=`cat $configuration_path | jq ".RECIPIENTS"`
  ORIGINATOR=`cat $configuration_path | jq ".ORIGINATOR"`
  MESSAGE=`cat $configuration_path | jq ".MESSAGE"`
}

function get_date() {
  echo "$(date +%d-%m-%Y" "%H:%M:%S)"
}

function log() {
  msg=$1
  echo "[`get_date`] $msg" | tee -a monish.log
}

function messagebird_send_sms() {
  ts=`date +%s`
  delta=`expr $ts - $ts_last_message`
  log "delta=$delta"
  if [[ "$delta" -gt "$MAX_DELTA_SECONDS" ]]; then
    resp=`curl --silent -X POST https://rest.messagebird.com/messages \
      -H "Authorization: AccessKey $ACCESS_KEY" \
      -d "recipients=$RECIPIENTS" \
      -d "originator=$ORIGINATOR" \
      -d "body=$MESSAGE"`
    ts_last_message=`date +%s`

    errors=`echo $resp | jq -c .errors`
    if [[ $errors == "null" ]]; then
      href=`echo $resp | jq .href`
      log "Request to messagebird succeeded! $href"
    else
      log "Request to messagebird failed! $resp"
    fi
  else
    log "$delta seconds from last message, postponing alert..."
    sleep $SLEEP_TIME_SECONDS
  fi
}

function main() {
  read_config "./config.json"
  regexp=$1
  if [ -p /dev/stdin ]; then
    while IFS= read line; do
      match=`echo ${line} | egrep $regexp`
      if [[ -n $match ]]; then
        log "Match found! $match"
        messagebird_send_sms 
      fi
    done
  else
    echo "usage: "
    echo "echo \"I bet you ain't match this!\" | ./moni.sh \"*atch\""
  fi
}

main "$1"
