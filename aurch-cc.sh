# Experimental aurch 'add on' feature to build aur packages in a clean chroot, integrating them with both aurch aur repos. 
# To enable, place this in the directory containing the aurch script to allow sourcing.
# Clones repo to /tmp/aurch/pkg, builds in chroot /var/lib/archbuild/*, installs/syncs package in aurch host and nspawn aur repos.
# 2024-08-03
# shellcheck shell=bash disable=SC2154

	printf '%s\n' "${czm} Clean chroot building depends on aurutils for dependency resolution and ordering."

if	pacman -Q aurutils; then
	printf '%s\n' "${czm} aurutils installed."
	else
	printf '%s\n' "${czm} Install missing package/s."
fi

if	[[ -d /tmp/aurch/"${package}" ]]; then
	sudo rm -rd /tmp/aurch/"${package}"
fi
	mkdir -p /tmp/aurch/"${package}"

	cd /tmp/aurch/ || exit

	aur depends -r "${package}" | tsort | aur fetch -S - |& tee >(grep 'Cloning' |cut -d"'" -f 2 >"cloned-pkgs.file")

	mv "cloned-pkgs.file" /tmp/aurch/"${package}"

	cd /tmp/aurch/"${package}" || exit

if	[[ -s cloned-pkgs.file ]]; then
	printf '%s\n' "${czm} Git cloned ${package} and/or it's dependencies:"
fi
	nl "cloned-pkgs.file"

	pkgctl build

	PKG=$(find -- /tmp/aurch/ -maxdepth 2 -name "${package}*pkg.tar*" | grep -Ev 'debug|log')
	cp "${PKG}" "${AURREPO}"
	cp "${PKG}" "${chroot}"/build

if	[[ -d ${homebuilduser}/${package} ]]; then
	sudo cp -R .git "${homebuilduser}/${package}/.git"
	sudo chown -R  "$(id -un):$(id -gn)" "${homebuilduser}/${package}/.git"
	printf '%s\n' "${czm} Copied current ${package} .git dir to aurch build dir if it exists."
	printf '%s\n' "${czm} This will allow checking VCS pkgs for updates to work accurately."
fi
	repo-add "${chroot}"/build/aur.db.tar.gz "${chroot}/build/$(basename "${PKG}")"
	sudo systemd-nspawn -a -q -D "${chroot}" --pipe \
	pacsync aur >/dev/null

	printf '%s\n' "${czm} Copied ${package} to ${AURREPO} and ${chroot}/build"
	printf '%s\n' "${czm} Adding package/s to aurch nspawn and host 'AURREPO' databases"

	repo-add "${AURREPO}/${REPONAME}".db.tar.gz "${AURREPO}/$(basename "${PKG}")"
	sudo pacsync "${REPONAME}" >/dev/null
