apt-get install -y libdata-validate-ip-perl
apt-get install -y sendmail
apt-get install -y libjson-any-perl
apt-get install -y libssl-dev
cpan IO::Socket::SSL
cp ddclient /usr/sbin/
mkdir /etc/ddclient
mkdir /var/cache/ddclient
cp sample-etc_ddclient.conf /etc/ddclient/ddclient.conf

