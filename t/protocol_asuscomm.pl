use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

# Stand up a local test server that mimics ns1.asuscomm.com
httpd()->run(sub {
    my ($req) = @_;
    diag('==============================================================================');
    diag("Test server received request:\n" . $req->as_string());

    my $uri    = $req->uri->as_string;
    my $auth   = $req->header('Authorization') // '';
    my $method = $req->method;

    # All ASUS DDNS requests must be GET to /ddns/update.jsp
    unless ($method eq 'GET' && $uri =~ m{^/ddns/update\.jsp}) {
        return [400, ['Content-Type' => 'text/plain'], ['unexpected request: ' . $uri]];
    }

    # Reject anything with wrong MAC (simulate auth check)
    if ($auth !~ /AABBCCDDEEFF/) {
        return [401, ['Content-Type' => 'text/plain'], []];
    }

    my %params = map { split(/=/, $_, 2) } split(/&/, ($uri =~ /\?(.*)/)[0] // '');
    my $hostname = $params{hostname} // '';
    my $myip     = $params{myip}     // '';

    if ($hostname eq 'myhost.asuscomm.com' && $myip =~ /^\d+\.\d+\.\d+\.\d+$/) {
        return [200, ['Content-Type' => 'text/plain'], ["200||"]];
    } elsif ($hostname eq 'nochg.asuscomm.com') {
        return [200, ['Content-Type' => 'text/plain'], ["220||"]];
    } elsif ($hostname eq 'transferred.asuscomm.com') {
        return [200, ['Content-Type' => 'text/plain'], ["230||old.asuscomm.com"]];
    } elsif ($hostname eq 'conflict.asuscomm.com') {
        return [200, ['Content-Type' => 'text/plain'], ["203||suggested.asuscomm.com"]];
    } elsif ($hostname eq 'badip.asuscomm.com') {
        return [200, ['Content-Type' => 'text/plain'], ["299||"]];
    } else {
        return [200, ['Content-Type' => 'text/plain'], ["297||"]];
    }
});

my $hostname = httpd()->endpoint();
# Strip scheme — protocol builds "http://$server/..."
(my $server = $hostname) =~ s{^https?://}{};

my @test_cases = (
    {
        desc => 'IPv4 update success (200)',
        cfg  => {h1 => {
            server   => $server,
            login    => 'AABBCCDDEEFF',
            password => '12345670',
            wantipv4 => '1.2.3.4',
        }, 'h1' => 'myhost.asuscomm.com'},
        host    => 'myhost.asuscomm.com',
        wantrecap => {
            'myhost.asuscomm.com' => {'status-ipv4' => 'good', 'ipv4' => '1.2.3.4', mtime => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.asuscomm.com'], msg => qr/1\.2\.3\.4/},
        ],
    },
    {
        desc => 'IPv4 no-change (220)',
        cfg  => {
            server   => $server,
            login    => 'AABBCCDDEEFF',
            password => '12345670',
            wantipv4 => '1.2.3.4',
        },
        host    => 'nochg.asuscomm.com',
        wantrecap => {
            'nochg.asuscomm.com' => {'status-ipv4' => 'good', 'ipv4' => '1.2.3.4', mtime => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['nochg.asuscomm.com'], msg => qr/unchanged/},
        ],
    },
    {
        desc => 'IPv4 update success after MAC transfer (230)',
        cfg  => {
            server   => $server,
            login    => 'AABBCCDDEEFF',
            password => '12345670',
            wantipv4 => '1.2.3.4',
        },
        host    => 'transferred.asuscomm.com',
        wantrecap => {
            'transferred.asuscomm.com' => {'status-ipv4' => 'good', 'ipv4' => '1.2.3.4', mtime => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['transferred.asuscomm.com'], msg => qr/1\.2\.3\.4/},
        ],
    },
    {
        desc => 'bad auth (401)',
        cfg  => {
            server   => $server,
            login    => 'WRONGMACADDR',
            password => '00000000',
            wantipv4 => '1.2.3.4',
        },
        host    => 'myhost.asuscomm.com',
        wantrecap => {
            'myhost.asuscomm.com' => {'status-ipv4' => 'failed'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['myhost.asuscomm.com'], msg => qr/401/},
        ],
    },
    {
        desc => 'hostname registered to different MAC (203)',
        cfg  => {
            server   => $server,
            login    => 'AABBCCDDEEFF',
            password => '12345670',
            wantipv4 => '1.2.3.4',
        },
        host    => 'conflict.asuscomm.com',
        wantrecap => {
            'conflict.asuscomm.com' => {'status-ipv4' => 'failed'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['conflict.asuscomm.com'], msg => qr/different MAC/},
        ],
    },
    {
        desc => 'invalid IP (299)',
        cfg  => {
            server   => $server,
            login    => 'AABBCCDDEEFF',
            password => '12345670',
            wantipv4 => '1.2.3.4',
        },
        host    => 'badip.asuscomm.com',
        wantrecap => {
            'badip.asuscomm.com' => {'status-ipv4' => 'failed'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['badip.asuscomm.com'], msg => qr/invalid IP/},
        ],
    },
);

plan(tests => scalar(@test_cases));

for my $tc (@test_cases) {
    run_logger_test($tc->{desc}, sub {
        local %ddclient::config;
        local %ddclient::recap;
        my $host = $tc->{host};
        $ddclient::config{$host} = {
            %{$tc->{cfg}},
            wantipv4 => $tc->{cfg}{wantipv4} // '1.2.3.4',
        };
        ddclient::nic_asuscomm_update(undef, $host);
        return \%ddclient::recap;
    }, $tc->{wantrecap}, $tc->{wantlogs});
}
