Name:           ddclient
Version:        %{rpm_version}
Release:        %{rpm_release}
Summary:        Dynamic DNS client

License:        GPL-2.0-or-later
URL:            https://github.com/ddclient/ddclient
Source0:        ddclient-%{upstream_version}.tar.gz

BuildArch:      noarch

BuildRequires:  automake
BuildRequires:  curl
BuildRequires:  findutils
BuildRequires:  make
BuildRequires:  perl-interpreter
BuildRequires:  perl(Data::Dumper)
BuildRequires:  perl(File::Basename)
BuildRequires:  perl(File::Path)
BuildRequires:  perl(File::Temp)
BuildRequires:  perl(Getopt::Long)
BuildRequires:  perl(Socket)
BuildRequires:  perl(Sys::Hostname)
BuildRequires:  perl(version) >= 0.77

Requires:       curl
Requires:       perl-interpreter
Requires:       perl(Data::Dumper)
Requires:       perl(File::Basename)
Requires:       perl(File::Path)
Requires:       perl(File::Temp)
Requires:       perl(Getopt::Long)
Requires:       perl(Socket)
Requires:       perl(Sys::Hostname)
Requires:       perl(version) >= 0.77

%description
ddclient is a Perl client used to update dynamic DNS entries for accounts
on many dynamic DNS services. It supports multiple protocols and can detect
your IP address from a variety of sources.


%prep
%autosetup -n %{name}-%{upstream_version}


%build
./autogen
%configure
%make_build


%install
%make_install
install -D -m 0644 sample-etc_systemd.service \
    %{buildroot}%{_unitdir}/ddclient.service
install -D -m 0644 sample-etc_cron.d_ddclient \
    %{buildroot}%{_sysconfdir}/cron.d/ddclient


%post
%systemd_post ddclient.service

%preun
%systemd_preun ddclient.service

%postun
%systemd_postun_with_restart ddclient.service


%files
%license COPYING
%doc README.md ChangeLog.md
%{_bindir}/ddclient
%config(noreplace) %attr(0600, root, root) %{_sysconfdir}/ddclient/ddclient.conf
%dir %{_localstatedir}/cache/ddclient
%{_unitdir}/ddclient.service
%{_sysconfdir}/cron.d/ddclient


%changelog
* Tue May 05 2026 Bryant Eadon <bryant.eadon@gmail.com> - 4.0.0-1
- Initial RPM packaging
