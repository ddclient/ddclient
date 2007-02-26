<?php
/*
 * $Id: router.php 23 2006-10-01 09:47:57Z wimpunk $
 *
 * $LastChangedDate: 2006-10-01 11:47:57 +0200 (Sun, 01 Oct 2006) $
 * $Rev: 23 $
 * $Author: wimpunk $
 *
 * */
	$text['id'] = "faq1";
	$text['title'] = "Ddclient doesn't update when I changed my IP manual";
	$text['menu']  = "forcing update";
	$text['body']  = 
		"<p>
		Ddclient doesn't check the dns result when it tries to update.
		It checks its cache file an when value saved in the cache
		differs from the result it got, it does an update.  So if
		you want to force an update, you could do it this way:
		<ul>
		<li>stop the normal instance of ddclient</li>
		<li>force a value by running <code>ddclient -use=ip -ip=1.2.3.4 -daemon=0</code></li>
		<li>start the normal instance of ddclient</li>
		</ul>
		This way, ddclient changes its cache and will see an changed IP 
		adres.
		</p>\n";
	$main[] = $text;
/*
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
*/
?>
