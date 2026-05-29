#!/bin/bash
# install.sh — Interactive installer for ddclient
#
# Detects your OS, installs missing dependencies, configures, builds, and
# installs ddclient.  Run as a normal user; sudo is invoked only when needed.
#
# Usage: bash install.sh [--non-interactive]

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
if [ -t 1 ]; then
    RED='\033[0;31m' YELLOW='\033[1;33m' GREEN='\033[0;32m'
    CYAN='\033[0;36m' BOLD='\033[1m' RESET='\033[0m'
else
    RED='' YELLOW='' GREEN='' CYAN='' BOLD='' RESET=''
fi

info()    { printf "${CYAN}==> ${RESET}%s\n" "$*"; }
success() { printf "${GREEN}✓  ${RESET}%s\n" "$*"; }
warn()    { printf "${YELLOW}!  ${RESET}%s\n" "$*" >&2; }
die()     { printf "${RED}✗  ${RESET}%s\n" "$*" >&2; exit 1; }

INTERACTIVE=true
[[ "${1:-}" == "--non-interactive" ]] && INTERACTIVE=false

ask() {
    # ask QUESTION [DEFAULT:y]
    local question="$1" default="${2:-y}"
    $INTERACTIVE || { [[ "$default" == "y" ]]; return; }
    local prompt
    [[ "$default" == "y" ]] && prompt="[Y/n]" || prompt="[y/N]"
    printf "${BOLD}%s %s ${RESET}" "$question" "$prompt"
    read -r answer
    case "${answer,,}" in
        y|yes|"") [[ "$default" == "y" ]] ;;
        n|no)     [[ "$default" == "n" ]] ;;
        *)        [[ "$default" == "y" ]] ;;
    esac
}

ask_value() {
    # ask_value PROMPT DEFAULT
    local prompt="$1" default="$2"
    $INTERACTIVE || { echo "$default"; return; }
    printf "${BOLD}%s${RESET} [%s]: " "$prompt" "$default"
    read -r value
    echo "${value:-$default}"
}

# ── Detect OS / package manager ───────────────────────────────────────────────
PKG_MGR=""
INSTALL_CMD=""
OS_NAME=""

detect_os() {
    if command -v apt-get &>/dev/null; then
        PKG_MGR="apt"
        INSTALL_CMD="apt-get install -y"
        OS_NAME="Debian/Ubuntu"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
        INSTALL_CMD="dnf install -y"
        OS_NAME="Fedora/RHEL"
    elif command -v yum &>/dev/null; then
        PKG_MGR="yum"
        INSTALL_CMD="yum install -y"
        OS_NAME="CentOS/RHEL"
    elif command -v pacman &>/dev/null; then
        PKG_MGR="pacman"
        INSTALL_CMD="pacman -S --noconfirm"
        OS_NAME="Arch Linux"
    elif command -v zypper &>/dev/null; then
        PKG_MGR="zypper"
        INSTALL_CMD="zypper install -y"
        OS_NAME="openSUSE"
    elif command -v brew &>/dev/null; then
        PKG_MGR="brew"
        INSTALL_CMD="brew install"
        OS_NAME="macOS (Homebrew)"
    else
        warn "Could not detect a supported package manager."
        warn "You will need to install dependencies manually."
        OS_NAME="Unknown"
    fi
}

# ── Package name maps by package manager ─────────────────────────────────────
# Usage: pkg_name LOGICAL_NAME
pkg_name() {
    local name="$1"
    case "$PKG_MGR:$name" in
        apt:curl)           echo "curl" ;;
        apt:perl)           echo "perl" ;;
        apt:make)           echo "make" ;;
        apt:autoconf)       echo "autoconf" ;;
        apt:automake)       echo "automake" ;;
        apt:perl-json-pp)   echo "libjson-pp-perl" ;;

        dnf:curl|yum:curl)            echo "curl" ;;
        dnf:perl|yum:perl)            echo "perl" ;;
        dnf:make|yum:make)            echo "make" ;;
        dnf:autoconf|yum:autoconf)    echo "autoconf" ;;
        dnf:automake|yum:automake)    echo "automake" ;;
        dnf:perl-json-pp|yum:perl-json-pp) echo "perl-JSON-PP" ;;

        pacman:curl)        echo "curl" ;;
        pacman:perl)        echo "perl" ;;
        pacman:make)        echo "make" ;;
        pacman:autoconf)    echo "autoconf" ;;
        pacman:automake)    echo "automake" ;;
        pacman:perl-json-pp) echo "perl-json-pp" ;;

        zypper:curl)        echo "curl" ;;
        zypper:perl)        echo "perl" ;;
        zypper:make)        echo "make" ;;
        zypper:autoconf)    echo "autoconf" ;;
        zypper:automake)    echo "automake" ;;
        zypper:perl-json-pp) echo "perl-JSON-PP" ;;

        brew:curl)          echo "curl" ;;
        brew:perl)          echo "perl" ;;
        brew:make)          echo "make" ;;
        brew:autoconf)      echo "autoconf" ;;
        brew:automake)      echo "automake" ;;
        brew:perl-json-pp)  echo "" ;;  # JSON::PP is bundled with Perl on macOS

        *) echo "$name" ;;  # fall back to the logical name
    esac
}

# ── Dependency checking and installation ─────────────────────────────────────
MISSING_PKGS=()

check_cmd() {
    # check_cmd COMMAND LOGICAL_PKG_NAME DESCRIPTION
    local cmd="$1" pkg="$2" desc="$3"
    if ! command -v "$cmd" &>/dev/null; then
        warn "Missing: $desc ($cmd)"
        local pname
        pname=$(pkg_name "$pkg")
        [[ -n "$pname" ]] && MISSING_PKGS+=("$pname")
        return 1
    fi
    return 0
}

check_perl_version() {
    if ! command -v perl &>/dev/null; then
        return 1
    fi
    if ! perl -e 'use 5.010001; 1' &>/dev/null; then
        die "Perl 5.10.1 or newer is required.  Found: $(perl -e 'print $^V')"
    fi
    return 0
}

check_perl_module() {
    # check_perl_module MODULE [LOGICAL_PKG_NAME]
    local mod="$1" pkg="${2:-}"
    if ! perl -e "use $mod; 1" &>/dev/null; then
        warn "Missing Perl module: $mod"
        if [[ -n "$pkg" ]]; then
            local pname
            pname=$(pkg_name "$pkg")
            [[ -n "$pname" ]] && MISSING_PKGS+=("$pname")
        fi
        return 1
    fi
    return 0
}

install_missing() {
    if [[ ${#MISSING_PKGS[@]} -eq 0 ]]; then
        return 0
    fi
    info "The following packages need to be installed: ${MISSING_PKGS[*]}"
    if ! ask "Install them now?"; then
        die "Cannot continue without required dependencies."
    fi
    if [[ "$PKG_MGR" == "brew" ]]; then
        $INSTALL_CMD "${MISSING_PKGS[@]}"
    else
        sudo $INSTALL_CMD "${MISSING_PKGS[@]}"
    fi
    MISSING_PKGS=()
}

# ── Determine build type ──────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IS_GIT_CLONE=false
HAS_CONFIGURE=false

[[ -f "$SCRIPT_DIR/ddclient.in" && -d "$SCRIPT_DIR/.git" ]] && IS_GIT_CLONE=true
[[ -f "$SCRIPT_DIR/configure" ]] && HAS_CONFIGURE=true

# ── Banner ────────────────────────────────────────────────────────────────────
printf "\n${BOLD}${CYAN}ddclient installer${RESET}\n"
printf "══════════════════════════════════════════════════════════════\n\n"

detect_os
info "Detected OS: $OS_NAME"

# Decide whether we need to run autogen.
NEED_AUTOGEN=false
if $IS_GIT_CLONE; then
    if ! $HAS_CONFIGURE; then
        info "Build type: git clone — configure absent, will run autogen"
        NEED_AUTOGEN=true
    else
        info "Build type: git clone — configure present"
        if ask "Re-run autogen? (do this after pulling upstream changes)" "n"; then
            NEED_AUTOGEN=true
        fi
    fi
elif $HAS_CONFIGURE; then
    info "Build type: release tarball (configure already present)"
else
    die "Could not find ddclient.in or configure.  Run this script from the ddclient source directory."
fi

# ── Check / install dependencies ─────────────────────────────────────────────
printf "\n${BOLD}Checking dependencies...${RESET}\n"

# Detect GNU make: prefer gmake (needed on BSD/macOS), fall back to make.
MAKE=""
for candidate in gmake make; do
    if command -v "$candidate" &>/dev/null; then
        # GNU make identifies itself with --version; BSD make does not.
        if "$candidate" --version 2>/dev/null | grep -q "GNU Make"; then
            MAKE="$candidate"
            break
        fi
    fi
done
if [[ -z "$MAKE" ]]; then
    warn "GNU make not found; will try 'make' and hope for the best."
    MAKE="make"
    MISSING_PKGS+=("$(pkg_name make)")
else
    success "GNU make: $MAKE ($(${MAKE} --version | head -1))"
fi

check_cmd curl curl "curl (required for HTTP requests)"
check_cmd perl perl "Perl interpreter"

if $NEED_AUTOGEN; then
    check_cmd autoconf autoconf "GNU Autoconf (required for git builds)"
    check_cmd automake automake "GNU Automake (required for git builds)"
fi

install_missing

# Check Perl version separately (needs perl installed first)
check_perl_version || die "Perl 5.10.1+ is required."
success "Perl $(perl -e 'print $^V') found"

# Core Perl modules (required at runtime)
MISSING_PKGS=()
printf "\n${BOLD}Checking required Perl modules...${RESET}\n"
check_perl_module "Data::Dumper"
check_perl_module "File::Basename"
check_perl_module "File::Path"
check_perl_module "File::Temp"
check_perl_module "Getopt::Long"
check_perl_module "Socket"
check_perl_module "Sys::Hostname"
check_perl_module "version 0.77"
install_missing
success "All required Perl modules present"

# Optional: JSON::PP for JSON-based protocols (cloudflare, digitalocean, etc.)
printf "\n${BOLD}Checking optional Perl modules...${RESET}\n"
if ! check_perl_module "JSON::PP" "perl-json-pp"; then
    if ask "Install JSON::PP? (needed for Cloudflare, DigitalOcean, Hetzner, and other JSON-based providers)" "y"; then
        if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
            jsonpp_pkg="${MISSING_PKGS[0]}"
            if [[ -n "$jsonpp_pkg" ]]; then
                if [[ "$PKG_MGR" == "brew" ]]; then
                    $INSTALL_CMD "$jsonpp_pkg"
                else
                    sudo $INSTALL_CMD "$jsonpp_pkg" || {
                        warn "Package install failed; trying CPAN..."
                        sudo perl -MCPAN -e "install JSON::PP"
                    }
                fi
            fi
        fi
        MISSING_PKGS=()
    else
        warn "JSON::PP not installed — JSON-based providers (Cloudflare, DigitalOcean, etc.) will not work."
    fi
else
    success "JSON::PP found"
fi

# ── Configure options ─────────────────────────────────────────────────────────
printf "\n${BOLD}Configure options${RESET}\n"
printf "The defaults below work for most Linux systems.\n\n"

PREFIX=$(ask_value "Install prefix" "/usr")
SYSCONFDIR=$(ask_value "Config directory (sysconfdir)" "/etc")
LOCALSTATEDIR=$(ask_value "State directory (localstatedir)" "/var")

# Derive confdir: ddclient keeps its config in ${sysconfdir}/ddclient by default
CONFDIR="${SYSCONFDIR}/ddclient"
info "ddclient.conf will live in: $CONFDIR"

# ── Build ─────────────────────────────────────────────────────────────────────
cd "$SCRIPT_DIR"

if $NEED_AUTOGEN; then
    printf "\n${BOLD}Running autogen...${RESET}\n"
    ./autogen
    success "autogen complete"
fi

printf "\n${BOLD}Running configure...${RESET}\n"
./configure \
    --prefix="$PREFIX" \
    --sysconfdir="$SYSCONFDIR" \
    --localstatedir="$LOCALSTATEDIR"
success "configure complete"

printf "\n${BOLD}Building ddclient...${RESET}\n"
$MAKE
success "Build complete"

# ── Optional: run tests ───────────────────────────────────────────────────────
if ask "Run test suite? (recommended, takes ~30 seconds)" "y"; then
    printf "\n${BOLD}Running tests...${RESET}\n"
    if $MAKE VERBOSE=1 check; then
        success "All tests passed"
    else
        warn "Some tests failed.  This may be due to optional dependencies."
        ask "Continue with installation anyway?" "y" || die "Installation cancelled."
    fi
fi

# ── Install ───────────────────────────────────────────────────────────────────
printf "\n${BOLD}Installing ddclient to ${PREFIX}...${RESET}\n"
if [[ "$PREFIX" == /usr* || "$PREFIX" == /opt* ]]; then
    info "This step requires sudo."
    sudo $MAKE install
else
    $MAKE install
fi
success "ddclient installed to $PREFIX/bin/ddclient"

# ── Post-install: config file ─────────────────────────────────────────────────
printf "\n${BOLD}Post-install setup${RESET}\n"

CONFIG_FILE="${SYSCONFDIR}/ddclient/ddclient.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
    info "No config file found at $CONFIG_FILE"
    if ask "Create a starter config file?"; then
        sudo mkdir -p "$(dirname "$CONFIG_FILE")"
        # The installed ddclient.conf is already placed by 'make install';
        # if for some reason it is absent, copy from source.
        if [[ ! -f "$CONFIG_FILE" ]] && [[ -f "$SCRIPT_DIR/ddclient.conf" ]]; then
            sudo cp "$SCRIPT_DIR/ddclient.conf" "$CONFIG_FILE"
        fi
        info "Edit $CONFIG_FILE to configure your dynamic DNS provider."
        info "See https://ddclient.net for provider-specific examples."
    fi
else
    success "Config file already exists: $CONFIG_FILE"
fi

# ── Post-install: systemd service ────────────────────────────────────────────
SYSTEMD_UNIT_SRC="$SCRIPT_DIR/sample-etc_systemd.service"
SYSTEMD_UNIT_DST="/etc/systemd/system/ddclient.service"

if command -v systemctl &>/dev/null && [[ -f "$SYSTEMD_UNIT_SRC" ]]; then
    if [[ ! -f "$SYSTEMD_UNIT_DST" ]]; then
        if ask "Install and enable systemd service?"; then
            sudo cp "$SYSTEMD_UNIT_SRC" "$SYSTEMD_UNIT_DST"
            sudo systemctl daemon-reload
            sudo systemctl enable ddclient.service
            if ask "Start ddclient now?"; then
                sudo systemctl start ddclient.service
                success "ddclient service started"
            else
                info "Start it later with: sudo systemctl start ddclient.service"
            fi
        fi
    else
        success "systemd service already installed: $SYSTEMD_UNIT_DST"
    fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n${GREEN}${BOLD}Installation complete!${RESET}\n\n"
printf "  Binary:  %s/bin/ddclient\n"  "$PREFIX"
printf "  Config:  %s\n"               "$CONFIG_FILE"
printf "  Docs:    https://ddclient.net\n\n"
printf "Next steps:\n"
printf "  1. Edit %s\n"                "$CONFIG_FILE"
printf "  2. Test with: ddclient --foreground --debug --verbose\n\n"
