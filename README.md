# PowerDNS Helper Scripts

## Intro
Helper scripts for PowerDNS 4, which interact via the API.

## Features
- Apply rDNS template to a specified IPv4 subnet

## Instructions

### Generic Instructions
- Clone or download repository to your computer
- Rename pdns.conf.example to pdns.conf
- Fill in pdns.conf with your PowerDNS API URL (protocol, host and port only)
- Fill in pdns.conf with your API key
- Make sure you have whitelisted the IP you will be running scripts from for API use on the PowerDNS server

### Apply rDNS Template Instructions
- Complete generic instructions
- Create a reverse zone in PowerDNS for the subnet (/24 or smaller at a time)  you will be applying a template to (ie: 30.168.192.in-addr.arpa.)
- Fill in pdns.conf with the PowerDNS Zone ID you just created. (Include the . at the end)
- Enter the domain you wish to point your generic rDNS records to. (ie. static.host.com)
  - Using the above example your resulting records will look like "128-30-168-192.static.host.com"
- Fill in pdns.conf with the /24 subnet which you will be applying the template to
- Open up a terminal within this directory
- Run the following command: ```$ ./apply-rdns-template.sh -o``` (You must add a flag to the script as confirmation. Currently the only options are "-h/--help" and "-o/--overwrite". Please note, "-o" will overwrite any existing data you have in your zone's PTR rrset)
