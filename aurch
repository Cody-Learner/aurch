#!/bin/bash
# aurch 2021-11-29
# dependencies: arch-install-scripts base-devel git pacutils *
# * Aurutils is installed and setup in the chroot. Not as a dependency on host.

#========================================================================================================================#

basedir="$(pwd)"						# HOST  base directory		  : /home/<user>/aurbuilds
[[ ! -s ${basedir}/.#ID ]] && mktemp -u XXX > .#ID		# Create unique chroot suffix.
chroot="${basedir}/chroot-$(< .#ID)"				# HOST path to chroot	  	  : /home/<user>/aurbuilds/chroot-xxx
chrbuilduser="/home/builduser"					# CHROOT builduser home directory : /home/builduser
homebuilduser="${basedir}/chroot-$(< .#ID)/home/builduser"	# HOST   builduser home directory : /home/<user>/aurbuilds/chroot-xxx/home/builduser
package="${2,,}"						# Convert <package> to lower case.
[[ ! -v AURREPO ]] && AURREPO="/tmp/aurch"			# HOST  local pacman aur repo.
[[ ! -d ${AURREPO} ]] && mkdir "${AURREPO}"			# Create host AUR repo.
tmpc="/var/tmp/aurch"						# CHROOT tmp dir (used within chroot)
tmph="${chroot}${tmpc}"						# HOST tmp dir   (used on host)
[[ -d ${chroot} && ! -d ${tmph} ]] && mkdir "${tmph}"		# Create aurch tmp directory.
czm=$(echo -e '\033[1;96m'":: aurch ==>"'\033[00m')		# Aurch color pointer.
error=$(echo -e '\033[1;91m' "ERROR:" '\033[00m')		# Red 'ERROR' text.
line2=$(printf %"$(tput cols)"s |tr " " "-")			# Set line '---' to terminal width.

#========================================================================================================================#

help(){
cat << EOF
${line2}

NAME
	aurch - sets up and builds AUR packages in chroot

DESCRIPTION
	Aurch creates a chroot, sets up aurutils with a local AUR repo(1), and sets up user 'builduser'(*1) in the directory it's ran in.
	Can be used for various AUR package related tasks including '-B 'for easy one command builds.
	Upon completing AUR build/s, aurch will place copy/s of the package/s in the host AURREPO file.
	Keeps a copy of all AUR packages and dependencies built in the chroot AUR repo for future use.
	Automatically installs all required pgp keys in the chroot.
	Automatically maintains a 144 package count in the chroot via automated cleanup.
	The chroot is intended to be reused.
	Does not perform 'clean chroot' builds.
	The emphasis of this script is using a chroot for 'build isolation' rather than 'clean building'.

	(*1)(within the chroot)

USAGE
		aurch [operation[options]] [package | pgp key]


OPERATIONS 
		    --setup		Sets up a chroot.
		-B*  --build		Builds an AUR package in one step.
		-G  --git		Git clones an AUR package.
		-C  --compile		Builds an AUR package on existing PKGBUILD.
		-Rc  [--long NA]	Remove AUR pkg from chroot  /build/<package>, $HOME/<build dir>, and database entry.
		-Rh  [--long NA]	Remove AUR pkg from host /AURREPO/<package>, <package> if installed, and database entry.
		-Lu*  --listupdates	List updates available for AUR packages in chroot AUR repo.
		-Lc*  --listchroot	List contents of AUR db on chroot.
		-Lh*  --listhost	List contents of AUR db on host.
		    --clean		Manually remove unneeded packages from chroot.
		    --pgp		Manually import pgp key in chroot.
		-h, --help		Prints help.

OPTIONS
	-L, List:
		Append 'q' to list operations -L[u,c,h] for quiet mode.
		Example: aurch -Luq
		Do not mix order or attempt to use 'q' other than described.

	-B, Build:
		Append 'i' to build operation -B to install package in host.
		Example: aurch -Bi
		Do not mix order or attempt to use 'i' other than described.

OVERVIEW
		Run 'aurch --setup' before using aurch.
		Run aurch from directory containing chroot created during 'aurch --setup'.

EXAMPLES
		Create a directory to setup chroot in:		mkdir ~/aurbuilds
		Move into directory:				cd ~/aurbuilds
		Set up chroot:					aurch --setup		 
		Build an AUR package in the chroot:		aurch -B <aur-package>
		Git clone package				aurch -G <aur-package>
		Build (Compile) AUR pkg on existing PKGBUILD	aurch -C <aur-package>
		List chroot AUR repo updates available:		aurch -Lu
		List chroot AUR sync database contents:		aurch -Lc
		List host AUR sync database contents:		aurch -Lh
		Manually import a pgp key in chroot:		aurch --pgp <short or long key id>
		Manually remove unneeded packages in chroot:	aurch --clean

VARIABLES
		AURREPO </path/to/host/directory>
		AURREPO Default: /tmp/aurch

		To copy built AUR packages to host, set:
		AURREPO="/path/to/host/local-pacman-repo"
MISC
		Aurch runtime messages will be proceeded with this:	${czm}
		Aurch runtime errors will be proceeded with this:	${czm}${error}

${line2}
EOF
}
#========================================================================================================================#
setup_chroot(){

	mkdir "${chroot}"

	sudo chown root:root "${chroot}"

if	sudo pacstrap "${chroot}" base base-devel git ; then

	echo "${czm} Pacstrap finished chroot install."
	sleep 2

	cd "${chroot}"										|| { echo "[line ${LINENO}]" ; exit 1 ; }

	sudo rm -rd "${chroot}"/var/lib/pacman/sync/*.db
	sudo systemd-nspawn -q 	pacman -Syy							|| { echo "[line ${LINENO}]" ; exit 1 ; }

	sudo systemd-nspawn -q    useradd -m -G wheel -s /bin/bash builduser
	sudo systemd-nspawn -q    mkdir /build
	sudo systemd-nspawn -q    chown builduser:builduser /build

	sudo systemd-nspawn -q sed -i '$a\#'                        /etc/pacman.conf
	sudo systemd-nspawn -q sed -i '$a\# Path to aurt.conf'      /etc/pacman.conf
	sudo systemd-nspawn -q sed -i '$a\Include = /etc/aurt.conf' /etc/pacman.conf
	sudo systemd-nspawn -q sed -i '/CacheDir/s/^#//g'           /etc/pacman.conf
	sudo systemd-nspawn -q sed -i '/ParallelDownloads/s/^#//g'  /etc/pacman.conf
	sudo systemd-nspawn -q sed -i '/VerbosePkgLists/s/^#//g'    /etc/pacman.conf

	echo "${czm} Following is the contents of new file: /etc/aurt.conf"

cat	<<-EOF	  | sudo tee "${chroot}"/etc/aurt.conf

	[options]
	CacheDir    = /build
	CleanMethod = KeepInstalled

	[aur]
	SigLevel = Optional TrustAll
	Server = file:///build

EOF
    else
	echo "${czm} Pacstrap failed."
fi
	cd "${basedir}"										|| { echo "[line ${LINENO}]" ; exit 1 ; }

if	[[ -d  ${chroot}/build ]] && [[ -d ${homebuilduser} ]] ; then

	printf '%s\n' "%wheel ALL=(ALL) NOPASSWD: ALL"  > 01-sudoers-addendum
	sudo chown root:root 01-sudoers-addendum
	sudo mv ./01-sudoers-addendum "${chroot}/etc/sudoers.d/01-sudoers-addendum"

	sudo systemd-nspawn -q   -D "${chroot}"   -u builduser \
	install -d /build -o builduser

	sudo systemd-nspawn -q   -D "${chroot}"   -u builduser \
	repo-add /build/aur.db.tar.gz

	sudo systemd-nspawn -q   -D "${chroot}"  \
	pacman -Sy

	sudo systemd-nspawn -q  -D "${chroot}"  -u builduser --chdir="${chrbuilduser}" --pipe \
	git clone https://aur.archlinux.org/aurutils.git
		
	sudo systemd-nspawn -q  -D "${chroot}"  -u builduser --chdir="${chrbuilduser}"/aurutils --pipe \
	makepkg -si --noconfirm

	sudo pacman	-r "${chroot}" \
			-b "${chroot}/var/lib/pacman/" \
			--config "${chroot}/etc/pacman.conf" \
			--noconfirm -Qq \
			| nl > .#orig-pkgs.log

	if	[[ -e  aurch.README ]]; then
		rm aurch.README
	fi
	cat <<-EOF | tee >( sed 's/\x1B\[[0-9;]*[A-Za-z]//g' >aurch.README)
	${czm} Setup completed.
	${czm} Chroot has base, base-devel, git, and aurutils installed.
	${czm} User builduser is set up, no password required for sudo.
	${czm} Local chroot AUR repo is setup as /build.
	${czm} Do not alter files proceeded with '#.' in base directory.
EOF
    else
	echo; echo "${czm} User setup failed."
fi
}
#========================================================================================================================#

is_it_available(){

	check=$(curl --compressed -s "https://aur.archlinux.org/rpc/?v=5\&type=info&arg\[\]=${package}" \
		| jshon -e results -a -e  Name \
		| awk -F\" '{print $2}')

if	[[ ${package} != "${check}" ]] ; then
	echo "${czm}${error}\"${package}\" not available. See: https://aur.archlinux.org/packages/"
	exit
fi
}
#========================================================================================================================#

fetch_pkg(){

	is_it_available

	sudo systemd-nspawn -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}" \
	aur fetch -Sr "${package}" | tee >(awk -F\' '/Cloning/ {print $2}' >"${tmph}"/cloned-pkgs.file)
	#[SAVE] -S Alias for --sync=auto
	#[SAVE] -r Download packages and their dependencies

if	[[ -s ${tmph}/cloned-pkgs.file ]]; then
	echo "${czm} Git cloned ${package} and/or it's dependencies:"
	nl "${tmph}"/cloned-pkgs.file
fi
}
#========================================================================================================================#

build_pkg(){

	rm -f "${tmph}"/*.file

	cacheB=$(find "${AURREPO}"/*pkg.tar* 2>/dev/null |sort)

	find "${chroot}"/build/*pkg.tar* 2>/dev/null >"${tmph}"/before.file

	cd "${homebuilduser}"									|| { echo "[line ${LINENO}]" ; exit 1 ; }

	sudo systemd-nspawn -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}" --pipe bash << EOF
	aur depends -b "${package}" >"${tmpc}"/buildorder.file
	aur depends -n "${package}" | grep -v "${package}" >"${tmpc}"/dependencies.file
EOF
	echo "${czm} Buildorder list for ${package}:"
	nl "${tmph}"/buildorder.file

	echo "${czm} AUR dependencies list for ${package}:"
	nl "${tmph}"/dependencies.file

	readarray -t -O1 buildorder <"${tmph}"/buildorder.file

	depi=$(( ${#buildorder[*]} - 1 ))
	pkgi="${#buildorder[*]}"

for	dependency in "${buildorder[@]:0:${depi}}"
    do

	cd "${homebuilduser}/${dependency}"							|| { echo "[line ${LINENO}]" ; exit 1 ; }
	package="${dependency}"

	fetch_pgp_key

	echo "${czm} Building and installing ${buildorder[${pkgi}]} dependency: ${dependency}"

	sudo systemd-nspawn -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${dependency}" --pipe \
	aur build -ns --margs -i
    done
        echo  "${czm} Building: ${buildorder[${pkgi}]}"

	cd "${homebuilduser}/${buildorder[${pkgi}]}"						|| { echo "[line ${LINENO}]" ; exit 1 ; }
	package="${buildorder[${pkgi}]}"

	fetch_pgp_key

	sudo systemd-nspawn -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${buildorder[pkgi]}" --pipe bash << EOF
	aur build -fnsr |& tee >(grep 'WARNING:' >"${tmpc}"/warning.file) | tee >(grep 'Adding package' >"${tmpc}"/pkg-nv.file)
EOF
#---------------------------------------------------------------------------------------------
# Move packages to host and print results.

	find "${chroot}"/build/*pkg.tar* 2>/dev/null >"${tmph}"/after.file

	comm -23 <(sort "${tmph}"/after.file) <(sort "${tmph}"/before.file) >"${tmph}"/move.file

	for pkg in $(< "${tmph}"/move.file)
    do
	cp "${pkg}" "${AURREPO}"								|| { echo "cp err [line ${LINENO}]"; exit 1 ; }
	basename "${pkg}" >> "${tmph}"/moved.file
    done
	cleanup_chroot

if	[[ -s  ${tmph}/moved.file ]] ; then
	echo "${czm} Copied AUR package/s to host AURREPO:"
	nl "${tmph}"/moved.file

    else   # For rebuilt packages

	if	[[ -s "${tmph}"/warning.file ]]; then

		awk -F\' '{print $2}' "${tmph}"/pkg-nv.file \
		| xargs -I {} cp "${chroot}"/build/{} "${AURREPO}"				|| { echo "cp err [line ${LINENO}]"; exit 1 ; }

		echo "${czm} Copied rebuilt pkgs to host AURREPO:"
		awk -F\' '{print $2}' "${tmph}"/pkg-nv.file | nl
	fi
fi
	cacheA=$(find "${AURREPO}"/*pkg.tar*|sort)
	comm -23 <(printf '%s\n' "${cacheA}") <(printf '%s\n' "${cacheB}") | tee > "${tmph}"/added-pkgs.file

	upd_aur_db
	sudo pacsync aur >/dev/null

#---------------------------------------------------------------------------------------------
# Optionally install package.

if	[[ "${1}" == -Bi ]]; then
	echo "${czm} Installing ${buildorder[${pkgi}]} in host."
	sudo pacsync aur
	sudo pacman -S "${buildorder[${pkgi}]}"
fi
}
#========================================================================================================================#

upd_aur_db(){

if	find "${AURREPO}"/*.db.tar.gz &>/dev/null && [[ -s "${tmph}"/added-pkgs.file ]]; then
	echo "${czm} Adding package/s to host 'AURREPO' database"

	for pkg in $(< "${tmph}"/added-pkgs.file)
   do
	repo-add "${AURREPO}"/aur.db.tar.gz "${pkg}"
   done
    else
	echo "${czm} No new or updated packages detected in AURREPO."
	echo " Rebuilt packages overwrite existing packages in AURREPO."
fi
}
#========================================================================================================================#

check_updates(){

	cd "${homebuilduser}"									|| { echo "[line ${LINENO}]" ; exit 1 ; }

	basedir=$(pwd)
	rm -f /tmp/check-ud-updates
	readarray -t dirs < <(find "${basedir}" -maxdepth 1 -mindepth 1 -type d -name "[!.]*" -printf '%f\n')

if	[[ $1 != -Luq ]]; then
	echo "${czm} Checking for updates on:"
	printf '%s\n' "${dirs[@]}" | nl
fi
	for pkg in "${dirs[@]}"
    do
	cd "${basedir}/${pkg}"									|| { echo "[line ${LINENO}]" ; exit 1 ; }
	localHEAD=$(git rev-parse HEAD)
	remoteHEAD=$(git ls-remote --symref -q  | head -1 | cut -f1)

	if	[[ ${localHEAD} != "${remoteHEAD}" ]]; then
		echo " ${pkg}" >> /tmp/check-ud-updates
	fi
    done

if	[[ -s  /tmp/check-ud-updates ]]; then
	if	[[ $1 != -Luq ]]; then
		echo >> /tmp/check-ud-updates
		echo "${czm}  Updates available:"
	fi
	cat /tmp/check-ud-updates
    else
	if	[[ $1 != -Luq ]]; then
		echo "${czm} No updates available."
	fi
fi

}
#========================================================================================================================#

fetch_pgp_key(){

	echo "${czm} Checking pgp key for ${package}."

if	[[ -e .SRCINFO ]]; then
	sudo systemd-nspawn -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${package}" --pipe \
	awk '/validpgpkeys/ {print $3}' .SRCINFO >pgp-keys.file					# SC2024: Is not ran as sudo within chroot.
    else
	sudo systemd-nspawn -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${package}" --pipe \
	makepkg --printsrcinfo | awk '/validpgpkeys/ {print $3}' >pgp-keys.file
fi
if	[[ -s pgp-keys.file ]] ; then
	for key in $(< pgp-keys.file); do
	sudo systemd-nspawn -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${package}" --pipe bash << EOF
	gpg --keyserver keyserver.ubuntu.com --recv-key "${key}" 2>&1 | grep -v 'insecure memory'
EOF
	done
    else
	rm pgp-keys.file
fi

}
#========================================================================================================================#

cleanup_chroot(){

if	[[ ! -e ${tmph}/orig-pkgs.log ]]; then
	awk '{print $2}'  "${basedir}"/.#orig-pkgs.log | sort  >"${tmph}"/orig-pkgs.log
fi
	echo "${czm} Checking/Cleaning chroot."
	sudo systemd-nspawn -q -D "${chroot}" --pipe bash << EOF
	comm -23 <(pacman -Qq) <(cat "${tmpc}"/orig-pkgs.log) | xargs  pacman -Rns --noconfirm 2>/dev/null \
	|| echo " Package count: $(pacman -b "${chroot}/var/lib/pacman/" --config "${chroot}/etc/pacman.conf" --noconfirm -Qq | wc -l)"
EOF
}
#========================================================================================================================#
# List AUR sync repos:

list_pkgs_host(){
if	[[ ${1} == -Lhq ]]; then
	opt1='-Slq' 
    else
	opt1='-Sl'
	echo "[sudo] to run pacsync on aur db"
        sudo pacsync aur | grep -v aur.db.sig
fi
	pacman --color=always "${opt1}" aur | column -t
}
list_pkgs_chroot(){
if	[[ ${1} == -Lcq ]]; then
	opt2='-Slq'
    else
	opt2='-Sl'
	echo "[sudo] to run systemd-nspawn"
	sudo systemd-nspawn -q -D "${chroot}" << EOF pacsync aur | grep -v aur.db.sig
EOF
fi
	pacman --color=always -b "${chroot}/var/lib/pacman/" --config "${chroot}/etc/pacman.conf" --noconfirm "${opt2}" aur \
	| column -t
}
#========================================================================================================================#

remove(){

if	[[ -n ${pkg} ]]; then

	if	[[ ${1} == -Rc ]]; then
		if	pacman -b "${chroot}/var/lib/pacman/" \
				--config "${chroot}/etc/pacman.conf" \
				-Slq aur \
			| grep -q "${pkg}"; then
			repo-remove "${chroot}"/build/aur.db.tar.gz "${pkg}"
			cd "${chroot}"/build							|| { echo "[line ${LINENO}]" ; exit 1 ; }
			remove=$(find "${pkg}"*.pkg.tar*)
			rm  "${remove}" && echo "${czm} Removed ${remove} from /build."
			cd "${homebuilduser}"							|| { echo "[line ${LINENO}]" ; exit 1 ; }
			sudo rm -rd "${pkg}"
			sudo systemd-nspawn -q -D "${chroot}" --pipe pacsync aur
		    else
			echo "${czm} ${pkg} is not present in chroot AUR repo."
		fi
	fi
	if	[[ ${1} == -Rh ]]; then
		if	pacman -Q "${pkg}" &>/dev/null ; then
			sudo pacman -Rns "${pkg}" 
		fi
	cd "${AURREPO}"										|| { echo "[line ${LINENO}]" ; exit 1 ; }
	remove=$(find "${pkg}"*.pkg.tar*)
	rm "${remove}" 2>/dev/null
		if	pacman -Slq aur | grep -q "${pkg}"; then
			repo-remove "${AURREPO}"/aur.db.tar.gz "${pkg}"
			sudo pacsync aur
		    else
			echo "${czm} Package ${pkg} is not present in host AUR repo."
		fi
	fi
    else
	echo "${czm} Need to specify package."
fi
}
#========================================================================================================================#
												
manual_pgp_key(){
	sudo systemd-nspawn -q -D "${chroot}" -u builduser  --pipe \
	gpg --keyserver keyserver.ubuntu.com --recv-key "${key}"				# SC2154: key is assigned in option parsing.
exit

}
#========================================================================================================================#
												# Aurch called with no args message.
if      [[ -z ${*} ]]; then
cat << EOF

 OPERATIONS	-B	build AUR package
		-G	git clone package
		-C	build on existing git clone
		-Rc	remove AUR pkg from chroot 
		-Rh	remove AUR pkg from host
		-Lu	list updates chroot
		-Lc	list AUR db chroot
		-Lh	list AUR db host
		--clean	remove unneeded packages
		--pgp	import pgp key
		--setup	builds new chroot
		-h	help

 OPTIONS	-L[x]'q'   quiet
		-B   'i'   install

 Chroot ID	$(basename "${chroot}")"

EOF
fi

#========================================================================================================================#

while :; do
	case "${1}" in
	-B*|--build)		fetch_pkg ; build_pkg "${1}"					;;
	-G|--git)		fetch_pkg							;;
	-C|--compile)		build_pkg							;;
	-R*)			pkg="${2}" remove "${1}"					;;
	-Lu*|--listupdates)	check_updates "${1}"						;;
	-Lh*|--listhost)	list_pkgs_host "${1}"						;;
	-Lc*|--listchroot)	list_pkgs_chroot "${1}"						;;
	--clean)		cleanup_chroot							;;
	--setup)		setup_chroot							;;
	--pgp)			key="${2}" manual_pgp_key					;;
	-h|--help)		help								;;
	-?*)                    echo "${czm}${error} Input error. Running --help" ; help	;;
	*)			break
        esac
    shift
done
