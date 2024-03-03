use Test::More;
use ddclient::t;
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);
ddclient::load_sha1_support("route53");

my $TARGET_REQUEST_HASH = "d23c59e5cfce6076ea5dabe3d32f02f89d8eb2c68fdf17aa53f514860ddacc51";

my $hosted_zone_id = "Z123456789ABCDEXAMPLE";
my $aws_access_key_id = "AKIAIOSFODNN7EXAMPLE";
my $aws_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY";
my $ttl_to_use = 300;
my $h = "test.example.com";
my $ip = "127.0.0.1";
my $resource_set_type = 'A';
my $date = ddclient::create_date(1369353600);

my $ROUTE53_NS = "https://route53.amazonaws.com/doc/2013-04-01/";
# The spacing below matters!
my $request_xml =
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <ChangeResourceRecordSetsRequest xmlns=\"$ROUTE53_NS\">
        <ChangeBatch>
            <Changes>
                <Change>
                    <Action>UPSERT</Action>
                    <ResourceRecordSet>
                        <Name>$h</Name>
                        <Type>$resource_set_type</Type>
                        <TTL>$ttl_to_use</TTL>
                        <ResourceRecords>
                            <ResourceRecord>
                                <Value>$ip</Value>
                            </ResourceRecord>
                        </ResourceRecords>
                    </ResourceRecordSet>
                </Change>
            </Changes>
        </ChangeBatch>
    </ChangeResourceRecordSetsRequest>";

subtest "canonical_request_hash" => sub {
    my %query_parameter_map = ();
    my %headers = (
        "content-type" => "application/xml"
    );

    my $canonical_request = ddclient::create_canonical_request_hash(
        "POST",
        "route53.amazonaws.com",
        "/2013-04-01/hostedzone/".$hosted_zone_id."/rrset/",
        \%query_parameter_map,
        $request_xml,
        \%headers,
        $date
    );

    is(%$canonical_request{hash}, $TARGET_REQUEST_HASH);
};

subtest "canonical_request_signature" => sub {
    my $string_to_sign = ddclient::create_string_to_sign($TARGET_REQUEST_HASH,"route53","us-east-1",$date);
    my $result_string = %$string_to_sign{string};
    my $signature = ddclient::create_signature($result_string,$aws_secret_access_key,"us-east-1","route53",$date);
    is($signature, "ad21008b4d3a4be1beffc7e8844388947570933735e4e81395f64d461fc03681");
};

# maybe add some more test to ensure headers and such, but the most critical parts have tests so yay!

done_testing();
