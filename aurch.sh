#!/bin/bash
# aurch 2024-08-03
# dependencies: base-devel git pacutils(pacsync) jshon mc
# shellcheck source=aurch-cc #Run with: shellcheck -x aurch

set -euo pipefail

#========================================================================================================================#

#-----------------------------------# 3 User variables below. Uncomment and set paths. #--------------------------------#
#------------------# IMPORTANT: These variables must match those used in aurch-setup if changed/set #-------------------#
#--------------------------# If you did not changed/set them in aurch-setup, do nothing here #--------------------------#

# BASEDIR="${HOME}"/.cache/aurch/base						# HOST  path to chroot base
# AURREPO="${HOME}"/.cache/aurch/repo						# HOST  path to aur repo
# REPONAME=aur									# HOST  aur repo name

#========================================================================================================================#
[[ ! -v BASEDIR ]] && BASEDIR="${HOME}"/.cache/aurch/base			# HOST    Set BASEDIR to default if unset
cd "${BASEDIR}" || { echo "[line ${LINENO}]"; exit 1 ; }			#         cd to BASEDIR
chroot="${BASEDIR}/chroot-$(< .#ID)"						# HOST    path to chroot root
chrbuilduser="/home/builduser"							# CHROOT  builduser home directory (same destination)
homebuilduser="${chroot}"/home/builduser					# HOST    builduser home directory (same destination)
[[ -n ${2-} ]] && package="${2,,}" || package="" 				#         Convert <package> input to all lower case
[[ ! -v AURREPO  ]] && AURREPO="${HOME}"/.cache/aurch/repo			# HOST    Set AURREPO to default if unset
[[ ! -v REPONAME ]] && REPONAME=aur						# HOST    Set REPONAME to default if unset
tmpc="/var/tmp/aurch"								# CHROOT  path to tmp dir (same destination)
tmph="${chroot}${tmpc}"								# HOST    path to tmp dir (same destination)

czm=$(echo -e '\033[1;96m'":: aurch ==>"'\033[00m')				# Aurch color pointer
error=$(echo -e '\033[1;91m' "ERROR:" '\033[00m')				# Red 'ERROR' text
line2=$(printf %"$(tput cols)"s |tr " " "-") 					# Set line '---' to terminal width
#========================================================================================================================#
# Print variables to .#aurch-vars

	cd "${BASEDIR}"									|| { echo "[line ${LINENO}]" ; exit 1 ; }
	echo "
	BASEDIR=${BASEDIR-}
	AURREPO=${AURREPO-}
	REPONAME=${REPONAME-}
	chroot=${chroot-}
	chrbuilduser=${chrbuilduser-}
	homebuilduser=${homebuilduser-}
	package=${package-}
	tmpc=${tmpc-}
	tmph=${tmph-}" \
	| awk ' {print;} NR % 1 == 0 {print "";}' > "${BASEDIR}"/.#aurch-vars

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
		-G  --git	Git clones an AUR package.
		-C  --compile	Build an AUR package on existing PKGBUILD. Useful for implementing changes to PKGBUILD.
		-Rh		Remove AUR pkg from host.   Removes:   /AURREPO/<package>,  <package> if installed,  and database entry.
		-Rc		Remove AUR pkg from nspawn container. Removes:   /build/<package>,    /${HOME}/<build dir>,    and database entry.
		-Syu  --update  Update nspawn container packages. ie: Runs 'pacman -Syu' inside the nspawn container.
		-Luh* --lsudh	List update info for AUR packages installed in host.
		-Luc* --lsudc	List update info for AUR packages/AUR dependencies in nspawn container.
		-Lah* --lsaurh	List AUR sync database contents/status of host.
		-Lac* --lsaurc	List AUR sync database contents/status of nspawn container.
		      --login   Login to nspawn container for maintenance.
		      --clean	Manually remove unneeded packages from nspawn container.
		      --pgp	Manually import pgp key in nspawn container.
		-h,   --help	Prints help.
		-V,   --version Prints aurch version.

OPTIONS
	-L, List:
		Append 'q' to  -L list operations for quiet mode.
		Example: aurch -Luhq
		Do not mix order or attempt to use 'q' other than described.

	-B, Build:
		Append 'i' to build operation -B to install package in host.
		Example: aurch -Bi
		Do not mix order or attempt to use 'i' other than described.

OVERVIEW
    		Run aurch-setup before using aurch.
    		Run aurch to manage AUR packages.
    		Aurch is designed to handle AUR packages individually, one at a time.
    		ie: No group updates or multi package per operation capability.
    		The aurch nspawn container must be periodically updated via the 'aurch -Syu' command.
    		Update nspawn container before buiding packages.

EXAMPLES
    		SETUP FOR AURCH:

    		Set up nspawn container:				aurch-setup --setupchroot
    		Set up local AUR repo:					aurch-setup --setuphost


    		USING AURCH:

    		Build an AUR package(+):				aurch -B  <aur-package>
    		Build and install AUR package:				aurch -Bi <aur-package>
    		Git clone package					aurch -G  <aur-package>
    		Build (Compile) AUR pkg on existing PKGBUILD		aurch -C  <aur-package>
    		Remove AUR package from host:				aurch -Rh <aur-package>
    		Remove AUR package from nspawn container:		aurch -Rc <aur-package>
    		List nspawn container AUR sync db contents:		aurch -Lac
    		List nspawn container AUR repo updates:			aurch -Luc
    		List host AUR sync database contents:			aurch -Lah
    		List host AUR repo updates available:			aurch -Luh
    		Manually import a pgp key in nspawn container:		aurch --pgp <short or long key id>
    		Manually remove unneeded packages in nspawn container:	aurch --clean
    		Login to chroot for maintenance:                	aurch --login

		(+) Package is placed into host AUR repo and entry made in pacman AUR database.
		    Install with 'pacman -S <aur-package>'

VARIABLES
    		BASEDIR = path to chroot base dir
    		AURREPO = path to host aur repo
    		REPONAME =  host aur repo name
		AURFM = AUR file manager,editor (mc = midnight commander)

MISC
		Aurch runtime messages will be proceeded with this:	${czm}
		Aurch runtime errors will be proceeded with this:	${czm}${error}

${line2}
EOF
}
#========================================================================================================================#
fetch_pkg(){

	[[ -z ${package} ]] && { echo "${czm} Need to specify package."; echo; exit ; }

	is_it_available
	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}" --pipe << EOF
	aur depends -r "${package}" | tsort | aur fetch -S - |& tee >(grep 'Cloning' |cut -d"'" -f 2 >"${tmpc}"/cloned-pkgs.file)
EOF

if	[[ -s ${tmph}/cloned-pkgs.file ]]; then
	echo "${czm} Git cloned ${package} and/or it's dependencies:"

	# awk -F\' '/Cloning/ {print $2}' "${tmph}"/cloned-pkgs.file | nl
	nl "${tmph}"/cloned-pkgs.file
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

	rm -f "${tmph}"/*.file

if	[[ ! -f ${AURREPO}/placeholder.pkg.tar ]]; then
	touch "${AURREPO}"/placeholder.pkg.tar
fi
	cacheB=$(find "${AURREPO}"/*pkg.tar* 2>/dev/null |sort)

if	[[ ! -f ${chroot}/build/placeholder.pkg.tar ]]; then
	touch "${chroot}"/build/placeholder.pkg.tar
fi
	find "${chroot}"/build/*pkg.tar* 2>/dev/null >"${tmph}"/before.file

	cd "${homebuilduser}"									|| { echo "[line ${LINENO}]" ; exit 1 ; }

	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}" --pipe bash << EOF
	aur depends -r "${package}" | tsort >"${tmpc}"/buildorder.file
	aur depends -n -r "${package}" | tsort | grep -v "${package}" >"${tmpc}"/dependencies.file || { echo "0 deps" ; }
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

	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${dependency}" --pipe \
	aur build -ns --margs -i
    done
        echo  "${czm} Building: ${buildorder[${pkgi}]}"

	cd "${homebuilduser}/${buildorder[${pkgi}]}"						|| { echo "[line ${LINENO}]" ; exit 1 ; }
	package="${buildorder[${pkgi}]}"

	fetch_pgp_key

	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${buildorder[pkgi]}" --pipe bash << EOF
	aur build -fnsr --margs -C --results=aur-build.log |& tee >(grep 'WARNING:'       >"${tmpc}"/warning.file) \
							   |  tee >(grep 'Adding package' >"${tmpc}"/pkg-nv.file)
EOF
#------------------------------### Move packages to host, print results ###------------------------------#

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

    else #------------------------------### For rebuilt packages ###------------------------------#

	readarray -t movepkgs < <(awk -F'/' '{print $5}' "${homebuilduser}/${buildorder[${pkgi}]}"/aur-build.log)

	if	[[ -s "${tmph}"/warning.file ]] && [[ -v movepkgs ]]; then

		for package in "${movepkgs[@]}"
	    do
		cp  "${chroot}"/build/"${package}"  "${AURREPO}"
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

	sudo /usr/bin/systemd-nspawn -a -q -D "${chroot}" --pipe /usr/bin/bash << EOF
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
	repo-add "${AURREPO}"/"${REPONAME}".db.tar.gz "${pkg}"
	done < "${tmph}"/added-pkgs.file
fi
if	[[ ${udb-} == alldone ]]; then
	return
    else
	if	find "${AURREPO}"/*.db.tar.gz &>/dev/null && [[ -s "${tmph}"/warning.file ]]; then
		echo "${czm} Adding package/s to host 'AURREPO' database"
		while IFS= read -r pkg; do
		repo-add "${AURREPO}"/"${REPONAME}".db.tar.gz "${AURREPO}"/"${pkg}"
		done	< <(awk -F'/' '{print $5}' "${homebuilduser}/${buildorder[${pkgi}]}"/aur-build.log)
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
			repo-remove "${chroot}"/build/aur.db.tar.gz "${pkg}"
			cd "${chroot}"/build							|| { echo "[line ${LINENO}]" ; exit 1 ; }

			remove=$(find "${pkg}"*.pkg.tar*)
			rm  ${remove} && echo "${czm} Removed ${remove} from /build."		# SC2086 Removed quotes for proper operation.
			cd "${homebuilduser}"							|| { echo "[line ${LINENO}]" ; exit 1 ; }
			sudo rm -rd "${pkg}"
			sudo systemd-nspawn -a -q -D "${chroot}" --pipe pacsync aur
		    else
			echo "${czm} ${pkg} not present in chroot AUR repo."
			if	[[ -d "${homebuilduser}"/"${pkg}" ]]; then
				sudo rm -rd "${homebuilduser}"/"${pkg}"
				echo "${czm} Removed ${pkg} build dir from chroot."
				remove=$(find "${chroot}"/build/ -type f -name "${pkg}*.pkg.tar*" 2>/dev/null)
				if	[[ -n ${remove} ]]; then
					rm -f "${remove}"
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
	rm ${remove} && echo "${czm} Removed ${remove}"						# SC2086 Removed quotes for proper operation.
		if	pacman -Slq "${REPONAME}" | grep -q "${pkg}"; then
			repo-remove "${AURREPO}"/"${REPONAME}".db.tar.gz "${pkg}"
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
	if	[[ $1 != -Luq ]]; then
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

	readarray -t aurpkgs < <(pacman --color=never -Slq "${REPONAME}" | pacman -Q - ; pacman --color=never -Qm)
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
	sudo systemd-nspawn -a -q -D "${chroot}"  su root
}
#========================================================================================================================#
manual_pgp_key(){

	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser  --pipe \
	gpg --keyserver keyserver.ubuntu.com --recv-key "${key}"
exit
}
#========================================================================================================================#
yes_no(){

	echo            "${czm} Inspect git cloned files?"
	while true; do
    		read -p '             Enter  [y/n] for yes/no ' yn				# SC2162 Command fails using -r.
    		case $yn in
        	[Yy]* ) inspect_files "${1}" ; break		;;
        	[Nn]* ) opt="${1}" build_pkg ; break		;;
        	    * ) echo "${czm}${error}[y/n] Only!"	;;
		esac
	done
}
#========================================================================================================================#
inspect_files(){

	AURFM=mc
if	[[ -s  ${tmph}/cloned-pkgs.file ]]; then
	while IFS= read -r pkg; do
	"${AURFM}" "${homebuilduser}"/"${pkg}"
	done < "${tmph}"/cloned-pkgs.file
    else
	"${AURFM}" "${homebuilduser}"/"${package}"
fi
	opt="${1}" build_pkg
}
#=======================================### EXPERIMENTAL: Clean chroot build  ###================================================#

clean_chroot(){

aurcc="$(type -p aurch)-cc"

if	[[ -s "${aurcc}" ]]; then 
	printf '\n%s\n\n' "${error} Experimental feature 'build pkg in clean chroot' being enabled. Proceed? [y/n]."
	while read -r reply ; do
	[[ ${reply} == y ]] && break
	[[ ${reply} == n ]] && exit
	done
	source "${aurcc}"
fi

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
 |                                                                                |
EOF
	printf '%-82s|\n' " |       Container Path:  ${chroot}"
	echo " |================================================================================|"
	echo -e '\033[00m'
fi
#========================================================================================================================#
while :; do
	case "${1-}" in
	-B*|--build)	fetch_pkg ; yes_no	"${1-}" 			;;
	-G|--git)	fetch_pkg ; 						;;
	-C|--compile)	opt="${1-}" build_pkg					;;
	-Cc|--cchroot)	clean_chroot		"${1-}"				;;
	-R*)		pkg="${2-}" remove	"${1-}"				;;
	-Syu|--update)  update_chroot						;;
	-Luh*|--lsudh)	check_host_updates	"${1-}"				;;
	-Luc*|--lsudc)	check_chroot_updates	"${1-}"				;;
	-Lah*|--lsaurh)	list_pkgs_host		"${1-}"				;;
	-Lac*|--lsaurc)	list_pkgs_chroot	"${1-}"				;;
	--login)	login_chroot						;;
	--clean)	cleanup_chroot						;;
	--pgp)		key="${2-}" manual_pgp_key				;;
	-h|--help)	help							;;
	-V|--version)	awk -e '/^# aurch/ {print $2,$3}' "$(which aurch)"	;;
	-?*)		echo "${czm}${error} Input error. Running help" ; help	;;
	*)		break
        esac
    shift
done
