#!/bin/bash
#
# This wrapper should be usefull for people who want to run a postscript with
# multiple arguments.  Currently ddclient has a feature which doesn't allow
# multiple arguments.
# This example has been written to be able to update multiple domains with
# multiple login.  It expects a /etc/ddclient/ddclient-domain2.conf with the
# configuration of the extra domain

# the second domain who has to be updated
: ${SECONDCONFIG:=/etc/ddclient/ddclient-domain2.conf}
# ddclient adds the new IP as argument
IP=$1

ddclient -ip ${IP} -file ${SECONDCONFIG} -daemon 0 
