<?php
/*
 * $Id$
 *
 * $LastChangedDate$
 * $Rev$
 * $Author$
 *
 * */
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
can be found on the <a href=\"?page=1\">usage page</a>.  There's also 
a sample configuration delivered with ddclient.
</p>
<p>
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
and put it in your startup scripts.  There are samples of startup scripts
provided with ddclient.
</p> \n"; 
$main[] = $text;

// help part
$text['id'] = "help";
$text['title'] = "Documentation and help";
$text['menu'] = "Documentation";
$text['body'] = "
<p>
The documentation about the configuration has been splitted in three
sections.  The <a href=\"?page=1\">usage page</a> describes the most parts
of the configuration while the <a href=\"?page=2\">supported protocols</a> 
page describes the protocol-specific options.  If you want to know how 
to use ddclient with your router, check the 
<a href=\"?page=3\">supported routers</a>.
</p>

<p>
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
"<p>
If this doesn't help for you, maybe
<a href=\"http://sourceforge.net/forum/forum.php?forum_id=399428\">
the help forum on sourceforge</a> can bring some help.
If you don't want to register on sf.net, you can try
<a href=\"http://sourceforge.net/mail/?group_id=116817\">
the ddclient-support mailinglist on sf.net</a>.
If you're lucky you can find some help on 
<a href=\"irc://irc.freenode.net\">#ddclient on irc.freenode.net</a>.  " .
	"I know the manual is not very clear, you have to read the example\n" .
	"configurations included in the tar-file or you can run\n" .
	"&quot;ddclient --help&quot; to get more help.  " .
	"</p>\n" .
	"<p>
More info about the ddclient project can be found on " .
	$link['project'] .
	"</p>";
$main[] = $text;
?>
