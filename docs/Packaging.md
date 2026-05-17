# Packaging

Author: [@beadon](https://github.com/beadon)\
Date: 2026-05-05

This document describes how ddclient is packaged for Linux distributions
and how the packaging workflow operates.

## Automated packaging

Two GitHub Actions workflows build and publish distribution packages
automatically whenever a release is published on GitHub. Both are also
triggerable manually via `workflow_dispatch` for testing.

| Workflow | File | Produces |
|---|---|---|
| Package RPM | [`.github/workflows/package-rpm.yml`](../.github/workflows/package-rpm.yml) | `.rpm` + `.src.rpm` |
| Package DEB | [`.github/workflows/package-deb.yml`](../.github/workflows/package-deb.yml) | `.deb` |

On each run each workflow:

1. Checks out the source at the release tag.
2. Builds the distribution tarball using the autotools build system
   (`./autogen && ./configure && make dist`).
3. Builds packages in parallel across distribution jobs (see
   [Supported distributions](#supported-distributions)).
4. Attaches all packages to the GitHub release as downloadable assets.

### Manual dispatch

Both workflows can be triggered manually without publishing a release,
which is useful for testing packaging changes on a branch before cutting a
release.

**Via the GitHub UI:**

1. Go to **Actions → Package RPM** (or **Package DEB**) on GitHub.
2. Click **Run workflow**, select the branch to build from, and click
   **Run workflow**.

**Via the `gh` CLI:**

```sh
# Run against the default branch
gh workflow run package-rpm.yml --repo ddclient/ddclient
gh workflow run package-deb.yml --repo ddclient/ddclient

# Run against a specific branch or tag
gh workflow run package-rpm.yml --repo ddclient/ddclient --ref my-branch
gh workflow run package-deb.yml --repo ddclient/ddclient --ref my-branch
```

When triggered this way packages are built and uploaded as workflow
artifacts (visible in the Actions run summary) but are **not** attached to
any release. The version is derived from whatever `make dist` produces on
the selected branch.

## Creating a release

Publishing a release on GitHub (i.e. not a draft) automatically triggers
the packaging workflow and attaches the resulting RPMs to the release.

### Via the GitHub UI

1. Go to **Releases → Draft a new release** on GitHub.
2. Enter the tag (e.g. `v4.0.1-rc.1` or `v4.0.1`) and title.
3. Write the release notes.
4. For a pre-release (alpha, beta, rc), check **Set as a pre-release**.
5. Click **Publish release**.

### Via the `gh` CLI

**Pre-release (alpha, beta, rc):**

```sh
gh release create v4.0.1-rc.1 \
  --repo ddclient/ddclient \
  --title "v4.0.1-rc.1" \
  --notes "Release candidate 1 for v4.0.1." \
  --prerelease
```

**Final release:**

```sh
gh release create v4.0.1 \
  --repo ddclient/ddclient \
  --title "v4.0.1" \
  --notes-from-tag
```

`--notes-from-tag` uses the annotated git tag message as the release notes.
To write notes inline use `--notes "..."` or `--notes-file changelog.md`
instead.

### Verifying the release artifacts

After the workflows complete, all package artifacts are attached to the release
and visible at:

```
https://github.com/ddclient/ddclient/releases/tag/v4.0.1-rc.1
```

To download and install a specific package to verify it:

```sh
# Fedora 44
curl -fsSL -O https://github.com/ddclient/ddclient/releases/download/v4.0.1-rc.1/ddclient-4.0.1-0.1.rc.1.fc44.noarch.rpm
sudo dnf install -y ./ddclient-4.0.1-0.1.rc.1.fc44.noarch.rpm
ddclient --version

# EPEL 9 (RHEL/AlmaLinux/Rocky 9)
curl -fsSL -O https://github.com/ddclient/ddclient/releases/download/v4.0.1-rc.1/ddclient-4.0.1-0.1.rc.1.el9.noarch.rpm
sudo dnf install -y ./ddclient-4.0.1-0.1.rc.1.el9.noarch.rpm
ddclient --version

# Debian 12 / Ubuntu 24.04
curl -fsSL -O https://github.com/ddclient/ddclient/releases/download/v4.0.1-rc.1/ddclient_4.0.1~rc.1-1_all.deb
sudo apt install -y ./ddclient_4.0.1~rc.1-1_all.deb
ddclient --version
```

## Supported distributions

### RPM-based

| Distribution | Container | Builds produced | EOL |
|---|---|---|---|
| Fedora 42 | `fedora:42` | noarch RPM + SRPM | 2026-05-27 |
| Fedora 43 | `fedora:43` | noarch RPM + SRPM | 2026-12-09 |
| Fedora 44 | `fedora:44` | noarch RPM + SRPM | 2027-06-02 |
| Fedora rawhide | `fedora:rawhide` | noarch RPM + SRPM | rolling |
| EPEL 8 (RHEL/AlmaLinux 8) | `almalinux:8` | noarch RPM + SRPM | 2029-03-01 |
| EPEL 9 (RHEL/AlmaLinux 9) | `almalinux:9` | noarch RPM + SRPM | 2032-05-31 |
| EPEL 10 (RHEL/AlmaLinux 10) | `almalinux:10` | noarch RPM + SRPM | 2035-05-31 |

The matrix in [`.github/workflows/package-rpm.yml`](../.github/workflows/package-rpm.yml) should be updated when Fedora releases
reach stable or end-of-life. See <https://endoflife.date/fedora> for Fedora
and <https://endoflife.date/almalinux> for EPEL/RHEL support windows.

### DEB-based

| Distribution | Container | Builds produced | EOL |
|---|---|---|---|
| Debian 12 (Bookworm) | `debian:12` | all.deb | 2028-06-10 |
| Debian 13 (Trixie) | `debian:13` | all.deb | ~2031 |
| Ubuntu 22.04 LTS (Jammy) | `ubuntu:22.04` | all.deb | 2027-04-01 |
| Ubuntu 24.04 LTS (Noble) | `ubuntu:24.04` | all.deb | 2029-04-01 |

The matrix in [`.github/workflows/package-deb.yml`](../.github/workflows/package-deb.yml) should be updated when Debian
or Ubuntu releases reach stable or end-of-life. See <https://endoflife.date/debian>
for Debian and <https://endoflife.date/ubuntu> for Ubuntu support windows.

## Version translation

ddclient uses [Semantic Versioning 2.0.0](https://semver.org/) with a
pre-release suffix separated by `-` and a post-release suffix separated by
`+`. Both RPM and Debian have their own conventions for encoding this.

### RPM

RPM forbids `-` in the `Version:` field, so the version is split at
the boundary and the suffix is moved into `Release:`.

| ddclient version | RPM `Version:` | RPM `Release:`         |
|------------------|----------------|------------------------|
| `4.0.0`          | `4.0.0`        | `1%{?dist}`            |
| `4.0.1-alpha`    | `4.0.1`        | `0.1.alpha%{?dist}`    |
| `4.0.1-beta.2`   | `4.0.1`        | `0.1.beta.2%{?dist}`   |
| `4.0.1-rc.3`     | `4.0.1`        | `0.1.rc.3%{?dist}`     |
| `4.0.1+r.2`      | `4.0.1`        | `1.r.2%{?dist}`        |

Pre-release versions (leading `0.` in `Release:`) sort before the final
release. Post-release versions sort after. This follows the
[Fedora packaging versioning guidelines](https://docs.fedoraproject.org/en-US/packaging-guidelines/Versioning/).

The `%{?dist}` macro in `Release:` is automatically expanded by the RPM
build system to a distribution tag derived from the build host — for
example `.fc44` on Fedora 44 or `.el9` on EPEL 9. This means each
per-distribution build gets a naturally unique filename at no extra effort:

```
ddclient-4.0.1-0.1.rc.1.fc44.noarch.rpm
ddclient-4.0.1-0.1.rc.1.el9.noarch.rpm
```

If `%{?dist}` expands to nothing (e.g. on a plain RHEL host without the
`redhat-rpm-config` macros), the dist tag is simply omitted from the
filename, which is harmless for local builds.

### Debian

#### The tilde (`~`) separator

The `~` (tilde) character has a special meaning in Debian version ordering:
a tilde sorts *before* anything, including the empty string. The full rule is:

```
A~B  <  A  <  A+B
```

ddclient uses this in two ways, both applied in the packaging workflow:

**1. Pre-release SemVer translation**

The SemVer `-` pre-release separator is replaced with `~` so that Debian
sees the correct ordering (`4.0.1~rc.1 < 4.0.1`). Post-release `+` suffixes
are left unchanged as they already sort after the base version.

**2. Distro-targeting suffix (`+CODENAMEn`)**

Each build appends `+<codename>n` to the Debian revision (e.g. `+bookworm1`,
`+jammy1`), giving every distribution a unique filename:

```
ddclient_4.0.1~rc.1-1+bookworm1_all.deb
ddclient_4.0.1~rc.1-1+jammy1_all.deb
```

`+` is used rather than `~` for two reasons:

- **GitHub release assets**: GitHub's API sanitizes `~` to `.` in release
  asset filenames, mangling the name users download. `+` is preserved as-is.
- **Semantic correctness**: `+` sorts *after* the base revision in Debian
  version ordering, which accurately reflects that this is a distro-specific
  build layered on top of the upstream release, not a pre-release of it.

The trailing integer `n` is a **distro-build counter**. It starts at `1` (not
`0`) because Debian version ordering treats `1` as the conventional first
revision — the same reason the package revision itself starts at `-1`. In
practice `n` will almost always stay at `1`. The only reason to increment it
is if a packaging defect is found after a release and the package needs to be
rebuilt for a specific distro without bumping the upstream version:

```
ddclient_4.0.1~rc.1-1+bookworm1_all.deb   ← original build
ddclient_4.0.1~rc.1-1+bookworm2_all.deb   ← rebuilt to fix a packaging bug
```

Users already running `+bookworm1` will receive `+bookworm2` via `apt upgrade`
without any change to the upstream version. Users on other distros are
unaffected. To trigger a distro rebuild, edit the workflow's `printf` line for
the relevant job and change the hardcoded `1` to `2`.

The codename is read at build time from `/etc/os-release` inside the container
(`VERSION_CODENAME`), so no mapping table needs to be maintained in the
workflow as new distributions are added.

#### Version table

| ddclient version | Debian `Version:` (Bookworm example)    |
|------------------|-----------------------------------------|
| `4.0.0`          | `4.0.0-1+bookworm1`                     |
| `4.0.1-alpha`    | `4.0.1~alpha-1+bookworm1`               |
| `4.0.1-beta.2`   | `4.0.1~beta.2-1+bookworm1`              |
| `4.0.1-rc.3`     | `4.0.1~rc.3-1+bookworm1`                |
| `4.0.1+r.2`      | `4.0.1+r.2-1+bookworm1`                 |

Replace `bookworm` with the target codename (`trixie`, `jammy`, `noble`, etc.)
for other distributions.

The Debian revision (`-1`) is always `1` for packages built directly from an
upstream release. The workflows do not validate or restrict the SemVer suffix —
any string after `-` is treated as a pre-release label and any string after `+`
is treated as a post-release label, passed through verbatim.

## Building a DEB locally

**On Debian or Ubuntu:**

```sh
sudo apt-get install -y automake curl debhelper dpkg-dev make perl
```

Build the distribution tarball and the DEB using [`packaging/debian/`](../packaging/debian/):

```sh
./autogen
./configure
make dist

TARBALL=$(ls ddclient-*.tar.gz)
UPSTREAM="${TARBALL#ddclient-}"; UPSTREAM="${UPSTREAM%.tar.gz}"

# Get distro codename and translate version
CODENAME=$(. /etc/os-release && echo "${VERSION_CODENAME}")
case "$UPSTREAM" in
  *-*) DEB_VERSION="${UPSTREAM%%-*}~${UPSTREAM#*-}-1+${CODENAME}1" ;;
  *)   DEB_VERSION="${UPSTREAM}-1+${CODENAME}1" ;;
esac

SRCDIR="ddclient-${UPSTREAM}"
tar xzf "$TARBALL"
cp -r packaging/debian "${SRCDIR}/debian"

printf 'ddclient (%s) %s; urgency=low\n\n  * Local build of upstream version %s.\n\n -- Local Builder <local@localhost>  %s\n' \
    "${DEB_VERSION}" "${CODENAME}" "${UPSTREAM}" "$(date -R)" \
    > "${SRCDIR}/debian/changelog"

cd "${SRCDIR}"
dpkg-buildpackage -b --no-sign
```

The resulting `.deb` will be in the parent directory (`../ddclient_*.deb`).
Install it with:

```sh
sudo apt install ../ddclient_${DEB_VERSION}_all.deb
```

## Building an RPM locally

**On Fedora:**

```sh
sudo dnf install -y automake curl findutils make rpm-build systemd-rpm-macros \
    perl-interpreter perl-Data-Dumper perl-File-Path perl-Getopt-Long \
    perl-Socket perl-Sys-Hostname perl-version
```

**On EPEL (RHEL/AlmaLinux/Rocky):** enable EPEL and CRB first, then install
with `--skip-broken` since some Perl modules are bundled into `perl-core`
rather than shipped as separate packages:

```sh
sudo dnf install -y 'dnf-command(config-manager)' epel-release
sudo dnf config-manager --set-enabled crb   # use 'powertools' on el8
sudo dnf install --skip-broken -y automake curl findutils make perl-core \
    rpm-build systemd-rpm-macros perl-interpreter perl-Data-Dumper \
    perl-File-Path perl-Getopt-Long perl-Socket perl-Sys-Hostname perl-version
```

Build the distribution tarball and the RPMs using [`packaging/rpm/ddclient.spec`](../packaging/rpm/ddclient.spec):

```sh
./autogen
./configure
make dist

TOPDIR="$(pwd)/rpmbuild"
mkdir -p "$TOPDIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

TARBALL=$(ls ddclient-*.tar.gz)
UPSTREAM="${TARBALL#ddclient-}"; UPSTREAM="${UPSTREAM%.tar.gz}"

case "$UPSTREAM" in
  *-*) RPM_VERSION="${UPSTREAM%%-*}"; LABEL="${UPSTREAM#*-}"; RPM_RELEASE="0.1.${LABEL}%{?dist}" ;;
  *+*) RPM_VERSION="${UPSTREAM%%+*}"; LABEL="${UPSTREAM#*+}"; RPM_RELEASE="1.${LABEL}%{?dist}" ;;
  *)   RPM_VERSION="$UPSTREAM"; RPM_RELEASE="1%{?dist}" ;;
esac

cp "$TARBALL" "$TOPDIR/SOURCES/"
cp packaging/rpm/ddclient.spec "$TOPDIR/SPECS/"

rpmbuild \
  --define "_topdir $TOPDIR" \
  --define "upstream_version ${UPSTREAM}" \
  --define "rpm_version ${RPM_VERSION}" \
  --define "rpm_release ${RPM_RELEASE}" \
  -ba "$TOPDIR/SPECS/ddclient.spec"
```

The resulting RPMs will be in `rpmbuild/RPMS/` and `rpmbuild/SRPMS/`.

## Adding a new distribution

### RPM-based (Fedora, AlmaLinux, RHEL)

For a new **Fedora** release, add the version number to the `fedora_version`
matrix in the `build-fedora` job in
[`.github/workflows/package-rpm.yml`](../.github/workflows/package-rpm.yml).

For a new **EPEL** release (RHEL/AlmaLinux/Rocky), add the major version to
the `epel_version` matrix in the `build-epel` job. No changes to the spec
file are needed in either case.

### DEB-based (Debian, Ubuntu)

For a new **Debian** release, add the version number to the `debian_version`
matrix in the `build-debian` job in
[`.github/workflows/package-deb.yml`](../.github/workflows/package-deb.yml).

For a new **Ubuntu** release, add the version (e.g. `"26.04"`) to the
`ubuntu_version` matrix in the `build-ubuntu` job. No changes to the
`packaging/debian/` files are needed in either case.

### Other package formats (Arch, etc.)

Add a new spec or build file under `packaging/<format>/` and a
corresponding workflow under `.github/workflows/package-<format>.yml`,
following the same pattern as the RPM or DEB workflow:

- Derive the version from the distribution tarball produced by `make dist`.
- Pass version components to the build tool rather than hardcoding them.
- Use `softprops/action-gh-release` to attach built packages to the release.
