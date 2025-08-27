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
		-B* --build     Build new or update an existing AUR package.
		-G  --git       Git clones an AUR package.
		-C  --compile   Build an AUR package on existing PKGBUILD.(1) 
		-Rh             Remove AUR pkg from host.(2)
		-Rc             Remove AUR pkg from nspawn container.(3)
		-Syu  --update  Update nspawn container packages.(4)
		-Lah* --lsaurh  List AUR sync database contents/status of host.
		-Lac* --lsaurc  List AUR sync database contents/status of nspawn container.
		-Luh* --lsudh   List update info for AUR packages installed in host.
		-Luc* --lsudc   List update info for AUR pkgs/AUR deps in nspawn container.
		-Lv             List aurch variables.
                  --login   Login to nspawn container for maintenance.
                  --clean   Manually remove unneeded packages from nspawn container.
                  --pgp     Manually import pgp key in nspawn container.
		-h,   --help    Prints help.
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

    		Set up nspawn container:                        aurch-setup --setupchroot
    		Set up local AUR repo:                          aurch-setup --setuphost


    		USING AURCH:

    		Build an AUR package(+):                        aurch -B  <aur-package>
    		Build and install AUR package:                  aurch -Bi <aur-package>
    		Git clone package                               aurch -G  <aur-package>
    		Build (Compile) AUR pkg on existing PKGBUILD    aurch -C  <aur-package>
    		Remove AUR package from host:                   aurch -Rh <aur-package>
    		Remove AUR package from nspawn container:       aurch -Rc <aur-package>
    		List nspawn container AUR sync db contents:     aurch -Lac
    		List nspawn container AUR repo updates:         aurch -Luc
    		List host AUR sync database contents:           aurch -Lah
    		List host AUR repo updates available:           aurch -Luh
    		Manually import a pgp key in nspawn container:  aurch --pgp <short/long id>
    		Manually remove unneeded pkgs from container:   aurch --clean
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

Screenshot: `aurch --setup`	 https://cody-learner.github.io/aurch-setup.html <br>
Screenshot: `aurch -B bauerbill`	 https://cody-learner.github.io/aurch-building-bauerbill.html <br>
<br>


### NEWS, UPDATE, INFO:
----
**UPDATE For August 27, 2025**

**aurch.sh**
* Set `CleanChroot` path as a variable.
* Changed `czm` var name to 'acp' (aurch colored pointer).
* Added `note` var for green color text formatting.
* Deleted the `'ck_per` (check/correct file permissions) function.
* Function `fetch_pgp_key`, edited the ubuntu keyserver to port 443, and added a fallback `hkps://keys.openpgp.org` in case of failure.
* Function `cleanup_chroot`, added delete `/etc/sudoers.d/aurch-sudo` file, so 'trap' will remove 'aurch-sudo' file if `build_clean_chroot` function is interrupted.
* Function `check_chroot_updates', rewrote function to speed up via batches of parallel checks and provide a progress bar.
* Eliminate building debug packages in '-Cc' clean chroot option.
* Added check/update `-Cc` clean chroot build env.
* Function `cleanup_host` added delete `/etc/sudoers.d/aurch-sudo` file, so 'trap' will remove `aurch-sudo` file if `build_pkg` function is interrupted.
* Added if statement to print `-Cc` clean chroot build path in aurch's info only if it exists (has been used).
* Changed print `--log` operation formatting.

**README.md:**
* Update to reflect changes.

----

**UPDATE For JANUARY 16, 2025**

***Bug fix:*** In a fresh aurch install, running `aurch --clean` before building a package in a <br>
clean chroot `aurch -Cc` results in an error.


**aurch.sh**
* Relocated creation of directory  `/var/tmp/aurch` from within function `build_clean_chroot` to beginning of script.

-----

**UPDATE For DECEMBER 05, 2024**

**aurch-setup.sh**
* Corrected dependencies in script comments and `check_depends` function.
* Added punctuation to printed message.

**aurch.sh**
* Corrected dependencies in script comments. 
* Reworded and added printed comments.
* Changed name of file `/etc/sudoers.d/aurch` to `/etc/sudoers.d/aurch-sudo` to avoid potential overwrite.
* Added color cancel code to `if [[ -z ${*} ]]` printed script info after testing in `arch install media`.

------

**UPDATE For DECEMBER 03, 2024**

**aurch.sh:**
* Changed temp work file names to enhance intuitive readablity.
* Replaced array and vars with temp work files where appropriate.
* Added printed message clarifying when rebuilding existing, current packages.
* Replaced parsing output from `aur fetch` to implementing `--results=` file.
* Implemented `pr` command for improved formatting printed messages.
* Implemented `ln` `options` for improved formatting printed messages.
* Implemented parsing output of `repo-add` to be used for verification.

------

**UPDATE For November 26, 2024**

***Bug fix:*** In a fresh aurch install, first run of '-B' operation with an empty local AUR repo, an empty 'find' result, resulted in aurch exiting.

**aurch.sh:**
* Remove trailing whitespace.
* Operation `--help`, reword `-Ccb` info.
* Function `build_pkg`, rewrite first `find` command to not exit script on empty `find` results.
  * ie: New or empty repo.<br>
* Function `build_clean_chroot`: <br>
  * Change several `read` commands options including implementation of `-p` to eliminate proceeding `printf` message lines.
  * On repetitive usage of the same variable in `while read` loops for user input, unset variable after each use.

**README.md:**
* Update to reflect changes.

-------

**UPDATE For November 24, 2024**

**aurch.sh:**
* Function `ck_per`, changed formatting sent to log.
* Function `is_it_available`, added log upon error.
* Added `--log` operation to display `logfile` in less.

-------

**UPDATE For November 23, 2024**

Today we offer an actual release, or somewhat of a 'tune up' on the urgently release bug fix yesterday.<br>
ie: clean up, additional testing, shellcheck, minimal feature creep<br>
Keeping the `ck_per` function to check/correct the AUR repo permissions for now. 
It will eventually be removed after additional testing time indicates everything is in order.<br>
An aurch log file is now available, `/var/log/aurch.log`. 

**aurch.sh:**<br>
* Removed `permlog` variable.
* Added `logfile` variable.
* Added creation, set permission of logfile if not present.
* Added `dt` variable (date time) used for logging.
* Added basic logging capabilities.

**README.md:**<br>
* Update to reflect changes.

---------

**UPDATE For November 22, 2024 (2nd)**

This is a bug fix release that eliminates the AUR repo permission issues. <br>

I spent more time describing the issue below than the actual fix once I had the tools needed for troubleshooting. <br>

I'm too tired to get into great detail, so please see the commit comments link and diff for additional info: <br>

https://github.com/Cody-Learner/aurch/commit/369ab0186a840176aa208f81d416d34a19e1d490

--------

**UPDATE And INFO For November 22, 2024**

Getting a better handle on local AUR repo permission issues in both host and container.
Obviously moving away from the current workaround of monitoring and correcting permissions would be the best path forward.

One issue is collisions upon rebuilding packages owned by user, that can't overwrite existing packages owned by root.
Another issue is the aur db permissions randomly changing to root owner rather than user, making them inaccessible by user.

Made several changes that were possibly contributing to the issues in both `aurch` and `aurch-setup`.
Added automated diagnostic code in `aurch` and supplied a separate script `paths`, to use manually to provide a quick overview 
of permissions on the potentially troublesome directories/files.

Added an automated `chown -R user:group` to the directories containing the repos, when triggered by the db's owner being changed from user.

However, I'm unsure about how and when some of the permissions on packages in my local AUR repos were changed. 
I do way too much testing, etc on this machine that may have contributed to these issues, to attempt to track down the root cause until now.

With a fresh `chown` and the changes described, it should be pretty straightforward tracking the issues into the future.

With the changes made including the elimination of several unneeded `sudo` calls, time with testing will tell how this plays out. 
If it does continue, there will be an evidence trail this time around in the new log file. 
Having info on what operations are leading up to it should provide a solid path forward for troubleshooting.


**aurch-setup.sh:** 
* Removed three dependencies used for clean chroot builds. The `aurch` script installs them upon first usage of `-Cc*` operation.
* Removed user `alpm` from permission settings.
* Implemented `SUDO_USER` in various areas.

**aurch.sh:**
* Removed `clean local AUR repo` code from `build_clean_chroot` function, to it's own function, `cleanup_host`.
* Replaced `set_perm` function with `ck_per`, changed repo permission correction from 'octal' to 'user:group' names, 
  added printed warning notification when permissions have changed, and added diagnostic logging.
* Eliminated the AUR repo 'placeholder' fake packages. Rewrote the `find` commands to exit zero on file not found.
* Changed AUR repos permission checks/corrections to run once before `-B,-C,-R` operations. It's still located within the `build_clean_chroot` function.
* Eliminated several sudo calls that were unnecessary.
* Function `build_pkg` (`-B*`,`-C` operations), moved order of code around to get similar output as `-Cc*` provides at end of build.
* Function `cleanup_chroot` changed printf quoting in 'heredoc'.
* Moved script comments to dedicated lines rather than trailing code lines.
* Function `build_clean_chroot` (`-Cc*` operation), improved building/installing dependencies automatically after user confirmation 
  and changed quoting on printf commands.
* The `--clean` operation, added `cleanup_host` function. It still performs several container cleaning tasks and now cleans up host AUR repo. 
  Added this after testing revealed a broken AUR pkg during a "clean chroot build" exit, resulted in host local AUR repo being polluted 
  with dozens of official pkgs.
* Added a `trap` command to handle cleanup upon script exit while building broken AUR packages.

**aurch.sh diagnostics:**
* Added `permlog` variable that sets the aurch log location.
* All data sent to log is formatted: \<year\>-\<month\>-\<day\> : \<args\>
* All aurch commands with one or more args will be logged.
* All AUR repo permission corrections will be logged.

------------

**UPDATE For November 20, 2024**

**aurch.sh:**
* Spelling corrections, rewording, add script comments.
* Clean up some existing code.
* Remove three dependencies listed and installed in aurch-setup that are only needed for `-Cc*` clean chroot build.
  These dependencies are checked, user asked for conformation if missing, then installed when running `-Cc*` clean chroot build.
* Changed function name `build-clean-chroot` to `build_clean_chroot` to maintain consistency, using `_` rather than `-` for seperators.

-------

**UPDATE For November 19, 2024**

**aurch.sh**
* Added option to `-Cc* --cchroot` operation, `-Ccb` 'b is for both', to copy and register package in both host and container.
Running `-Cc` copies and registers package into host only. This will be useful for example, the `python2` package. It
requires building in a clean chroot to pass the default testing, and is a dependency of additional AUR packages. Using
the `-Ccb` option will place `python2` in the aurch container AUR cache and sync db, which enables it to be used as a
dependency for other AUR builds, rather than building it as an unavailable in sync db AUR dependency.
* Display the `-h --help` operation info in the `less`(1) pager so it opens at top rather than bottom of the page.
* Added `-Ccb` option to help page along with some rewording/reformatting.
* Working on distinguishing the terms, 'container' vs 'chroot' in displayed info. Aurutils refers to their clean chroot container as
'chroot'. Aurch used to use the same, 'chroot' until some time ago I decided to change it to more accuracy point out the use of
'nspawn container', with 'container' as the short version. With the implementation of aurutils clean chroot building on the aurch
host system now, I'd like clear distinction of these terms to avoid any possible confusion for users.
* Function `build-clean-chroot` (`-Cc*` operation): Added code to facilitate the `b` option.

(1) Note to self: Should probably either add `less` (`man-db` dep) as a dependency, check for less install and default to cat if needed, 
or look into use/set PAGER...

--------

**UPDATE For November 18, 2024 (2nd)**

**aurch.sh** <br>
* Function `build-clean-chroot` (`-Cc` operation): <br>
* Corrected variable used from `package` to `build` that's printed to screen as current package being built.
* Renamed `build.log` file to `aurch-build.log` for improved script readability.
* Improved `keeppkgs` variable to include additional AUR packages in `-ignore` list used by `paccache`.
* Corrected file used and improved formatting of printed 'copied and registered packages' list at end of build.
* Added and clarified various script comments.

------

**UPDATE For November 18, 2024**

**aurch.sh:** <br>
* Function `build-clean-chroot` (`-Cc` operation): <br>
  Added `--keyserver keyserver.ubuntu.com` to the `gpg --recv-key` command. <br>
  Note: Even though `dirmngr --gpgconf-list` lists `//keyserver.ubuntu.com` as default,
  the pgp key issues I experienced during testing stopped after making this change.
* Fixed the 'packages built' list at end of clean chroot build that could list unrelated packages.

------

**UPDATE For November 17, 2024**

**aurch.sh**
* Edited `cleanup_chroot` function (`-Cc` operation), the `cleanup_chroot` heredoc script, eliminated the need for 'fake pkg.tar' 
and refined info printed to screen. Added script notes.

* Edited `remove` function (`-Rh -Rc` operations). Rewrote around one half the code. Replaced several 'set vars' to use with `rm` commands with 
`find` `-delete`, `-print/-printf` and figured out how to implement various `find` exit code conditions. Provide additional feedback printed to screen. 
Added script notes.


------

**UPDATE For November 15, 2024**

**aurch.sh:** <br>
* Refined variable definition code for: `czm`, `error`, `warn`. Changes involved quoting and spaces.
* Added `# shellcheck disable=SC2016 disable=SC2028` to script so as to not warn about intended behavior.
* Edited `print_vars` function (`-Lv` operation) to now provide output capable of copy, paste into shell, to set all `aurch` variables currently set. 
  This is to facilitate working with script.
* Edited `help` function.
* Replaced several `echo` commands with `printf` throughout script.
* Edited `cleanup_chroot` function (`--clean` operation). It's now `heredock`-ing a new script into the nspawn container if not present, then running the script. 
  The script uninstalls all unneeded pkgs, cleans official pkg cache of all pkgs, cleans the AUR cache of all non AUR pkgs, removes older versions 
  of existing AUR pkgs, removes any `download-*` dirs left by pacman, and prints quantitative results to screen.
* Edited `build-clean-chroot` function (`-Cc` operation), adding existing `is_it_available` function, reworded printed warning message, added printed
  info regarding pgp keys, added the removal of any `download-*` dirs left by pacman.

-------

**UPDATE For November 13, 2024**

**aurch.sh:** <br>
* Added a new `-Cc --cchroot` operation. Builds package in a clean chroot. This involved a complete rewrite of the testing operation. 
  The `aurch-cc` script has been eliminated with the new code residing in aurch. <br>
  Note: The new clean chroot operation is functional but needs additional testing and refinement. <br>
* Added a fix including printed text when it's ran. The issue is some build directories were left without a PKGBUILD. 
  The issue surfaces when an existing package is rebuilt. It was caused from early clean chroot testing. <br>
* Replaced code that was parsing and using info printed to screen, with a more robust solution. <br>
* Function `upd_aur_db`, changed an `awk` command to be more flexible. ie: `print $5` to `$NF`. <br>


**aurch-setup.sh:** <br>
* New dependencies added for clean chroot builds: sudo devtools paccat. 
  These are checked for and optionally added in aurch when '-Cc' is ran as well. <br>
* Added printed info regarding the sudo requirement over alternatives. <br>
* Registered aurutils installation in container aur database. <br>


**README.md:** <br>
Updated 'info and updates' section to reflect changes. <br>

------

**UPDATE For November 8, 2024**

**aurch:** <br>

* Added 'warn' variable.
* Added if statement to 'fetch_pkg' function to 'mkdir $chroot/var/tmp/aurch' if not present. ie: for testing.
* Moved 'set_perm' and 'rest_perm' functions from option parsing to specifically wrap 'aur build' commands.
* Reworked, edited 'aur build --results=aur-build-raw.log' command to to utilize '--results=aur-build-raw.log' file rather than parsing and using raw output. Need a 'feature add' to aurutils for this to work.
* Added code to parse 'aur-build-raw.log' data.

**UPDATE For November 5, 2024**

**aurch:** <br>
* Added `perm` variable, octal permission of `"${chroot}"/build/aur.db.tar.gz` <br>
* Renamed `re_pr` function to `rest_perm` for improved future readability. <br>
* The `set_perm` and `rest_perm` functions change permission on `"${chroot}"/build/aur.db.tar.gz` from `644` to `646`, then back to `644`, 
for the two functions requiring write access. The container system pacman sets it to `644`. <br>
* Replaced `set_env` function with `print_vars` to print variables via `-Lv` to terminal and write to file `"${BASEDIR}"/.#aurch-vars` <br>
* Added info and reworded `--help` information. <br>
* Added additional info printed to terminal for `-Cc` operation. <br>
* Removed `set_env` from option parsing. Checking indicated this unnecessary. <br>

**aurch-setup:** <br>
* Removed `print_env` function, it's contents run on base script now. Function unneeded with new `sudo` invocation requirement for script. <br>
* Reworded `--help` information. <br>
* Added if statement to create `"${BASEDIR}/.#aurch-vars"` if not present, with the message `"To populate with variables run: 'aurch -Lv'"`. <br>
* Removed `print_env` function from  option parsing. <br>

**aurch-cc:** <br>
* Reworded script header info. This info is now printed to terminal for additional info when using `-Cc` <br>

----

**UPDATE And INFO Info November 4, 2024**


**Manual Intervention Required For `aurch 2024-11-04`** <br>

<br>

With pacman 7 implementing Linux landlock and user `alpm`, this version of `aurch-install` is placing the  
chroot and local AUR repo outside the users home directory, relocating them under `/usr/local/aurch/`.
This relocation required changes to `aurch` as well, making this update non-backward compatible.

The motivating factor in this change was driven by the requirement to muck around with permissions to use pacman 7's enhanced security
features with `aurch`. This update eliminates any potential `$HOME` filesystem permission compromises required going forward.

To be clear, mixing previous versions of `aurch-setup` script including the container it provides, with this release 
of `aurch` will not work together. The new release of `aurch` has numerous permission related changes to enable it to work properly with 
the new location of the nspawn container.

Run the following for the scripts version, which is also printed in the script headers.

    aurch-setup -V
    aurch -V

Unfortunately, as much of an outspoken proponent I am of 'never break backward compatability', I just couldn't justify not making breaking 
changes in this case. A new nspawn container using `aurch-setup` is the way forward.

My thoughts about the new nspawn setup requirement are anyone adventurous enough to be using `aurch` most likely wouldn't need 
instruction for the process. That said, I'll still provide an overview of the process I used for my first aurch container 
switch, from the perspective of a long term user with a few dozen AUR package average over the years. Best case scenario is 
this overview may foster some thought, leading to an improved process.

I'll start by providing the default locations of the previous and current nspawn containers and local AUR repos.


**Previous versions** `aurch` default locations placed the container/repo under `/home`:

* nspawn container: `$HOME/.cache/aurch/base/chroot-XXX/`
* local AUR repo  : `$HOME/.cache/aurch/repo/`

<br>

**Current version** `aurch` default locations place the container/repo under `/usr` : <br>

* nspawn container: `/usr/local/aurch/base/chroot-XXX`
* local AUR repo  : `/usr/local/aurch/repo`

<br>

The update process I used went something like the following: <br>

<br>

**UPDATE PREP:**
* Make sure your system is up to date.
* Remove `/etc/aurch.conf`
* Remove the line `Include = /etc/aurch.conf` from `/etc/pacman.conf`.
* Remove `/var/lib/pacman/sync/aur.db`.
* Remove `/var/lib/pacman/sync/aur.files`.
* Make sure `/usr/local/aurch/` is not present.
* Remove the previous version `aurch` scripts from $PATH.

<br>

I manually moved / entered previously built AUR packages and build directories from old to new locations. <br>
A new install of AUR packages would be a viable option as well. <br>

<br>

**INSTALL AND SETUP:**
* Place the latest version `aurch` scripts under $PATH. 
* Run the `aurch-setup` script, both the `-Sc` and `-Sh` operations.
* For reinstalling AUR packages, you're done here. Use the latest version of `aurch` to reinstall.
* Manually move the previously built AUR packages under container `/build/` and the host aur `/repo/`
  to the new locations under `/usr/local/aurch/`.
* Use `repo-add` + some bash to manually add the packages to the new databases.
* Move the previously created build directories (containing .git) under <br>
  `... /aurch/base/chroot-XXX/home/builduser/` from the old to new container.


Technically the pacman databases could be relocated and reused along with the packages. <br>
I'll give this a try on the next update and consider reporting the process, depending on the outcome.

Any changes made to permissions as posted previously below, can now be reverted to their previous/default settings.
Below are the default permissions of HOME on a fresh arch install.

    $ stat ${HOME}
      File: /home/jeff
      Size: 4096      	Blocks: 8          IO Block: 4096   directory
    Device: 8,4	Inode: 261633      Links: 9
    Access: (0700/drwx------)  Uid: ( 1000/    jeff)   Gid: ( 1000/    jeff)
    Access: 2024-11-04 16:26:28.510897414 -0800
    Modify: 2024-11-04 16:26:41.680812205 -0800
    Change: 2024-11-04 16:26:41.680812205 -0800
     Birth: 2024-10-28 00:23:23.049409103 -0700
    
    $ getfacl "${HOME}"
    getfacl: Removing leading '/' from absolute path names
    # file: home/jeff
    # owner: jeff
    # group: jeff
    user::rwx
    group::---
    other::---

See the latest commmits for additional details on changes.

----

**INFO For Nov 03, 2024** <br>

I noticed **gpg stopped working** in my Arch Linux `aurch` nspawn container. There's a user gpg config 
file that's automagically generated in nspawn containers, that's breaking pgp and is the culprit. I've not yet looked into 
the details, but **getting rid of the config will get gpg back up and running.** <br>
The file/dir is in an `aurch nspawn container`. <br>
The full path from host to config using default locations is: <br>
And there's a directory being created there as well: <br>

    /home/jeff/.cache/aurch/base/chroot-Hj8/home/builduser/.gnupg/common.conf > single line: use-keyboxd
    /home/jeff/.cache/aurch/base/chroot-Hj8/home/builduser/.gnupg/public-keys.d > 36 files
 

A little investigation with a fresh arch nspawn container revealed, these are created upon 
the first invocation of gpg. An auto generated config is not something I'd expect from Arch. Possibly a
gnupg thing where it recognises it's in a container, or even a systemd thing?

The files/dirs are not present in my bare metal installs. When I get some time I may look into this a bit more.(*)
I did see something related to the config, a daemon? When it worked again without the config I settled for good enough.

This config is already taken care of in the upcoming version of `aurch-install`.


(*)
https://gnupg.org/documentation/manuals/gnupg/GPG-Configuration.html
> If the default home directory ~/.gnupg does not exist, GnuPG creates this directory and a common.conf file with "use-keyboxd".
 
This was not the case in my testing, as I was in the ~/.gnupg directory before starting gpg.

----


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


----

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

----

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


----

**UPDATE For  Aug 9, 2024**										<br>
aurch-setup.sh:												<br>
Added container shell configs: colored shell prompts, header id's, and alias's.				<br>
Corrected script comments and printed comments replacing 'chroot' with 'container'/'nspawn-container'.	<br>
Changed 'sleep' times.											<br>
Added printed comments for added container configuration.						<br>
Cleaned up trailing white space.									<br>
README.md:												<br>
Updated to report changes.										<br>

----

**UPDATE For  Aug 3, 2024**								<br>
Fixed the processing of a printed message to the user.					<br>
Added a file of experimental code for aurch to build packages in clean chroot, 		<br>
rather the aurch nspawn container.							<br>
Somewhat Unrelated:									<br>
Added an `.sh` suffix to several of the scripts in here and my other repos/scripts. 	<br>
The suffix is used in the [github-ca.sh](https://github.com/Cody-Learner/github-clone-all) 
script to streamline installing my scripts in a new system.		<br>

----

**UPDATE For  Aug 1, 2024**                                            <br>
aurch:                                                                 <br>
Worked on elimimating 'sudo timeouts' on long running package builds.  <br>
Edited 'cleanup_chroot' function to eliminate sudo timeouts,           <br>
works in conjunction with supplied '/etc/sudoers.d/aurch' example.     <br>
Edited 'check_host_updates' function to provide accurate results       <br>
on installed version if package is downgraded or held back from latest.<br>
Cleaned up script comments.                                            <br>

----

**UPDATE For  July 19, 2024** <br>
Fixed "Review Files" for AUR dependency review when they are downloaded.<br>
Renamed `PAGER` variable to `AURFM` to eliminate potential issues. <br>
Corrected the incorrect/interchangeable usage of the words 'chroot' and 'nspawn container' in README.md <br>
and '--help' sections of scripts. <br>

----

**UPDATE For  July 14, 2024** <br>
Updated dependencies list in aurch. <br>
Updated --help option and README file to mention PAGER variable. <br>

----

**UPDATE For  April 21, 2024** <br>
Aurch-setup: Added 'mc' package as checked/installed dependency.<br>

----

**UPDATE For  April 17, 2024** <br>
Aurch: <br>
Fix info box "Chroot Path" line, to automatically align.<br>
Added '-' to 'opt' variable in '# Optionally install package #' section for <br>
incorrect shellcheck SC2154. # SC2154 opt is assigned in option parsing.<br>

----

**UPDATE For  April 14, 2024** <br>
Added '-V --version' operation to both aurch and aurch-setup. <br>
Append '-' to 'udb' variable in 'upd_aur_db' function as required by 'set -u'. <br>

----

**NEWS For  April 12, 2024** <br>
Subject: Debug Packages <br>
Some time back, pacman enabled debug packages by default in '/etc/makepkg.conf'. <br>
This results in a dbug package being build for AUR packages. <br>
If this is unwanted behavior, edit '/*container-path*/etc/makepkg.conf' appropriately.  <br>
See: Notes in makepkg.conf for add info. <br>
To remove any unwanted AUR debug packages from the host and/or AUR sync db,  <br>
*Install the 'package-debug' with pacman.* <br>
*Remove it using aurch. ie: aurch -Rh 'package-debug'.* <br>

----

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

----

**UPDATE For  April 8, 2024** <br>
Fix 'Convert <package> input to all lower case', positional parameter expansion to 'package' variable. <br>
Added error handling for no package input used with '-B' and '-G' operations. <br>
Cleaned up script comments and removed commented out testing code. <br>

----

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

----

**UPDATE For  March 10, 2023** <br>
Updated script for compatiblity with interface changes made to aurutils-11. <br>
https://github.com/AladW/aurutils/releases/tag/11<br>
Updated README to reflect changes and clarify info.<br>

----

**UPDATE For  Jan 07, 2023** <br>
When deleting AUR packages from host, corrected ability to remove "all versions" of pkgs from the host AUR package cache. <br>
Add an if statement to 'check_host_updates' function to properly handle and print message 'No Updates Available'. <br>
Edited message in 'check_host_updates' function when package is newer than the AUR rpc version to:  <br>
"VCS Packages newer than AUR rpc version. Run 'aurch -Luc' to check them for updates.".<br>

----

**UPDATE For  Feb 11, 2022** <br>
Change curl commands to reflect AUR RPC interface update/changes. <br>
Add removal of /var/tmp/aurch/orig-pkgs.log ("${tmph}"/orig-pkgs.log) in chroot so 'orig package list' reflects edits/changes made to 
.#orig-pkgs.log in base dir. <br>
Add if statement to check build dir/s for .git dir. This allows adding misc dir's (ie: 'testing' toolchain pkgs) under buildusers home. <br>

----

**UPDATE For  Jan 21, 2022** <br>
Disable 'set -e'. <br>
Testing in virtual hw system revealed failure to build pkg that was not present on test system. <br>

----

**UPDATE For  Jan 06, 2022** <br>
Implemented 'set -e' in script. <br>
Added code line 162 to enable proper 'set -e'. <br>
Added '-a' opt to systemd-nspawn commands. <br>
Replaced cat with sort in subshell for comm command. <br>
Added 'else' to if statement in upd_aur_db function. <br>

----

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

----

**UPDATE For  Dec 10, 2021** <br>
The predominant focus this time around was implementing some additional flexibility to allow aurch to be usable for more 
than my personal setup and preferences. Implemented virtual hardware testing as a start towards this objective. <br>
Split the system setup and building packages into separate scripts. To many additional smaller changes to go over here. 
Future road map includes implementing a built in inspection step of downloaded AUR data and running a check for existing 
PGP keys to eliminate needless re-downloading.<br>

----

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

----

**UPDATE For  Nov 27, 2021** <br>
Rewrote 'here document' usage to extend systemd-nspawn functionality, rather than inserting multiple small scripts into chroot. <br>
Added code and printed comments relating to rebuilding and reinstalling same version of packages. <br>
Reworked 'setup_chroot' function to eliminated the evil 'eval' command. <br>
Integrated /var/tmp directory usage in chroot and added file extensions to ease it's cleanup. <br>

----

**UPDATE For  Nov 24, 2021** <br>
Added '-L  --listup' operation, to lists updates. <br>
The new function runs on the packages in the chroot AUR repo. <br>
It compares local vs remote git HEAD and lists mismatching packages. <br>

----

**UPDATE For  Nov 21, 2021** <br>
Added function to add packages to hosts AUR repo database.<br>

----

**UPDATE For  Nov 20, 2021** <br>
Fixed for proper split package handling.<br>

----

**UPDATE For  Nov 14, 2021** <br>
Rewrote aurch to no longer require AUR dependencies. No AUR helper required on host. <br>
Creates a chroot with aurutils set up, including a local pacman AUR repo, inside the chroot. <br>
Added ability to git clone and build package independently to ease customization. <br>
AUR packages are retained in the chroot for dependency usage. <br>

----

**NEWS FOR Oct 31, 2021** <br>
Initial release of the aurch script. <br>
The script is in the testing phase. <br>
