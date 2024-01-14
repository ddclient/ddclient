use Test::More;
use ddclient::t;
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);
ddclient::load_sha1_support("route53");

my $TARGET_REQUEST_HASH = "18edc7204269d65bfa6a075381b0496cdb38166dfc3654207e929c6178d1a1ba";

my $hosted_zone_id = "Z123456789ABCDEXAMPLE";
my $aws_access_key_id = "AKIAIOSFODNN7EXAMPLE";
my $aws_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY";
my $ttl_to_use = 300;
my $h = "test.example.com";
my $ip = "127.0.0.1";
my $resource_set_type = 'A';
my $date = ddclient::create_date(1369353600);

my $ROUTE53_NS = "https://route53.amazonaws.com/doc/2013-04-01/";

my $request_xml =<<"Route53Payload";
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
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
</ChangeResourceRecordSetsRequest>
Route53Payload
;

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
    is($signature, "2bcc6ad2c792934174d1065d49e58b91c8fb874521a625eb0af785f33ef8829d");
};

# maybe add some more test to ensure headers and such, but the most critical parts have tests so yay!

done_testing();
