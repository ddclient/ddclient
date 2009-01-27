This directory will contain anything related to releasing a new version of 
ddclient.  It will be a replacement for 
http://ddclient.wiki.sourceforge.net/HowtoRelease

Releasing files

* tagging current version: see svn book
* update RELEASE NOTES
* update ChangeLog
* update version number
* svn copy https://ddclient.svn.sourceforge.net/svnroot/ddclient/trunk https://ddclient.svn.sourceforge.net/svnroot/ddclient/tags/release-3.7.2
( on the last release it has been done by just copying the local dir )
* bz2 en gz file aanmaken
* rsync -av ddclient-3.8.0.* wimpunk@frs.sf.net:uploads
* aanmaken release:

Release Notes 3.6.5 	2004-11-24
ddclient-3.6.5.tar.bz2 	33311 	0 	Any 	.bz2
ddclient-3.6.5.tar.gz 	35726 	0 	Any 	.gz

* mail naar ddclient-support
* news updaten

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

