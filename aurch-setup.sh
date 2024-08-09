#!/bin/bash
# aurch-setup 2024-08-09
# dependencies:  base-devel arch-install-scripts git pacutils jshon mc

set -euo pipefail

#======================================================================================================================#
#-----------------------------# 3 User Set variables below. Uncomment and set paths. #------------------------------#
# BASEDIR=
# AURREPO=
# REPONAME=
#-------------------------------------------# Default variables list #----------------------------------------------#
# BASEDIR="${HOME}"/.cache/aurch/base						# HOST chroot base path
# AURREPO="${HOME}"/.cache/aurch/repo						# HOST aur repo path
# REPONAME=aur									# HOST aur repo name
#========================================================================================================================#
[[ ! -v   BASEDIR  ]] && BASEDIR="${HOME}"/.cache/aurch/base			# Set    BASEDIR to default if unset
[[ ! -d ${BASEDIR} ]] && mkdir -p "${BASEDIR}"					# Create BASEDIR directory if not present
[[ ! -v   AURREPO  ]] && AURREPO="${HOME}"/.cache/aurch/repo			# Set    AURREPO to default in unset
[[ ! -d ${AURREPO} ]] && mkdir -p "${AURREPO}"  2>/dev/null			# Create host AUR repo if not present
[[ ! -v REPONAME   ]] && REPONAME=aur						# Set    REPONAME to default if unset
[[ ! -s ${BASEDIR}/.#ID ]] && mktemp -u XXX > "${BASEDIR}"/.#ID			# If not present, create unique suffix file
chroot="${BASEDIR}"/chroot-$(< "${BASEDIR}"/.#ID)				# HOST   path to chroot
chrbuilduser=/home/builduser							# CHROOT builduser home directory
homebuilduser="${chroot}"/home/builduser					# HOST   builduser home directory
#-------------------------------------------------------------------------------------------------------------------#
czm=$(echo -e '\033[1;96m'":: aurch ==>"'\033[00m')				# Aurch color pointer
error=$(echo -e '\033[1;91m' "ERROR:" '\033[00m')				# Red 'ERROR' text.
line2=$(printf %"$(tput cols)"s |tr " " "-")					# Set line '---' to terminal width
#========================================================================================================================#
# Print variables to .#aurch-setup-vars

	cd "${BASEDIR}"									|| { echo "[line ${LINENO}]" ; exit 1 ; }
	echo "
	BASEDIR=${BASEDIR}
	AURREPO=${AURREPO}
	chroot=${chroot}
	chrbuilduser=${chrbuilduser}
	homebuilduser=${homebuilduser}" \
	| awk ' {print;} NR % 1 == 0 { print ""; }' > "${BASEDIR}"/.#aurch-setup-vars

#========================================================================================================================#
check_depends(){

	echo "${czm} Checking dependencies for aurch and arch-install."
	sudo pacman --needed -S base-devel arch-install-scripts git pacutils jshon mc
	echo
}
#========================================================================================================================#
help(){
cat << EOF
${line2}

NAME
		aurch-setup - sets up a system for aurch

DESCRIPTION
		Aurch-setup sets up a system for the aurch script to build AUR packages.
		Sets up an nspawn container for building AUR packages.
		Sets up a local pacman repo for AUR package on the host.
		Aurutils is setup and installed within the nspawn container to build AUR packages.

USAGE
		aurch-setup [operation]

OPERATIONS
                -Sc  --setupchroot	Sets up an nspawn container.
                -Sh  --setuphost	Sets up the host aur repo.
                -h   --help		Prints help.
                -V   --version		Prints aurch version.

VARIABLES
		User variables:
				BASEDIR   Path to host aurch chroot setup.
				AURREPO   Path to host pacman local AUR repo.
		Defaults:
				BASEDIR   "${HOME}"/.cache/aurch/build
				AURREPO   "${HOME}"/.cache/aurch/repo

EXAMPLES
		Setup a chroot for aurch on the host:        aurch-setup -Sc
		Setup a pacman local AUR repo on the host:   aurch-setup -Sh

MISC
		Aurch-setup runtime messages will be proceeded with this:   ${czm}
		Aurch-setup runtime errors will be proceeded with this:     ${czm}${error}

${line2}
EOF
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

	sudo chown root:root "${chroot}"

if      sudo pacstrap -c "${chroot}" base base-devel git ; then

	echo "${czm} Pacstrap finished nspawn-container install."
	echo "${czm} Setting up container with builduser, colored shell prompts, header id's, and alias's."
	sleep 5

	cd "${chroot}"									|| { echo "[line ${LINENO}]" ; exit 1 ; }

	mkdir -p "${chroot}"/var/tmp/aurch						|| { echo "[line ${LINENO}]" ; exit 1 ; }
	sudo systemd-nspawn --as-pid2 -q    useradd -m -G wheel -s /bin/bash builduser
	sudo systemd-nspawn --as-pid2 -q    mkdir /build
	sudo systemd-nspawn --as-pid2 -q    chown builduser:builduser /build

	cat << 'EOF' | sudo tee -a "${chroot}"/etc/bash.bashrc

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
	cd "${BASEDIR}"									|| { echo "[line ${LINENO}]" ; exit 1 ; }

if	[[ -d  ${chroot}/build ]] && [[ -d ${homebuilduser} ]] ; then

	printf '%s\n' "%wheel ALL=(ALL) NOPASSWD: ALL"  > 01-sudoers-addendum
	sudo chown root:root 01-sudoers-addendum
	sudo mv ./01-sudoers-addendum "${chroot}/etc/sudoers.d/01-sudoers-addendum"

	sudo systemd-nspawn --as-pid2 -q   -D "${chroot}"   -u builduser \
	install -d /build -o builduser

	sudo systemd-nspawn --as-pid2 -q  -D "${chroot}"  -u builduser --chdir="${chrbuilduser}" --pipe \
	git clone https://aur.archlinux.org/aurutils.git

	sudo systemd-nspawn --as-pid2 -q  -D "${chroot}"  -u builduser --chdir="${chrbuilduser}"/aurutils --pipe \
	makepkg -sri --noconfirm

	cd "${chroot}"								|| { echo "[line ${LINENO}]" ; exit 1 ; }

	sudo systemd-nspawn --as-pid2 -q sed -i '$a\#'					/etc/pacman.conf
	sudo systemd-nspawn --as-pid2 -q sed -i '$a\[options]'				/etc/pacman.conf
	sudo systemd-nspawn --as-pid2 -q sed -i '$a\CacheDir    = /build'		/etc/pacman.conf
	sudo systemd-nspawn --as-pid2 -q sed -i '$a\CleanMethod = KeepInstalled'	/etc/pacman.conf
	sudo systemd-nspawn --as-pid2 -q sed -i '$a\[aur]'				/etc/pacman.conf
	sudo systemd-nspawn --as-pid2 -q sed -i '$a\SigLevel = Optional TrustAll'	/etc/pacman.conf
	sudo systemd-nspawn --as-pid2 -q sed -i '$a\Server = file:///build'		/etc/pacman.conf
	sudo systemd-nspawn --as-pid2 -q sed -i '/CacheDir/s/^#//g'			/etc/pacman.conf
	sudo systemd-nspawn --as-pid2 -q sed -i '/ParallelDownloads/s/^#//g'		/etc/pacman.conf
	sudo systemd-nspawn --as-pid2 -q sed -i '/VerbosePkgLists/s/^#//g'		/etc/pacman.conf

	cat << "EOF" > "${homebuilduser}/aurutils/add-aur-repo"
	#!/bin/bash
	repo-add /build/aur.db.tar.gz   $(find /home/builduser/aurutils/ -maxdepth 1 -type f -name aurutils*pkg.tar.zst)
EOF
	chmod +x "${homebuilduser}/aurutils/add-aur-repo"

	sudo systemd-nspawn --as-pid2 -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}"/aurutils --pipe \
	./add-aur-repo

	sudo systemd-nspawn --as-pid2 -q  -D "${chroot}" --pipe \
	pacman -Sy

	sudo pacman     -r "${chroot}" \
			-b "${chroot}/var/lib/pacman/" \
			--config "${chroot}/etc/pacman.conf" \
			--noconfirm -Qq \
			| nl > "${BASEDIR}/.#orig-pkgs.log"

	if	[[ -e  aurch.README ]]; then
		rm aurch.README
	fi
	cat <<-EOF | tee >( sed 's/\x1B\[[0-9;]*[A-Za-z]//g' >"${BASEDIR}/aurch.README")
	${czm} Aurch nspawn-container setup completed.
	${czm} Has base, base-devel, git, and aurutils installed.
	${czm} Container AUR repo is set up in ${chroot}/build.
	${czm} User builduser is set up, no password required for sudo.
	${czm} Do not alter files proceeded with '#.' in base directory.
	${czm} To setup host local AUR repo, run: aurch-setup -Sh
EOF
    else
	echo; echo "${czm} builduser setup failed in container."
fi
}
#========================================================================================================================#
setup_local_aur_repo(){

	echo "${czm} Local AUR repo: ${AURREPO}"

	sudo sed -i '$a\#'                         /etc/pacman.conf
	sudo sed -i '$a\# Path to aurch.conf'      /etc/pacman.conf
	sudo sed -i '$a\Include = /etc/aurch.conf' /etc/pacman.conf
	sudo sed -i '/CacheDir/s/^#//g'            /etc/pacman.conf

	echo "${czm} Following is aurch.conf file: /etc/aurch.conf"

cat	<<-EOF	  | sudo tee /etc/aurch.conf

	[options]
	CacheDir    = ${AURREPO}
	CleanMethod = KeepInstalled

	[${REPONAME}]
	SigLevel = Optional TrustAll
	Server = file://${AURREPO}

EOF
	sudo mkdir -p "${AURREPO}"
	sudo chown "${USER}":"${USER}" "${AURREPO}"

	install -d "${AURREPO}" -o "${USER}"

	pkg=$(find "${homebuilduser}/aurutils/" -type f -name "aurutils*pkg.tar.zst")
	repo-add "${AURREPO}/${REPONAME}".db.tar.gz "${pkg}"

	sudo pacsync "${REPONAME}"
 	sudo pacman -Sy

	echo; echo "${czm} Completed setting up a local pacman AUR repo in ${AURREPO}."
	echo " In order to avoid an unplanned system update within the script, your system has been left in a"
	echo " 'partial update' condition. It's imperative to run a 'pacman -Syu' update upon completion."; echo
}
#========================================================================================================================#
if      [[ -z ${*} ]]; then
cat << EOF

 aurch-setup	Sets up host for aurch usage.

            	Run 'aurch-setup -h' for help.
 Container ID: 	$(basename "${chroot}")

EOF
fi
#========================================================================================================================#
while :; do
	case "${1-}" in
	-Sc|--setupchroot)	check_depends; setup_chroot					;;
	-Sh|--setuphost)	check_depends; setup_local_aur_repo				;;
	-h|--help)		help								;;
	-V|--version)		awk -e '/^# aurch/ {print $2,$3}' "$(which aurch-setup)"	;;
	-?*)			echo "${czm}${error} Input error. Running --help" ; help	;;
	*)			break
        esac
    shift
done
