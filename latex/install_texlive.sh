#!/bin/bash
set -e

#=============================================================================
# This script downloads and installs TeX Live in the most recent major release
# on Ubuntu 16.04 systems. It also sets up the global environment variables
# and creates and installs dummy packages for the APT package manager to
# satisfy dependencies of other packages.
# It also installs the following additional packages which are not included in
# the TeX Live distribution (either due to licensing issues or due to the
# TeX Live packaging policy):
#   * acrotex
#       create fillable PDF forms, e.g. with electronic signature fields.
#=============================================================================

CTAN_SERVER_URL="http://ctan.space-pro.be/tex-archive"


# ref: https://askubuntu.com/a/30157/8698
if ! [ $(id -u) = 0 ]; then
   echo "ERROR: This script needs to be run as root (with sudo)." >&2
   exit 1
fi

if [ $SUDO_USER ]; then
    REAL_USER=$SUDO_USER
else
    REAL_USER=$(whoami)
fi


function create_and_install_deb_package {
    cat > ${1} << EOF
### Commented entries have reasonable defaults.
### Uncomment to edit them.
# Source: <source package name; defaults to package name>
Section: misc
Priority: optional
# Homepage: <enter URL here; no default>
Standards-Version: 3.9.2

Package: ${1}
Version: 9999
Maintainer: M.Eng. René Schwarz <mail@rene-schwarz.com>
# Pre-Depends: <comma-separated list of packages>
# Depends: <comma-separated list of packages>
# Recommends: <comma-separated list of packages>
# Suggests: <comma-separated list of packages>
# Provides: <comma-separated list of packages>
# Replaces: <comma-separated list of packages>
Architecture: all
# Copyright: <copyright file; defaults to GPL2>
# Changelog: <changelog file; defaults to a generic changelog>
# Readme: <README.Debian file; defaults to a generic one>
# Extra-Files: <comma-separated list of additional files for the doc directory>
# Files: <pair of space-separated paths; First is file to include, second is destination>
#  <more pairs, if there's more than one file to include. Notice the starting space>
Description: Dummy package for $1
 TeX Live has been installed manually on this system. This package just serves as a dummy package for the system's package management system to satisfy possible dependencies of other packages. It does not provide any real functionality.
EOF

    equivs-build ${1}
    dpkg -i ${1}_9999_all.deb
}

sudo -u ${REAL_USER} mkdir -p ~/build
cd ~/build
curl ${CTAN_SERVER_URL}/systems/texlive/tlnet/install-tl-unx.tar.gz -o tl-installer.tar.gz

EXTRACTED_DIR=`tar -tzf tl-installer.tar.gz | head -1 | cut -f1 -d"/"`
tar -xzvf tl-installer.tar.gz

TL_VERSION=`./$EXTRACTED_DIR/install-tl --version | head -2 | tail -1 | sed -e 's/TeX Live .* version //g'`
INSTALLER_VER=`echo $EXTRACTED_DIR | sed 's/install-tl-//g'`

mv tl-installer.tar.gz texlive-$TL_VERSION-$INSTALLER_VER.tar.gz
mv $EXTRACTED_DIR texlive-$TL_VERSION-$INSTALLER_VER

cd texlive-$TL_VERSION-$INSTALLER_VER

# create texlive.profile file
cat > texlive.profile << EOF
selected_scheme scheme-basic
TEXDIR /usr/local/texlive/${TL_VERSION}
TEXMFCONFIG ~/.texlive${TL_VERSION}/texmf-config
TEXMFHOME ~/texmf
TEXMFLOCAL /usr/local/texlive/texmf-local
TEXMFSYSCONFIG /usr/local/texlive/${TL_VERSION}/texmf-config
TEXMFSYSVAR /usr/local/texlive/${TL_VERSION}/texmf-var
TEXMFVAR ~/.texlive${TL_VERSION}/texmf-var
binary_x86_64-linux 1
instopt_adjustpath 0
instopt_adjustrepo 1
instopt_letter 0
instopt_portable 0
instopt_write18_restricted 1
tlpdbopt_autobackup 1
tlpdbopt_backupdir tlpkg/backups
tlpdbopt_create_formats 1
tlpdbopt_desktop_integration 1
tlpdbopt_file_assocs 1
tlpdbopt_generate_updmap 0
tlpdbopt_install_docfiles 1
tlpdbopt_install_srcfiles 1
tlpdbopt_post_code 1
tlpdbopt_sys_bin /usr/local/bin
tlpdbopt_sys_info /usr/local/share/info
tlpdbopt_sys_man /usr/local/share/man
tlpdbopt_w32_multi_user 1
EOF

# begin TeX Live installation
./install-tl --location ${CTAN_SERVER_URL}/systems/texlive/tlnet --profile=texlive.profile

# environment variables
cat >> /etc/environment << EOF

export PATH=\$PATH:/usr/local/texlive/${TL_VERSION}/bin/x86_64-linux
export INFOPATH=\$INFOPATH:/usr/local/texlive/${TL_VERSION}/texmf-dist/doc/info
export MANPATH=\$MANPATH:/usr/local/texlive/${TL_VERSION}/texmf-dist/doc/man
EOF
ln -s /usr/local/texlive/${TL_VERSION} /usr/local/texlive/current

# create dummy packages
apt-get install -y equivs
mkdir -p dummy_packages
cd dummy_packages
apt-cache pkgnames texlive | sort | while read -r line ; do
    create_and_install_deb_package ${line}
done
create_and_install_deb_package tex4ht
create_and_install_deb_package tex4ht-common
create_and_install_deb_package tex-common
create_and_install_deb_package tex-gyre

cd ..
chown -R ${REAL_USER}:${REAL_USER} .
cd ..
chown ${REAL_USER}:${REAL_USER} texlive-$TL_VERSION-$INSTALLER_VER.tar.gz

# source new environment variables
source /etc/environment

curl https://tools.rene-schwarz.com/texlive-repo/tl-dignative.public.key -o tl-dignative.public.key
tlmgr key add tl-dignative.public.key
rm tl-dignative.public.key
tlmgr repository add https://tools.rene-schwarz.com/texlive-repo/${TL_VERSION} DigNative
tlmgr pinning add DigNative acrotex
tlmgr install acrotex

luaotfload-tool --update

rm -fR /usr/local/texlive/current/texmf-dist/doc

exit 0
