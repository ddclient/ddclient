use Test::More;
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

my %variable_collections = (
    map({ ($_ => $ddclient::variables{$_}) } grep($_ ne 'merged', keys(%ddclient::variables))),
    map({ ("protocol=$_" => $ddclient::protocols{$_}{variables}); } keys(%ddclient::protocols)),
);
my %seen;
my @test_cases = (
    map({
        my $vcn = $_;
        my $vc = $variable_collections{$_};
        map({
            my $def = $vc->{$_};
            my $seen = exists($seen{$def});
            $seen{$def} = undef;
            ({desc => "$vcn $_", def => $vc->{$_}}) x !$seen;
        } sort(keys(%$vc)));
    } sort(keys(%variable_collections))),
);
for my $tc (@test_cases) {
    if ($tc->{def}{required}) {
        is($tc->{def}{default}, undef, "'$tc->{desc}' (required) has no default");
    } else {
        my $norm;
        my $valid = eval { $norm = ddclient::check_value($tc->{def}{default}, $tc->{def}); 1; };
        ok($valid, "'$tc->{desc}' (optional) has a valid default");
        is($norm, $tc->{def}{default}, "'$tc->{desc}' default normalizes to itself") if $valid;
    }
}
done_testing();
