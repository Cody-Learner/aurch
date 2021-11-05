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

Usage: aurch [operation] [package]

Operations: <br>

        --setup		Sets up a chroot
    -B, --build		Builds an AUR package in chroot
        --chrootpacman	Manually run pacman in chroot
        --pgp		Manually import pgp key in chroot
    -h, --help		Prints help

Examples: <br>

    Create a directory to setup chroot in:	mkdir ~/aurch
    Move into directory:			cd ~/aurch
    Set up chroot:				aurch --setup		 
    Build an AUR package in the chroot:		aurch -B <aurpackage>
    Manually import a pgp key in chroot:	aurch --pgp <short or long key id>
    Run pacman commands in chroot:		aurch --chrootpacman <pacman operations options> <package>

<br>
<br>

![Screenshot_2021-11-02_18-13-26](https://user-images.githubusercontent.com/36802396/140189725-9f30c9dc-b071-447c-9cd9-a2c177ac3371.png)

Screenshot: aurch --setup	 https://cody-learner.github.io/aurch-setup.html <br>
Screenshot: aurch -B bauerbill	 https://cody-learner.github.io/aurch-building-bauerbill.html <br>

<br>
<br>
NEWS/UPDATE INFO:<br>
<br>
NEWS FOR Oct 31, 2021: <br>
Initial release of the aurch script. <br>
The script is in the testing phase. <br>
