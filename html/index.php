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
$pages[0]['php'] = "home.php";

// documentation 
$pages[1]['nr'] = 1;
$pages[1]['title'] = "usage";
$pages[1]['php'] = "doc.php";

$pages[2]['nr'] = 2;
$pages[2]['title'] = "supported protocols";
$pages[2]['php'] = "protocol.php";

$pages[3]['nr'] = 3;
$pages[3]['title'] = "supported routers";
$pages[3]['php'] = "router.php";

if ($debug) {
	$pages[4]['nr'] = 4;
	$pages[4]['title'] = "xml";
	$pages[4]['php'] = "xml.php";
}


$curpage = isset($_GET['page'])?$_GET['page']:0;
$titleextra = $pages[$curpage]['title'];
$page       = $pages[$curpage]['nr'];

require($pages[$page]['php']);

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
