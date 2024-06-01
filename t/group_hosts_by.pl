use Test::More;
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);
eval { require Data::Dumper; } or skip($@, 1);
Data::Dumper->import();

my $h1 = 'h1';
my $h2 = 'h2';
my $h3 = 'h3';

$ddclient::config{$h1} = {
    common => 'common',
    h1h2 => 'h1 and h2',
    unique => 'h1',
    falsy => 0,
    maybeunset => 'unique',
};
$ddclient::config{$h2} = {
    common => 'common',
    h1h2 => 'h1 and h2',
    unique => 'h2',
    falsy => '',
    maybeunset => undef,  # should not be grouped with unset
};
$ddclient::config{$h3} = {
    common => 'common',
    h1h2 => 'unique',
    unique => 'h3',
    falsy => undef,
    # maybeunset is intentionally not set
};

my @test_cases = (
    {
        desc => 'empty attribute set yields single group with all hosts',
        groupby => [qw()],
        want => [[$h1, $h2, $h3]],
    },
    {
        desc => 'common attribute yields single group with all hosts',
        groupby => [qw(common)],
        want => [[$h1, $h2, $h3]],
    },
    {
        desc => 'subset share a value',
        groupby => [qw(h1h2)],
        want => [[$h1, $h2], [$h3]],
    },
    {
        desc => 'all unique',
        groupby => [qw(unique)],
        want => [[$h1], [$h2], [$h3]],
    },
    {
        desc => 'combination',
        groupby => [qw(common h1h2)],
        want => [[$h1, $h2], [$h3]],
    },
    {
        desc => 'falsy values',
        groupby => [qw(falsy)],
        want => [[$h1], [$h2], [$h3]],
    },
    {
        desc => 'set, unset, undef',
        groupby => [qw(maybeunset)],
        want => [[$h1], [$h2], [$h3]],
    },
    {
        desc => 'missing attribute',
        groupby => [qw(thisdoesnotexist)],
        want => [[$h1, $h2, $h3]],
    },
);

for my $tc (@test_cases) {
    my %got = ddclient::group_hosts_by([$h1, $h2, $h3], $tc->{groupby});
    # %got is used as a set of sets.  Sort everything to make comparison easier.
    my @got = sort({
        for (my $i = 0; $i < @$a && $i < @$b; ++$i) {
            my $x = $a->[$i] cmp $b->[$i];
            return $x if $x != 0;
        }
        return @$a <=> @$b;
    } map({ [sort(@$_)]; } values(%got)));
    is_deeply(\@got, $tc->{want}, $tc->{desc})
        or diag(Data::Dumper->Dump([\@got, $tc->{want}], [qw(got want)]));
}

done_testing();
