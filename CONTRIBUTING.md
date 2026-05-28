# How to Contribute

Thank you for your interest in making ddclient better! This document
provides guidelines to make the contribution process as smooth as
possible.

To contribute changes, please open a pull request against the
[ddclient GitHub project](https://github.com/ddclient/ddclient/pulls).

## Developer Certificate of Origin

All contributions are subject to the [Developer Certificate of Origin
v1.1](https://developercertificate.org/), copied below. A
`Signed-off-by` line in each commit message is **not** required.

```
Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
1 Letterman Drive
Suite D4700
San Francisco, CA, 94129

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.


Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.
```

## Style

  * Above all else, try to match the existing style surrounding your
    edits.
  * No trailing whitespace.
  * Use spaces, not tabs.
  * Indentation level is 4 spaces.
  * Use parentheses for Perl function invocations: `print($fh "foo")`
    not `print $fh "foo"`
  * When reasonable, break lines longer than 99 characters. Rationale:
    - Imposing a limit makes it practical to open many side-by-side
      files or terminals without worrying about horizontal scrolling.
    - 99 is used instead of 100 so that the +/- column added by
      unified diff does not cause wrapping in 100 column wide
      terminals.
  * Add spaces to vertically align adjacent lines of code when doing
    so improves readability.

The following [perltidy](https://metacpan.org/pod/perltidy) command is
not perfect but it can get you close to our preferred style:

```shell
perltidy -l=99 -conv -ci=4 -ola -ce -nbbc -kis -pt=2 -b ddclient
```

## Git Hygiene

  * Please keep your pull request commits rebased on top of `main`.
  * Please use `git rebase -i` to make your commits easy to review:
    - Put unrelated changes in separate commits
    - Squash your fixup commits
  * Write your commit message in imperative mood, and explain *why*
    the change is made (unless obvious) in addition to *what* is
    changed.

If you are not very comfortable with Git, we encourage you to read
[Pro Git](https://git-scm.com/book) by Scott Chacon and Ben Straub
(freely available online).

## Unit tests

Always add tests for your changes when feasible.

To run the ddclient test suite:

  1. Install GNU Autoconf and Automake
  2. Run: `./autogen && ./configure && make VERBOSE=1 check`

To add a new test script:

  1. Create a new `t/*.pl` file with contents like this:

     ```perl
     use Test::More;
     # Your test dependencies go here.

     SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
     eval { require 'ddclient'; } or BAIL_OUT($@);

     # Your tests go here.

     done_testing();
     ```

     See the documentation for
     [Test::More](https://perldoc.perl.org/Test/More.html) for
     details.

  2. Add your script to the `handwritten_tests` variable in
     `Makefile.am`.

  3. If your test script requires 3rd party modules, add the modules
     to the list of test modules in `configure.ac` and re-run
     `./autogen && ./configure`. Be sure to skip the tests if the
     module is not available. For example:

     ```perl
     eval { require Foo::Bar; } or plan(skip_all => $@);
     ```

## Integration tests

Integration tests verify that a protocol implementation works correctly against
the real provider API. They complement the unit tests in `t/` by catching API
drift, authentication changes, and documentation errors that mock tests cannot
detect.

### Requirement for new protocols

A pull request that adds a new protocol must include an integration test. The
test does not need to pass in CI before the pull request is reviewed, but the
corresponding credentials must be added to the upstream repository's GitHub
Actions secrets before the pull request is merged.

The rationale: the developer already has a working provider account at the time
they write the protocol. Capturing the credential at that point costs almost
nothing; doing so later is easy to defer indefinitely.

### Writing an integration test

Integration tests live in `t/integration/`. They follow the same structure as
unit tests, with the addition of a credential check at the top that skips the
test when the required environment variables are not set:

```perl
use Test::More;
SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

my $key  = $ENV{DDCLIENT_TEST_MYPROVIDER_KEY}
    or plan(skip_all => 'DDCLIENT_TEST_MYPROVIDER_KEY not set');
my $zone = $ENV{DDCLIENT_TEST_MYPROVIDER_ZONE}
    or plan(skip_all => 'DDCLIENT_TEST_MYPROVIDER_ZONE not set');
```

The test should:

  1. Update a known A or AAAA record in the test zone to a known IP address,
     using ddclient's protocol implementation directly (not via the `ddclient`
     binary).
  2. Verify the update succeeded by querying the provider API or resolving the
     record via DNS.
  3. Restore the record to its original value, or delete it, after the test
     completes — whether the test passed or failed.

### Test zones

Each provider's integration test operates against a subdomain of
`ci.ddclient.net` whose NS records are delegated to that provider. For example,
`namesilo.ci.ddclient.net` is delegated to NameSilo's nameservers. This means
the project requires only one registered domain regardless of how many providers
are under test.

The zone to use is supplied through the `DDCLIENT_TEST_<PROTOCOL>_ZONE`
environment variable so that contributors can substitute their own domain when
developing locally.

### Credential naming

Credentials are passed through environment variables named
`DDCLIENT_TEST_<PROTOCOL>_<VAR>`, where `<PROTOCOL>` is the protocol name in
uppercase and `<VAR>` describes the credential. Examples:

  * `DDCLIENT_TEST_NAMESILO_KEY` — NameSilo API key
  * `DDCLIENT_TEST_NAMECOM_LOGIN` and `DDCLIENT_TEST_NAMECOM_PASSWORD`
  * `DDCLIENT_TEST_NETCUP_LOGIN`, `DDCLIENT_TEST_NETCUP_APIKEY`,
    `DDCLIENT_TEST_NETCUP_PASSWORD`

### Credential management

Credentials for the upstream test zones are stored as GitHub Actions secrets in
the `ddclient/ddclient` repository. A maintainer adds the secrets before merging
the pull request. Contributors developing a new protocol should use their own
provider account and test domain when running integration tests locally.

### When integration tests run

Integration tests are excluded from the standard `make check` run. They run in
two situations:

  * **Nightly**, against the `main` branch.
  * **On a pull request**, when a maintainer approves the run. Because this
    repository is public, GitHub does not expose secrets to workflows triggered
    by pull requests from forks. The integration test job uses the
    `pull_request_target` event and a [GitHub Environment][gh-env] configured to
    require maintainer approval. A maintainer approves the run after reviewing
    the pull request code, satisfying themselves that it will not misuse the
    credentials. The workflow definition always comes from `main`, not from the
    pull request branch, so a contributor cannot modify the CI to exfiltrate
    secrets.

Tests for a given protocol are skipped automatically when the corresponding
secrets are absent, so the CI job does not need to be updated when a new
protocol is added.

[gh-env]: https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment

## Compatibility

We strive to find the right balance between features, code
maintainability, and broad platform support. To that end, please limit
yourself to Perl language features and modules available on the
following platforms:

  * Debian oldstable and newer
  * Ubuntu, [all maintained
    releases](https://ubuntu.com/about/release-cycle)
  * Fedora, [all maintained
    releases](https://fedoraproject.org/wiki/Fedora_Release_Life_Cycle)
  * CentOS, [all maintained
    releases](https://wiki.centos.org/About/Product)
  * Red Hat Enterprise Linux, [all maintained
    releases](https://access.redhat.com/support/policy/updates/errata/)

See https://pkgs.org for available modules and versions.

Exceptions:
  * You may depend on modern language features or modules for new
    functionality when no feasible alternative exists, as long as the
    new dependency does not break existing functionality on old
    plaforms.
  * Test scripts may depend on arbitrary modules as long as the tests
    are skipped if the modules are not available. Effort should be
    taken to only use modules that are broadly available.

You may use any core Perl module as long as it is available in all
versions of Perl we support. (Though please make sure it is listed in
the appropriate `configure.ac` check.) Stated another way: We are not
interested in supporting platforms that lack some core Perl modules,
unless doing so is trivial.

All shell scripts should conform with [POSIX Issue 7 (2018
edition)](https://pubs.opengroup.org/onlinepubs/9699919799/) or later.

## Prefer Revert and Redo, Not Fix

Suppose a recent change broke something or otherwise needs
refinement. It is tempting to simply push a fix, but it is usually
better to revert the original change then redo it:

  * There is less subjectivity with a revert, so you are more likely
    to get a quick approval and merge. You can quickly "stop the
    bleeding" while you and the project maintainers debate about the
    best way to fix the problem with the original commit.
  * It is easier and less mistake-prone to cherry-pick a single commit
    (the redo commit) than two commits (the original commit plus the
    required fix).
  * Someone using blame to review the history will see the redo
    commit, not the buggy original commit.

## For ddclient Project Maintainers

### Merging Pull Requests

To facilitate reviews and code archaeology, `main` should have a
semi-linear commit history like this:

```
*   f4e6e90 sandro.jaeckel@gmail.com 2020-05-31 07:29:51 +0200 (main)
|\          Merge pull request #142 from rhansen/config-line-format
| * 30180ed rhansen@rhansen.org 2020-05-30 13:09:38 -0400
|/          Expand comment documenting config line format
*   01a746c rhansen@rhansen.org 2020-05-30 23:47:54 -0400
|\          Merge pull request #138 from rhansen/dyndns-za-net
| * 08c2b6c rhansen@rhansen.org 2020-05-29 14:44:57 -0400
|/          Replace dydns.za.net with dyndns.za.net
*   d65805b rhansen@rhansen.org 2020-05-30 22:30:04 -0400
|\          Merge pull request #140 from ddclient/fix-interpolation
| * babbef1 sandro.jaeckel@gmail.com 2020-05-30 04:03:44 +0200
|/          Fix here doc interpolation
*   6ae69a1 rhansen@rhansen.org 2020-05-30 22:23:57 -0400
|\          Merge pull request #141 from ddclient/show-debug-ssl
| * 096288e sandro.jaeckel@gmail.com 2020-05-30 04:42:27 +0200
| |         Expand tabs to spaces in vim
| * 0206262 sandro.jaeckel@gmail.com 2020-05-30 04:40:58 +0200
|/          Show debug connection settings after evaluating use-ssl
...
```

See https://stackoverflow.com/a/15721436 for an explanation of the
benefits.

This semi-linear style is mostly useful for multi-commit pull
requests. For single-commit pull requests, GitHub's "Squash and merge"
and "Rebase and merge" options are fine, though this approach still
has value:

  * The merge commit's commit message can link to the pull request
    or contain other contextual information.
  * It's easier to see who merged the PR (just look at the merge
    commit author.)
  * You can easily see both the original author timestamp (when the
    change was made) and the merge timestamp (when it went live).

To achieve a history like the above, the pull request must be rebased
onto `main` before merging. Unfortunately, GitHub does not have a
one-click way to do this (the "Rebase and merge" option does a
fast-forward merge, which is not what we want). See
[isaacs/github#1143](https://github.com/isaacs/github/issues/1143) and
[isaacs/github#1017](https://github.com/isaacs/github/issues/1017). Until
GitHub adds that feature, it has to be done manually:

```shell
# Set this to the name of the GitHub user or project that owns the
# fork used for the pull request:
PR_USER=

# Set this to the name of the branch in the fork used for the pull
# request:
PR_BRANCH=

# The commands below assume that `origin` refers to the
# ddclient/ddclient repository
git remote set-url origin git@github.com:ddclient/ddclient.git

# Add a remote for the fork used in the PR
git remote add "${PR_USER:?}" git@github.com:"${PR_USER:?}"/ddclient

# Fetch the latest commits for the PR and ddclient main
git remote update -p

# Switch to the pull request branch
git checkout -b "${PR_USER:?}-${PR_BRANCH:?}" "${PR_USER:?}/${PR_BRANCH:?}"

# Rebase the commits (optionally using -i to clean up history) onto
# the current ddclient main branch
git rebase origin/main

# Force update the contributor's fork. This will only work if the
# contributor has checked the "Allow edits by maintainers" box in the
# PR. If not, you will have to manually merge the rebased commits.
git push -f

# If the force push was successful, you can now go into the GitHub UI
# and merge using the "Create a merge request" option.
#
# If the force push failed because the contributor did not check
# "Allow edits by maintainers", or if you prefer to merge manually,
# continue with the next steps.

# Switch to the local main branch
git checkout main

# Make sure the local main branch is up to date
git merge --ff-only origin/main

# Merge in the rebased pull request branch **WITHOUT DOING A
# FAST-FORWARD MERGE**
git merge --no-ff "${PR_USER:?}-${PR_BRANCH:?}"

# Review the commits before pushing
git log --graph --oneline --decorate origin/main..

# Push to ddclient main
git push origin main
```
