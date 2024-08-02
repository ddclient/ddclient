use Test::More;
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

{
    my $output;
    open(my $fh, '>', \$output);
    local *STDERR = $fh;
    ddclient::logmsg('to STDERR');
    close($fh);
    is($output, "to STDERR\n", 'logs to STDERR by default');
}

{
    my $output;
    open(my $fh, '>', \$output);
    ddclient::logmsg(fh => $fh, 'to file handle');
    close($fh);
    is($output, "to file handle\n", 'logs to provided file handle');
}

my @test_cases = (
    {
        desc => 'adds a newline',
        args => ['xyz'],
        want => "xyz\n",
    },
    {
        desc => 'removes one trailing newline (before adding a newline)',
        args => ["xyz \n\t\n\n"],
        want => "xyz \n\t\n\n",
    },
    {
        desc => 'accepts msg keyword parameter',
        args => [msg => 'xyz'],
        want => "xyz\n",
    },
    {
        desc => 'msg keyword parameter trumps message parameter',
        args => [msg => 'kw', 'pos'],
        want => "kw\n",
    },
    {
        desc => 'msg keyword parameter trumps message parameter',
        args => [msg => 'kw', 'pos'],
        want => "kw\n",
    },
    {
        desc => 'email appends to email body',
        args => [email => 1, 'foo'],
        init_email => "preexisting message\n",
        want_email => "preexisting message\nfoo\n",
        want => "foo\n",
    },
    {
        desc => 'single-line label',
        args => [label => 'LBL', 'foo'],
        want => "LBL:     > foo\n",
    },
    {
        desc => 'multi-line label',
        args => [label => 'LBL', "foo\nbar"],
        want => ("LBL:     > foo\n" .
                 "LBL:       bar\n"),
    },
    {
        desc => 'single-line long label',
        args => [label => 'VERY LONG LABEL', 'foo'],
        want => "VERY LONG LABEL: > foo\n",
    },
    {
        desc => 'multi-line long label',
        args => [label => 'VERY LONG LABEL', "foo\nbar"],
        want => ("VERY LONG LABEL: > foo\n" .
                 "VERY LONG LABEL:   bar\n"),
    },
    {
        desc => 'single line, no label, single context',
        args => ['foo'],
        ctxs => ['only context'],
        want => "[only context]> foo\n",
    },
    {
        desc => 'single line, no label, two contexts',
        args => ['foo'],
        ctxs => ['context one', 'context two'],
        want => "[context one][context two]> foo\n",
    },
    {
        desc => 'single line, label, two contexts',
        args => [label => 'LBL', 'foo'],
        ctxs => ['context one', 'context two'],
        want => "LBL:     [context one][context two]> foo\n",
    },
    {
        desc => 'multiple lines, label, two contexts',
        args => [label => 'LBL', "foo\nbar"],
        ctxs => ['context one', 'context two'],
        want => ("LBL:     [context one][context two]> foo\n" .
                 "LBL:     [context one][context two]  bar\n"),
    },
    {
        desc => 'ctx arg',
        args => [label => 'LBL', ctx => 'three', "foo\nbar"],
        ctxs => ['one', 'two'],
        want => ("LBL:     [one][two][three]> foo\n" .
                 "LBL:     [one][two][three]  bar\n"),
    },
);

for my $tc (@test_cases) {
    subtest $tc->{desc} => sub {
        $tc->{wantemail} //= '';
        my $output;
        open(my $fh, '>', \$output);
        local $ddclient::emailbody = $tc->{init_email} // '';
        local $ddclient::_l = $ddclient::_l;
        $ddclient::_l = ddclient::pushlogctx($_) for @{$tc->{ctxs} // []};
        ddclient::logmsg(fh => $fh, @{$tc->{args}});
        close($fh);
        is($output, $tc->{want}, 'output text matches');
        is($ddclient::emailbody, $tc->{want_email} // '', 'email content matches');
    }
}

my @logfmt_test_cases = (
    {
        desc => 'single argument is printed directly, not via sprintf',
        args => ['%%'],
        want => "DEBUG:   > %%\n",
    },
    {
        desc => 'multiple arguments are formatted via sprintf',
        args => ['%s', 'foo'],
        want => "DEBUG:   > foo\n",
    },
    {
        desc => 'single argument with context',
        args => [ctx => 'context', '%%'],
        want => "DEBUG:   [context]> %%\n",
    },
    {
        desc => 'multiple arguments with context',
        args => [ctx => 'context', '%s', 'foo'],
        want => "DEBUG:   [context]> foo\n",
    },
);

for my $tc (@logfmt_test_cases) {
    my $got;
    open(my $fh, '>', \$got);
    local $ddclient::globals{debug} = 1;
    %ddclient::globals if 0;
    {
        local *STDERR = $fh;
        ddclient::debug(@{$tc->{args}});
    }
    close($fh);
    is($got, $tc->{want}, $tc->{desc});
}

done_testing();
