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
        args => [label => 'LBL:', 'foo'],
        want => "LBL:     > foo\n",
    },
    {
        desc => 'multi-line label',
        args => [label => 'LBL:', "foo\nbar"],
        want => "LBL:     > foo\nLBL:       bar\n",
    },
    {
        desc => 'single-line long label',
        args => [label => 'VERY LONG LABEL:', 'foo'],
        want => "VERY LONG LABEL: > foo\n",
    },
    {
        desc => 'multi-line long label',
        args => [label => 'VERY LONG LABEL:', "foo\nbar"],
        want => "VERY LONG LABEL: > foo\nVERY LONG LABEL:   bar\n",
    },
    {
        desc => 'single line, no label, file',
        args => ['foo'],
        file => 'name',
        want => "file name: > foo\n",
    },
    {
        desc => 'single line, no label, file, and line number',
        args => ['foo'],
        file => 'name',
        lineno => 42,
        want => "file name, line 42: > foo\n",
    },
    {
        desc => 'single line, label, file, and line number',
        args => [label => 'LBL:', 'foo'],
        file => 'name',
        lineno => 42,
        want => "LBL:     file name, line 42: > foo\n",
    },
    {
        desc => 'multiple lines, label, file, and line number',
        args => [label => 'LBL:', "foo\nbar"],
        file => 'name',
        lineno => 42,
        want => "LBL:     file name, line 42: > foo\nLBL:     file name, line 42:   bar\n",
    },
);

for my $tc (@test_cases) {
    subtest $tc->{desc} => sub {
        $tc->{wantemail} //= '';
        my $output;
        open(my $fh, '>', \$output);
        $ddclient::emailbody = $tc->{init_email} // '';
        local $ddclient::file = $tc->{file} // '';
        $ddclient::file if 0;  # suppress spurious warning "Name used only once: possible typo"
        local $ddclient::lineno = $tc->{lineno} // '';
        $ddclient::lineno if 0;  # suppress spurious warning "Name used only once: possible typo"
        ddclient::logmsg(fh => $fh, @{$tc->{args}});
        close($fh);
        is($output, $tc->{want}, 'output text matches');
        is($ddclient::emailbody, $tc->{want_email} // '', 'email content matches');
    }
}

{
    my $output;
    open(my $fh, '>', \$output);
    local *STDERR = $fh;
    local $ddclient::globals{debug} = 1;
    ddclient::debug('%%');
    close($fh);
    is($output, "DEBUG:   > %%\n", 'single argument is printed directly, not via sprintf');
}

{
    my $output;
    open(my $fh, '>', \$output);
    local *STDERR = $fh;
    local $ddclient::globals{debug} = 1;
    ddclient::debug('%s', 'foo');
    close($fh);
    is($output, "DEBUG:   > foo\n", 'multiple arguments are formatted via sprintf');
}

done_testing();
