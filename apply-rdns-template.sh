#!/bin/bash
###############################################################
#
# Copyright (c) 2021, Spry Servers, LLC
#
# Licensed under BSD 2-Clause License (Simplified BSD License)
#
# PowerDNS Helper Scripts
#
# Mass Update rDNS
#
################################################################

set -e

# Cleanup any possible tmp files from previous failed or cancelled batches
rm -rf tmp

PTR_TEMPLATE=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
      -u | --nonexisting )    PTR_TEMPLATE=AddNonExistPTR.template.json
      ;;
      -o | --overwrite )      PTR_TEMPLATE=OverwriteAddPTR.template.json
      ;;
      -h | --help | \? )
      echo "Usage:"
      echo ""
      echo "--nonexisting | -u Update only non-existing rDNS records"
      echo "--overwrite   | -o Overwrite entire PTR zone with template records"
      echo "--help        | -h Print this help message"
      exit 0
      ;;
      *) echo "Unknown parameter passed: $1. Pass -h for help."
      exit 1
      ;;
    esac
    shift
  done

if [ -z $PTR_TEMPLATE ];
then
  echo "Please specify PTR update method. Type -h for help"
  exit 1
fi

########### Import config vars ###########
source pdns.conf

###### Create Temporary Directory ########

mkdir tmp
########## Define some functions ##########

gen_ip_list() {
  nmap -n -sL $RDNS_IP_SUBNET | awk '/Nmap scan report/{print $NF}' > tmp/ip-list.txt
}

pdns_payload_generate() {
  source tmp/ip-var.txt
  cat payload-templates/$PTR_TEMPLATE | sed -e 's|ip_arpa|'"$ip_arpa"'|g' -e 's|rdns_entry|'"$rdns_entry"'|g' > tmp/curlPayloadPTRrecord.json
}

pdns_curl() {
    curl -s -S \
         -o /dev/null \
         -w '%{http_code}' \
         -H "X-API-Key: $PDNS_API_KEY" \
         -H "Content-Type: application/json" \
         -d @tmp/curlPayloadPTRrecord.json \
         -X PATCH $PDNS_API_URL/api/v1/servers/localhost/zones/$PDNS_ZONE_ID > /tmp/http-respcode.txt
}

push_payload() {
  iplist="tmp/ip-list.txt"
  ips=$(cat $iplist)
  for ip in $ips
  do
    echo "$ip" | awk -F . '{print "ip_arpa="""$4"."$3"."$2"."$1".in-addr.arpa."""}' > tmp/ip-var.txt
    echo "$ip" | awk -F . '{print "rdns_entry="""$4"-"$3"-"$2"-"$1".""'"$RDNS_DOMAIN"'"""}' >> tmp/ip-var.txt
    pdns_payload_generate
    pdns_curl
    echo ""
    http_code=$(cat /tmp/http-respcode.txt)
    if [[ $http_code -eq 204 ]]; then
      echo "Set rDNS record for IP $ip successfully"
    else
      echo "Error: Response code: $http_code"
      exit 1
    fi
  done
}

############## End functions ##############
############# Generate IP List ############
gen_ip_list
############## Push Payload ###############
push_payload

###### Remove Temporary Directory #########
rm -rf tmp
