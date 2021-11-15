# aurch

Aurch creates a chroot, sets up aurutils with a local AUR repo*, and sets up 'builduser'* in the directory it's ran in. <br>
Can be used for various AUR package related tasks including -B, for easy one command builds. <br>
Upon completing AUR build/s, aurch will place copy/s of the package/s in the host AURREPO file. <br>
Keeps a copy of AUR packages and dependencies built in the chroot for future use. <br>
Automatically builds and installs required AUR dependencies.<br>
Automatically installs all required pgp keys in the chroot. <br>
Automatically maintains a 144 package count in the chroot via automated cleanup. <br>
The chroot is intended to be reused. <br>
The emphasis of this script is using a chroot for 'build isolation' rather than 'clean building'. <br>
Isolates the build environment from the host.
<br>
*(within the chroot)<br>
<br>
Note: This script isolates the build process from the host, not to be confused with building in a clean chroot.
      Scripts such as devtools and aurutils which uses devtools, do not isolate the build process from the host.
<br>
    Usage:
    		aurch [operation] [package | pgp key] [--chrootpacman <pacman commands> <packages>]
    
    
    Operations: 
    		    --setup		Sets up a chroot
    		-B  --build		Builds an AUR package in one step
    		-G  --git		Git clones an AUR package			(allows modification before building)
    		-C  --compile		Builds an AUR package on existing PKGBUILD
    		    --clean		Manually remove unneeded packages from chroot
    		    --pgp		Manually import pgp key in chroot
    		-h, --help		Prints help
    
    Overview:
    		Run 'aurch --setup' before using aurch.
    		Run aurch from directory containing chroot created during 'aurch --setup'.
    
    Examples:
    		Create a directory to setup chroot in:		mkdir ~/aurbuilds
    		Move into directory:				cd ~/aurbuilds
    		Set up chroot:					aurch --setup		 
    		Build an AUR package in the chroot:		aurch -B <aur-package>
    		Git clone package				aurch -G <aur-package>
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
UPDATE 2021-11-14
Rewrote aurch to no longer require AUR dependencies. No AUR helper required on host!
Creates a chroot with aurutils set up, including a local pacman AUR repo, inside the chroot.
Added ability to git clone and build package independently to ease customization.
AUR packages are retained in the chroot for dependency usage.
<br>
<br>
NEWS FOR Oct 31, 2021: <br>
Initial release of the aurch script. <br>
The script is in the testing phase. <br>
