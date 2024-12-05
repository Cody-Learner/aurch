#!/bin/bash
# aurch 2024-12-05
# dependencies: base-devel pacman-contrib pacutils git jshon mc less
# shellcheck disable=SC2016 disable=SC2028  disable=SC1012 # Explicitly do not want expansion on 'echo' lines in 'print_vars'.

set -euo pipefail

	[[ -n "${2-}" ]]	&& package="${2,,}" || package="" 		#         Convert <package> input to all lower case
	[[ ! -v BASEDIR ]]	&& BASEDIR=/usr/local/aurch/base		# HOST    Set BASEDIR to default if unset
	[[ ! -v AURREPO  ]]	&& AURREPO=/usr/local/aurch/repo		# HOST    Set AURREPO to default if unset
	[[ ! -v REPONAME ]]	&& REPONAME=aur					# HOST    Set REPONAME to default if unset

chroot="${BASEDIR}"/chroot-$(< "${BASEDIR}"/.#ID)				# HOST    path to chroot root
chrbuilduser="/home/builduser"							# CHROOT  builduser home directory (same destination 1)
homebuilduser="${chroot}"/home/builduser					# HOST    builduser home directory (same destination 1)
tmpc="/var/tmp/aurch"								# CHROOT  path to tmp dir (same destination 2)
tmph="${chroot}${tmpc}"								# HOST    path to tmp dir (same destination 2)
AURFM=mc									# Application to inspect git cloned repos
logfile=/var/log/aurch.log							# Logfile destination
perm=$(stat -c '%a' "${chroot}"/build/aur.db.tar.gz)				# Container octal permission: /build/aur.db.tar.gz
czm=$(echo -e "\033[1;96m:: aurch ==>\033[00m")					# Aurch color pointer
error=$(echo -e "\033[1;91m ERROR:\033[00m")					# Red 'ERROR' text
warn=$(echo -e "\033[1;33m WARNING:\033[00m")					# Yellow 'WARNING' text
dt=$(printf '%s' "[$(date '+%Y-%m-%d %r')]")					# Date time in format: [2024-11-23 12:35:22 PM]
line2=$(printf %"$(tput cols)"s |tr " " "-") 					# Set line '---' to terminal width

if	[[ ! -e ${logfile} ]]; then
	printf '%s\n' "${czm} '${logfile}' not present, so lets create it."
	sudo touch ${logfile} ; sudo chown "${USER}":"${USER}" ${logfile}
fi
#========================================================================================================================#
print_vars(){
	printf '%s\n' "
	package=${package-}
	BASEDIR=${BASEDIR-}
	AURREPO=${AURREPO-}
	REPONAME=${REPONAME-}
	chroot=${chroot-}
	chrbuilduser=${chrbuilduser-}
	homebuilduser=${homebuilduser-}
	tmpc=${tmpc-}
	tmph=${tmph-}
	AURFM=${AURFM}
	logfile=${logfile}" | awk '{$1=$1};1'						| sudo tee    "${BASEDIR}"/.#aurch-vars
	echo 'perm=$(stat -c '%a' "${chroot}"/build/aur.db.tar.gz)'|sed "s/%a/\'%a\'/g"	| sudo tee -a "${BASEDIR}"/.#aurch-vars
	echo 'czm=$(echo -e "\033[1;96m:: aurch ==>\033[00m")'				| sudo tee -a "${BASEDIR}"/.#aurch-vars
	echo 'error=$(echo -e "\033[1;91m ERROR:\033[00m")'				| sudo tee -a "${BASEDIR}"/.#aurch-vars
	echo 'warn=$(echo -e "\033[1;33m WARNING:\033[00m")'				| sudo tee -a "${BASEDIR}"/.#aurch-vars
	echo 'dt=$(printf "%s" "[$(date "+%Y-%m-%d %r")]")'				| sudo tee -a "${BASEDIR}"/.#aurch-vars
	echo 'line2=$(printf %"$(tput cols)"s |tr " " "-")'				| sudo tee -a "${BASEDIR}"/.#aurch-vars

	printf '%s\n' "
	Last six lines expanded:
	perm=${perm}
	czm=${czm}
	error=${error}
	warn=${warn}
	dt=${dt}
	line2=${line2}" | awk '{$1=$1};1'

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
		-Cc* --cchroot  Build package in clean chroot using aurutils.
		-Rh		Remove AUR pkg from host. Removes: ${AURREPO}/<aur-package>, if installed <aur-package> and database entry.
		-Rc		Remove AUR pkg from container. Removes: /build/<package>, ${chrbuilduser}/<aur-package>, database entry.
		-Lah* --lsaurh	List all host AUR sync database contents/status.
		-Lac* --lsaurc	List all container AUR sync database contents/status.
		-Luh* --lsudh	List update info for AUR packages installed in host.
		-Luc* --lsudc	List update info for AUR packages/AUR dependencies in container.
		-Lv		List set variables in console and print to ${BASEDIR}/.#aurch-vars.
		-Syu  --update  Update container system. ie: Runs 'pacman -Syu' inside container.
		      --login   Login to nspawn container for maintenance.
		      --clean	Manually clean up nspawn container and host AUR pkg cache.
		      --pgp	Manually import pgp key into nspawn container.
                      --log	Display '/var/log/aurch.log'.
		-h,   --help	Prints help in 'less' pager. Press [q] to quit. Optionally, pipe into cat: 'aurch -h | cat'
		-V,   --version Prints aurch <version>.

*OPTIONS

  -B, Build:
		Append 'i' to build operation '-B' to install package in host.
		Example: aurch '-Bi <aurpkg>'
		Do not mix order or attempt to use 'i' other than described.

  -L, List:
		Append 'q' to  '-L' list operations for quiet mode.
		Example: 'aurch -Lahq'
		Do not mix order or attempt to use 'q' other than described.

  -Cc, Clean Chroot:
		Append 'b' to '-Cc' operation for both host and container(1).
		Example: 'aurch -Ccb <aurpkg>'
		Do not mix order or attempt to use 'b' other than described.

	   (1)  aurch '-Cc' builds and sets up pkg for host install only.
	   IE:	Use '-Ccb' to copy and register package in both host and
		container AUR cache and database.
	Usage:	Python2 is a dependency of several AUR packages, that must
		be built in a clean chroot to successfully pass tests.
		Use '-Ccb' to have it available as a prebuilt dependency
		in the aurch container when needed.


OVERVIEW
    		Run aurch-setup before using aurch.
    		Aurch is designed to handle AUR packages individually, one at a time.
    	   IE:	No group updates or multiple packages per operation capability.
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
		Aurch runtime warnings will be proceeded with this:	${czm}${warn}
		Aurch runtime errors will be proceeded with this:	${czm}${error}


${line2}
EOF
}
#========================================================================================================================#
ck_per(){
													# Check/correct repo perms, notify, log
	local=$(stat -c '%U:%G' "${AURREPO}/${REPONAME}".db.tar.gz)
	container=$(stat -c '%U:%G' "${chroot}"/build/aur.db.tar.gz)
if	[[ ${local} !=  "${USER}:${USER}" ]]; then
	printf '%s' "${dt} : Incorrect Permission reset "		>> "${logfile}"
	stat -c '%a  %U:%G  %n' "${AURREPO}/${REPONAME}".db.tar.gz	>> "${logfile}"
	printf '%s\n' "${czm}${warn} On local AUR repo permissions. Resetting..."
	sudo chown -R "${USER}:${USER}" "${AURREPO}"
fi
if	[[ ${container} !=  "${USER}:${USER}" ]]; then
	printf '%s' "${dt} : Incorrect Permission reset "		>> "${logfile}"
	stat -c '%a  %U:%G  %n' "${chroot}"/build/aur.db.tar.gz		>> "${logfile}"
	printf '%s\n' "${czm}${warn} On container AUR repo permissions. Resetting..."
	sudo chown -R "${USER}:${USER}" "${chroot}"/build
fi
}
#========================================================================================================================#
fetch_pkg(){
		rm -f "${tmph}"/rebuilt-pkg.logfile
		rm -f "${tmpc}"/cloned-pkgs.logfile
	[[ -z ${package} ]] && { printf '%s\n\n' "${czm}${error} Need to specify a package."; exit ; }

	is_it_available

if	[[ ! -d "${chroot}${tmpc}" ]]; then
	sudo systemd-nspawn -a -q -D "${chroot}" --pipe << EOF
	mkdir "${tmpc}"
EOF
	sudo systemd-nspawn -a -q -D "${chroot}" chmod -R 777 "${tmpc}"
fi
														# Deleted bld dir if PKGBUILD NA
if	[[ -d  "${homebuilduser}/${package}" ]] && [[ ! -s  "${homebuilduser}/${package}/PKGBUILD" ]]; then
	sudo rm -rd "${homebuilduser}/${package}"
fi
if	cd "${homebuilduser}/${package}" 2>/dev/null ;then
												# 'sudo printf' prevents printed msg before sudo prompt.
	if	git pull | grep -q 'up to date'; then
		sudo printf '%s\n' "${czm} Git repo current, rebuilding...."
		printf '%s\n' "Git repo current, rebuilding ${package}." >> "${tmph}"/rebuilt-pkg.logfile
	fi
fi
	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}" --pipe << EOF
	aur depends -r "${package}" | tsort | aur fetch -S - --results="${tmpc}"/cloned-pkgs.logfile
EOF

if	[[ -s ${tmph}/cloned-pkgs.logfile ]]; then
	printf '%s\n' "${czm} Git cloned ${package} and/or it's dependencies in container:"
	cut -d'/' -f3- "${tmph}"/cloned-pkgs.logfile | pr -To 13
	printf '%s\n' "${czm} Build dir: ${homebuilduser}/${package}"
fi
}
#========================================================================================================================#
is_it_available(){

	check=$(curl --compressed -s "https://aur.archlinux.org/rpc?v=5&type=info&arg=${package}" \
		| jshon -e results -a -e  Name \
		| awk -F\" '{print $2}')

if	[[ ${package} != "${check}" ]] ; then
	printf '%s\n' "${czm}${error}\"${package}\" not available. See: https://aur.archlinux.org/packages/" |& tee -a "${logfile}"
	exit 1
fi
}
#========================================================================================================================#
build_pkg(){
		rm -f "${tmph}"/*.file
	find "${AURREPO}"/ -name '*pkg.tar*' 2>/dev/null >"${tmph}"/host-aurrepo-before.file

if	[[ ! -d "${homebuilduser}/${package}" ]]; then
	printf '%s\n' "${czm}${error} Package build directory missing in container." ; cat <<-EOF | pr -to 5
        If running '-C --compile', run '-G --gitclone' first to fetch requirements."
EOF
	exit
fi
	find "${chroot}"/build/ -name '*pkg.tar*' 2>/dev/null >"${tmph}"/cont-aurrepo-before.file
	cd "${homebuilduser}"									|| { echo "[line ${LINENO}]" ; exit 1 ; }

	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}" --pipe bash << EOF
	aur depends -r "${package}" | tsort >"${tmpc}"/buildorder.file
	aur depends -n -r "${package}" | tsort | grep -v "^${package}$" >"${tmpc}"/dependencies.file \
	|| printf '%s\n' "None" >"${tmpc}"/dependencies.file
EOF
	printf '%s\n' "${czm} Buildorder list for ${package}:"
	nl -w12 -s" " "${tmph}"/buildorder.file

	printf '%s\n' "${czm} AUR dependencies list for ${package}:"
	deps=$(< "${tmph}"/dependencies.file)

if	[[ ${deps} != "None" ]]; then
	nl -w12 -s" " "${tmph}"/dependencies.file
    else
	pr -To 13 "${tmph}"/dependencies.file
fi
	readarray -t -O1 buildorder <"${tmph}"/buildorder.file

	depi=$(( ${#buildorder[*]} - 1 ))
	pkgi="${#buildorder[*]}"

	for dependency in "${buildorder[@]:0:${depi}}"
    do
	cd "${homebuilduser}/${dependency}"							|| { echo "[line ${LINENO}]" ; exit 1 ; }
	package="${dependency}"

	fetch_pgp_key

	printf '%s\n' "${czm} Building  ${dependency} , a dependency of:  ${buildorder[${pkgi}]}"

	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${dependency}" --pipe bash << EOF
	aur build -fns --margs -C --results=aur-build.log | tee aurch-container-build.log
	cut -d '/' -f5 aur-build.log >>"${tmpc}"/total.file
EOF
    done
	printf '%s\n'  "${czm} Building: ${buildorder[${pkgi}]}"

	cd "${homebuilduser}/${buildorder[${pkgi}]}"						|| { echo "[line ${LINENO}]" ; exit 1 ; }
	package="${buildorder[${pkgi}]}"

	fetch_pgp_key

	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${buildorder[pkgi]}" --pipe bash << EOF
	aur build -fnsr --margs -C --results=aur-build.log | tee aurch-container-build.log
	cut -d '/' -f5 aur-build.log >>"${tmpc}"/total.file
EOF
#------------------------------### Move packages to host, print results ###------------------------------#

	find "${chroot}"/build/*pkg.tar* 2>/dev/null >"${tmph}"/cont-aurrepo-after.file

	comm -23 <(sort "${tmph}"/cont-aurrepo-after.file) <(sort "${tmph}"/cont-aurrepo-before.file) >"${tmph}"/cont-aurrepo-add.file

	for pkg in $(< "${tmph}"/cont-aurrepo-add.file)
    do
	cp "${pkg}" "${AURREPO}"								|| { echo "cp err [line ${LINENO}]"; exit 1 ; }
	basename "${pkg}" >> "${tmph}"/moved-tohost.file
    done
	cleanup_chroot

if	[[ -s  ${tmph}/moved-tohost.file ]] ; then

	find "${AURREPO}"/ -name '*pkg.tar*' 2>/dev/null > "${tmph}"/host-aurrepo-after.file
	comm -23 <(sort "${tmph}"/host-aurrepo-after.file) <(sort "${tmph}"/host-aurrepo-before.file) >>"${tmph}"/host-added-pkgs.file
	upd_aur_db
	sudo pacsync "${REPONAME}" >/dev/null

	printf '%s\n\n' "${czm} Copied and registered the following pkgs to host AUR repo: ${AURREPO}"
	awk -F '-x86|-any' '{print $1}' "${tmph}"/moved-tohost.file | pr -To 13
	printf '\n'
    else	#------------------------------### For rebuilt packages ###------------------------------#

	readarray -t movepkgs < "${tmph}"/total.file

	if	[[ -s "${tmph}"/rebuilt-pkg.logfile ]] && [[ -v movepkgs ]]; then

			for package in "${movepkgs[@]}"
			do
				cp  "${chroot}"/build/"${package}"  "${AURREPO}"
			done

		upd_aur_db
		sudo pacsync "${REPONAME}" >/dev/null

		printf '%s\n\n' "${czm} Copied and registered the following rebuilt pkgs to host AUR repo: ${AURREPO}"
		printf '%s\n' "${movepkgs[@]}" | awk -F '-x86|-any' '{print $1}' | pr -To 13
		printf '\n'								  # Note: 'repad-ver.file' created in 'upd_aur_db' funct above.
		if	[[ -s "${tmph}"/repad-ver.file ]]; then

			if	! diff <(sort "${tmph}"/total.file) <(sort "${tmph}"/repad-ver.file); then
				printf '%s\n' "${czm}${error} Copy and register packages to host verification failed."
				printf '%s\n' "${tmph} /total.file and /repad-ver.file do not match."
			fi
		fi
	fi
fi
#------------------------------### Optionally install package ###------------------------------#

if	[[ "${opt-}" == -Bi ]]; then
	if	[[ -s "${tmph}"/repad-ver.file ]]; then
		printf '%s\n' "${czm} Installing in host:"
		sudo pacsync "${REPONAME}" ; wait
		sudo pacman -S - < <(sed -e's/-[0-9].*//g' -e's/-[a-z][0-9].*//g' "${tmph}"/repad-ver.file)   ### SC2024 Irrelevant in this case.
	    else
		printf '%s\n' "${czm} Installing ${buildorder[${pkgi}]} in host."
		sudo pacsync "${REPONAME}" ; wait
		sudo pacman -S "${buildorder[${pkgi}]}"
	fi
fi
}
#========================================================================================================================#
fetch_pgp_key(){
	printf '%s\n' "${czm} Checking pgp key for ${package}."

if	[[ -e .SRCINFO ]]; then
	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --chdir="${chrbuilduser}/${package}" --pipe \
	awk '/validpgpkeys/ {print $3}' .SRCINFO >pgp-keys.file         ### SC2024: Not ran as sudo. https://github.com/koalaman/shellcheck/issues/2358
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
			printf '%s\n' "gpg   aurch chroot local key data:"
			gpg -k "${key}" |& grep -v 'insecure memory'
		fi
EOF
		done
    else
	printf '%s\n' "pgp key not used" | pr -To 13
	rm pgp-keys.file
fi
}
#========================================================================================================================#
cleanup_chroot(){		# REMINDER: Change both dates below if heredoc script is modified.

if	[[ ! -e ${tmph}/orig-pkgs.log ]]; then
	awk '{print $2}'  "${BASEDIR}"/.#orig-pkgs.log | sort  >"${tmph}"/orig-pkgs.log
fi
	printf '%s\n' "${czm} Cleaning aurch nspawn container."

if	[[ $(grep '^#202*'  2>/dev/null "${chroot}"/bin/aurch-cleanup) !=  '#2024-11-22' ]]; then
	printf '%s\n' "${czm}${warn} Updating container 'aurch-cleanup' script."
												# Install cleanup script in container if needed
#---------------------------------------------- START Heredoc Script -----------------------------------------#

	cat << "EOF" | sudo tee "${chroot}"/usr/bin/aurch-cleanup &>/dev/null
#!/bin/bash
#2024-11-22

czm=$(echo -e '\033[1;96m'":: aurch ==>"'\033[00m')

	pacman -S --noconfirm pacman-contrib 1>/dev/null

	printf '%s\n' "${czm} Paccache output from cleaning both container package caches:"
	paccache -v --cachedir /var/cache/pacman/pkg/ --remove --keep 0	| awk 'NF' | grep -v '==>'
	paccache -v --cachedir /build/                --remove --keep 1 | awk 'NF' | grep -v '==>'
	printf '%s\n' "Note: 'pacman-contrib' was '--clean' requirement."

	printf '%s\n'	"${czm} Pacman output from container: "
	comm -23 <(pacman -Qq) <(sort /var/tmp/aurch/orig-pkgs.log) | xargs  pacman -Rns --noconfirm 2>/dev/null

	find /build  /var/cache/pacman/pkg -maxdepth 1 -type d -name "download-*" -delete

	pkgcount=$(pacman -Qq | wc -l)

	aurcache=$(find /build -maxdepth 1 -type f -name "*pkg.tar*" | wc -l)

	printf '%s\n'   "${czm} Container clean report   :"
	printf '%s\n'   "              Official pkg cache count : $(ls -1 /var/cache/pacman/pkg | wc -l)"
	printf '%s\n'   "              AUR pkg cache count      : ${aurcache}"
	printf '%s\n\n' "              Installed package count  : ${pkgcount}"

EOF
#----------------------------------------------  END  Heredoc Script --------------------------------------#   # Run cleanup script in container
	sudo chmod +x "${chroot}"/usr/bin/aurch-cleanup
fi
if	[[ -e ${tmph}/orig-pkgs.log ]]; then
	sudo systemd-nspawn -a -q -D "${chroot}" --pipe \
	/usr/bin/aurch-cleanup
fi
	sudo rm "${tmph}"/orig-pkgs.log
}
#========================================================================================================================#
upd_aur_db(){

if	find "${AURREPO}"/*.db.tar.gz &>/dev/null && [[ -s "${tmph}"/host-added-pkgs.file ]]; then
	printf '%s\n' "${czm} Adding package/s to host 'AURREPO' database."
	udb=alldone
	while IFS= read -r pkg; do
		repo-add "${AURREPO}"/"${REPONAME}".db.tar.gz "${pkg}"
	done < "${tmph}"/host-added-pkgs.file
fi
if	[[ ${udb-} == alldone ]]; then
	return
    else
	if	find "${AURREPO}"/*.db.tar.gz &>/dev/null && [[ -s "${tmph}"/rebuilt-pkg.logfile ]]; then
		printf '%s\n' "${czm} Adding package/s to host 'AURREPO' database"
		while IFS= read -r pkg; do
		repo-add --nocolor "${AURREPO}"/"${REPONAME}".db.tar.gz "${AURREPO}"/"${pkg}" \
		| tee >(awk -F/ '/Adding package/{print $NF}'|sed -e "s/'//g" >> "${tmph}"/repad-ver.file)
		done	< "${tmph}"/total.file
	fi
fi
}
#========================================================================================================================#
remove(){
												# Note: pkg variable is set in option parsing.
if	[[ -n ${pkg} ]]; then

	if	[[ ${1} == -Rc ]]; then
		if	pacman -b "${chroot}/var/lib/pacman/" \
				--config "${chroot}/etc/pacman.conf" \
				-Slq aur \
			| grep -q "${pkg}"; then
			sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --pipe bash << EOF
			printf '%s\n' "${czm} Removing ${pkg} from container aur database."
			repo-remove /build/aur.db.tar.gz "${pkg}"
EOF
			printf '%s\n' "${czm} Removing from container aur package cache:"
			find "${chroot}"/build -name "${pkg}*.pkg.tar*" -delete -print

			if	[[ -d  "${homebuilduser}"/"${pkg}" ]]; then
				printf '%s\n' "${czm} Removing container build directory:"
				printf '%s\n' "${chrbuilduser}/${pkg}"
				sudo rm -rd "${homebuilduser}"/"${pkg}"
			fi
			sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --pipe bash << EOF
			printf '%s\n' "${czm} Syncing container aur database:"
			sudo 2>/dev/null pacsync aur
EOF
		    else
			printf '%s\n' "${czm} ${pkg} not present in container AUR database."
			if	[[ -d "${homebuilduser}"/"${pkg}" ]]; then
				printf '%s\n' "${czm} Removing container build directory:"
				printf '%s\n' "${chrbuilduser}/${pkg}"
				sudo rm -rd "${homebuilduser}"/"${pkg}"
				cd "${chroot}"/build/
				if	find "${pkg}"*.pkg.tar* &>/dev/null; then
					printf '%s\n' "${czm} Removing from container aur package cache:"
					find "${chroot}"/build/ -name "${pkg}*.pkg.tar*" -delete -print
				    else
					printf '%s\n' "${czm} Container ${pkg} not present in AUR package cache."
				fi
			    else
				printf '%s\n' "${czm} Container ${pkg} build directory not present."
			fi
		fi
	fi
	if	[[ ${1} == -Rh ]]; then
		if	pacman -Q "${pkg}" &>/dev/null ; then
			sudo pacman -Rns "${pkg}"
		fi
	printf '%s\n' "${czm} Removed from host ${REPONAME} package cache:"
	sudo find "${AURREPO}" -name "${pkg}*.pkg.tar*" -delete -print
		if	pacman -Slq "${REPONAME}" | grep -q "${pkg}"; then
			repo-remove "${AURREPO}"/"${REPONAME}".db.tar.gz "${pkg}"
			sudo pacsync "${REPONAME}"  >/dev/null
		    else
			printf '%s\n' "${czm} Package ${pkg} is not present in host AUR repo."
		fi
	fi
    else
	printf '%s\n\n' "${czm} Need to specify package."
fi
}
#========================================================================================================================#
check_chroot_updates(){

	cd "${homebuilduser}"									|| { echo "[line ${LINENO}]" ; exit 1 ; }
	rm -f /tmp/check-ud-updates
	readarray -t dirs < <(find "${homebuilduser}" -maxdepth 1 -mindepth 1 -type d -name "[!.]*" -printf '%f\n'|sort)

if	[[ $1 != -Lucq ]]; then
	printf '%s\n' "${czm} Checking for updates on:"
	printf '%s\n' "${dirs[@]}" | nl
fi
	for pkg in "${dirs[@]}"
    do
	cd "${homebuilduser}/${pkg}"								|| { echo "[line ${LINENO}]" ; exit 1 ; }
	if	[[ -d .git ]]; then
		localHEAD=$(git rev-parse HEAD)
		remoteHEAD=$(git ls-remote --symref -q  | head -1 | cut -f1)

		if	[[ ${localHEAD} != "${remoteHEAD}" ]]; then
				printf '%s\n' " ${pkg}" >> /tmp/check-ud-updates
		fi
	fi
    done
if	[[ -s  /tmp/check-ud-updates ]]; then
	if	[[ $1 != -Lucq ]]; then
		echo >> /tmp/check-ud-updates
		printf '%s\n' "${czm}  Updates available:"
	fi
	cat /tmp/check-ud-updates
    else
	if	[[ $1 != -Lucq ]]; then
		printf '%s\n' "${czm} No updates available."
	fi
fi
}
#========================================================================================================================#
check_host_updates(){

	readarray -t aurpkgs < <(pacman --color=never -Slq "${REPONAME}" | pacman -Q - 2>/dev/null; pacman --color=never -Qm 2>/dev/null)
if	[[ $1 == -Luhq ]]; then	:
    else
	printf '%s\n' "${czm} Checking for updates:"
	printf '%s\n' "${aurpkgs[@]%' '*}" | nl | column -t
fi
	rm -f /tmp/aurch-updates /tmp/aurch-updates-newer

for pkg in "${aurpkgs[@]}"; do {

    	pckg="${pkg%' '*}"
	check=$(curl -s "https://aur.archlinux.org/rpc?v=5&type=info&arg=${pckg}" | jshon -e results -a -e  Version -u)
	compare=$(vercmp "${pkg#*' '}" "${check}")

	if	[[ -n  ${check} && ${compare} == -1 ]]; then
		printf '%s\n' "${pkg} -> ${check}" >>/tmp/aurch-updates
    	elif	[[ -n  ${check} &&  ${compare} == 1 ]]; then
    		printf '%s\n' "${pkg} <- ${check}" >>/tmp/aurch-updates-newer
	fi } &

done; wait

if	[[ $1 == -Luhq ]]; then
	awk '{print $1}' /tmp/aurch-updates 2>/dev/null
    else
	if	[[ -s  /tmp/aurch-updates ]]; then
		printf '%s\n\n' "${czm} Updates available:"
		column -t /tmp/aurch-updates
	    else
		printf '%s\n\n' "${czm} No Updates available"
	fi
	if	[[ -s  /tmp/aurch-updates-newer ]]; then
		printf '%s\n' "${czm} VCS Packages newer than AUR rpc version. Run 'aurch -Luc' to check them for updates."
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

	sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --pipe sudo 2>/dev/null pacsync aur

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
	printf '%s\n' "${czm} Inspect git cloned files?"
	while true; do
    		read -n1 -srp "             Enter  [y/n] for yes/no " yn
    		case $yn in
        	[Yy]* )           inspect_files "${1-}" ; break		;;
        	[Nn]* ) message ; opt="${1-}" build_pkg ; break		;;
        	    * ) printf '%s\n' "${czm}${error}[y/n] Only!"	;;
		esac
	done
}
#========================================================================================================================#
inspect_files(){
		  awk -F/ '{print $NF}' "${tmph}"/cloned-pkgs.logfile >"${tmph}"/inspect_files.file

if	[[ -s  ${tmph}/inspect_files.file ]]; then
	while IFS= read -r pkg; do
	"${AURFM}" "${homebuilduser}"/"${pkg}"
	done < "${tmph}"/inspect_files.file
    else
	"${AURFM}" "${homebuilduser}"/"${package}"
fi
	opt="${1}" build_pkg
}
#===================================================================================#   # aurch -Cc*' Depends : aurutils paccat devtools
				###  C L E A N   C H R O O T   B U I L D  ###		# aurutils scripts    : aur-build, aur-chroot use: -->
											# devtools scripts    : checkpkg  mkarchroot arch-nspawn
build_clean_chroot(){

	is_it_available

	printf '\n%s\n' "${czm}${warn} Respectfully informing the user as a courtesy." ; cat <<-EOF | pr -to 5
        Clean chroot building is WIP with limited testing that will be further refined over time.
        It adds, then removes a sudo config '/etc/sudoers.d/aurch' as a convenience workaround.
        Review the code in 'build_clean_chroot' function before running, then proceed at your discretion."
EOF
	while read -n1 -srp "             Proceed? [y/n]  " reply
	do
		if [[ ${reply} == y ]]; then printf "yes" ; echo ; break ; fi
		if [[ ${reply} == n ]]; then printf "no"  ; echo ; exit  ; fi
		unset reply
	done
													# Check for deps, confirm to install
	printf '%s\n' "${czm} Checking dependencies for clean chroot build..."
if	! type -P aur bash paccat checkpkg mkarchroot arch-nspawn &>/dev/null ; then

	printf '%s\n' "${czm} Clean chroot building dependencies not installed. Installing now."

	while read -n1 -srp "             Proceed? [y/n]  " reply
	do
		if	[[ ${reply} == y ]]; then printf "yes"
			printf '\n'
			if	pacman -Ssq aurutils &>/dev/null ; then
				sudo pacman -S  --noconfirm aurutils paccat devtools
				pacman -Q --color=always aurutils paccat devtools | column -t
				printf '\n%s\n\n' "${czm} Dependencies installed. Proceeding with clean chroot build.....1"
				sleep 4
			    else
				moveit=$(find "${chroot}"/build/ -name 'aurutils*')
													# Fetch containers aurutils
				if	[[ -n  ${moveit} ]]; then
					cp  "${moveit}" "${AURREPO}"
					repo-add "${AURREPO}"/"${REPONAME}".db.tar.gz "${moveit}"
					sudo pacsync aur
				fi
				sudo pacman -S --noconfirm aurutils paccat devtools
				pacman -Q --color=always aurutils paccat devtools | column -t
				printf '\n%s\n\n' "${czm} Dependencies installed. Proceeding with clean chroot build.....2"
				sleep 4
			fi
		    break
		fi

		if	[[ ${reply} == n ]]; then printf "no"
			echo
			printf '%s\n' " Exiting script."
			exit
		fi
		unset reply
	done
    else
	printf '%s\n' "${czm} $(pacman -Q --color=always aurutils) and all other dependencies installed."
fi													# Create log dir if needed
	[[ ! -d /var/tmp/aurch ]] && mkdir /var/tmp/aurch

#----------------------------------------- M A K E   A U R - C H R O O T ---------------------------#	# Create clean chroot if needed
if	[[ ! -d /var/lib/aurbuild/x86_64/root ]]; then

	sudo paccat pacman -- pacman.conf  | sudo tee /etc/aurutils/pacman-x86_64.conf &>/dev/null
	sudo paccat pacman -- makepkg.conf | sudo tee /etc/aurutils/makepkg-x86_64.conf &>/dev/null
	sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/g'  /etc/aurutils/pacman-x86_64.conf

	aur chroot --create

	if	! grep -q 'aurch' /etc/aurutils/pacman-x86_64.conf ; then
													# Config shared local AUR repo/cache
		cat <<-EOF | sudo tee -a /etc/aurutils/pacman-x86_64.conf &>/dev/null
		#
		# aurch config for 'aur build'.
		#
		[options]
		CacheDir    = /usr/local/aurch/repo
		CleanMethod = KeepInstalled

		[aur]
		SigLevel = Never TrustAll
		Server = file:///usr/local/aurch/repo

EOF
		printf '\n%s\n' "${czm} Configured '/etc/aurutils/pacman-x86_64.conf' to share aurch local AUR repo."
	fi
fi
#-----------------------------------------  S T A R T   B U I L D  ---------------------------------#	# Remove any existing log files
	rm -f /var/tmp/aurch/*

	cd "${homebuilduser}"

	[[ -d  "${homebuilduser}/${package}" ]] && sudo rm -rd "${homebuilduser}/${package}"

	aur depends -r "${package}" | tsort |
		tee /var/tmp/aurch/cloned-pkgs.log |
		aur fetch -S -

	printf '%s\n' "${czm} Git cloned ${package} and AUR dependencies."
	nl /var/tmp/aurch/cloned-pkgs.log

if	[[ ! -d  ${HOME}/.gnupg/ ]]; then
	gpg --list-keys &>/dev/null
fi
	while read -n1 -srp "${czm} Inspect git cloned files? [y/n]  "  reply
	do
		if [[ ${reply} == y ]]; then printf "yes" ; "${AURFM}" "${homebuilduser}"/"${package}" ; break ; fi
		if [[ ${reply} == n ]]; then printf "no"  ; echo && break ; fi
		unset reply
	done
													# Beginning build packages in cloned-pkgs.log
	while read -r build
	do
		cd "${homebuilduser}/${build}" || exit
		awk '/validpgpkeys/ {print $3}' .SRCINFO  >pgp-keys.file

		printf '%s\n' "${czm} Checking pgp keys."
													# Check/install pgp keys
		if	[[ ! -s pgp-keys.file ]]; then
			printf '%s\n' "             Not used for ${build}."
		    else
			while read -r key
			do
				gpg --keyserver keyserver.ubuntu.com --recv-key "${key}" 2>&1 |& grep -v 'insecure memory'
			done < pgp-keys.file
		fi
													# Fix successive pacman sudo prompts
		printf '%s\n' "${USER} ALL=(ALL) NOPASSWD: /usr/bin/pacman" |
				sudo tee /etc/sudoers.d/aurch &>/dev/null
		printf '%s\n' "${czm} Building ${build} in clean chroot."
													# Check/correct AUR repo permissions
		ck_per
													# BUILD INDIVIDUAL CHROOT PACKAGES
		aur build -cfnsr --results=aur-build.log
													# Remove sudo config and restore permissions
		sudo rm /etc/sudoers.d/aurch
		awk -F'/' '{print $NF}' aur-build.log >> /var/tmp/aurch/aurch-build.log

	done   < /var/tmp/aurch/cloned-pkgs.log

	cleanup_host
													# If 'b' option, copy/register pkgs to cont.
if	[[ ${1} == -Ccb ]]; then
	while read -r transfer
	do
		cp       "${AURREPO}/${transfer}"                 "${chroot}/build/"
		sudo systemd-nspawn -a -q -D "${chroot}" -u builduser --pipe bash << EOF
		repo-add /build/"${REPONAME}".db.tar.gz  /build/"${transfer}"
		sudo 2>/dev/null pacsync aur
EOF
	done < /var/tmp/aurch/aurch-build.log
fi
	printf '%s\n' "${czm} Clean chroot build location: $(aur chroot --path | sed "s/root/${USER}/g")"
	printf '%s\n' "${czm} Copied and registered the following pkgs to host AUR repo: ${AURREPO}"
if	[[ ${1} == -Ccb ]]; then
	printf '%s\n' "${czm} Copied and registered the following pkgs to container AUR repo: ${chroot}/build"
fi
	echo    											# Print build results to screen
	awk -F'/' '{print $NF}' /var/tmp/aurch/aurch-build.log | nl -w3 -s" " | pr -To 11
	echo
}
#========================================================================================================================#
cleanup_host(){

	sudo true
	printf '%s\n' "${czm} Cleaning official packages from local AUR cache: "

	aurch -Lahq  >  /var/tmp/aurch/aurch-keeppkgs
	aurch -Lacq >>  /var/tmp/aurch/aurch-keeppkgs
	keeppkgs=$(sort -u /var/tmp/aurch/aurch-keeppkgs | xargs | sed 's/ /,/g')
	sudo paccache -v -rk0 -i "${keeppkgs}" -c /usr/local/aurch/repo/ |& awk NF

	printf '%s\n' "${czm} Cleaning leftover directories from local AUR cache:"
	find "${AURREPO}" -maxdepth 1 -type d -name "download-*" -delete -print

	printf '%s\n' "==> no directories list indicate nothing to remove"
}
#=======================================### Aurch called with no args ###================================================#

if      [[ -z ${*} ]]; then cat << EOF
	$(echo -e '\033[0;96m')
 |==================================================================================|
 |   Aurch, an AUR helper script.    USAGE:  $ aurch [operation[*opt]] [package]    |
 |----------------------------------------------------------------------------------|
 |      -B*   build AUR package in container    -Luc*   list updates container      |
 |      -G    git clone package                 -Luh*   list updates host           |
 |      -C    build on existing git clone       -Lac*   list AUR sync db container  |
 |     -Cc*   build AUR pkg in clean chroot     -Lah*   list AUR sync db host       |
 |     -Rc    remove AUR pkg from container      -Lv    list expanded variables     |
 |     -Rh    remove AUR pkg from host         --pgp    import pgp key in container |
 |    -Syu    update container               --clean    cleanup host & container    |
 |      -V    print version                  --login    log into container          |
 |      -h    help, Press [q] to quit          --log    display aurch.log           |
 |                                                  *   options, See help           |
EOF
	printf '%-84s|\n' " |            Aurch Container Path:  ${chroot}"
	if	aur chroot --path &>/dev/null ; then
		printf '%-84s|\n' " |           Aurutils Clean Chroot Path:  $(aur chroot --path)"
	fi
	printf '%s\n\n' " |==================================================================================|"
fi
#===================================================================================================#   # Trap and Logging
	trp(){ printf '%s\n' "${dt} : Error trap was ran : $(basename "${0}") ${*}" ; }
	trap 'cleanup_host ; cleanup_chroot ; trp "${@} ${package}" >> "${logfile}" ; exit 1' ERR SIGINT
	(($# > 0)) && printf '%s\n' "${dt} : $(basename "${0}") ${*}"  >> "${logfile}"
#========================================================================================================================#
while (($# > 0)); do
	case "${1-}" in
	-B*|--build)		ck_per ; fetch_pkg ; yes_no	"${1-}"		;;
	-G|--gitclone)		fetch_pkg					;;
	-C|--compile)		ck_per ; opt="${1-}" build_pkg			;;
	-Cc*|--cchroot)		build_clean_chroot		"${1-}"		;;
	-R*)			ck_per ; pkg="${2-}" remove	"${1-}"		;;
	-Syu|--update)		update_chroot					;;
	-Luh*|--lsudh)		check_host_updates		"${1-}"		;;
	-Luc*|--lsudc)		check_chroot_updates		"${1-}"		;;
	-Lah*|--lsaurh)		list_pkgs_host			"${1-}"		;;
	-Lac*|--lsaurc)		list_pkgs_chroot		"${1-}"		;;
	-Lv)			print_vars					;;
	--login)		login_chroot					;;
	--clean)		cleanup_host ; cleanup_chroot			;;
	--pgp)			key="${2-}" manual_pgp_key			;;
	--log)			less "${logfile}" ; exit			;;
	-h|--help)		help | /usr/bin/less -R	; exit			;;
	-V|--version)	awk -e '/^# aurch/ {print $2,$3}' "$(which aurch)"	;;
	-?*)		help; echo "${czm}${error} Input error. See help above"	;;
	*)		break
        esac
    shift
done
