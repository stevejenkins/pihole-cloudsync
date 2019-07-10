#!/bin/bash

###########################################################################

# pihole-cloudsync-pull
# Helper script to keep multiple Pi-hole lists synchronized via Git

# Version 1.0 - July 8, 2019 - Steve Jenkins (stevejenkins.com)

# REQUIREMENTS
# 1. Create a git repo (on Github, GitLab, etc.) with only a master branch.
# 2. In

# USAGE
# 
# Run ./pihole-cloudsync from the command line

###########################################################################

# Constants
personal_git_dir='/usr/local/bin/steve-test-1'
pihole_dir='/etc/pihole'
ad_list='adlists.list'
black_list='black.list'
blacklist_list='blacklist.txt'
whitelist_list='whitelist.txt'
regex_list='regex.list'

# Only used for debugging
# set -x

# Check to see whether command line option was provided
if [ -z "$1" ]
  then
    echo "Missing command line option. Try --push, --pull, or --help."
    exit 1
fi

# Determine which action to perform (Push, Pull, or Help)
for arg in "$@"
do

    # Initialize - adds local Pi-hole lists to local Git repo before first push/upload
    if [ "$arg" == "--initialize" ] || [ "$arg" == "--init" ] || [ "$arg" == "-i" ]
    then
        echo "$arg option detected. Initializing repo for Push/Upload.";
	cd $pihole_dir || exit
	cp $ad_list $black_list $blacklist_list $whitelist_list $regex_list $personal_git_dir
	cd $personal_git_dir || exit
	git add .
	echo "Local Pi-hole lists added to local repo. Now try 'sudo ./pihole-cloudsync --push'";
	exit 0

    # Push / Upload
    elif [ "$arg" == "--push" ] || [ "$arg" == "--upload" ] || [ "$arg" == "--up" ] || [ "$arg" == "-u" ]
    then
        echo "$arg option detected. Running in Push/Upload mode."
	cd $pihole_dir || exit
	cp $ad_list $black_list $blacklist_list $whitelist_list $regex_list $personal_git_dir
	cd $personal_git_dir || exit

        CHANGED=$(git --work-tree=$personal_git_dir status --porcelain)
        if [ -n "${CHANGED}" ]; then
                echo 'Local Pi-hole lists are different than remote repo. Updating repo...';
		rightnow=$(date +"%B %e, %Y %l:%M%p")
		# Remove -q option if you don't want to run in "quiet" mode
		git commit -a -m "Updated $rightnow" -q
		git push -q
		echo 'Done!';
		exit 0
        else
                echo 'Remote repo matches local Pi-hole lists. No further action required.';
		exit 0
        fi

    # Pull / Download
    elif [ "$arg" == "--pull" ] || [ "$arg" == "--download" ] || [ "$arg" == "--down" ]|| [ "$arg" == "-d" ]
    then
        echo "$arg option detected. Running in Pull/Download mode."
	cd $personal_git_dir || exit
	CHANGED=$(git --work-tree=$personal_git_dir status --porcelain)
	if [ -n "${CHANGED}" ]; then
                echo 'Remote repo is different than local Pi-hole lists. Updating local lists...';
                # Remove -q option if you don't want to run in "quiet" mode
                git fetch --all -q
		git reset --hard origin/master -q
		cp $ad_list $black_list $blacklist_list $whitelist_list $regex_list $pihole_dir
		pihole -g
                echo 'Done!';
                exit 0
        else
                echo 'Local Pi-hole lists match remote repo. No further action required.';
                exit 0
        fi

    # Help
    elif [ "$arg" == "--help" ] || [ "$arg" == "-h" ] || [ "$arg" == "-?" ]
    then
	cat << EOF
Usage: pihole-cloudsync <option>

Options:
  --push, --upload, --up, -u		Push (upload) your Pi-hole lists to a Git repo
  --pull, --download, --down, -d	Pull (download) your lists from a Git repo
  --help, -h, -?			Show this help dialog

Examples:
  'pihole --push' will push (upload) your lists to a Git repo
  'pihole --pull' will pull (download) your lists from a Git repo

Project Home: https://github.com/stevejenkins/pihole-cloudsync
EOF

    # Invalid commang line option was passed
    else
	echo "Invalid command line option. Try --push, --pull, or --help."

    fi

done
