# aurch
Aurch creates a chroot in the directory it's ran in and builds AUR packages in the chroot. <br>
Run --setup before building packages. The chroot is intended to be reused. <br>
Builds a single package per -B operation. <br>
Installs all required official and AUR dependencies in the chroot. <br>
Installs required pgp keys in the chroot. <br>
Keeps AUR make dependencies installed in chroot. <br>
Keeps chroot packages minimal via makepkg -r. <br>
Does not perform "clean" chroot builds. <br>
The emphasis of this script is using a chroot for 'build isolation' rather than 'clean building'. <br>

Usage: aurch [operation] [package]<br>

    Operations: <br>
    		    --setup	Sets up a chroot <br>
    		-B, --build	Builds an AUR package in chroot <br>
    		    --pgp	Manually import pgp key <br>
    		-h, --help	Prints help <br>

Examples: <br>

    Set up chroot:				aurch --setup <br>
    Build an AUR package in the chroot:	aurch -B <aurpackage> <br>
    Manually import a pgp key in chroot:	aurch --pgp <short or long key id> <br>

<br>
<br>
NEWS/UPDATE INFO:<br>
<br>
NEWS FOR Oct 31, 2021: <br>
Initial release of the aurch script. <br>
The script is in the testing phase. <br>
