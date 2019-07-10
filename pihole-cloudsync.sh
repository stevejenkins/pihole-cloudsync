#!/bin/bash

###########################################################################

# pihole-cloudsync
# Helper script to keep multiple Pi-holes' lists synchronized via Git

# Version 1.3 - July 10, 2019 - Steve Jenkins (stevejenkins.com)

# SETUP
# Follow the instructions in the README to set up your own private Git
# repository BEFORE running this script for the first time. This script
# will not work without a properly configured Git repo and credentials.

# USAGE: pihole-cloudsync <option>

# OPTIONS:
#  --push, --upload, --up, -u		Push (upload) your Pi-hole lists to a remote Git repo
#  --pull, --download, --down, -d	Pull (download) your lists from a remote Git repo
#  --initialize, --init, -i		Add local Pi-hole lists to local Git repo before first push
#  --help, -h, -?			Show this help dialog

# EXAMPLES:
#  'pihole-cloudsync --push' will push (upload) your lists to a remote Git repo
#  'pihole-cloudsync --pull' will pull (download) your lists from a remote Git repo

# Project Home: https://github.com/stevejenkins/pihole-cloudsync

###########################################################################

# CONSTANTS
personal_git_dir='/usr/local/bin/my-pihole-lists'
pihole_dir='/etc/pihole'
ad_list='adlists.list'
black_list='black.list'
blacklist_list='blacklist.txt'
whitelist_list='whitelist.txt'
regex_list='regex.list'

# Force sudo if not running with root privileges
SUDO=''
if [ "$EUID" -ne 0 ]
  then SUDO='sudo'
fi

# FUNCTIONS
initialize () {
	cd $pihole_dir || exit
	$SUDO cp $ad_list $black_list $blacklist_list $whitelist_list $regex_list $personal_git_dir
	cd $personal_git_dir || exit
	$SUDO git add .
	echo "Local Pi-hole lists added to local Git repo. Run 'pihole-cloudsync --push' to push to remote Git repo.";
}

push () {
	cd $pihole_dir || exit
	$SUDO cp $ad_list $black_list $blacklist_list $whitelist_list $regex_list $personal_git_dir
	cd $personal_git_dir || exit

        CHANGED=$($SUDO git --work-tree=$personal_git_dir status --porcelain > /dev/null)
        if [ -n "${CHANGED}" ]; then
                echo 'Local Pi-hole lists are different than remote Git repo. Updating remote repo...';
		rightnow=$(date +"%B %e, %Y %l:%M%p")
		# Remove -q option if you don't want to run in "quiet" mode
		$SUDO git commit -a -m "Updated $rightnow" -q
		$SUDO git push -q
		echo 'Done!';
		exit 0
        else
                echo 'Remote Git repo matches local Pi-hole lists. No further action required.';
		exit 0
        fi
}

pull () {
	cd $personal_git_dir || exit
	CHANGED=$($SUDO git remote update && git --work-tree=$personal_git_dir status --porcelain > /dev/null)
	if [ -n "${CHANGED}" ]; then
                echo 'Remote Git repo is different than local Pi-hole lists. Updating local lists...';
                # Remove -q option if you don't want to run in "quiet" mode
                $SUDO git fetch --all -q
		$SUDO git reset --hard origin/master -q
		$SUDO cp $ad_list $black_list $blacklist_list $whitelist_list $regex_list $pihole_dir
		$SUDO pihole -g
                echo 'Done!';
                exit 0
        else
                echo 'Local Pi-hole lists match remote Git repo. No further action required.';
                exit 0
        fi
}

#######################################################

# Check to see whether command line option was provided
if [ -z "$1" ]
  then
    echo "Missing command line option. Try --push, --pull, or --help."
    exit 1
fi

# Determine which action to perform (Push, Pull, or Help)
for arg in "$@"
do

    # Initialize - adds primary Pi-hole's lists to local Git repo before first push/upload
    if [ "$arg" == "--initialize" ] || [ "$arg" == "--init" ] || [ "$arg" == "-i" ]
    then
	echo "$arg option detected. Initializing local Git repo for Push/Upload.";
	initialize
	exit 0

    # Push / Upload - Pushes updated local Pi-hole lists to remote Git repo
    elif [ "$arg" == "--push" ] || [ "$arg" == "--upload" ] || [ "$arg" == "--up" ] || [ "$arg" == "-u" ]
    then
	echo "$arg option detected. Running in Push/Upload mode."
	push
	exit 0

    # Pull / Download - Pulls updated Pi-hole lists from remote Git repo
    elif [ "$arg" == "--pull" ] || [ "$arg" == "--download" ] || [ "$arg" == "--down" ]|| [ "$arg" == "-d" ]
    then
        echo "$arg option detected. Running in Pull/Download mode."
	pull
        exit 0

    # Help - Displays help dialog
    elif [ "$arg" == "--help" ] || [ "$arg" == "-h" ] || [ "$arg" == "-?" ]
    then
	cat << EOF
Usage: pihole-cloudsync <option>

Options:
  --push, --upload, --up, -u		Push (upload) your Pi-hole lists to a remote Git repo
  --pull, --download, --down, -d	Pull (download) your lists from a remote Git repo
  --initialize, --init, -i		Add local Pi-hole lists to local Git repo before first push
  --help, -h, -?			Show this help dialog

Examples:
  'pihole-cloudsync --push' will push (upload) your lists to a Git repo
  'pihole-cloudsync --pull' will pull (download) your lists from a Git repo

Project Home: https://github.com/stevejenkins/pihole-cloudsync
EOF

    # Invalid commang line option was passed
    else
	echo "Invalid command line option. Try --push, --pull, or --help."
	exit 1
    fi
done
