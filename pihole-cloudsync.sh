#!/bin/bash

###########################################################################

# pihole-cloudsync-pull
# Helper script to keep multiple Pi-hole lists synchronized via GitHub

# Version 1.0 - July 8, 2019 - Steve Jenkins (stevejenkins.com)

# USAGE
# Run ./pihole-cloudsync from the command line

###########################################################################

# Constants
personal_git_dir='/usr/local/bin/my-pihole-lists'
pihole_dir='/etc/pihole'
ad_list='adlists.list'
black_list='black.list'
blacklist_list='blacklist.txt'
whitelist_list='whitelist.txt'
regex_list='regex.list'

# Only used for debugging
set -x

# Check to see whether command line argument was provided
if [ -z "$1" ]
  then
    echo "Missing command line argument. Try --push, --pull, or --help."
    exit 1
fi

# Determine which action to perform (Push, Pull, or Help)
for arg in "$@"
do
    # Push / Upload
    if [ "$arg" == "--push" ] || [ "$arg" == "--upload" ] || [ "$arg" == "-u" ]
    then
        echo "Push (Upload) argument detected."
	cd $pihole_dir || exit
	cp $ad_list $black_list $blacklist_list $whitelist_list $regex_list $personal_git_dir
	cd $personal_git_dir || exit

        CHANGED=$(git --work-tree=$personal_git_dir status --porcelain)
        if [ -n "${CHANGED}" ]; then
                echo 'changed';
        else
                echo 'Remote repo matches local Pi-hole lists. No further action required.';
		exit 0
        fi

    # Pull / Download
    elif [ "$arg" == "--pull" ] || [ "$arg" == "--download" ] || [ "$arg" == "-d" ]
    then
        echo "Pull (Download) argument detected."
	cd $personal_git_dir || exit
	CHANGED=$(git --work-tree=$personal_git_dir status --porcelain)
        if [ -n "${CHANGED}" ]; then
                echo 'changed';
        else
                echo 'Local Pi-hole lists match remote repo. No further action required.';
                exit 0
        fi

    # Help
    elif [ "$arg" == "--help" ] || [ "$arg" == "-h" ]
    then
	cat << EOF
Usage: pihole-cloudsync <option>

Options:
  --push, --upload, -u		Push (upload) your Pi-hole lists to GitHub
  --pull, --download, -d	Pull (download) your lists from GitHub
  --help, -h			Show this help dialog

Examples:
  'pihole --push' to push/upload your lists to GitHub
  'pihole --pull' to pull/download your lists from GitHub

Project Home: https://github.com/stevejenkins/pihole-cloudsync
EOF

    # Invalid commang line argument was passed
    else
	echo "Invalid command line argument. Try --push, --pull, or --help."

    fi

done
