<?php session_start(); ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<?php
/* Extra ideetjes voor de website
- contents: readme file & stuff
*/
$title="ddclient";

// dynamic stuff
$link['project']  = '<a href="http://sourceforge.net/projects/ddclient/" ' .
			'title="ddclient project page">'.
			'the ddclient project page on sourceforge</a>';
$link['download'] = '<a href="http://sourceforge.net/project/showfiles.php?group_id=116817" ' .
	               	'title="Download page on sourceforge">'.
			'sourceforge</a>'."\n";
$link['developers'] = "<a href=\"http://sourceforge.net/project/memberlist.php?group_id=116817\" ".
			"title=\"link to the ddclient developers\">developers for ddclient on sourceforge</a>";

// Setting debugshit
if (isset($_REQUEST['debug'])) {
	$debug = !($_REQUEST['debug'] == 0);
} else if (isset($_SESSION['debug'])) {
	$debug = $_SESSION['debug'];
} else {
	$debug = 0;
}
$_SESSION['debug'] = $debug;

// pages information; should be in a database

// main
$pages[0]['nr'] = 0;
$pages[0]['title'] = "home";
// documentation 
$pages[1]['nr'] = 1;
$pages[1]['title'] = "usage";

$pages[2]['nr'] = 2;
$pages[2]['title'] = "supported protocols";

$pages[3]['nr'] = 3;
$pages[3]['title'] = "supported routers";


$curpage = isset($_GET['page'])?$_GET['page']:0;
$titleextra = $pages[$curpage]['title'];
$page       = $pages[$curpage]['nr'];

// filling the page; should be in a dbase to
if ($page == 0 ) { 					// home page
// Introduction
$text['id'] = "intro";
$text['title'] = "Introduction";
$text['menu'] = "Introduction";
$text['body'] = 
	"<p>" .
	"Ddclient is a Perl client used to update dynamic DNS entries for accounts " .
	"on Dynamic DNS Network Services' free DNS service. It was origanally " .
	"written by Paul Burry and is now maintaned by ".$link['developers'].". " .
	"It has the capability to update more than only <a href=\"http://dyndns.org\">" .
	"dyndns</a> and it can fetch your WAN-ipaddress on a few different ways.  Check the " .
	"configuration pages to find how to do this." .
	"</p>\n" .
	"<p>\n" .
	"According to <a href=\"http://linux.cudeso.be\">cudeso.be</a>:<BR>" .
	"DDclient is a small but full featured client requiring only Perl " .
	"and no additional modules. It runs under most UNIX OSes and has " .
	"been tested under GNU/Linux and FreeBSD. Supported features " .
	"include: operating as a daemon, manual and automatic updates, " .
	"static and dynamic updates, optimized updates for multiple " .
	"addresses, MX, wildcards, abuse avoidance, retrying failed " .
	"updates, and sending update status to syslog and through e-mail." .
	"</p>";
$main[] = $text;

// install 
$text['id'] = "install";
$text['title'] = "How to install";
$text['menu'] = "Quick Installation";
$text['body'] = 
	"<p>\n
Ddclient doesn't have any automatic installation procedure.  Get the tar-file 
from " . $link['download'] .  " and untar it.  Copy the perl script to your
favorit location (ex. /usr/sbin) and create a /etc/ddclient/ddclient.conf 
configuration file.  
</p><p>
There are a few configuration examples provided which you can copy to 
/etc/ddclient/ddclient.conf and modify. More info about the configuration
can be found on the <a href=\"?page=1\">usage page</a>
</p><p>
A typical configuration like:
<div class=\"code\">
<pre>
#
# /etc/ddclient/ddclient.conf
#
protocol=dyndns2
use=web
login=mylogin
password=mypassword
myhost.dyndns.org
</pre>
</div>
</p>
<p>
You can run ddclient as &quot;/usr/sbin/ddclient -daemon 300 -syslog&quot; 
and put it in your startup scripts. 
</p> \n"; 
$main[] = $text;

// help part
$text['id'] = "help";
$text['title'] = "Documentation and help";
$text['menu'] = "Documentation";
$text['body'] = "
<p>The documentation about the configuration has been splitted in three
sections.  The <a href=\"?page=1\">usage page</a> describes the most parts
of the configuration while the <a href=\"?page=2\">supported protocols</a> 
page describes the protocol-specific options.  If you want to know how 
to use ddclient with your router, check the 
<a href=\"?page=3\">supported routers</a>.
</p><p>
Debugging ddclient looks pretty hard but it isn't.  First try to put \n".
	"as less as necessary in your configuration. Try to run \n".
	"`./ddclient -daemon=0 -noquiet -debug` and check the result. \n" .
	"Try to add the features you need and check it again.  Once \n".
	"you're happy with the result, run it as a daemon.\n" .
	"<p>\n" .
	"<p>\n" .
	"If this doesn't work for you, \n".
	"there are a few places where you can look for help.  If you need \n".
	"any help in configuring ddclient, you could try ddclient --help. \n".
	"It should give you all the possible configuration options so.\n" .
	"</p>\n".
	"<p>\n" .
	"If you think your configuration is correct, but ddclient doesn't \n" .
	"work as you expected, you can enable debug and verbose messages \n" .
	"by running ddclient -daemon=0 -debug -verbose -noquiet.\n".
	"</p>\n".
	"<p>\n" .
	"If this doesn't help for you, maybe \n" .
	"<a href=\"http://sourceforge.net/forum/forum.php?forum_id=399428\">\n" .
	"the help forum on sourceforge</a> can bring some help.\n" .
	"I know the manual is not very clear, you have to read the example " .
	"configurations included in the tar-file or you can run " .
	"&quot;ddclient --help&quot; to get more help.  " .
	"If you lucky you can find some help on #ddclient on irc.freenode.net" .
	"</p>\n" .
	"<p>
More info about the ddclient project can be found on " .
	$link['project'] .
	"</p>";
$main[] = $text;


} else if ($page == 1) {				 // documentation
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

} else if ($page == 2) {				 // supported sevices
	$text['id'] = "intro";
	$text['title'] = "Introduction about the supported protocols";
	$text['menu']  = "Introduction";
	$text['body']  = "<p>".
		"This is an incomplete list of the services supported by ddclient.  ".
		"If your favoriet dynamic dns provider isn't here, check the result " . 
		"ddclient --help with the most recent version of ddclient.  If it's " .
		"there, check the patches section on sf.net and if it's really not " .
		"supported by ddclient you can try to modify ddclient yourself. " .
		"</p>" .
		"<p>
Since ddclient version 3.7, ddclient also supports https to update
your favorit provider. Use the ssl=yes option to use this feature.
		</p>";

	$main[] = $text;
// dnspark
$text['id'] = "dnspark";
$text['title'] = "dnspark protocol";
$text['menu']  = "dnspark";
$text['body']  = 
	"<p>The 'dnspark' protocol is used by DNS service offered by www.dnspark.com.</p>\n ".
	"<p>Configuration variables applicable to the 'easydns' protocol are:\n ".
	"<table>\n" .
  "<tr><td>protocol=dnspark             </td><td> </td></tr>\n".
  "<tr><td>server=fqdn.of.service       </td><td> defaults to www.dnspark.com</td></tr>\n".
  "<tr><td>backupmx=no|yes              </td><td> indicates that DNSPark should be the secondary MX " .
						 "for this domain or host.</td></tr>\n".
  "<tr><td>mx=any.host.domain           </td><td> a host MX'ing for this host or domain.</td></tr>\n".
  "<tr><td>mxpri=priority               </td><td> MX priority.</td></tr>\n".
  "<tr><td>login=service-login          </td><td> login name and password  registered with the service</td></tr>\n".
  "<tr><td>password=service-password    </td><td></td></tr>\n".
  "<tr><td>fully.qualified.host         </td><td> the host registered with the service.</td></tr>\n".
	"</table>\n" .

"<p>Example ddclient.conf file entries:</p>\n" .
	"<div class=\"code\">\n" .
	"<pre>\n" .
  	"## single host update\n" .
  	"protocol=dnspark,                                         \\\n" .
  	"login=my-dnspark.com-login,                               \\\n" .
  	"password=my-dnspark.com-password                          \\\n" .
  	"myhost.dnspark.com \n" .
	"\n" .
  	"## multiple host update with wildcard'ing mx, and backupmx\n" .
  	"protocol=dnspark,                                         \\\n" .
  	"login=my-dnspark.com-login,                               \\\n" .
  	"password=my-dnspark.com-password,                         \\\n" .
  	"mx=a.host.willing.to.mx.for.me,                           \\\n" .
  	"mxpri=10,                                                 \\\n" .
  	"my-toplevel-domain.com,my-other-domain.com\n" .
	"\n" .
  	"## multiple host update to the custom DNS service\n" .
  	"protocol=dnspark,                                         \\\n" .
  	"login=my-dnspark.com-login,                               \\\n" .
  	"password=my-dnspark.com-password                          \\\n" .
  	"my-toplevel-domain.com,my-other-domain.com\n" .
	"<pre>\n" . 
	"</div>\n" ;

$main[] = $text;
// dslreports
$text['id'] = "dslreports";
$text['title'] = "dslreports";
$text['menu']  = "dslreports";
$text['body']  = 
"<p>The 'dslreports1' protocol is used by a free DSL monitoring service\n" .
"offered by www.dslreports.com.</p>\n" .

"<p>Configuration variables applicable to the 'dslreports1' protocol are:</p>" .
"<table>\n" .
  "<tr><td>protocol=dslreports1         </td><td> </td></tr>" .
  "<tr><td>server=fqdn.of.service       </td><td> defaults to www.dslreports.com</td></tr>" .
  "<tr><td>login=service-login          </td><td> login name and password  registered with the service</td></tr>" .
  "<tr><td>password=service-password    </td><td></td></tr>" .
  "<tr><td>unique-number                </td><td> the host registered with the service.</td></tr>" .
"<table>\n" .

"<p>Example ddclient.conf file entries:</p>" .
	"<div class=\"code\">\n" .
	"<pre>\n" .
  "## single host update\n" .
  "protocol=dslreports1,                                     \\\n" .
  "server=www.dslreports.com,                                \\\n" .
  "login=my-dslreports-login,                                \\\n" .
  "password=my-dslreports-password                           \\\n" .
  "123456\n" .
"</div>\n" .
"</pre>\n" .

"<p>Note: DSL Reports uses a unique number as the host name.  This number\n" .
"can be found on the Monitor Control web page.</p>\n" ;
$main[] = $text;
$text['id'] = "dyndns1";
$text['title'] = "dyndns1";
$text['menu']  = "dyndns1";
$text['body']  = 
"<p>The 'dyndns1' protocol is a deprecated protocol used by the free dynamic \n".
"DNS service offered by www.dyndns.org. The 'dyndns2' should be used to \n".
"update the www.dyndns.org service.  However, other services are also  \n".
"using this protocol so support is still provided by ddclient. </p>\n".
" \n".
"Configuration variables applicable to the 'dyndns1' protocol are: \n".
"<table>\n" .
  "<tr><td>protocol=dyndns1             </td><td> </td></tr>\n" .
  "<tr><td>server=fqdn.of.service       </td><td> defaults to members.dyndns.org</td></tr>\n" .
  "<tr><td>backupmx=no|yes              </td><td> indicates that this host is the primary MX for the domain.</td></tr>\n" .
  "<tr><td>mx=any.host.domain           </td><td> a host MX'ing for this host definition.</td></tr>\n" .
  "<tr><td>wildcard=no|yes              </td><td> add a DNS wildcard CNAME record that points to {host}</td></tr>\n" .
  "<tr><td>login=service-login          </td><td> login name and password  registered with the service</td></tr>\n" .
  "<tr><td>password=service-password    </td><td></td></tr>\n" .
  "<tr><td>fully.qualified.host         </td><td> the host registered with the service.</td></tr>\n" .
"</table>\n" .

"<p>Example ddclient.conf file entries:</p>" .
	"<div class=\"code\">\n" .
	"<pre>\n" .
  "## single host update\n" . 
  "protocol=dyndns1,                                         \\\n" . 
  "login=my-dyndns.org-login,                                \\\n" . 
  "password=my-dyndns.org-password                           \\\n" . 
  "myhost.dyndns.org \n" . 
"\n" . 
  "## multiple host update with wildcard'ing mx, and backupmx\n" . 
  "protocol=dyndns1,                                         \\\n" . 
  "login=my-dyndns.org-login,                                \\\n" . 
  "password=my-dyndns.org-password,                          \\\n" . 
  "mx=a.host.willing.to.mx.for.me,backupmx=yes,wildcard=yes  \\\n" . 
  "myhost.dyndns.org,my2ndhost.dyndns.org \n" . 
  "</div> \n" .
	"</pre>\n" .
	"<p>Note: you only need one of the examples</p>\n";

$main[] = $text;
// dyndns2
$text['id'] = "dyndns2";
$text['title'] = "dyndns2";
$text['menu']  = "dyndns2";
$text['body']  = 
"<p>The 'dyndns2' protocol is a newer low-bandwidth protocol used by a\n" .
"free dynamic DNS service offered by www.dyndns.org.  It supports\n" .
"features of the older 'dyndns1' in addition to others.  [These will be\n" .
"supported in a future version of ddclient.]</p>\n" .
"\n".
"<p>Configuration variables applicable to the 'dyndns2' protocol are:</p>\n" .
"<table>\n".
  "<tr><td>protocol=dyndns2             </td><td> </td></tr>\n" .
  "<tr><td>server=fqdn.of.service       </td><td> defaults to members.dyndns.org</td></tr>\n" .
  "<tr><td>backupmx=no|yes              </td><td> indicates that this host is the primary MX for the domain.</td></tr>\n" .
  "<tr><td>static=no|yes                </td><td> indicates that this host has a static IP address.</td></tr>\n" .
  "<tr><td>custom=no|yes                </td><td> indicates that this host is a 'custom' top-level domain name.</td></tr>\n" .
  "<tr><td>mx=any.host.domain           </td><td> a host MX'ing for this host definition.</td></tr>\n" .
  "<tr><td>wildcard=no|yes              </td><td> add a DNS wildcard CNAME record that points to {host}</td></tr>\n" .
  "<tr><td>login=service-login          </td><td> login name and password  registered with the service</td></tr>\n" .
  "<tr><td>password=service-password    </td><td></td></tr>\n" .
  "<tr><td>fully.qualified.host         </td><td> the host registered with the service.</td></tr>\n" .
"</table>\n" .

"<p>Example ddclient.conf file entries:</p>" . 
	"<div class=\"code\">\n" .
	"<pre>\n" .
  "## single host update\n" .
  "protocol=dyndns2,                                         \\\n" .
  "login=my-dyndns.org-login,                                \\\n" .
  "password=my-dyndns.org-password                           \\\n" .
  "myhost.dyndns.org \n" .
"\n" .
  "## multiple host update with wildcard'ing mx, and backupmx\n" .
  "protocol=dyndns2,                                         \\\n" .
  "login=my-dyndns.org-login,                                \\\n" .
  "password=my-dyndns.org-password,                          \\\n" .
  "mx=a.host.willing.to.mx.for.me,backupmx=yes,wildcard=yes  \\\n" .
  "myhost.dyndns.org,my2ndhost.dyndns.org \n" .
"\n" .
  "## multiple host update to the custom DNS service\n" .
  "protocol=dyndns2,                                         \\\n" .
  "login=my-dyndns.org-login,                                \\\n" .
  "password=my-dyndns.org-password                           \\\n" .
  "my-toplevel-domain.com,my-other-domain.com\n" .
	"</pre>\n" .
	"</div>\n" .
	"<p>Note: you only need one of the examples</p>\n";

$main[] = $text;
// easydns
$text['id'] = "easydns";
$text['title'] = "easydns";
$text['menu']  = "easydns";
$text['body']  = 
"<p>The 'easydns' protocol is used by the for fee DNS service offered \n" .
"by www.easydns.com.</p>\n" .

"<p>Configuration variables applicable to the 'easydns' protocol are:\n".
"<table>\n" .
  "<tr><td>protocol=easydns             </td><td> </td></tr>\n" .
  "<tr><td>server=fqdn.of.service       </td><td> defaults to members.easydns.com</td></tr>\n" .
  "<tr><td>backupmx=no|yes              </td><td> indicates that EasyDNS should be the secondary MX for this domain or host.</td></tr>\n" .
  "<tr><td>mx=any.host.domain           </td><td> a host MX'ing for this host or domain.</td></tr>\n" .
  "<tr><td>wildcard=no|yes              </td><td> add a DNS wildcard CNAME record that points to {host}</td></tr>\n" .
  "<tr><td>login=service-login          </td><td> login name and password  registered with the service</td></tr>\n" .
  "<tr><td>password=service-password    </td><td></td></tr>\n" .
  "<tr><td>fully.qualified.host         </td><td> the host registered with the service.</td></tr>\n" .
  "</table></p>\n" .

"<p>Example ddclient.conf file entries:</p> " .
	"<div class=\"code\">\n" .
	"<pre>\n" .
  "## single host update\n" .
  "protocol=easydns,                                         \\\n" .
  "login=my-easydns.com-login,                               \\\n" .
  "password=my-easydns.com-password                          \\\n" .
  "myhost.easydns.com \n" .
"\n" .
  "## multiple host update with wildcard'ing mx, and backupmx\n" .
  "protocol=easydns,                                         \\\n" .
  "login=my-easydns.com-login,                               \\\n" .
  "password=my-easydns.com-password,                         \\\n" .
  "mx=a.host.willing.to.mx.for.me,                           \\\n" .
  "backupmx=yes,                                             \\\n" .
  "wildcard=yes                                              \\\n" .
  "my-toplevel-domain.com,my-other-domain.com\n" .
"\n" .
  "## multiple host update to the custom DNS service\n" .
  "protocol=easydns,                                         \\\n" .
  "login=my-easydns.com-login,                               \\\n" .
  "password=my-easydns.com-password                          \\\n" .
  "my-toplevel-domain.com,my-other-domain.com\n" .
  "</pre>\n" .
  "</div>\n" .
  "<p></p>";
$main[] = $text;
// hammernode
$text['id'] = "hammernode";
$text['title'] = "hammernode";
$text['menu']  = "hammernode";
$text['body']  = 
"<p>" .
"The 'hammernode1' protocol is the protocol used by the free dynamic \n" .
"DNS service offered by Hammernode at www.hn.org </p>\n" .

"Configuration variables applicable to the 'hammernode1' protocol are: </p>\n" .
"<table>\n" .
  "<tr><td>protocol=hammernode1         </td><td> </td></tr>\n" .
  "<tr><td>server=fqdn.of.service       </td><td> defaults to members.dyndns.org</td></tr>\n" .
  "<tr><td>login=service-login          </td><td> login name and password  registered with the service</td></tr>\n" .
  "<tr><td>password=service-password    </td><td></td></tr>\n" .
  "<tr><td>fully.qualified.host         </td><td> the host registered with the service.</td></tr>\n" .
  "</table>\n" .

"<p>Example ddclient.conf file entries:</p>\n" .
	"<div class=\"code\">\n" .
	"<pre>\n" .
  "## single host update\n" .
  "protocol=hammernode1,                                 \\\n" .
  "login=my-hn.org-login,                                \\\n" .
  "password=my-hn.org-password                           \\\n" .
  "myhost.hn.org \n" .
"\n" .
  "## multiple host update\n" .
  "protocol=hammernode1,                                 \\\n" .
  "login=my-hn.org-login,                                \\\n" .
  "password=my-hn.org-password,                          \\\n" .
  "myhost.hn.org,my2ndhost.hn.org\n" .
  "</pre>\n" .
  "</div>\n" .
  "";

$main[] = $text;
// namecheap
$text['id'] = "namecheap";
$text['title'] = "namecheap";
$text['menu']  = "namecheap";
$text['body']  = 
"<p>The 'namecheap' protocol is used by DNS service offered by www.namecheap.com.</p>\n" . 
"\n" .
"<p>Configuration variables applicable to the 'easydns' protocol are:</p>\n" .
"<table>\n" .
  "<tr><td>protocol=namecheap           </td><td> </td></tr>\n" .
  "<tr><td>server=fqdn.of.service       </td><td> defaults to dynamicdns.park-your-domain.com</td></tr>\n" .
  "<tr><td>login=service-login          </td><td> login name and password  registered with the service</td></tr>\n" .
  "<tr><td>password=service-password    </td><td></td></tr>\n" .
  "<tr><td>fully.qualified.host         </td><td> the host registered with the service.</td></tr>\n" .
"</table>\n" .

"<p>Example ddclient.conf file entries:</p>".
	"<div class=\"code\">\n" .
	"<pre>\n" .
  "## single host update\n" .
  "protocol=namecheap,                                         \\\n" .
  "login=my-namecheap.com-login,                               \\\n" .
  "password=my-namecheap.com-password                          \\\n" .
  "myhost.namecheap.com \n" .
    "</pre>\n" .
      "</div>\n" .
  "<p></p>";


$main[] = $text;
$text['id'] = "zoneedit1";
$text['title'] = "zoneedit1";
$text['menu']  = "zoneedit1";
$text['body']  = 
"<p>The 'zoneedit1' protocol is used by a DNS service offered by
www.zoneedit.com.</p>\n" .

"<p>Configuration variables applicable to the 'zoneedit1' protocol are:</p>\n" .
  "<tr><td>protocol=zoneedit1           </td><td> </td></tr>\n" .
  "<tr><td>server=fqdn.of.service       </td><td> defaults to www.zoneedit.com</td></tr>\n" .
  "<tr><td>login=service-login          </td><td> login name and password  registered with the service</td></tr>\n" .
  "<tr><td>password=service-password    </td><td></td></tr>\n" .
  "<tr><td>your.domain.name             </td><td> the host registered with the service.</td></tr>\n" .

"<p>Example ddclient.conf file entries:</p>\n" .
	"<div class=\"code\">\n" .
	"<pre>\n" .
  "## single host update\n" .
  "protocol=zoneedit1,                                     \\\n" .
  "server=www.zoneedit.com,                                \\\n" .
  "login=my-zoneedit-login,                                \\\n" .
  "password=my-zoneedit-password                           \\\n" .
  "my.domain.name\n" .
  "\n" .
  "## multiple host update                                 \\\n" .
  "protocol=zoneedit1,                                     \\\n" .
  "server=www.zoneedit.com,                                \\\n" .
  "login=my-zoneedit-login,                                \\\n" .
  "password=my-zoneedit-password                           \\\n" .
  "my.domain.name,my2nd.domain.com\n" .
    "</pre>\n" .
      "</div>\n" .
  "<p></p>";
$main[] = $text;
} else if ($page == 3) {				 // supported routers
	$text['id'] = "intro";
	$text['title'] = "Introduction about the -use option";
	$text['menu']  = "introduction";
	$text['body']  = 
		"<p>". 
		"Ddclient can get the needed IP-address on a lot of different\n".
		"ways.  By default, it fetches it's IP from the internet but \n".
		"you can it also from a router or specify it yourself.\n".
		"</p>\n".
		"<p>Ddclient supports a lot of different routers. To configure ".
		"your favorit router, modify your use-line in your configuration ".
		"to something like -use=linksys-ver2.  Don't forget to put your ".
		"router password and login in the configuration.".
		"</p>".
		"<p>".
		"If your favorit router isn't here, try to run ddclient --help. \n".
		"This list is rather incomplete so there are a few more routers \n".
		"supported by the most recent version of ddclient.  \n".
		"</p>";
	$main[] = $text;

	$text['id'] = "nonrouter";
	$text['title'] = "Non router option";
	$text['menu']  = "Non router";
	$text['body']  = 
	"<table>" .
    	"<tr><td>-use=web</td><td> obtain IP from an IP discovery page on the web.  This is the default way if none is specified<tr></td>\n" .
    	"<tr><td>-use=if</td><td> obtain IP from the -if {interface}.<tr></td>" .
    	"<tr><td>-use=ip</td><td> obtain IP from -ip {address}.<tr></td>\n" .
    	"<tr><td>-use=cmd</td><td> obtain IP from the -cmd {external-command}.<tr></td>" .
    	"<tr><td>-use=fw</td><td> obtain IP from the firewall specified by -fw {type|address}.<tr></td>" .
	"</table>";
	$main[] = $text;

	$text['title'] = "Incomplete list of supported routers";
	$text['menu']  = "routers";
	$text['body']  = 
	"<table>".
	"<tr><td>-use=3com-3c886a            </td><td> obtain IP from 3com 3c886a 56k Lan Modem at the -fw {address}.</tr></td>" .
	"<tr><td>-use=3com-oc-remote812      </td><td> obtain IP from 3com OfficeConnect Remote 812 at the -fw {address}.</tr></td>" .
	"<tr><td>-use=alcatel-stp            </td><td> obtain IP from Alcatel Speed Touch Pro at the -fw {address}.</tr></td>" .
	"<tr><td>-use=allnet-1298            </td><td> obtain IP from Allnet 1298 at the -fw {address}.</tr></td>" .
    	"<tr><td>-use=cayman-3220h           </td><td> obtain IP from Cayman 3220-H DSL at the -fw {address}.<tr></td>" .
    	"<tr><td>-use=cisco                  </td><td> obtain IP from Cisco FW at the -fw {address}.<tr></td>" .
    	"<tr><td>-use=dlink-604              </td><td> obtain IP from D-Link DI-604 at the -fw {address}.<tr></td>" .
    	"<tr><td>-use=dlink-614              </td><td> obtain IP from D-Link DI-614+ at the -fw {address}.<tr></td>" .
    	"<tr><td>-use=e-tech                 </td><td> obtain IP from E-tech Router at the -fw {address}.<tr></td>" .
    	"<tr><td>-use=elsa-lancom-dsl10      </td><td> obtain IP from ELSA LanCom DSL/10 DSL FW at the -fw {address}.<tr></td>" .
    	"<tr><td>-use=elsa-lancom-dsl10-ch01 </td><td> obtain IP from ELSA LanCom DSL/10 DSL FW (isdn ch01) at the -fw {address}.<tr></td>" .
    	"<tr><td>-use=elsa-lancom-dsl10-ch02 </td><td> obtain IP from ELSA LanCom DSL/10 DSL FW (isdn ch01) at the -fw {address}.<tr></td>" .
    	"<tr><td>-use=linksys                </td><td> obtain IP from Linksys FW at the -fw {address}.<tr></td>\n" .
    	"<tr><td>-use=linksys2               </td><td> obtain IP from Linksys FW ver 2 at the -fw {address}.<tr></td>\n" .
    	"<tr><td>-use=maxgate-ugate3x00      </td><td> obtain IP from MaxGate UGATE-3x00 FW at the -fw {address}.<tr></td>\n" .
    	"<tr><td>-use=netgear-rt3xx          </td><td> obtain IP from Netgear FW at the -fw {address}.<tr></td>\n" .
    	"<tr><td>-use=netopia-r910           </td><td> obtain IP from Netopia R910 FW at the -fw {address}.<tr></td>\n" .
    	"<tr><td>-use=smc-barricade          </td><td> obtain IP from SMC Barricade FW at the -fw {address}.<tr></td>\n" .
    	"<tr><td>-use=sohoware-nbg800        </td><td> obtain IP from SOHOWare BroadGuard NBG800 at the -fw {address}.<tr></td>\n" .
    	"<tr><td>-use=vigor-2200usb          </td><td> obtain IP from Vigor 2200 USB at the -fw {address}.<tr></td>\n" .
    	"<tr><td>-use=watchguard-soho        </td><td> obtain IP from Watchguard SOHO FW at the -fw {address}.<tr></td>\n" .
    	"<tr><td>-use=xsense-aero            </td><td> obtain IP from Xsense Aero at the -fw {address}.<tr></td>\n" .
		"</table>".
	"<p>Remember, if your router isn't here, check the result of ddclient --help</p>";
	$main[] = $text;

}
?>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en-AU">
  <head>
    <meta http-equiv="content-type" content="application/xhtml+xml; charset=UTF-8" />
    <meta name="author" content="haran" />
    <meta name="generator" content="author" />

    <!-- Navigational metadata for large websites (an accessibility feature): -->
<!--
    <link rel="top"      href="./index.html" title="Homepage" />
    <link rel="up"       href="./index.html" title="Up" />
    <link rel="first"    href="./index.html" title="First page" />
    <link rel="previous" href="./index.html" title="Previous page" />
    <link rel="next"     href="./index.html" title="Next page" />
    <link rel="last"     href="./index.html" title="Last page" />
    <link rel="toc"      href="./index.html" title="Table of contents" />
    <link rel="index"    href="./index.html" title="Site map" />
-->
    <link rel="stylesheet" type="text/css" href="ddclient.css" media="screen" title="ddclient" />
    <title><?php echo "$title $titleextra" ?></title>
  </head>

  <body>
    <!-- For non-visual user agents: -->
      <div id="top"><a href="#main-copy" class="doNotDisplay doNotPrint">Skip to main content.</a></div>

    <!-- ##### Header ##### -->

    <div id="header">

      <div class="midHeader">
        <h1 class="headerTitle"><?php echo $title ?></h1>
      </div>

      <div class="subHeader">
        <span class="doNotDisplay">Navigation:</span>
<!--
        <a href="./index.php?page=home" <?php if ($page==0) printf("class=\"highlight\"");?>>home</a> |
        <a href="./index.php?page=doc"  <?php if ($page==1) printf("class=\"highlight\"");?>>documentation</a> |
        <a href="./index.php">download</a> |
        <a href="./index.php">Links</a> |
-->

<?php
$cnt=0;
foreach ($pages as $id => $subpage) {
	if ($cnt++) printf(" | ");
        printf("<a href=\"./index.php?page=%s\"%s>%s</a>",
	$subpage['nr'],
	// $id,
	// $subpage['title'],
	$page==$subpage['nr']?' class="highlight"':"",
	$subpage['title']
);
}
?>

      </div>
    </div>

    <!-- ##### Side Bar ##### -->

    <div id="side-bar">
      <div>
        <!--p class="sideBarTitle">Navigate this page</p-->
        <ul>
<?php
foreach ($main as $id => $text) {
printf("<li><a href=\"#%s\" title=\"%s\">&rsaquo; %s</a></li>",
	$text['id'],
	$text['title'],
	$text['menu']
);
}
?>
        </ul>
      </div>
    
      <div class="lighterBackground">
        <p class="sideBarTitle">Thanks</p>
        <span class="sideBarText">
	  Website design based on <a href="http://www.oswd.org/viewdesign.phtml?id=1165">Sinorca</a>
	</span>
        <span class="sideBarText">
	  Ddclient was originally written by Paul Burry
	</span>
        <span class="sideBarText">
	  M for choosing the colors
	</span>
        <span class="sideBarText">
	  Website is hosted on
<A href="http://sourceforge.net"> <IMG src="http://sourceforge.net/sflogo.php?group_id=116817&amp;type=2" width="125" height="37" border="0" alt="SourceForge.net Logo" /></A>
	</span>
      </div>
    </div>

    <!-- ##### Main Copy ##### -->

    <div id="main-copy">
<?php
foreach ($main as $text) {
printf("<a class=\"topOfPage\" href=\"#top\" title=\"Go to the top of this page\">^ TOP</a>\n");
printf("<h1 id=\"%s\">%s</h1>\n",$text['id'],$text['title']);
printf("%s\n",$text['body']);
}
?>
    </div>
    
    <!-- ##### Footer ##### -->

    <div id="footer">
      <!--div class="left">
        E-mail:&nbsp;<a href="./index.html" title="Email webmaster">webmaster@your.company.com</a><br />
        <a href="./index.html" class="doNotPrint">Contact Us</a>
      </div-->

      <br class="doNotDisplay doNotPrint" />

      <div class="right">
<?php
$fp = fopen(".", "r");
// gather statistics
$fstat = fstat($fp);
// close the file
fclose($fp);
printf("Last update: %s\n", date("d F Y",$fstat['mtime']));
?>
      </div>
    </div>
  </body>
</html>
