#!/bin/bash
# aurch 2024-11-13
# dependencies: base-devel git pacutils(pacsync) jshon mc
# shellcheck source=aurch-cc.sh # Run: shellcheck -x aurch.sh

set -euo pipefail

	[[ ! -v BASEDIR ]]	&& BASEDIR=/usr/local/aurch/base		# HOST    Set BASEDIR to default if unset
	[[ -n "${2-}" ]]	&& package="${2,,}" || package="" 		#         Convert <package> input to all lower case
	[[ ! -v AURREPO  ]]	&& AURREPO=/usr/local/aurch/repo		# HOST    Set AURREPO to default if unset
	[[ ! -v REPONAME ]]	&& REPONAME=aur					# HOST    Set REPONAME to default if unset

chroot="${BASEDIR}"/chroot-$(< "${BASEDIR}"/.#ID)				# HOST    path to chroot root
chrbuilduser="/home/builduser"							# CHROOT  builduser home directory (same destination 1)
homebuilduser="${chroot}"/home/builduser					# HOST    builduser home directory (same destination 1)
tmpc="/var/tmp/aurch"								# CHROOT  path to tmp dir (same destination 2)
tmph="${chroot}${tmpc}"								# HOST    path to tmp dir (same destination 2)
perm=$(stat -c '%a' "${chroot}"/build/aur.db.tar.gz)				# Container octal permission: /build/aur.db.tar.gz
AURFM=mc									# Application to inspect git cloned repos
czm=$(echo -e '\033[1;96m'":: aurch ==>"'\033[00m')				# Aurch color pointer
error=$(echo -e '\033[1;91m' "ERROR:" '\033[00m')				# Red 'ERROR' text
warn=$(echo -e '\033[1;33m'"WARNING:"'\033[00m')				# Yellow 'WARNING' text
line2=$(printf %"$(tput cols)"s |tr " " "-") 					# Set line '---' to terminal width

#========================================================================================================================#
print_vars(){

	cat <<-EOF | sudo tee "${BASEDIR}"/.#aurch-vars &>/dev/null

	BASEDIR=${BASEDIR-}
	AURREPO=${AURREPO-}
	REPONAME=${REPONAME-}
	chroot=${chroot-}
	chrbuilduser=${chrbuilduser-}
	homebuilduser=${homebuilduser-}
	package=${package-}
	tmpc=${tmpc-}
	tmph=${tmph-}
	perm=$(stat -c '%a' "${chroot}"/build/aur.db.tar.gz)
	AURFM=${AURFM}
	czm=Aurch_color_pointer
	error=Red_'ERROR'_text
	warn=Yellow_'WARNING'_text
	line2=Line_'---'_set_to_terminal_width
EOF
	sed 's/=/ = /g' "${BASEDIR}"/.#aurch-vars | column -t
}
#========================================================================================================================#
help(){
cat << EOF
${line2}

NAME
	aurch - Isolates the host system when building AUR packages from potential errors or malicious content.

DESCRIPTION
	Aurch builds AUR packages in an nspawn container implemented for build isolation.
	Not to be confused with building packages in a clean chroot. ie: devtools package scripts.
	Upon completing AUR builds, aurch places copies of the packages in the host AURREPO directory.
	Keeps a copy of AUR packages and dependencies in the nspawn container for future use.
	Automatically installs required pgp keys in the nspawn container.
	Automatically maintains a set package count in the nspawn container via automated cleanup.
	The nspawn container is intended to be reused rather than recreated for each package.

USAGE
		aurch [operation[options]] [package | pgp key]

OPERATIONS
		-B* --build	Build new or update an existing AUR package.
		-G  --gitclone	Git clones AUR package to ${homebuilduser}/<aur-package>.
		-C  --compile	Build an AUR package on existing PKGBUILD. Useful for implementing changes to PKGBUILD.
		-Cc --cchroot   Build package in clean chroot.
		-Rh		Remove AUR pkg from host. Removes: ${AURREPO}/<aur-package>, if installed <aur-package> and database entry.
		-Rc		Remove AUR pkg from container. Removes: /build/<package>, ${chrbuilduser}/<aur-package>, database entry.
		-Lah* --lsaurh	List all host AUR sync database contents/status.
		-Lac* --lsaurc	List all container AUR sync database contents/status.
		-Luh* --lsudh	List update info for AUR packages installed in host.
		-Luc* --lsudc	List update info for AUR packages/AUR dependencies in container.
		-Lv		List variables expanded in console and print to ${BASEDIR}/.#aurch-vars.
		-Syu  --update  Update container system. ie: Runs 'pacman -Syu' inside container.
		      --login   Login to nspawn container for maintenance.
		      --clean	Manually remove unneeded packages from nspawn container.
		      --pgp	Manually import pgp key into nspawn container.
		-h,   --help	Prints help.
		-V,   --version Prints aurch <version>.

*OPTIONS
	-L, List:
		Append 'q' to  -L list operations for quiet mode.
		Example: aurch -Lahq
		Do not mix order or attempt to use 'q' other than described.

	-B, Build:
		Append 'i' to build operation -B to install package in host.
		Example: aurch -Bi
		Do not mix order or attempt to use 'i' other than described.

OVERVIEW
    		Run aurch-setup before using aurch.
    		Aurch is designed to handle AUR packages individually, one at a time.
    		 ie: No group updates or multiple packages per operation capability.
    		The aurch nspawn container must be manually updated 'aurch -Syu'
		 and pacman cache maintained 'aurch --login' or manually via filesystem.
    		Best results obtained with container updated before buiding packages.

EXAMPLES
    		SETUP FOR AURCH:

    		Set up nspawn container:				sudo aurch-setup --setupcontainer
    		Set up local AUR repo:					sudo aurch-setup --setuphost


    		USING AURCH:

    		Build an AUR package(+):				aurch -B  <aur-package>
    		Build and install AUR package:				aurch -Bi <aur-package>
    		Git clone an AUR package:				aurch -G  <aur-package>
    		Compile (build) a git cloned AUR pkg:			aurch -C  <aur-package>
    		Remove host AUR package:				aurch -Rh <aur-package>
    		Remove container AUR package:				aurch -Rc <aur-package>
    		List all host AUR packages:				aurch -Lah
    		List all container packages:				aurch -Lac
    		List host updates, AUR packages:			aurch -Luh
    		List container updates, AUR packages:			aurch -Luc
    		pgp key import in container: 				aurch --pgp <short or long key id>
    		Clean unneeded packages in container:			aurch --clean
    		Login to container for maintenance:                	aurch --login

		(+) Package is placed into host AUR repo and entry made in pacman AUR database.
		    Install with 'pacman -S <aur-package>'

VARIABLES
		AURFM = AUR file manager,editor Default: AURFM=mc (midnight commander)
		        Note: Untested, possibly use vifm.

MISC
		Aurch runtime messages will be proceeded with this:	${czm}
		Aurch runtime errors will be proceeded with this:	${czm}${error}

${line2}
EOF
}
#========================================================================================================================#
# Reset container AUR db permission

set_perm(){

if	((perm != 646)); then
	sudo systemd-nspawn -a -q -D "${chroot}" chmod 646 /build/aur.db.tar.gz
fi
}
#========================================================================================================================#
# Restore container AUR db permission

rest_perm(){
	sudo systemd-nspawn -a -q -D "${chroot}" chmod 644 /build/aur.db.tar.gz
}
#========================================================================================================================#
fetch_pkg(){

	[[ -z ${package} ]] && { echo "${czm}${error} Need to specify a package."; echo; exit ; }

	is_it_available

if	[[ ! -d "${chroot}/var/tmp/aurch" ]]; then
	sudo systemd-nspawn -a -q -D "${chroot}" mkdir /var/tmp/aurch
fi
	sudo systemd-nspawn -a -q -D "${chroot}" chmod -R 777 "${tmpc}"

if	[[ -d  "${homebuilduser}/${package}" ]] && [[ ! -s  "${homebuilduser}/${package}/PKGBUILD" ]]; then
	printf '\n%s\n' "${czm} Information: Testing an if statement for a fix. Proceed as normal...."
	printf '%s\n'   "${czm} Existing build dir is without a PKGBUILD. Deleted build dir for replacement."
 	printf '%s\n\n'   "${czm} Cause: Clean chroot builds and 'aur fetch' will not overwrite if current."
	sudo rm -rd "${homebuilduser}/${package}"
fi

	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}" --pipe << EOF
	aur depends -r "${package}" | tsort | aur fetch -S - |& tee >(grep 'Cloning' |cut -d"'" -f 2 >"${tmpc}"/cloned-pkgs.file)
EOF

if	[[ -s ${tmph}/cloned-pkgs.file ]]; then
	echo "${czm} Git cloned ${package} and/or it's dependencies:"

	# awk -F\' '/Cloning/ {print $2}' "${tmph}"/cloned-pkgs.file | nl
	nl "${tmph}"/cloned-pkgs.file
	echo "${czm} Build dir: ${homebuilduser}/${package}"
fi
}
#========================================================================================================================#
is_it_available(){

	check=$(curl --compressed -s "https://aur.archlinux.org/rpc?v=5&type=info&arg=${package}" \
		| jshon -e results -a -e  Name \
		| awk -F\" '{print $2}')

if	[[ ${package} != "${check}" ]] ; then
	echo "${czm}${error}\"${package}\" not available. See: https://aur.archlinux.org/packages/"
	exit
fi
}
#========================================================================================================================#
build_pkg(){

	rm -f "${tmph}"/*.file					# The 'placeholder' files are for 'set -e' to not exit the script
								# upon 'find' command not finding 'pkg.tar' on first run.
if	[[ ! -f ${AURREPO}/placeholder.pkg.tar ]]; then
	sudo touch "${AURREPO}"/placeholder.pkg.tar
fi
	cacheB=$(find "${AURREPO}"/*pkg.tar* 2>/dev/null |sort)

if	[[ ! -f ${chroot}/build/placeholder.pkg.tar ]]; then
	touch "${chroot}"/build/placeholder.pkg.tar
fi

if	[[ ! -d "${homebuilduser}/${package}" ]]; then
	echo "${czm}${error} Package build directory missing in container."
	echo "               If running '-C --compile', run '-G --gitclone' first to fetch requirements."
	exit
fi

	find "${chroot}"/build/*pkg.tar* 2>/dev/null >"${tmph}"/before.file

	cd "${homebuilduser}"									|| { echo "[line ${LINENO}]" ; exit 1 ; }

	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}" --pipe bash << EOF
	aur depends -r "${package}" | tsort >"${tmpc}"/buildorder.file
	aur depends -n -r "${package}" | tsort | grep -v "${package}" >"${tmpc}"/dependencies.file || echo
EOF
	echo "${czm} Buildorder list for ${package}:"
	nl "${tmph}"/buildorder.file

	echo "${czm} AUR dependencies list for ${package}:"
	nl "${tmph}"/dependencies.file

	readarray -t -O1 buildorder <"${tmph}"/buildorder.file

	depi=$(( ${#buildorder[*]} - 1 ))
	pkgi="${#buildorder[*]}"

	for dependency in "${buildorder[@]:0:${depi}}"
    do

	cd "${homebuilduser}/${dependency}"							|| { echo "[line ${LINENO}]" ; exit 1 ; }
	package="${dependency}"

	fetch_pgp_key

	echo "${czm} Building and installing ${buildorder[${pkgi}]} dependency: ${dependency}"

	set_perm

	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${dependency}" --pipe \
	aur build -ns --margs -i

	rest_perm

    done
        echo  "${czm} Building: ${buildorder[${pkgi}]}"

	cd "${homebuilduser}/${buildorder[${pkgi}]}"						|| { echo "[line ${LINENO}]" ; exit 1 ; }
	package="${buildorder[${pkgi}]}"

	fetch_pgp_key

	set_perm

	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${buildorder[pkgi]}" --pipe bash << EOF
	aur build -fnsr --margs -C --results=aur-build-raw.log |& tee aurch-container-build.log
EOF

if	git pull | grep -q 'up to date'; then
	printf '%s\n' "current" | sudo tee "${tmph}"/warning.file &>/dev/null
fi
if	grep '^build:' aur-build-raw.log ; then
	grep '^build:' aur-build-raw.log > aur-build.log
fi

	rest_perm
#------------------------------### Move packages to host, print results ###------------------------------#

	find "${chroot}"/build/*pkg.tar* 2>/dev/null >"${tmph}"/after.file

	comm -23 <(sort "${tmph}"/after.file) <(sort "${tmph}"/before.file) >"${tmph}"/move.file

	for pkg in $(< "${tmph}"/move.file)
    do
	sudo cp "${pkg}" "${AURREPO}"								|| { echo "cp err [line ${LINENO}]"; exit 1 ; }
	basename "${pkg}" >> "${tmph}"/moved.file
    done
	cleanup_chroot

if	[[ -s  ${tmph}/moved.file ]] ; then
	echo "${czm} Copied AUR package/s to host AURREPO:"
	nl "${tmph}"/moved.file

    else	#------------------------------### For rebuilt packages ###------------------------------#

	readarray -t movepkgs < <(awk -F'/' '{print $5}' "${homebuilduser}/${buildorder[${pkgi}]}"/aur-build.log)

	if	[[ -s "${tmph}"/warning.file ]] && [[ -v movepkgs ]]; then

			for package in "${movepkgs[@]}"
	    		do
				sudo cp  "${chroot}"/build/"${package}"  "${AURREPO}"
	    		done

		echo "${czm} Copied rebuilt pkgs to host AURREPO:"
		printf '%s\n' "${movepkgs[@]}" | nl
	fi
fi

	cacheA=$(find "${AURREPO}"/*pkg.tar*|sort)
	comm -23 <(printf '%s\n' "${cacheA}") <(printf '%s\n' "${cacheB}") | tee > "${tmph}"/added-pkgs.file

	upd_aur_db
	sudo pacsync "${REPONAME}" >/dev/null

#------------------------------### Optionally install package ###------------------------------#

if	[[ "${opt-}" == -Bi ]]; then
	echo "${czm} Installing ${buildorder[${pkgi}]} in host."
	sudo pacsync "${REPONAME}" ; wait
	sudo pacman -S "${buildorder[${pkgi}]}"
fi
}
#========================================================================================================================#
fetch_pgp_key(){
	echo "${czm} Checking pgp key for ${package}."

if	[[ -e .SRCINFO ]]; then
	echo "[sudo] to run systemd-nspawn on chroot."
	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${package}" --pipe \
	awk '/validpgpkeys/ {print $3}' .SRCINFO >pgp-keys.file					# SC2024: Is not ran as sudo within chroot.
												# https://github.com/koalaman/shellcheck/issues/2358
    else
	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${package}" --pipe \
	makepkg --printsrcinfo | awk '/validpgpkeys/ {print $3}' >pgp-keys.file
fi
if	[[ -s pgp-keys.file ]] ; then
	for key in $(< pgp-keys.file); do
		sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${package}" --pipe bash << EOF
		if	! gpg -k "${key}" &>/dev/null ; then
			gpg --keyserver keyserver.ubuntu.com --recv-key "${key}" 2>&1 |& grep -v 'insecure memory'
		   else
			echo "gpg   aurch chroot local key data:"
			gpg -k "${key}" |& grep -v 'insecure memory'
		fi
EOF
		done
    else
	rm pgp-keys.file
fi
}
#========================================================================================================================#
cleanup_chroot(){

if	[[ ! -e ${tmph}/orig-pkgs.log ]]; then
	awk '{print $2}'  "${BASEDIR}"/.#orig-pkgs.log | sort  >"${tmph}"/orig-pkgs.log
fi
	echo "${czm} Checking/Cleaning chroot."

	sudo systemd-nspawn -a -q -D "${chroot}" --pipe /usr/bin/bash << EOF
	comm -23 <(pacman -Qq) <(sort "${tmpc}"/orig-pkgs.log) | xargs  pacman -Rns --noconfirm 2>/dev/null \
	|| echo " Package count: $(pacman -b "${chroot}/var/lib/pacman/" --config "${chroot}/etc/pacman.conf" --noconfirm -Qq | wc -l)"
EOF
	sudo rm "${tmph}"/orig-pkgs.log
}
#========================================================================================================================#
upd_aur_db(){

if	find "${AURREPO}"/*.db.tar.gz &>/dev/null && [[ -s "${tmph}"/added-pkgs.file ]]; then
	echo "${czm} Adding package/s to host 'AURREPO' database."
	udb=alldone
	while IFS= read -r pkg; do
	sudo repo-add "${AURREPO}"/"${REPONAME}".db.tar.gz "${pkg}"
	done < "${tmph}"/added-pkgs.file
fi
if	[[ ${udb-} == alldone ]]; then
	return
    else
	if	find "${AURREPO}"/*.db.tar.gz &>/dev/null && [[ -s "${tmph}"/warning.file ]]; then
		echo "${czm} Adding package/s to host 'AURREPO' database"
		while IFS= read -r pkg; do
		sudo repo-add "${AURREPO}"/"${REPONAME}".db.tar.gz "${AURREPO}"/"${pkg}"
		done	< <(awk -F'/' '{print $NF}' "${homebuilduser}/${buildorder[${pkgi}]}"/aur-build.log)
	fi
fi
}
#========================================================================================================================#
remove(){

if	[[ -n ${pkg} ]]; then

	if	[[ ${1} == -Rc ]]; then
		if	pacman -b "${chroot}/var/lib/pacman/" \
				--config "${chroot}/etc/pacman.conf" \
				-Slq aur \
			| grep -q "${pkg}"; then
			sudo systemd-nspawn -a -q -D "${chroot}" --pipe \
			repo-remove /build/aur.db.tar.gz "${pkg}"
			cd "${chroot}"/build							|| { echo "[line ${LINENO}]" ; exit 1 ; }

			remove=$(find "${pkg}"*.pkg.tar*)
			sudo rm  ${remove} && echo "${czm} Removed ${remove} from /build."	# SC2086 Removed quotes for proper operation.
			cd "${homebuilduser}"							|| { echo "[line ${LINENO}]" ; exit 1 ; }
			sudo rm -rdf "${pkg}"
			sudo systemd-nspawn -a -q -D "${chroot}" --pipe pacsync aur
		    else
			echo "${czm} ${pkg} not present in chroot AUR repo."
			if	[[ -d "${homebuilduser}"/"${pkg}" ]]; then
				sudo rm -rd "${homebuilduser}"/"${pkg}"
				echo "${czm} Removed ${pkg} build dir from chroot."
				remove=$(find "${chroot}"/build/ -type f -name "${pkg}*.pkg.tar*" 2>/dev/null)
				if	[[ -n ${remove} ]]; then
					sudo rm -f "${remove}"
					echo "${czm} Removed $(basename "${remove}") from chroot /build."
				    else
					echo "${czm} ${pkg} not present in chroot /build."
				fi
			    else
				echo "${czm} ${pkg} build dir in chroot not present."
			fi
		fi
	fi
	if	[[ ${1} == -Rh ]]; then
		if	pacman -Q "${pkg}" &>/dev/null ; then
			sudo pacman -Rns "${pkg}"
		fi
	cd "${AURREPO}"										|| { echo "[line ${LINENO}]" ; exit 1 ; }
	remove=$(find "${pkg}"*.pkg.tar*)
	sudo rm ${remove} && echo "${czm} Removed ${remove}"					# SC2086 Removed quotes for proper operation.
		if	pacman -Slq "${REPONAME}" | grep -q "${pkg}"; then
			sudo repo-remove "${AURREPO}"/"${REPONAME}".db.tar.gz "${pkg}"
			sudo pacsync "${REPONAME}"  >/dev/null
		    else
			echo "${czm} Package ${pkg} is not present in host AUR repo."
		fi
	fi
    else
	echo "${czm} Need to specify package."; echo
fi
}
#========================================================================================================================#
check_chroot_updates(){

	cd "${homebuilduser}"									|| { echo "[line ${LINENO}]" ; exit 1 ; }

	rm -f /tmp/check-ud-updates
	readarray -t dirs < <(find "${homebuilduser}" -maxdepth 1 -mindepth 1 -type d -name "[!.]*" -printf '%f\n'|sort)

if	[[ $1 != -Lucq ]]; then
	echo "${czm} Checking for updates on:"
	printf '%s\n' "${dirs[@]}" | nl
fi
	for pkg in "${dirs[@]}"
    do
	cd "${homebuilduser}/${pkg}"								|| { echo "[line ${LINENO}]" ; exit 1 ; }
	if	[[ -d .git ]]; then
		localHEAD=$(git rev-parse HEAD)
		remoteHEAD=$(git ls-remote --symref -q  | head -1 | cut -f1)

		if	[[ ${localHEAD} != "${remoteHEAD}" ]]; then
				echo " ${pkg}" >> /tmp/check-ud-updates
		fi
	fi
    done
if	[[ -s  /tmp/check-ud-updates ]]; then
	if	[[ $1 != -Lucq ]]; then
		echo >> /tmp/check-ud-updates
		echo "${czm}  Updates available:"
	fi
	cat /tmp/check-ud-updates
    else
	if	[[ $1 != -Lucq ]]; then
		echo "${czm} No updates available."
	fi
fi
}
#========================================================================================================================#
check_host_updates(){

	readarray -t aurpkgs < <(pacman --color=never -Slq "${REPONAME}" | pacman -Q - 2>/dev/null; pacman --color=never -Qm 2>/dev/null)
if	[[ $1 == -Luhq ]]; then	:
    else
	echo; echo "${czm} Checking for updates:"
	printf '%s\n' "${aurpkgs[@]%' '*}" | nl | column -t
fi
	rm -f /tmp/aurch-updates /tmp/aurch-updates-newer

for pkg in "${aurpkgs[@]}"; do {

    	pckg="${pkg%' '*}"

	check=$(curl -s "https://aur.archlinux.org/rpc?v=5&type=info&arg=${pckg}" | jshon -e results -a -e  Version -u)

	compare=$(vercmp "${pkg#*' '}" "${check}")

	if	[[ -n  ${check} && ${compare} == -1 ]]; then
		echo "${pkg} -> ${check}" >>/tmp/aurch-updates
    	elif	[[ -n  ${check} &&  ${compare} == 1 ]]; then
    		echo "${pkg} <- ${check}" >>/tmp/aurch-updates-newer
	fi } &

done; wait

if	[[ $1 == -Luhq ]]; then
	awk '{print $1}' /tmp/aurch-updates 2>/dev/null
    else
	if	[[ -s  /tmp/aurch-updates ]]; then
		echo; echo "${czm} Updates available:"
	 	column -t /tmp/aurch-updates
		echo
	    else
		echo; echo "${czm} No Updates available"
	fi
	if	[[ -s  /tmp/aurch-updates-newer ]]; then
		echo "${czm} VCS Packages newer than AUR rpc version. Run 'aurch -Luc' to check them for updates."
		column -t /tmp/aurch-updates-newer
		echo
	fi
fi
}
#========================================================================================================================#
list_pkgs_host(){

	echo
        sudo pacsync "${REPONAME}" >/dev/null

if	[[ ${1} == -Lahq ]]; then
 	pacman --color=always -Slq "${REPONAME}"
    else
	pacman --color=always -Sl "${REPONAME}" | awk '{$1="" ; print}' | nl | column -t
fi
}
#========================================================================================================================#
list_pkgs_chroot(){

	sudo systemd-nspawn -a -q -D "${chroot}" << EOF pacsync aur >/dev/null ; echo
EOF
if	[[ ${1} == -Lacq ]]; then
	pacman --color=always -b "${chroot}/var/lib/pacman/" --config "${chroot}/etc/pacman.conf" --noconfirm -Slq aur
    else
	pacman --color=always -b "${chroot}/var/lib/pacman/" --config "${chroot}/etc/pacman.conf" --noconfirm -Sl aur \
	| awk '{$1="" ; print}' | nl | column -t
fi
}
#========================================================================================================================#
update_chroot(){
	sudo systemd-nspawn -a -q -D "${chroot}" --pipe pacman -Syu
}
#========================================================================================================================#
login_chroot(){
	sudo systemd-nspawn --background=0 -a -q -D "${chroot}"  su root
}
#========================================================================================================================#
manual_pgp_key(){

	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser  --pipe \
	gpg --keyserver keyserver.ubuntu.com --recv-key "${key}"
exit
}
#========================================================================================================================#
yes_no(){

	message(){ printf '\n%s\n' "             Proceeding with build...." ; }

	printf '%s\n'            "${czm} Inspect git cloned files?"
	while true; do
    		read -n1 -p "             Enter  [y/n] for yes/no " -r yn
    		case $yn in
        	[Yy]* )           inspect_files "${1-}" ; break	;;
        	[Nn]* ) message ; opt="${1-}" build_pkg ; break	;;
        	    * ) echo "${czm}${error}[y/n] Only!"	;;
		esac
	done
}
#========================================================================================================================#
inspect_files(){

if	[[ -s  ${tmph}/cloned-pkgs.file ]]; then
	while IFS= read -r pkg; do
	"${AURFM}" "${homebuilduser}"/"${pkg}"
	done < "${tmph}"/cloned-pkgs.file
    else
	"${AURFM}" "${homebuilduser}"/"${package}"
fi
	opt="${1}" build_pkg
}
#=======================================### EXPERIMENTAL: Clean chroot build  ###========================================#
build-clean-chroot(){

	printf '\n%s\n' "${czm} ${warn} Clean chroot building is a WIP that needs additional work and testing."
	printf '%s\n'   "${czm} This function changes, then restores filesystem permissions and sudo config as temporary convenience"
	printf '%s\n'   "${czm} workarounds. It's working with minimal testing ATM. Look at the code and proceed at your discretion."
	printf '%s\n' "${czm} Proceed? [y/n]."

	while read -n1 -r reply
	do
		[[ ${reply} == y ]] && echo && break
		[[ ${reply} == n ]] && echo && exit
	done

	echo "${czm} 'aurch -Cc' needs aurutils, checking..."
if	! type -P aur &>/dev/null ; then								# Check and install aurutils if needed

	printf '%s\n' "${czm} Aurutils not installed. Installing it now."
	printf '%s\n' "${czm} Proceed? [y/n]"

	while read -n1 -r reply
	do
		if	[[ ${reply} == y ]]; then
			echo
			if	pacman -Ssq aurutils &>/dev/null ; then
				sudo pacman -S aurutils
		    	    else
				aurch -Bi aurutils
			fi
			break
		fi
		if	[[ ${reply} == n ]]; then
			echo
			echo " Exiting script."
			exit
		fi
	done
    else
	printf '%s\n' "${czm} $(pacman -Q --color=always aurutils) installed."
fi
	[[ ! -d /var/tmp/aurch ]] && mkdir /var/tmp/aurch						# Create log dir if needed

#####################  CREATE AND CONFIGURE 'AUR CHROOT' IF NEEDED ##################################

if	[[ ! -d /var/lib/aurbuild/x86_64/root ]]; then							# Create clean chroot if needed

	sudo paccat pacman -- pacman.conf  | sudo tee /etc/aurutils/pacman-x86_64.conf &>/dev/null
	sudo paccat pacman -- makepkg.conf | sudo tee /etc/aurutils/makepkg-x86_64.conf &>/dev/null
	sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/g'  /etc/aurutils/pacman-x86_64.conf

	aur chroot --create

	if	! grep -q 'aurch' /etc/aurutils/pacman-x86_64.conf ; then

		cat <<-EOF | sudo tee -a /etc/aurutils/pacman-x86_64.conf &>/dev/null
		#
		### Aurch created config for 'aur build'. ###
		#
		[options]
		CacheDir    = /usr/local/aurch/repo
		CleanMethod = KeepInstalled

		[aur]
		SigLevel = Never TrustAll
		Server = file:///usr/local/aurch/repo

EOF
		printf '\n%s\n' "${czm} Configured '/etc/aurutils/pacman-x86_64.conf' to use aurch local AUR repo."
	fi
fi
#####################  S T A R T   B U I L D ##################################

	rm -f /var/tmp/aurch/*										# Remove existing log files

	cd "${homebuilduser}"

	[[ -d  "${homebuilduser}/${package}" ]] && sudo rm -rd "${homebuilduser}/${package}"

	aur depends -r "${package}" | tsort |
		tee /var/tmp/aurch/cloned-pkgs.log |
		aur fetch -S -

	printf '%s\n' "${czm} Git cloned ${package} and AUR dependencies."
	nl /var/tmp/aurch/cloned-pkgs.log

	printf '\n%s\n\n' "${czm} Inspect git cloned files? [y/n]"

if	[[ ! -d  ${HOME}/.gnupg/ ]]; then
	gpg --list-keys &>/dev/null
fi
	while read -n1 -r reply
	do
		[[ ${reply} == y ]] && "${AURFM}" "${homebuilduser}"/"${package}" && break
		[[ ${reply} == n ]] && echo && break
	done
													# Build packages in cloned-pkgs.log
	while read -r build
	do
		cd "${homebuilduser}/${build}" || exit
		awk '/validpgpkeys/ {print $3}' .SRCINFO  >pgp-keys.file
		printf '%s\n' "${czm} Building ${build} in clean chroot."
		printf '%s\n\n' "${czm} Managing pgp keys."

		while read -r key
		do
			gpg --recv-key "${key}" 2>&1 |& grep -v 'insecure memory'
		done < pgp-keys.file
													# Fix using a local repo outside HOME
		sudo chmod 646 /usr/local/aurch/repo/aur.db.tar.gz
		sudo chmod 757 /usr/local/aurch/repo/
													# Fix bs successive sudo prompts...
		printf '%s\n' "${USER} ALL=(ALL) NOPASSWD: /usr/bin/pacman" |
				sudo tee /etc/sudoers.d/aurch &>/dev/null

		aur build -cfnsr --results=aur-build.log
													# BUILD INDIVIDUAL CHROOT PACKAGES
		sudo rm /etc/sudoers.d/aurch
													# Remove sudo config and restore permissions
		sudo chmod 644 /usr/local/aurch/repo/aur.db.tar.gz
		sudo chmod 755 /usr/local/aurch/repo/

		awk -F'/' '{print $NF}' aur-build.log >> /var/tmp/aurch/build.log

	done   < /var/tmp/aurch/cloned-pkgs.log

	printf '%s\n' "${czm} Cleaning local AUR package cache."

	keeppkgs=$(aurch -Lahq | xargs | sed 's/ /,/g')

	sudo paccache -rk0 -i "${keeppkgs}" -c /usr/local/aurch/repo/

	printf '%s\n' "${czm} Clean chroot build location: $(aur chroot --path)"
	printf '%s\n' "${czm} Copied and registered the following pkgs to host AUR repo: ${AURREPO}"

	while read -r packgs
	do
		aurch -Lah | grep --color=never "${packgs}" | cut -c 3-

	done < /var/tmp/aurch/cloned-pkgs.log
	echo
}
#=======================================### Aurch called with no args ###================================================#

if      [[ -z ${*} ]]; then cat << EOF
	$(echo -e '\033[0;96m')
 |================================================================================|
 |   Aurch, an AUR helper script.    USAGE:  $ aurch [operation[*opt]] [package]  |
 |--------------------------------------------------------------------------------|
 |      -B*   build AUR package                 -Luc*   list updates chroot       |
 |      -G    git clone package                 -Luh*   list updates host         |
 |      -C    build on existing git clone       -Lac*   list AUR sync db chroot   |
 |     -Rc    remove AUR pkg from container     -Lah*   list AUR sync db host     |
 |     -Rh    remove AUR pkg from host         --pgp    import pgp key            |
 |    -Syu    update chroot                  --clean    remove unneeded packages  |
 |      -V    print version                  --login    log into chroot           |
 |      -h    help				 -Lv    list expanded variables   |
 |                                                                                |
EOF
	printf '%-82s|\n' " |            Container Path:  ${chroot}"
	echo " |================================================================================|"
	echo -e '\033[00m'
fi
#========================================================================================================================#
while :; do
	case "${1-}" in
	-B*|--build)		fetch_pkg ; yes_no	"${1-}"			;;
	-G|--gitclone)		fetch_pkg					;;
	-C|--compile)		opt="${1-}" build_pkg				;;
	-Cc|--cchroot)		build-clean-chroot	"${1-}"			;;
	-R*)			pkg="${2-}" remove	"${1-}"			;;
	-Syu|--update)		update_chroot					;;
	-Luh*|--lsudh)		check_host_updates	"${1-}"			;;
	-Luc*|--lsudc)		check_chroot_updates	"${1-}"			;;
	-Lah*|--lsaurh)		list_pkgs_host		"${1-}"			;;
	-Lac*|--lsaurc)		list_pkgs_chroot	"${1-}"			;;
	-Lv)			print_vars					;;
	--login)		login_chroot					;;
	--clean)		cleanup_chroot					;;
	--pgp)			key="${2-}" manual_pgp_key			;;
	-h|--help)		help						;;
	-V|--version)	awk -e '/^# aurch/ {print $2,$3}' "$(which aurch)"	;;
	-?*)		help ; echo "${czm}${error} Input error. Running help"	;;
	*)		break
        esac
    shift
done
