<?php
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
