use Test::More;
use Scalar::Util qw(blessed);
use MIME::Base64;
eval { require ddclient::Test::Fake::HTTPD; } or plan(skip_all => $@);
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

my $httpd = ddclient::Test::Fake::HTTPD->new();
$httpd->run(sub {
    my ($req) = @_;
    diag('==============================================================================');
    diag("Test server received request:\n" . $req->as_string());
    my $headers = ['content-type' => 'text/plain; charset=utf-8'];
    my $wantauthn = 'Basic ' . encode_base64('username:password', '');
    return [401, [@$headers, 'www-authenticate' => 'Basic realm="realm", charset="UTF-8"'],
            ['authentication required']] if ($req->header('authorization') // '') ne $wantauthn;
    return [400, $headers, ['invalid method: ' . $req->method()]] if $req->method() ne 'GET';
    return [400, $headers, ['unexpected request: ' . $req->uri() . "\n",
                            'want: ' . $req->header('want-req')]]
        if $req->uri() ne $req->header('want-req');
    return [200, $headers, [map("$_\n", $req->header('line'))]];
});
diag("started IPv4 HTTP server running at " . $httpd->endpoint());

{
    package Logger;
    BEGIN { push(our @ISA, qw(ddclient::Logger)); }
    sub new {
        my ($class, $parent) = @_;
        my $self = $class->SUPER::new(undef, $parent);
        $self->{logs} = [];
        return $self;
    }
    sub _log {
        my ($self, $args) = @_;
        push(@{$self->{logs}}, $args)
            if ($args->{label} // '') =~ qr/^(?:WARNING|FATAL|SUCCESS|FAILED)$/;
        return $self->SUPER::_log($args);
    }
}

my @test_cases = (
    {
        desc => 'IPv4, single host, good',
        cfg => {h1 => {wantipv4 => '192.0.2.1'}},
        resp => ['good'],
        wantquery => 'hostname=h1&myip=192.0.2.1',
        wantrecap => {
            h1 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv4/},
        ],
    },
    {
        desc => 'IPv4, single host, nochg',
        cfg => {h1 => {wantipv4 => '192.0.2.1'}},
        resp => ['nochg'],
        wantquery => 'hostname=h1&myip=192.0.2.1',
        wantrecap => {
            h1 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'WARNING', ctx => ['h1'], msg => qr/nochg/},
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv4/},
        ],
    },
    {
        desc => 'IPv4, single host, bad',
        cfg => {h1 => {wantipv4 => '192.0.2.1'}},
        resp => ['nohost'],
        wantquery => 'hostname=h1&myip=192.0.2.1',
        wantrecap => {
            h1 => {'status-ipv4' => 'nohost'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['h1'], msg => qr/nohost/},
        ],
    },
    {
        desc => 'IPv4, single host, unexpected',
        cfg => {h1 => {wantipv4 => '192.0.2.1'}},
        resp => ['WAT'],
        wantquery => 'hostname=h1&myip=192.0.2.1',
        wantrecap => {
            h1 => {'status-ipv4' => 'WAT'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['h1'], msg => qr/unexpected.*WAT/},
        ],
    },
    {
        desc => 'IPv4, multiple hosts, multiple good',
        cfg => {
            h1 => {wantipv4 => '192.0.2.1'},
            h2 => {wantipv4 => '192.0.2.1'},
        },
        resp => [
            'good 192.0.2.1',
            'good',
        ],
        wantquery => 'hostname=h1,h2&myip=192.0.2.1',
        wantrecap => {
            h1 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
            h2 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv4/},
            {label => 'SUCCESS', ctx => ['h2'], msg => qr/IPv4/},
        ],
    },
    {
        desc => 'IPv4, multiple hosts, mixed success',
        cfg => {
            h1 => {wantipv4 => '192.0.2.1'},
            h2 => {wantipv4 => '192.0.2.1'},
            h3 => {wantipv4 => '192.0.2.1'},
        },
        resp => [
            'good',
            'nochg',
            'dnserr',
        ],
        wantquery => 'hostname=h1,h2,h3&myip=192.0.2.1',
        wantrecap => {
            h1 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
            h2 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
            h3 => {'status-ipv4' => 'dnserr'},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv4/},
            {label => 'WARNING', ctx => ['h2'], msg => qr/nochg/},
            {label => 'SUCCESS', ctx => ['h2'], msg => qr/IPv4/},
            {label => 'FAILED', ctx => ['h3'], msg => qr/dnserr/},
        ],
    },
    {
        desc => 'IPv6, single host, good',
        cfg => {h1 => {wantipv6 => '2001:db8::1'}},
        resp => ['good'],
        wantquery => 'hostname=h1&myip=2001:db8::1',
        wantrecap => {
            h1 => {'status-ipv6' => 'good', 'ipv6' => '2001:db8::1', 'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv6/},
        ],
    },
    {
        desc => 'IPv4 and IPv6, single host, good',
        cfg => {h1 => {wantipv4 => '192.0.2.1', wantipv6 => '2001:db8::1'}},
        resp => ['good'],
        wantquery => 'hostname=h1&myip=192.0.2.1,2001:db8::1',
        wantrecap => {
            h1 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1',
                   'status-ipv6' => 'good', 'ipv6' => '2001:db8::1',
                   'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv4/},
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv6/},
        ],
    },
    {
        desc => 'excess status line',
        cfg => {
            h1 => {wantipv4 => '192.0.2.1'},
            h2 => {wantipv4 => '192.0.2.1'},
        },
        resp => [
            'good',
            'good',
            'WAT',
        ],
        wantquery => 'hostname=h1,h2&myip=192.0.2.1',
        wantrecap => {
            h1 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
            h2 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv4/},
            {label => 'SUCCESS', ctx => ['h2'], msg => qr/IPv4/},
            {label => 'WARNING', ctx => ['h1,h2'], msg => qr/unexpected.*\nWAT$/},
        ],
    },
    {
        desc => 'multiple hosts, single failure',
        cfg => {
            h1 => {wantipv4 => '192.0.2.1'},
            h2 => {wantipv4 => '192.0.2.1'},
        },
        resp => ['abuse'],
        wantquery => 'hostname=h1,h2&myip=192.0.2.1',
        wantrecap => {
            h1 => {'status-ipv4' => 'abuse'},
            h2 => {'status-ipv4' => 'abuse'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['h1'], msg => qr/abuse/},
            {label => 'FAILED', ctx => ['h2'], msg => qr/abuse/},
        ],
    },
    {
        desc => 'multiple hosts, single success',
        cfg => {
            h1 => {wantipv4 => '192.0.2.1'},
            h2 => {wantipv4 => '192.0.2.1'},
        },
        resp => ['good'],
        wantquery => 'hostname=h1,h2&myip=192.0.2.1',
        wantrecap => {
            h1 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
            h2 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'WARNING', ctx => ['h1,h2'], msg => qr//},
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv4/},
            {label => 'SUCCESS', ctx => ['h2'], msg => qr/IPv4/},
        ],
    },
    {
        desc => 'multiple hosts, fewer results',
        cfg => {
            h1 => {wantipv4 => '192.0.2.1'},
            h2 => {wantipv4 => '192.0.2.1'},
            h3 => {wantipv4 => '192.0.2.1'},
        },
        resp => [
            'good',
            'nochg',
        ],
        wantquery => 'hostname=h1,h2,h3&myip=192.0.2.1',
        wantrecap => {
            h1 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
            h2 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
            h3 => {'status-ipv4' => 'unknown'},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv4/},
            {label => 'WARNING', ctx => ['h2'], msg => qr/nochg/},
            {label => 'SUCCESS', ctx => ['h2'], msg => qr/IPv4/},
            {label => 'FAILED', ctx => ['h3'], msg => qr/assuming failure/},
        ],
    },
);

for my $tc (@test_cases) {
    diag('==============================================================================');
    diag("Starting test: $tc->{desc}");
    diag('==============================================================================');
    local $ddclient::globals{debug} = 1;
    local $ddclient::globals{verbose} = 1;
    my $l = Logger->new($ddclient::_l);
    local %ddclient::config;
    local %ddclient::recap;
    $ddclient::config{$_} = {
        login => 'username',
        password => 'password',
        server => $httpd->endpoint(),
        script => '/nic/update',
        %{$tc->{cfg}{$_}},
    } for keys(%{$tc->{cfg}});
    {
        local @ddclient::_test_headers = (
            "want-req: /nic/update?$tc->{wantquery}",
            map("line: $_", @{$tc->{resp}}),
        );
        local $ddclient::_l = $l;
        ddclient::nic_dyndns2_update(undef, sort(keys(%{$tc->{cfg}})));
    }
    is_deeply(\%ddclient::recap, $tc->{wantrecap}, "$tc->{desc}: recap")
        or diag(ddclient::repr(Values => [\%ddclient::recap, $tc->{wantrecap}],
                               Names => ['*got', '*want']));
    $tc->{wantlogs} //= [];
    subtest("$tc->{desc}: logs" => sub {
        my @got = @{$l->{logs}};
        my @want = @{$tc->{wantlogs}};
        for my $i (0..$#want) {
            last if $i >= @got;
            my $got = $got[$i];
            my $want = $want[$i];
            subtest("log $i" => sub {
                is($got->{label}, $want->{label}, "label matches");
                is_deeply($got->{ctx}, $want->{ctx}, "context matches");
                like($got->{msg}, $want->{msg}, "message matches");
            }) or diag(ddclient::repr(Values => [$got, $want], Names => ['*got', '*want']));
        }
        my @unexpected = @got[@want..$#got];
        ok(@unexpected == 0, "no unexpected logs")
            or diag(ddclient::repr(\@unexpected, Names => ['*unexpected']));
        my @missing = @want[@got..$#want];
        ok(@missing == 0, "no missing logs")
            or diag(ddclient::repr(\@missing, Names => ['*missing']));
    });
}

done_testing();
