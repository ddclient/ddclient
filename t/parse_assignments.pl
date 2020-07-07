use Test::More;
use Data::Dumper;

SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

$Data::Dumper::Sortkeys = 1;

sub tc {
    return {
        name => shift,
        input => shift,
        want_vars => shift,
        want_rest => shift,
    };
}

my @test_cases = (
    tc('no assignments',             "",             {},                     ""),
    tc('one assignment',             "a=1",          { a => '1' },           ""),
    tc('empty value',                "a=",           { a => '' },            ""),
    tc('sep: comma',                 "a=1,b=2",      { a => '1', b => '2' }, ""),
    tc('sep: space',                 "a=1 b=2",      { a => '1', b => '2' }, ""),
    tc('sep: comma space',           "a=1, b=2",     { a => '1', b => '2' }, ""),
    tc('sep: space comma',           "a=1 ,b=2",     { a => '1', b => '2' }, ""),
    tc('sep: space comma space',     "a=1 , b=2",    { a => '1', b => '2' }, ""),
    tc('leading space',              " a=1",         { a => '1' },           ""),
    tc('trailing space',             "a=1 ",         { a => '1' },           ""),
    tc('leading comma',              ",a=1",         { a => '1' },           ""),
    tc('trailing comma',             "a=1,",         { a => '1' },           ""),
    tc('empty assignment',           "a=1,,b=2",     { a => '1', b => '2' }, ""),
    tc('rest',                       "a",            {},                     "a"),
    tc('rest leading space',         " x",           {},                     "x"),
    tc('rest trailing space',        "x ",           {},                     "x "),
    tc('rest leading comma',         ",x",           {},                     "x"),
    tc('rest trailing comma',        "x,",           {},                     "x,"),
    tc('assign space rest',          "a=1 x",        { a => '1' },           "x"),
    tc('assign comma rest',          "a=1,x",        { a => '1' },           "x"),
    tc('assign comma space rest',    "a=1, x",       { a => '1' },           "x"),
    tc('assign space comma rest',    "a=1 ,x",       { a => '1' },           "x"),
    tc('single quoting',             "a='\", '",     { a => '", ' },         ""),
    tc('double quoting',             "a=\"', \"",    { a => "', " },         ""),
    tc('mixed quoting',              "a=1\"2\"'3'4", { a => "1234" },        ""),
    tc('unquoted escaped backslash', "a=\\\\",       { a => "\\" },          ""),
    tc('squoted escaped squote',     "a='\\''",      { a => "'" },           ""),
    tc('dquoted escaped dquote',     "a=\"\\\"\"",   { a => '"' },           ""),
);

for my $tc (@test_cases) {
    my ($got_rest, %got_vars) = ddclient::parse_assignments($tc->{input});
    subtest $tc->{name} => sub {
        is(Dumper(\%got_vars), Dumper($tc->{want_vars}), "vars");
        is($got_rest, $tc->{want_rest}, "rest");
    }
}

done_testing();
