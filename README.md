# aurch

The emphasis of aurch is using a chroot for AUR 'build isolation' rather than 'clean chroot building'.  <br>
Aurch isolates the build environment to mitigate build script errors or malicious intent causing issues on the host. <br>
The original aurch script has been split into two scripts. <br>
The setup operations are now separate from the AUR package building  operations. <br>
<br>
<br>
**aurch-setup:**<br>
Aurch-setup builds and sets up an systemd nspawn chroot for building packages with aurutils, a local AUR repo, and user name "builduser", all within the chroot. The chroot is persistent, and intended for data storage and to be used for all AUR builds. Aurch-setup is also  capable of setting up the host system with a local pacman AUR repo.
<br>
<br>
**aurch:**<br>
Builds all AUR packages in the chroot, isolated from the host. <br>
After the packages are built, they're copied into the host AUR cache and entered into the pacman database.<br>
Builds and installs all required AUR dependencies in the chroot. <br>
Installs any required pgp keys in the chroot. <br>
Removes all packages used in the chroot building process upon completion, maintaining a minimal footprint with a small, consistent package base. <br>
All the AUR packages and AUR dependencies are backed up within the chroot.  <br>
<br>
<br>
Note: <br>
Aurch script isolates the build process from the host, not to be confused with building packages in a clean chroot. <br>
Scripts such as devtools were not written to and do not isolate the build process from the host. <br>
[devtools info](https://wiki.archlinux.org/title/DeveloperWiki:Building_in_a_clean_chroot)  <br>
References: <br>
 https://www.reddit.com/r/archlinux/comments/q2qwbr/aur_build_in_chroot_to_mitigate_risks/hfn7x0p/ <br>
 https://www.reddit.com/r/archlinux/comments/qk3rk7/wrote_script_to_setup_an_nspawn_chroot_and_build/hixia0b/ <br>
<br>

    USAGE
		aurch [operation[options]] [package | pgp key]

    OPERATIONS
		-B* --build	Build new or update an existing AUR package.
		-G  --git	Git clones an AUR package.
		-C  --compile	Build an AUR package on existing PKGBUILD. Useful for implementing changes to PKGBUILD.
		-Rh		Remove AUR pkg from host.   Removes:   /AURREPO/<package>,  <package> if installed,  and database entry.
		-Rc		Remove AUR pkg from chroot. Removes:   /build/<package>,    /${HOME}/<build dir>,    and database entry.
		-Syu  --update  Update chroot packages. ie: Runs pacman -Syu in chroot.
		-Luh* --lsudh	List update info for AUR packages installed in host.
		-Luc* --lsudc	List update info for AUR packages in chroot.
		-Lah* --lsaurh	List AUR database contents/status of host.
		-Lac* --lsaurc	List AUR database contents/status of chroot.
		      --login   Login to chroot for maintenance.
		      --clean	Manually remove unneeded packages from chroot.
		      --pgp	Manually import pgp key in chroot.
		-h,   --help	Prints help.

    
    OPTIONS *
    	-L, List:
    		Append 'q' to list operations -L[u,c,h] for quiet mode.
    		Example: aurch -Luq
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
    		The aurch chroot must be periodically updated via the 'aurch -Syu' command.
    		Update chroot before buiding packages.
    
    EXAMPLES
    		SETUP FOR AURCH:

    		Create a directory to setup the chroot:		mkdir ~/aurbuilds
    		Move into directory:				cd ~/aurbuilds
    		Set up chroot:					aurch-setup --setupchroot
    		Set up local AUR repo:				aurch-setup --setuphost


    		USING AURCH:

    		Build an AUR package(+):			aurch -B  <aur-package>
    		Build and install AUR package:			aurch -Bi <aur-package>
    		Git clone package				aurch -G  <aur-package>
    		Build (Compile) AUR pkg on existing PKGBUILD	aurch -C  <aur-package>
    		Remove AUR package from host:			aurch -Rh <aur-package>
    		Remove AUR package from chroot:			aurch -Rc <aur-package>
    		List chroot AUR repo updates available:		aurch -Luc
    		List chroot AUR sync database contents:		aurch -Lac
    		List host AUR sync database contents:		aurch -Lah
    		List host AUR repo updates available:		aurch -Lah
    		Manually import a pgp key in chroot:		aurch --pgp <short or long key id>
    		Manually remove unneeded packages in chroot:	aurch --clean
    		Login to chroot for maintenance:                aurch --login
    
    USER VARIABLES
    		BASEDIR = path to chroot base dir
    		AURREPO = path to host aur repo
    		REPONAME =  host aur repo name

    (+) Package is placed into local AUR repo and entry made in pacman AUR database.
        Install with pacman -S <aur-package>
    		
<br>
<br>

![Screenshot_2021-11-02_18-13-26](https://user-images.githubusercontent.com/36802396/140189725-9f30c9dc-b071-447c-9cd9-a2c177ac3371.png)

Screenshot: aurch --setup	 https://cody-learner.github.io/aurch-setup.html <br>
Screenshot: aurch -B bauerbill	 https://cody-learner.github.io/aurch-building-bauerbill.html <br>
<br>
<br>
**NEWS/UPDATE INFO:**<br>
<br>
<br>
**UPDATE For  April 7, 2024** <br>
Made changes to accommodate implementation of 'set -euo pipefail'<br>
Although I don't personally judge the quality of bash scripts based on the controversial use of 'set -euo pipefail, <br>
I've none the less been curious about what changes would be required to implement it. <br>
Directly from my notes: <br>

    # 'set -u' Will not allow printing vars to file, lines 48-58.	Appending '-' to all vars fixed issue.
    # 'set -u' Will not allow using positional parameters.		Appending '-' to all positional parameters fixed issue.
    # 'set -u' Exits on: "/path/to/script/ line 147: $2: unbound variable"
    # Line 147, '$2' is part of an awk command inside an "EOF [here doc]" and not a bash positional parameter. (A bash bug?)
    # Rewrote 'fetch_pkg' function lines ~143-159, to accommodate 'set -u' by removing awk from the here doc.

<br>
**UPDATE For  March 10, 2023** <br><br>
Updated script for compatiblity with interface changes made to aurutils-11. <br>
https://github.com/AladW/aurutils/releases/tag/11<br>
Updated README to reflect changes and clarify info.<br>
<br>
**UPDATE For  Jan 07, 2023** <br>
When deleting AUR packages from host, corrected ability to remove "all versions" of pkgs from the host AUR package cache. <br>
Add an if statement to 'check_host_updates' function to properly handle and print message 'No Updates Available'. <br>
Edited message in 'check_host_updates' function when package is newer than the AUR rpc version to:  <br>
"VCS Packages newer than AUR rpc version. Run 'aurch -Luc' to check them for updates.".<br>
<br>
**UPDATE For  Feb 11, 2022** <br>
Change curl commands to reflect AUR RPC interface update/changes. <br>
Add removal of /var/tmp/aurch/orig-pkgs.log ("${tmph}"/orig-pkgs.log) in chroot so 'orig package list' reflects edits/changes made to .#orig-pkgs.log in base dir. <br>
Add if statement to check build dir/s for .git dir. This allows adding misc dir's (ie: 'testing' toolchain pkgs) under buildusers home. <br>
<br>
**UPDATE For  Jan 21, 2022** <br>
Disable 'set -e'. <br>
Testing in virtual hw system revealed failure to build pkg that was not present on test system. <br>
<br>
**UPDATE For  Jan 06, 2022** <br>
Implemented 'set -e' in script. <br>
Added code line 162 to enable proper 'set -e'. <br>
Added '-a' opt to systemd-nspawn commands. <br>
Replaced cat with sort in subshell for comm command. <br>
Added 'else' to if statement in upd_aur_db function. <br>
<br>
**UPDATE For  Dec 14, 2021** <br>
Added operations:<br>
    
    aurch -Syu     System update in chroot
    aurch -Luh     List updates available in host for installed AUR packages
    aurch --login  Login to chroot system to perform maintenance
    
Added check to avoid multiple re-downloading pgp keys.<br>
Added AUR file inspection before building using PAGER with interactive y/n option in script.<br>
Replaced some for loops with while loops when working with files.<br>
Added code to remove operation in chroot to assure all possible conditions are handled.<br>
Began implementation of 'aur build --results' file to replace grepped output for conditional processing.<br>
Added missing aur database entry for rebuilt, overwritten, same version packages.<br>
Removed install workaround in host for missing database entry using pacman -u.<br>
<br>
**UPDATE For  Dec 10, 2021** <br>
The predominant focus this time around was implementing some additional flexibility to allow aurch to be usable for more 
than my personal setup and preferences. Implemented virtual hardware testing as a start towards this objective. <br>
Split the system setup and building packages into separate scripts. To many additional smaller changes to go over here. 
Future road map includes implementing a built in inspection step of downloaded AUR data and running a check for existing 
PGP keys to eliminate needless re-downloading.<br>
<br>
**UPDATE For  Nov 29, 2021** <br>
Added pacutils as a dependency.<br>
Added ability when overwriting existing packages in host to handle multiple entries from split packages.<br>
Rewrote check_updates function to reduce and simplify code.<br>
Added/changed the following operations/options:<br>
<br>
Remove operation:<br>

    aurch -Rc	Performs the following on chroot:
    			Removes package from local AUR repo, /build.
    			Removes build dir /home/builduser/<package>.
    			Removes <package> entry in AUR database.
    
    aurch -Rh	Performs the following on host:
    			Removes package from local AUR repo, AURREPO.
    			Removes <package> (pacman -Rns) if installed.
    			Removes <package> entry in AUR database.

Build operation option:<br>

    aurch -Bi	[i][install] package in host after build.

List operation options:<br>

    aurch -Luq	[q][quiet] lists available aur updates for chroot [packages only].
    aurch -Lcq	[q][quiet] lists chroot aur sync database [packages only].
    aurch -Lhq	[q][quiet] lists host aur sync database [packages only].

<br>

**UPDATE For  Nov 27, 2021** <br>
Rewrote 'here document' usage to extend systemd-nspawn functionality, rather than inserting multiple small scripts into chroot. <br>
Added code and printed comments relating to rebuilding and reinstalling same version of packages. <br>
Reworked 'setup_chroot' function to eliminated the evil 'eval' command. <br>
Integrated /var/tmp directory usage in chroot and added file extensions to ease it's cleanup. <br>
<br>
**UPDATE For  Nov 24, 2021** <br>
Added '-L  --listup' operation, to lists updates. <br>
The new function runs on the packages in the chroot AUR repo. <br>
It compares local vs remote git HEAD and lists mismatching packages. <br>
<br>
**UPDATE For  Nov 21, 2021** <br>
Added function to add packages to hosts AUR repo database.<br>
<br>
**UPDATE For  Nov 20, 2021** <br>
Fixed for proper split package handling.<br>
<br>
**UPDATE For  Nov 14, 2021** <br>
Rewrote aurch to no longer require AUR dependencies. No AUR helper required on host. <br>
Creates a chroot with aurutils set up, including a local pacman AUR repo, inside the chroot. <br>
Added ability to git clone and build package independently to ease customization. <br>
AUR packages are retained in the chroot for dependency usage. <br>
<br>
**NEWS FOR Oct 31, 2021** <br>
Initial release of the aurch script. <br>
The script is in the testing phase. <br>
