<?php
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
?>
