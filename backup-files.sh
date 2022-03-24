#!/bin/sh
# Name:
# Backup-tar
# 
# Description:
# Create compressed tarball of key config dirs and files from system or user
# dirs. It also helps creating full backups for user content.
#
# Date:
# 24/03/2022
#
# Author:
# Javier Alonso del Saso <javialonsaso@gmail.com>

# Simple exit when error occurrs managing arguments
exit_abnormal(){
	echo "Usage: $0 [[ -u | -s ] -o <TAR_FILE> | -h]"
	exit 1
}

# Manage script arguments using getopts util
# Options are -u, -s, -h, -o <file>
while getopts ":usho:" options; do

	case "${options}" in
		h)
			echo "COMMAND"
			echo "$0 [[ -u | -s ] -o <TAR_FILE> | -h]"
			echo "DESCRIPTION"
			echo "Create a gzip-compressed tar file as a backup for system files and user files."
			echo "OPTIONS"
			echo "    -u"
			echo "    Backup user-specific content and save it as a tarball"
			echo ""
			echo "    -s"
			echo "    Backup system and user configuration and save it as a tarball"
			echo ""
			echo "    -h"
			echo "    Print this help message"
			echo ""
			echo "    -o <TAR_FILE>"
			echo "    Tarball filename"
			exit 0
			;;
		u) # User-defined content. This is quite big if your home dir is full!
			USER=true
			;;
		s) # System and user config dirs and files. This includes pacman database!
			USER=false
			;;
		o) # Mandatory! Tarball namefile
			TAR_FILE="${OPTARG}"
			;;
		:) # If you miss the name of tarball
			echo "Error: -${OPTARG} requires an argument."
			exit_abnormal
			;;
		*) # For anything else
			exit_abnormal
			;;
	esac
done

# If Tarball filename is not defined, exit
if [[ ! -v TAR_FILE ]]; then
	exit_abnormal
fi

# If -u opt is given, define user content for tarball
if [[ $USER = true ]]; then
	# Here include a list of dirs and files to be added
	INCLUDE_NAMES="
	"
	# Here exclude dirs and files from being added
	EXCLUDE_NAMES=(
					)
else
# If -s opt is given, define user and sys config for tarball
	INCLUDE_NAMES="
				etc/
				var/lib/pacman/local/
				usr/local/bin/
				usr/local/etc/
				usr/local/share/

				home/<user>/.password-store/
				home/<user>/.gnupg/
				home/<user>/.config/

				home/<user>/.local/var/aur/aurpkgs.db.tar
				home/<user>/.bash_profile
				home/<user>/.bashrc"
	EXCLUDE_NAMES=(
					--exclude="$0"
					)
fi
# Tar works by glob(3)ing pattern. For much more precision we use the complete
# dir name from root.

# Create archive preserving file permissions, ACLs properties and extended attributes
tar --create \
	--label='System and user config files and pacman database' \
	--one-file-system \
	--directory=/ \
	--exclude-caches \
	--preserve-permissions \
	--acls \
	--xattrs \
	--file=$TAR_FILE \
	"${EXCLUDE_NAMES[@]}" \
	$INCLUDE_NAMES

# If there wasn't any error, proceed to verify content of tarball to file system
if [ $? -eq 0 ]; then
	echo "Verifying archive..."
	tar --diff \
		--directory=/ \
		--file=$TAR_FILE
	echo "Verification completed!"

	echo "Backup saved in ${TAR_FILE}"
else
	echo "Tar exited with error(s)"
	exit 1
fi

exit 0
