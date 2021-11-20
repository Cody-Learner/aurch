# aurch

The emphasis of aurch is using a chroot for 'build isolation' rather than 'clean chroot building'. <br>
Isolates the build environment to mitigate build script related issues potentially creating issues on the host. <br>
<br>
Aurch sets up aurutils, sets up a local AUR repo, sets up a builduser, within a chroot. <br>
Can be used for various AUR package related tasks including -B, for easy one command builds. <br>
Upon completing AUR build/s, aurch places copy/s of the package/s in the host AURREPO file. <br>
Keeps a copy of AUR packages and dependencies built in the chroot for future use. <br>
Automatically builds and installs required AUR dependencies in the chroot. <br>
Automatically installs required pgp keys in the chroot. <br>
Automatically maintains a 144 package count in the chroot via automated cleanup. <br>
The chroot is intended to be reused. <br>
<br>
<br>
Note: <br>
This script isolates the build process from the host, not to be confused with building packages in a clean chroot. <br>
Scripts such as devtools* were not written to and do not isolate the build process from the host. <br>
References: <br>
 https://www.reddit.com/r/archlinux/comments/q2qwbr/aur_build_in_chroot_to_mitigate_risks/hfn7x0p/ <br>
 https://www.reddit.com/r/archlinux/comments/qk3rk7/wrote_script_to_setup_an_nspawn_chroot_and_build/hixia0b/ <br>
<br>

    Usage:
    		aurch --setup, [-B,-G,-C] [package], --pgp [pgp key], --clean
    
    
    Operations: 
    		    --setup		Sets up a chroot
    		-B  --build		Builds an AUR package in one step
    		-G  --git		Git clones an AUR package (allowing modification before building)
    		-C  --compile		Builds an AUR package on existing PKGBUILD
    		    --clean		Manually remove unneeded packages from chroot
    		    --pgp		Manually import pgp key in chroot
    		-h, --help		Prints help
    
    Overview:
    		Run 'aurch --setup' before attempting to build packages.
    		Run aurch from directory containing chroot created during 'aurch --setup'.
    
    Examples:
    		Create a directory to setup chroot in:		mkdir ~/aurbuilds
    		Move into directory:				cd ~/aurbuilds
    		Set up chroot:					aurch --setup		 
    		Build an AUR package in the chroot:		aurch -B <aur-package>
    		Git clone an AUR package			aurch -G <aur-package>
    		Build (Compile) AUR pkg on existing PKGBUILD	aurch -C <aur-package>
    		Manually import a pgp key in chroot:		aurch --pgp <short or long key id>
    		Manually remove unneeded packages in chroot:	aurch --clean
    
    Variables:
    		AURREPO </path/to/host/directory>
    		Default: /tmp/aurch
    
    		To have packages copied to local pacman repo or directory run or edit:
    		AURREPO="/path/to/host-repo"
    
<br>
<br>

![Screenshot_2021-11-02_18-13-26](https://user-images.githubusercontent.com/36802396/140189725-9f30c9dc-b071-447c-9cd9-a2c177ac3371.png)

Screenshot: aurch --setup	 https://cody-learner.github.io/aurch-setup.html <br>
Screenshot: aurch -B bauerbill	 https://cody-learner.github.io/aurch-building-bauerbill.html <br>
<br>
<br>
NEWS/UPDATE INFO:<br>
<br>
UPDATE For  Nov 20, 2021 <br>
Fixed for proper split package handling.<br>
<br>
<br>
UPDATE For  Nov 14, 2021 <br>
Rewrote aurch to no longer require AUR dependencies. No AUR helper required on host. <br>
Creates a chroot with aurutils set up, including a local pacman AUR repo, inside the chroot. <br>
Added ability to git clone and build package independently to ease customization. <br>
AUR packages are retained in the chroot for dependency usage. <br>
<br>
<br>
NEWS FOR Oct 31, 2021: <br>
Initial release of the aurch script. <br>
The script is in the testing phase. <br>
