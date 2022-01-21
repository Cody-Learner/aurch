# aurch

The emphasis of aurch is using a chroot for AUR 'build isolation' rather than 'clean chroot building'.  <br>
Aurch isolates the build environment to mitigate build script errors or malicious intent causing issues on the host. <br>
<br>
Aurch sets up aurutils, sets up a local AUR repo, sets up a builduser, within a chroot. <br>
Can be used for various AUR package related tasks including -B, for easy one command builds. <br>
Upon completing AUR build/s, aurch places copy/s of the package/s in the host AURREPO file. <br>
Keeps a copy of all AUR packages and dependencies built in the chroot AUR repo for future use. <br>
Automatically builds and installs required AUR dependencies in the chroot. <br>
Automatically installs required pgp keys in the chroot. <br>
Automatically maintains a 144 package count in the chroot via automated cleanup. <br>
The chroot is intended to be reused. <br>
<br>
<br>
Note: <br>
This script isolates the build process from the host, not to be confused with building packages in a clean chroot. <br>
Scripts such as devtools were not written to and do not isolate the build process from the host. <br>
[devtools info](https://wiki.archlinux.org/title/DeveloperWiki:Building_in_a_clean_chroot)  <br>
References: <br>
 https://www.reddit.com/r/archlinux/comments/q2qwbr/aur_build_in_chroot_to_mitigate_risks/hfn7x0p/ <br>
 https://www.reddit.com/r/archlinux/comments/qk3rk7/wrote_script_to_setup_an_nspawn_chroot_and_build/hixia0b/ <br>
<br>
    
    USAGE
    		aurch [operation[options]] [package | pgp key]
    
    
    OPERATIONS 
    		    --setup		Sets up a chroot.
    		-B*  --build		Builds an AUR package in one step.
    		-G  --git		Git clones an AUR package.
    		-C  --compile		Builds an AUR package on git clone after modifications.
    		-Rc  [--long NA]	Remove AUR pkg from chroot /build/<package>, $HOME/<build dir>, and database entry.
    		-Rh  [--long NA]	Remove AUR pkg from host /AURREPO/<package>, <package> if installed, and database entry.
    		-Lu*  --listupdates	List updates available for AUR packages in chroot AUR repo.
    		-Lc*  --listchroot	List contents of AUR db on chroot.
    		-Lh*  --listhost	List contents of AUR db on host.
    		    --clean		Manually remove unneeded packages from chroot.
    		    --pgp		Manually import pgp key in chroot.
    		-h, --help		Prints help.
    
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
