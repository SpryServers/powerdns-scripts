#!/bin/bash
set -e

########### Import config vars ###########
source pdns.conf

### Cleanup any previous leftover files ###
rm -f ip-list.txt ip-var.txt curlPayloadPTRrecord.json

########## Define some functions ##########
gen_ip_list() {
  nmap -n -sL $RDNS_IP_SUBNET | awk '/Nmap scan report/{print $NF}' > ip-list.txt
}

pdns_payload_generate() {
  cat addPTR.template.json | sed -e 's|ip_arpa|'"$ip_arpa"'|g' -e 's|rdns_entry|'"$rdns_entry"'|g' > curlPayloadPTRrecord.json
}

pdns_curl() {
  curl -H "X-API-Key: $PDNS_API_KEY" \
       -H "Content-Type: application/json" \
       -d @curlPayloadPTRrecord.json \
       -X PATCH $PDNS_API_URL/api/v1/servers/localhost/zones/$PDNS_ZONE_ID
}

push_payload() {
  iplist="ip-list.txt"
  ips=$(cat $iplist)
  for ip in $ips
  do
    echo "$ip" | awk -F . '{print "ip_arpa="""$4"."$3"."$2"."$1".in-addr.arpa."""}' > ip-var.txt
    echo "$ip" | awk -F . '{print "rdns_entry="""$4"-"$3"-"$2"-"$1".""'"$RDNS_DOMAIN"'"""}' >> ip-var.txt
    source ip-var.txt
    $(pdns_payload_generate)
    $(pdns_curl)
  done
}
############## End functions ##############
############# Generate IP List ############
$(gen_ip_list)
############## Push Payload ###############
$(push_payload)
