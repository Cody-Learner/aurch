#!/bin/bash
# aurch-setup 2024-11-13
# dependencies:  base-devel arch-install-scripts git pacutils jshon mc sudo devtools paccat

set -euo pipefail


if	[[ $(id -u) != 0 ]]; then
	echo " Needs elevated privileges. Run with sudo."
	echo
	echo " FYI: This script uses the 'SUDO_USER' variable to set a symlink."
	echo "      The default 'secure_path' sudo configuration is broken."
	echo "      If you're having issues, the sudo 'secure_path' may need setup. ie: "
	echo "     '/etc/sudoers' line: Defaults secure_path=\"/existing/path/entries:/APPEND/PATH\""
	exit
fi

	[[ ! -v   BASEDIR  ]] && BASEDIR=/usr/local/aurch/base				# Set    BASEDIR if unset
	[[ ! -d ${BASEDIR} ]] && mkdir -p "${BASEDIR}"					# Create BASEDIR dir if not present
	[[ ! -v   AURREPO  ]] && AURREPO=/usr/local/aurch/repo				# Set    AURREPO if unset
	[[ ! -d ${AURREPO} ]] && mkdir -p "${AURREPO}"  2>/dev/null			# Create AURREPO dir if not present
	[[ ! -v REPONAME   ]] && REPONAME=aur						# Set    REPONAME if unset
	[[ ! -s ${BASEDIR}/.#ID ]] && mktemp -u XXX > "${BASEDIR}"/.#ID			# Create unique suffix file if not present


chroot="${BASEDIR}"/chroot-$(< "${BASEDIR}"/.#ID)					# HOST   path to chroot
chrbuilduser=/home/builduser								# CHROOT builduser home directory
homebuilduser="${chroot}"/home/builduser						# HOST   builduser home directory
czm=$(echo -e '\033[1;96m'":: aurch ==>"'\033[00m')					# Aurch color pointer
error=$(echo -e '\033[1;91m' "ERROR:" '\033[00m')					# Red 'ERROR' text.
line2=$(printf %"$(tput cols)"s |tr " " "-")						# Set line '---' to terminal width

#========================================================================================================================#

	echo "
	BASEDIR=${BASEDIR}
	AURREPO=${AURREPO}
	chroot=${chroot}
	chrbuilduser=${chrbuilduser}
	homebuilduser=${homebuilduser}" > "${BASEDIR}"/.#aurch-setup-vars

#========================================================================================================================#
help(){
cat << EOF
${line2}

NAME
		aurch-setup - sets up a system for aurch

DESCRIPTION
		Aurch-setup sets up an nspawn container for the aurch script to build AUR packages.
		Aurutils is installed and setup in the nspawn container.
		Sets up a local pacman repo for AUR packages on the host.


USAGE
		sudo aurch-setup [operation]

OPERATIONS
                -Sc  --setupcontainer	Sets up an nspawn container.
                -Sh  --setuphost	Sets up the host aur repo.
                -h   --help		Prints help.
                -V   --version		Prints aurch version.


EXAMPLES
		Setup an nspawn container for aurch:  sudo aurch-setup -Sc
		Setup host with a local AUR repo:     sudo aurch-setup -Sh

MISC
		Aurch-setup runtime messages will be proceeded with this:   ${czm}
		Aurch-setup runtime errors will be proceeded with this:     ${czm}${error}
		Aurch-setup prints additional important info while running.

${line2}
EOF
}
#========================================================================================================================#
check_depends(){

	echo "${czm} Checking dependencies for aurch and arch-install."
	pacman -S --needed --confirm base-devel arch-install-scripts git pacutils jshon mc sudo devtools paccat
	echo
}
#========================================================================================================================#
setup_chroot(){

	cd "${BASEDIR}"									|| { echo "[line ${LINENO}]" ; exit 1 ; }
	existing=$(find  "${BASEDIR}" -maxdepth 1 -type d -name "chroot-*" 2>/dev/null)

if      [[ -n ${existing} ]]; then
	echo "${czm}${error}An aurch chroot, '${chroot}' detected in '${BASEDIR}'."
	echo " If you want to setup a new aurch container, the following needs removed."
	echo " ${chroot}"
	echo " ${BASEDIR}/.#ID"
	exit
fi
	echo "${czm} Building aurch nspawn-container."
	sleep 2

	mkdir "${chroot}"

if      pacstrap -c "${chroot}" base base-devel git ; then

	echo "${czm} Pacstrap finished nspawn-container install."
	echo "${czm} Setting up container with builduser, colored shell prompts, header id's, and alias's."
	sleep 5

	cd "${chroot}"									|| { echo "[line ${LINENO}]" ; exit 1 ; }

	mkdir -p "${chroot}"/var/tmp/aurch						|| { echo "[line ${LINENO}]" ; exit 1 ; }
	systemd-nspawn -a -q    useradd -m -G wheel -s /bin/bash builduser
	systemd-nspawn -a -q    mkdir /build
	systemd-nspawn -a -q    chown -R builduser:builduser /build

	chmod 755 "${chroot}/build"
	chown -R :alpm "${chroot}/build"

	cat << 'EOF' >> "${chroot}"/etc/bash.bashrc

if	[[ $(whoami) == root ]]; then
	# Color bash prompt bold red
	PS1="\[\033[1;91m\][\u@\h \W]\\$ \[\e[0m\]"
	tput setaf 1
	echo " |_____________________________________| Root Aurch Container |______________________________________|"
	tput sgr0
fi

if	[[ $(whoami) == builduser ]]; then
	# Color bash prompt bold green
	PS1="\[\033[1;92m\][\u@\h \W]\\$ \[\e[0m\]"
	tput setaf 2
	echo " |___________________________________| Builduser Aurch Container |___________________________________|"
	tput sgr0
fi

alias sub='		su builduser; cd'
alias ls='		ls --color=auto -h --group-directories-first'
alias c='	reset; source /etc/bash.bashrc' # reset

	### PACMAN ALIASES ###

alias Syy='		sudo pacman --color=always -Syy'
alias Syu='		sudo pacman --color=always -Syu'
alias p='		pacman --color=always '
alias sp='		sudo pacman --color=always '
alias Q='		pacman --color=always -Q'
alias S='		sudo pacman --color=always -S'
alias R='		sudo pacman --color=always -Rns'
alias U='		sudo pacman --color=always -U'
alias F='		pacman --color=always -F'

EOF
	sed -e '/^PS1/s/^/#/g' -i "${homebuilduser}"/.bashrc

    else
	echo "${czm} Pacstrap failed."
fi
#----------------------------------------------------------------------------------------------
# set up container for aurch

	echo "${czm} Setting up container for building AUR packages."
	sleep 3
	cd "${BASEDIR}"								|| { echo "[line ${LINENO}]" ; exit 1 ; }

if	[[ -d  ${chroot}/build ]] && [[ -d ${homebuilduser} ]] ; then

	printf '%s\n' "%wheel ALL=(ALL) NOPASSWD: ALL"  > "${chroot}/etc/sudoers.d/01-sudoers-addendum"

	systemd-nspawn -a -q  -D "${chroot}"  -u builduser --chdir="${chrbuilduser}" --pipe \
	git clone https://aur.archlinux.org/aurutils.git

	systemd-nspawn -a -q  -D "${chroot}"  -u builduser --chdir="${chrbuilduser}"/aurutils --pipe \
	makepkg -sri --noconfirm

	cd "${chroot}"								|| { echo "[line ${LINENO}]" ; exit 1 ; }

	systemd-nspawn -a -q sed -i '$a\#'				/etc/pacman.conf
	systemd-nspawn -a -q sed -i '$a\[options]'			/etc/pacman.conf
	systemd-nspawn -a -q sed -i '$a\CacheDir    = /build'		/etc/pacman.conf
	systemd-nspawn -a -q sed -i '$a\CleanMethod = KeepInstalled'	/etc/pacman.conf
	systemd-nspawn -a -q sed -i '$a\[aur]'				/etc/pacman.conf
	systemd-nspawn -a -q sed -i '$a\SigLevel = Never TrustAll'	/etc/pacman.conf
	systemd-nspawn -a -q sed -i '$a\Server = file:///build'		/etc/pacman.conf		# SC2016 We don't want expansion here!
	systemd-nspawn -a -q sed -i '/CacheDir/s/^#//g'			/etc/pacman.conf
	systemd-nspawn -a -q sed -i '/Color/s/^#//g'			/etc/pacman.conf
	systemd-nspawn -a -q sed -i '/VerbosePkgLists/s/^#//g'		/etc/pacman.conf
	systemd-nspawn -a -q sed -i '/ParallelDownloads/s/^#//g'	/etc/pacman.conf


	cat <<-"EOF" > "${homebuilduser}/add-aur-repo"
	#!/bin/bash

	set -e
	repo-add /build/aur.db.tar.gz   $(find /home/builduser/aurutils/ -maxdepth 1 -type f -name aurutils*pkg.tar.zst)
	chmod 646 /build/aur.db.tar.gz
	chown builduser:alpm /build/aur.db.tar.gz
EOF
	systemd-nspawn -a -q  -D "${chroot}" --chdir="${chrbuilduser}" --pipe \
	chmod +x add-aur-repo

	systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}" --pipe \
	sudo ./add-aur-repo

	systemd-nspawn -a -q  -D "${chroot}" --pipe \
	pacman -Sy

	pacman	-r "${chroot}" \
		-b "${chroot}/var/lib/pacman/" \
		--config "${chroot}/etc/pacman.conf" \
		--noconfirm -Qq |
		nl > "${BASEDIR}/.#orig-pkgs.log"
												 	# Fix auto generated broken user gpg config.
	systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}" --pipe << EOF
	gpg --list-keys &>/dev/null
	mv /home/builduser/.gnupg/common.conf  /home/builduser/.gnupg/common.conf-BU

EOF

if	[[ -d /usr/local/aurch ]] && [[ ! -h /home/${SUDO_USER}/.aa-Aurch ]]; then
	ln -s /usr/local/aurch  "/home/${SUDO_USER}/.aa-Aurch"
fi

if	[[ -d "${BASEDIR}" ]]; then
	echo "To populate with variables run: 'aurch -Lv'" > "${BASEDIR}/.#aurch-vars"
fi

	echo
	cat <<-EOF | tee >( sed 's/\x1B\[[0-9;]*[A-Za-z]//g' >"${BASEDIR}/aurch.README")
	${czm} Aurch nspawn-container setup completed.
	${czm} Has base, base-devel, git, and aurutils installed.
	${czm} Container AUR repo is set up in ${chroot}/build.
	${czm} A symlink has been created from /usr/local/aurch to /home/${SUDO_USER}/.aa-Aurch
	${czm} User builduser is set up in container, no password required for sudo.
	${czm} Do not alter files proceeded with '#.' in base directory.
	${czm} This info has been printed to: /usr/local/aurch/base/aurch.README
EOF
	sleep 1
	echo "${czm} To proceed with setting up the required local AUR repo, run:  aurch-setup -Sh"
    else
	echo; echo "${czm} builduser setup failed in container."
fi
}
#========================================================================================================================#
setup_local_aur_repo(){

	echo "${czm} Local AUR repo: ${AURREPO}"

	sed -i '$a\#'                         /etc/pacman.conf
	sed -i '$a\# Path to aurch.conf'      /etc/pacman.conf
	sed -i '$a\Include = /etc/aurch.conf' /etc/pacman.conf
	sed -i '/CacheDir/s/^#//g'            /etc/pacman.conf

	echo "${czm} Following is the aurch.conf file: /etc/aurch.conf"

 cat	<<-EOF > /etc/aurch.conf

	[options]
	CacheDir    = ${AURREPO}
	CleanMethod = KeepInstalled

	[${REPONAME}]
	SigLevel = Never TrustAll
	Server = file://${AURREPO}

EOF

if	[[ ! -d  ${AURREPO} ]]; then
	mkdir -p "${AURREPO}"
fi
#	repo-add "${AURREPO}/${REPONAME}".db.tar.gz
	repo-add "${AURREPO}/${REPONAME}".db.tar.gz   $(find "${chroot}"/build/aurutils-*-any.pkg.tar.zst)

	pacsync "${REPONAME}"
	chown -R :alpm "${AURREPO}"
	pacman -Sy

	echo; echo "${czm} Completed setting up a local pacman AUR repo in ${AURREPO}."
	echo "             In order to avoid an unplanned system update within the script,"
	echo "             your system has been left in a partial update' state."
	echo "${czm} Run 'pacman -Syu' upon completion."; echo
}
#========================================================================================================================#
if      [[ -z ${*} ]]; then
	help
fi

while :; do
	case "${1-}" in
	-Sc|--setupcontainer)	check_depends ; setup_chroot					;;
	-Sh|--setuphost)	check_depends ; setup_local_aur_repo				;;
	-h|--help)		help								;;
	-V|--version)		awk -e '/^# aurch/ {print $2,$3}' "$(which aurch-setup)"	;;
	-?*)			echo "${czm}${error} Input error. Running --help" ; help	;;
	*)			break
        esac
    shift
done
