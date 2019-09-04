#!/bin/bash
# 
# Scirpt to fetch IP from fritzbox
#
# Contributed by @Rusk85 in request #45
# Script can be used in the configuration by adding
#
#    use=cmd, cmd=/etc/ddclient/get-ip-from-fritzbox
#
# All credits for this one liner go to the author of this blog:
# http://scytale.name/blog/2010/01/fritzbox-wan-ip
# As the author explains its not required to tamper with the provided IP for the FritzBox
# as it always binds to that address for UPnP.
# Disclaimer: It might be necessary to make the script executable

curl -s -H 'Content-Type: text/xml; charset="utf-8"' \
  -H 'SOAPAction: urn:schemas-upnp-org:service:WANIPConnection:1#GetExternalIPAddress' \
  -d '<?xml version="1.0" encoding="utf-8"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"> <s:Body> <u:GetExternalIPAddress xmlns:u="urn:schemas-upnp-org:service:WANIPConnection:1" /></s:Body></s:Envelope>' \
  'http://fritz.box:49000/igdupnp/control/WANIPConn1' | \
  grep -Eo '\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>'
