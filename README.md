# aurch

The emphasis of aurch is using an nspawn container for AUR 'build isolation' rather than a 'clean chroot'.  <br>
Aurch isolates the build environment to mitigate build script errors/malicious intent causing issues on host. <br>
The original aurch script has been split up into two seperate scripts with a dedicated setup script now. <br>
<br>
<br>
**aurch-setup:**<br>
Aurch-setup sets up an nspawn container for building AUR packages and sets up a local AUR repo in the host. <br>
The nspawn container has Aurutils setup within it with Aurch acting as an nspawn and aurutils wrapper. <br>
The nspawn container is persistent, has an AUR repo, and is maintained to a minimal base package set. <br>
ie: Currently 154 packages.
<br>
<br>
**aurch:**<br>
Aurch builds AUR packages in the nspawn container isolated from the host. <br>
After packages are built, they're copied into the host AUR cache and entered into host pacman sync db.<br>
Automatically builds and saves all required AUR dependencies in the nspawn container AUR repo. <br>
Installs any required pgp keys in the nspawn container. <br>
Removes all official and AUR* packages used in the nspawn container build process upon completion, 
maintaining a minimal footprint of a small, consistent set of base packages. <br>
\* Removed from the containers arch install while remaining in the containers local AUR repo. <br>
<br>
<br>
Note: <br>
Aurch script isolates the build process from the host, not to be confused with building packages in a 'clean chroot'.
Scripts such as devtools were not written to and do not isolate the build process from the host. <br>

References: <br>
[Arch wiki: building in a clean chroot](https://wiki.archlinux.org/title/DeveloperWiki:Building_in_a_clean_chroot)  <br>
 https://www.reddit.com/r/archlinux/comments/q2qwbr/aur_build_in_chroot_to_mitigate_risks/hfn7x0p/ <br>
 https://www.reddit.com/r/archlinux/comments/qk3rk7/wrote_script_to_setup_an_nspawn_chroot_and_build/hixia0b/ <br>
<br>

    USAGE
		aurch [operation[options]] [package | pgp key]

    OPERATIONS
		-B* --build	Build new or update an existing AUR package.
		-G  --git	Git clones an AUR package.
		-C  --compile	Build an AUR package on existing PKGBUILD.(1) 
		-Rh		Remove AUR pkg from host.(2)
		-Rc		Remove AUR pkg from nspawn container.(3)
		-Syu  --update  Update nspawn container packages.(4)
		-Lah* --lsaurh	List AUR sync database contents/status of host.
		-Lac* --lsaurc	List AUR sync database contents/status of nspawn container.
		-Luh* --lsudh	List update info for AUR packages installed in host.
		-Luc* --lsudc	List update info for AUR pkgs/AUR deps in nspawn container.
		      --login   Login to nspawn container for maintenance.
		      --clean	Manually remove unneeded packages from nspawn container.
		      --pgp	Manually import pgp key in nspawn container.
		-h,   --help	Prints help.
		-V,   --version Prints aurch version.
    
    		(1) Useful for implementing changes to PKGBUILD, etc.
    		(2) Removes:  /AURREPO/<package>, <package> if installed, and database entry.
    		(3) Removes:  /build/<package>,   /${HOME}/<build dir>,   and database entry.
    		(4) Runs `pacman -Syu` inside the nspawn container.

    OPTIONS *
    	-L, List:
    		Append 'q' to  -L list operations for quiet mode.
                    Examples: aurch -Lahq
                              aurch -Luhq
                              aurch -Lacq
                              aurch -Lucq
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
    		The aurch nspawn container must be periodically updated via aurch -Syu.
    		Update nspawn container before buiding packages.
    
    EXAMPLES
    		SETUP FOR AURCH:

    		Set up nspawn container:			aurch-setup --setupchroot
    		Set up local AUR repo:				aurch-setup --setuphost


    		USING AURCH:

    		Build an AUR package(+):			aurch -B  <aur-package>
    		Build and install AUR package:			aurch -Bi <aur-package>
    		Git clone package				aurch -G  <aur-package>
    		Build (Compile) AUR pkg on existing PKGBUILD	aurch -C  <aur-package>
    		Remove AUR package from host:			aurch -Rh <aur-package>
    		Remove AUR package from nspawn container:	aurch -Rc <aur-package>
    		List nspawn container AUR sync db contents:	aurch -Lac
    		List nspawn container AUR repo updates:		aurch -Luc
    		List host AUR sync database contents:		aurch -Lah
    		List host AUR repo updates available:		aurch -Luh
    		Manually import a pgp key in nspawn container:	aurch --pgp <short/long id>
    		Manually remove unneeded pkgs from container:	aurch --clean
    		Login to chroot for maintenance:                aurch --login
    
    		(+) Package placed into host AUR repo and entry made in pacman AUR database.
    		Install with `pacman -S <aur-package>`
    
    USER VARIABLES
    		BASEDIR = path to chroot base dir
    		AURREPO = path to host aur repo
    		REPONAME =  host aur repo name
    		AURFM = AUR file manager,editor (mc = midnight commander)
    		
<br>
<br>

![Screenshot_2021-11-02_18-13-26](https://user-images.githubusercontent.com/36802396/140189725-9f30c9dc-b071-447c-9cd9-a2c177ac3371.png)

Screenshot: aurch --setup	 https://cody-learner.github.io/aurch-setup.html <br>
Screenshot: aurch -B bauerbill	 https://cody-learner.github.io/aurch-building-bauerbill.html <br>
<br> 
<br>
**NEWS, UPDATE, INFO:**<br>
<br>
<br>
**INFO For Oct 09, 2024** <br>
From my personal notes on aurch to use pacman7 new features. <br>
<br>
This is a condensed summary of the previous two **INFO** posts below. <br>
Of course my username and the gid numbers below will vary from system to system. <br>
*If you're trying to use aurch on a multiuser system where your user uid:gid are not 1000,* <br>
*I've created a non released version of aurch that works in that environment.* <br>
*Contact me for additional info.* <br>
 <br>
 <br>
Pacman7 must be installed prior to using this. ie: alpm group:user will be needed <br>
These instructions are specifically for the AUR repo residing in default location under ${HOME} <br>
An AUR repo under / has not been tested. <br>

--------------------------------------------------------------------------------------------------------<br>
***Check file permissions:***


		$ stat ${HOME} | grep 'Access: ('
		Access: (0750/drwxr-x---)  Uid: ( 1000/    jeff)   Gid: (  970/    alpm)

<br>

		$ stat ${HOME}/.cache/aurch/repo | grep 'Access: ('
		Access: (0755/drwxr-xr-x)  Uid: ( 1000/    jeff)   Gid: (  970/    alpm)

<br>
If the octal permissions and 'alpm' group for ${HOME} aren't set correctly,<br>
use the following commands to change them as required.<br>
<br>

		$ sudo chown :alpm "${HOME}"
		$ chmod 750 "${HOME}"

<br>

If the permissions on the AUR repo directory aren't set to 755, $USER:alpm per above <br>
set them as required: <br>

		$ sudo chown -R :alpm "${HOME}/.cache/aurch/repo/"
		$ chmod 755 "${HOME}/.cache/aurch/repo"

<br>

--------------------------------------------------------------------------------------------------------<br>
***Create the following directory and config file:***

This is a configuration file for the nspawn container used by aurch. <br>
It passes the Linux kernels landlock sandbox feature to the container. <br>


		$ sudo mkdir /etc/systemd/nspawn/



Create file '/etc/systemd/nspawn/<chroot-XXX>.nspawn' with the following content: <br>


		$ sudo nano /etc/systemd/nspawn/<chroot-XXX>.nspawn

<br>

		
		[Exec]
		SystemCallFilter=@sandbox
		


-------------------------------------------------------------------------------------------------------- <br>
***Check the pacman.conf settings in***  <br>
***both host and nspawn container are*** <br>
***set to the following default settings:*** <br>


		$ grep -E 'DownloadUser|DisableSandbox' /etc/pacman.conf
		$ grep -E 'DownloadUser|DisableSandbox' ${HOME}/.cache/aurch/base/chroot-*/etc/pacman.conf

<br>

		DownloadUser = alpm
		#DisableSandbox


-------------------------------------------------------------------------------------------------------- <br>
***Check "${HOME}" ACL settings:***

The following should be set. <br>

			$ getfacl "${HOME}"

			group::r-x


If not set correctly, run: <br>

			$ setfacl -m g:alpm:r-x "${HOME}"

If set correctly, you should see: <br>

			$ getfacl "${HOME}"

			# owner: jeff
			# group: alpm
			user::rwx
			group:alpm:r-x

<br>
<br>
<br>

**INFO For  Sep 30, 2024** <br>
I've figured out how to easily enable pacman 7.0 sandboxing in the nspawn container used by aurch. <br>
These findings will eventually make their way into aurch-install.<br>
To use pacman sandboxing in an nspawn container there are a few options. <br>
<br>
 Use '@sandbox' with '--system-call-filter=' on the CLI. ie: <br>

    $ sudo systemd-nspawn --system-call-filter=@sandbox    ..... 

Or setup a config file as follows for regularly used containers. See refs below for details. <br>
<br>
As root, create a dir '/etc/systemd/nspawn/' and file '/etc/systemd/nspawn/\<nspawn-root-dir-name\>.nspawn' <br>
using the directory name containing the nspawn root FS or image name, with the following content. <br>
ie: If directory 'chroot-Dz8' contains the root filesystem of an nspawn container. <br>

    $ sudo nano /etc/systemd/nspawn/chroot-Dz8.nspawn

    [Exec]
    SystemCallFilter=@sandbox

Be sure 'DownloadUser' is uncommented and 'DisableSandbox' is commented <br>
in the nspawn container pacman config file '/etc/pacman.conf'.<br>

<br>
References:<br>

https://wiki.archlinux.org/title/Systemd-nspawn#Configuration  
https://man.archlinux.org/man/systemd.nspawn.5  
https://linux-audit.com/systemd/systemd-syscall-filtering/  
https://man.archlinux.org/man/systemd.exec.5  

<br>
<br>
<br>

**INFO For  Sep 18, 2024**										<br>
Pacman 7 has added new security related features requiring manual intervention for both Arch and Aurch.	<br>
Systems using Aurch need changes to allow pacman user 'alpm' access to the local AUR repo.	<br>
The pacman user 'alpm', is a new, minimally permissioned system user:group used to download packages.	<br>
The following commands assume the local AUR repo is located in the default location, within $HOME.	<br>
The first two commands change $HOME directory group to 'alpm' and the 700 permission to 750.		<br>
The last command changes the AUR repo directory group to 'alpm' recursively.				<br>

    $ chown :alpm "${HOME}"
    $ chmod 750 "${HOME}"
    $ sudo chown -R :alpm "${HOME}/.cache/aurch/repo"

An edit to pacman.conf in nspawn is also required as Linux 'landlock' is unavailable in the container.	<br>
In the AUR nspawn container, /etc/pacman.conf, comment out the following line containing DownloadUser.	<br>
Commenting out the 'DownloadUser' line will have pacman fall back to using root to download packages.	<br>

    # DownloadUser = alpm

***Additional Info:***											<br>
*Arch News:* https://archlinux.org/news/manual-intervention-for-pacman-700-and-local-repositories-required/<br>
*Additional info:* `$ man pacman.conf` search: *DownloadUser* `$ man pacman` search: *--disable-sandbox*<br>
*pacman-dev mail list:* https://www.mail-archive.com/pacman-dev@lists.archlinux.org/msg01132.html	<br>
*Keep in mind the Arch News on pacman does not include the mandatory additional steps outlined above.*	<br>

***Opinion Short:***											<br>
Unfortunately, changes to pacman affecting users has at times seemed tightly held within the pacman development team.
Seems the pacman project just doesn't place much emphsis or resources on user level documentation.
That said, this is nothing unusual for open source projects. It's almost as if these talented volunteer 
programmers prefer writing code over writing accurate, thourough user level documentation!		<br>
I know, difficult to imagine! There's also source code available for a relaxing, insightful read. 		<br>

***Additional Show Stopping Findings:***									<br>
If you've implemented the above and still have issues, see the link below for info on ACL permissions.	<br>
Search for 'Additional show stopping finding:' located near the bottom the page.			<br>
https://bbs.archlinux.org/viewtopic.php?pid=2196652#p2196652						<br>
													<br>
I did have to make the ACL setting changes outlined in the link above on one Arch setup.		<br>
Last resort if all else fails in the host system: 							<br>
 (1) Try commenting out 'DownloadUser'.									<br>
 (2) Lastly, uncomment 'DisableSandbox' in pacman.conf							<br>
													<br>
Disabling the sandbox features in pacman would of course not take advantage of the new security enhancments.
Although I'd strongly advise against disabling snadboxing in the host system, there has never been a
reported case of a pacman security related exploit from downloading packages as root to my knowledge.
AFAIK, there has never been a security exploit of pacman reported since it's introduction ~20 years ago.

<br>
<br>
<br>

**UPDATE For  Aug 9, 2024**										<br>
aurch-setup.sh:												<br>
Added container shell configs: colored shell prompts, header id's, and alias's.				<br>
Corrected script comments and printed comments replacing 'chroot' with 'container'/'nspawn-container'.	<br>
Changed 'sleep' times.											<br>
Added printed comments for added container configuration.						<br>
Cleaned up trailing white space.									<br>
README.md:												<br>
Updated to report changes.										<br>
												<br>
**UPDATE For  Aug 3, 2024**								<br>
Fixed the processing of a printed message to the user.					<br>
Added a file of experimental code for aurch to build packages in clean chroot, 		<br>
rather the aurch nspawn container.							<br>
Somewhat Unrelated:									<br>
Added an `.sh` suffix to several of the scripts in here and my other repos/scripts. 	<br>
The suffix is used in the [github-ca.sh](https://github.com/Cody-Learner/github-clone-all) 
script to streamline installing my scripts in a new system.		<br>
									<br>
**UPDATE For  Aug 1, 2024**                                            <br>
aurch:                                                                 <br>
Worked on elimimating 'sudo timeouts' on long running package builds.  <br>
Edited 'cleanup_chroot' function to eliminate sudo timeouts,           <br>
works in conjunction with supplied '/etc/sudoers.d/aurch' example.     <br>
Edited 'check_host_updates' function to provide accurate results       <br>
on installed version if package is downgraded or held back from latest.<br>
Cleaned up script comments.                                            <br>
                                                                       <br>
**UPDATE For  July 19, 2024** <br>
Fixed "Review Files" for AUR dependency review when they are downloaded.<br>
Renamed `PAGER` variable to `AURFM` to eliminate potential issues. <br>
Corrected the incorrect/interchangeable usage of the words 'chroot' and 'nspawn container' in README.md <br>
and '--help' sections of scripts. <br>
 <br>
**UPDATE For  July 14, 2024** <br>
Updated dependencies list in aurch. <br>
Updated --help option and README file to mention PAGER variable. <br>
 <br>
**UPDATE For  April 21, 2024** <br>
Aurch-setup: Added 'mc' package as checked/installed dependency.<br>
<br>
**UPDATE For  April 17, 2024** <br>
Aurch: <br>
Fix info box "Chroot Path" line, to automatically align.<br>
Added '-' to 'opt' variable in '# Optionally install package #' section for <br>
incorrect shellcheck SC2154. # SC2154 opt is assigned in option parsing.<br>
<br>
**UPDATE For  April 14, 2024** <br>
Added '-V --version' operation to both aurch and aurch-setup. <br>
Append '-' to 'udb' variable in 'upd_aur_db' function as required by 'set -u'. <br>
<br>
**NEWS For  April 12, 2024** <br>
Subject: Debug Packages <br>
Some time back, pacman enabled debug packages by default in '/etc/makepkg.conf'. <br>
This results in a dbug package being build for AUR packages. <br>
If this is unwanted behavior, edit '/*container-path*/etc/makepkg.conf' appropriately.  <br>
See: Notes in makepkg.conf for add info. <br>
To remove any unwanted AUR debug packages from the host and/or AUR sync db,  <br>
*Install the 'package-debug' with pacman.* <br>
*Remove it using aurch. ie: aurch -Rh 'package-debug'.* <br>
<br>
**UPDATE For  April 12, 2024** <br>
Setup virtual environment for testing. <br>
Aurch-Setup: <br>
Pacman's repo-add no longer allows a new, empty repo to be initialized. <br>
Commit: https://gitlab.archlinux.org/pacman/pacman/-/commit/f91fa546f65af9ca7cdbe2b419c181df609969b7 <br>
Made changes to accommodate repo-adds new behavior.  <br>
Made changes to implement the use of 'set -euo pipefail'. <br>
Aurch: <br>
Discovered a new issue upon initial run caused by adding 'set -euo pipefail. <br>
Script exited on a 'find' command returning an empty result, along with expected non zero exit code. <br>
Set place holder files in AUR repos so find command returns a result, and zero exit code. <br>
 <br>
**UPDATE For  April 8, 2024** <br>
Fix 'Convert <package> input to all lower case', positional parameter expansion to 'package' variable. <br>
Added error handling for no package input used with '-B' and '-G' operations. <br>
Cleaned up script comments and removed commented out testing code. <br>
<br>
**UPDATE For  April 7, 2024** <br>
Although I don't base the quality of bash scripts on the use of the controversial 'set -euo pipefail',
I have been curious about what changes would be required to implement it. <br>
Updated the aurch script to implement 'set -euo pipefail'.<br>
Directly from my notes: <br>

    'set -u' Will not allow printing vars to file, lines 48-58.	Appending '-' to all vars fixed issue.
    'set -u' Will not allow using positional parameters.		Appending '-' to all positional parameters fixed issue.
    'set -u' Exits on: "/path/to/script/ line 147: $2: unbound variable"
    Line 147, '$2' is part of an awk command inside an "EOF [here doc]" and not a bash positional parameter. (A bash bug?)
    Rewrote 'fetch_pkg' function lines ~143-159, to accommodate 'set -u' by removing awk from the here doc.

**UPDATE For  March 10, 2023** <br>
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
Add removal of /var/tmp/aurch/orig-pkgs.log ("${tmph}"/orig-pkgs.log) in chroot so 'orig package list' reflects edits/changes made to 
.#orig-pkgs.log in base dir. <br>
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
