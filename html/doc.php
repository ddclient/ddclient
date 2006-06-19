<?php
// usage
$text['id'] = "introduction";
$text['title'] = "Introduction";
$text['menu']  = "intro";
$text['body']  = 
	"<p>\n" .
	"This page describes the configuration for ddclient.  If you need\n".
	"anymore info about supported routers or supported protocols, check the\n" .
	"other pages.  Other options are described here.\n" .
	"\n" .
	"<p>Normally you don't need many arguments when starting ddclient.  " .
	"You can run ddclient as &quot;/usr/sbin/ddclient -daemon 300 -syslog&quot; \n" .
	"which should be enough for most configuration.  You can put all the needed\n" .
	"parameters in the configuration file.\n" .
	"</p>\n" .
	"<p>" .
	"\n" .
	"\n" .
	"\n" .
	"\n" .
	"</p>\n" ;
$main[] = $text;

$text['id'] = "usage";
$text['title'] = "Usage";
$text['menu']  = "usage";
$text['body']  = 
	"usage: <code>ddclient [options]</code><BR>\n".
	"options are:<BR>\n".
	"<table>\n".
	"<tr><td>-daemon delay         </td><td> run as a daemon (default: 0).</td></tr>\n".
	"<tr><td>-proxy host           </td><td> use 'host' as the HTTP proxy.</td></tr>\n".
	"<tr><td>-server host          </td><td> update DNS information on 'host' (default: members.dyndns.org).</td></tr>\n".
	"<tr><td>-protocol type        </td><td> update protocol used (default: dyndns2).</td></tr>\n".
	"<tr><td>-file path            </td><td> load configuration information from 'path' (default: /etc/ddclient/ddclient.conf).</td></tr>\n".
	"<tr><td>-cache path           </td><td> record address used in 'path' (default: /etc/ddclient/ddclient.cache).</td></tr>\n".
	"<tr><td>-pid path             </td><td> record process id in 'path'.</td></tr>\n".
	"<tr><td>-use which            </td><td> how the should IP address be obtained. (default: ip). \n" .
	"					More information about the possible use-arguments can be found on \n" .
	"					the supported routers page</tr></td>" .
  	"<tr><td>-ip address           </td><td> set the IP address to 'address'.<td></tr>\n" .

  	"<tr><td>-if interface         </td><td> obtain IP address from 'interface' (default: ppp0).<td></tr>\n" .
  	"<tr><td>-if-skip pattern      </td><td> skip any IP addresses before 'pattern' in the output of ifconfig {if}.<td></tr>\n" .

  	"<tr><td>-web provider|url     </td><td> obtain IP address from provider's IP checking page (default: dyndns).<td></tr>\n" .
  	"<tr><td>-web-skip pattern     </td><td> skip any IP addresses before 'pattern' on the web provider|url.<td></tr>\n" .

  	"<tr><td>-fw address|url       </td><td> obtain IP address from firewall at 'address'.<td></tr>\n" .
  	"<tr><td>-fw-skip pattern      </td><td> skip any IP addresses before 'pattern' on the firewall address|url.<td></tr>\n" .
  	"<tr><td>-fw-login login       </td><td>   use 'login' when getting IP from fw.<td></tr>\n" .
  	"<tr><td>-fw-password secret   </td><td>   use password 'secret' when getting IP from fw.<td></tr>\n" .

  	"<tr><td>-cmd program          </td><td> obtain IP address from by calling {program}.<td></tr>\n" .
  	"<tr><td>-cmd-skip pattern     </td><td> skip any IP addresses before 'pattern' in the output of {cmd}.<td></tr>\n" .

  	"<tr><td>-login user           </td><td> login as 'user'.<td></tr>\n" .
  	"<tr><td>-password secret      </td><td> use password 'secret'.<td></tr>\n" .
  	"<tr><td>-host host            </td><td> update DNS information for 'host'.<td></tr>\n" .
  	"<tr><td>-{no}retry            </td><td> retry failed updates. (default: noretry).</td></tr>\n" .
  	"<tr><td>-{no}force            </td><td> force an update even if the update may be unnecessary (default: noforce).</td></tr>\n" .
  	"<tr><td>-timeout max          </td><td> wait at most 'max' seconds for the host to respond (default: 0).</td></tr>\n" .
  	"<tr><td>-{no}syslog           </td><td> log messages to syslog (default: nosyslog).</td></tr>\n" .
  	"<tr><td>-facility {type}      </td><td> log messages to syslog to facility {type} (default: daemon).</td></tr>\n" .
  	"<tr><td>-priority {pri}       </td><td> log messages to syslog with priority {pri} (default: notice).</td></tr>\n" .
  	"<tr><td>-mail address         </td><td> e-mail messages to {address}.</td></tr>\n" .
  	"<tr><td>-mail-failure address </td><td> e-mail messages for failed updates to {address}.</td></tr>\n" .
  	"<tr><td>-{no}exec             </td><td> do {not} execute; just show what would be done (default: exec).</td></tr>\n" .
  	"<tr><td>-{no}debug            </td><td> print {no} debugging information (default: nodebug).</td></tr>\n" .
  	"<tr><td>-{no}verbose          </td><td> print {no} verbose information (default: noverbose).</td></tr>\n" .
  	"<tr><td>-{no}quiet            </td><td> print {no} messages for unnecessary updates (default: noquiet).</td></tr>\n" .
  	"<tr><td>-help                 </td><td> this message (default: 0).</td></tr>\n" .
  	"<tr><td>-{no}query            </td><td> print {no} ip addresses and exit.</td></tr>\n" .
	"</table>\n" ;

$main[] = $text;
// config
$text['id'] = "config";
$text['title'] = "Configuring ddclient";
$text['menu']  = "config";
$text['body']  = 
	"<p>\n" .
	"The configuration file, ddclient.conf, can be used to define the \n" .
	"default behaviour and operation of ddclient.  The file consists of \n" .
	"sequences of global variable definitions and host definitions. \n" .
	"Since version 3.6.5, ddclient.conf is located by default in \n" .
	"/etc/ddclient/ddclient.conf.  Another location can be forced \n" .
	"by using the -file option" . 
	"</p>\n" .
	"<p>\n" .
	"Global definitions look like: \n" .
  	"name=value [,name=value]* \n" .
	"</p>\n" .
	"<p>\n" .
	"Next example \n" .
	"specifies that ddclient should operate as a daemon, checking the \n" .
	"eth0 interface for an IP address change every 5 minutes and use the \n" .
	"'dyndns2' protocol by default. \n" .
	"<div class=\"code\">\n" .
	"<pre>\n" .
  	"daemon=600                   \n" .
  	"use=if, if=eth0              \n" .
  	"proxy=proxy.myisp.com        \n" .
  	"protocol=dyndns2 \n" .
	"</pre>\n" .
	"</div> ".
	"</p>\n" .
	"<p>Host definitions look like: \n" .
  	"[name=value [,name=value]*]* a.host.domain [,b.host.domain] [login] [password] \n" .
	"</p><p>\n" . 
	"Next example specifies two host definitions.   \n" .
	"The first definition will use the hammernode1 protocol, \n" .
	"my-hn-login and my-hn-password to update the ip-address of \n" .
	"myhost.hn.org and my2ndhost.hn.org. \n" .
	"</p><p>\n" . 
	"The second host definition will use the current default protocol \n" .
	"('dyndns2'), my-login and my-password to update the ip-address of \n" .
	"myhost.dyndns.org and my2ndhost.dyndns.org. \n" .
	"</p><p>\n" . 
	"The order of this sequence is significant because the values of any \n" .
	"global variable definitions are bound to a host definition when the \n" .
	"host definition is encountered. \n" .
	"</p><p>\n" . 
	"<div class=\"code\">\n" .
	"<pre>\n" .
  	"protocol=hammernode1, \ \n" .
  	"login=my-hn-login, password=my-hn-password  myhost.hn.org \n" .
  	"login=my-login, password=my-password  myhost.dyndns.org,my2nd.dyndns.org \n" .
	"</pre>\n" .
	"</div> ".
	"<p>See the sample-ddclient.conf file for further examples. </p>\n" ;

$main[] = $text;
?>
