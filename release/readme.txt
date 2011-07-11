This directory will contain anything related to releasing a new version of 
ddclient.  It will be a replacement for 
https://sourceforge.net/apps/trac/ddclient/wiki/HowtoRelease

Releasing files

* update RELEASENOTE
* update ChangeLog: {{{ svn2cl --group-by-day -i }}}
* update version number: replace the version number in ddclient by the correct one
* tagging current version: 
{{{
svn copy trunk \
	https://ddclient.svn.sourceforge.net/svnroot/ddclient/tags/release-3.8.1
}}}
* svn update tags
* svn revert trunk
* mkdir trunk/release/ddclient-3.8.1
* cp ChangeLog trunk/release/ddclient-3.8.1
* cp tags/release-3.8.1 trunk/release/ddclient-3.8.1
* cd trunk/release
* remove unneeded directories release, patches, ...
* tar -cvzf ddclient-3.8.1.tar.gz ddclient-3.8.1
* tar -cvjf ddclient-3.8.1.tar.bz2 ddclient-3.8.1
* transfert via project page.  Seems to be changed.
* news updaten
* mail to ddclient-support @ lists.sourceforge.net
* freshmeat updaten
* website bijtimmeren: versie nummer aanpassen
(niet gevonden waar dat nu staat in de wiki)
* [https://www.dyndns.com/developers/listings/3 dyndns update]
(geen mogelijkheid gevonden om die te updaten)


website

* recentste routers
* postscript


rss feeds

* see https://sourceforge.net/export/rss2_project.php?group_id=116817

