# pihole-cloudsync
A script to help synchronize <a target="_blank" 
href="https://pi-hole.net/">Pi-hole</a> blocklist, blacklist, whitelist, and regex files across multiple Pi-holes using a Git repository.

# Why pihole-cloudsync?
I run six Pi-holes on three different networks at three different physical locations. I wanted all six Pi-holes to share the same blocklists, blacklists, whitelists, and regex files, but it was time-consuming to manually synchronize all of them (modify the local Pi-holes, VPN into the second network and modify those, then VPN into the third network and modify those).

I wanted to use Pi-hole's built-in web UI to manage only *one* set of lists on *one* Pi-hole -- and then securely synchronize an unlimited number of additional Pi-holes. I couldn't find an existing script that did exactly what I wanted... so I wrote `pihole-cloudsync`.

`pihole-cloudsync` is lightweight enough to use if you're only syncing 2 Pi-holes on a home network, but powerful enough to synchronize virtually *unlimited* Pi-holes on an *unlimited* number of networks. 

Feedback, suggestions, bug fixes, and code contributions are welcome.

# How pihole-cloudsync Works
`pihole-cloudsync` allows you to designate any Pi-hole on any network to act as your "Master" or "Primary." This is the only Pi-hole whose list settings you will need to manage using Pi-hole's built-in web UI. The Primary Pi-hole then uses `pihole-cloudsync` in **Push** mode to *upload* its blocklist, blacklist, whitelist, and regex files to a private Git repository that you control (such as GitHub).

All other Pi-holes that you wish to keep synchronized use `pihole-cloudsync` in **Pull** mode to *download* your Primary Pi-hole's blocklist, blacklist, whitelist, and regex files from your private Git repository.

The script is designed to work with any Git repo that your Pi-holes can access, but I have only personally tested it with GitHub.

# Setup
Prior to running `pihole-cloudsync`, you must first create a new dedicated Git respository to store your lists, then clone that new repository to all Pi-holes (both Primary and Secondary) that you wish to keep in sync. The easiest way to do that is to fork my own <a target="_blank" href="https://github.com/stevejenkins/my-pihole-lists">`my-pihole-lists`</a> GitHub repository. Don't worry if my personal lists in that repo are different than yours. You'll overwrite your forked version of the repo with your own Pi-hole lists the first time you run `pihole-cloudsync` in **Push** mode.

**On GitHub**
1. Sign into GitHub.
2. Go to https://github.com/stevejenkins/my-pihole-lists.
3. Press **Fork**.
4. Optional: If you wish to make your forked version of the repo private, press **Settings**, scroll down to the **Danger Zone**, then press **Make private**.
4. On your new repo's main page, press the **Clone or download** button and copy the **Clone with HTTPS** link to your clipboard.

**On your Primary Pi-hole device**
1. Install Git (on Raspbian/Debian do `sudo apt-get install git`).
2. Do `cd /usr/local/bin`.
3. Install `pihole-cloudsync` with `sudo git clone https://github.com/stevejenkins/pihole-cloudsync.git`.
4. Create your private local Git repo with `sudo git clone https://github.com/<yourusername>/my-pihole-lists.git` (paste the URL you copied from GitHub).
5. If you're using a repo name other than `my-pihole-lists`, edit `/usr/local/bin/pihole-cloudsync` and edit the `personal_git_dir` variable to match your local Git repo location.
6. Run `/usr/local/bin/pihole-cloudsync --init` to copy your Primary Pi-hole's list files from `/etc/pihole` and add them to your new local Git repo. You only need to use the `--init` option on your Primary, since it's the only one that will "push" your lists to the remote Git repo.
7. Run `/usr/local/bin/pihole-cloudsync --push` to push/upload your Primary Pi-hole's list from your local Git repo to your remote Git repo. You will have to manually enter your GitHub email address and password the first time you do this, but read below for how to save your login credentials so you can run this script unattended.

**On all Secondary Pi-hole devices**
1. Install Git (on Raspbian/Debian do `sudo apt-get install git`)
2. Do `cd /usr/local/bin`
3. Install `pihole-cloudsync` with `sudo git clone https://github.com/stevejenkins/pihole-cloudsync.git`
4. Create your private local Git repo with `sudo git clone https://github.com/<yourusername>/my-pihole-lists.git` (paste the URL you copied from GitHub)
5. If you're using a repo name other than `my-pihole-lists`, edit `/usr/local/bin/pihole-cloudsync` and edit the `personal_git_dir` variable to match your local Git repo location.
6. Run `/usr/local/bin/pihole-cloudsync --pull` to pull/download your Primary Pi-hole's lists from your remote Git repo to your local Git repo. You will have to manually enter your GitHub email address and password the first time you do this, but read below for how to save your login credentials so you can run this script unattended.
7. The script will automatically copy the downloaded file(s) to your Pi-hole directory and tell Pi-hole to do a `pihole -g` command to update its lists.

# Running pihole-cloudsync Unattended
**The following steps must be performed on each Pi-hole you wish to use with `pihole-cloudsync`.**

In order to automate or run `pihole-cloudsync` unattended, you will need to either store your GitHub login credentials locally or create an SSH key for your Pi-hole's root user and upload the public key to GitHub. You will need to do this on the Primary Pi-hole as well as all Secondary Pi-holes.

The SSH key approach is for more advanced users who don't need me to explain how to do it. To store your Git credentials locally, do the following on each Pi-hole:

`cd /usr/local/bin/my-pihole-lists`

`sudo git config --global credential.helper store`

The next time you pull from or push to the remote repository, you'll be prompted for your username and password. But you won't have to re-enter them after that. So do a simple:

`sudo git pull`

to enter and save your credentials. Now you can run `pihole-cloudsync` unattended on this Pi-hole device.

Again, **the above steps must be performed on each Pi-hole you wish to use with `pihole-cloudsync`.**

## Automating with cron
Once each Pi-hole's local Git repo has been configured to save your login credentials, you can automate your Primary Pi-hole's "push" and your Secondary Pi-holes' "pull" in any number of ways. The simplest way is to run a simple cron job a few times a day. Remember to set the cron job for the root user (with `sudo crontab -e`).

Once you can successfully run `pihole-cloudsync --push` from the command line on your Primary Pi-hole, do `sudo crontab -e` and create a cron entry such as:

`00 01,07,13,19 * * * /usr/local/bin/pihole-cloudsync/pihole-cloudsync --push > /dev/null 2>&1 #Push Master Pi-hole Lists to remote Git repo`

And once you can successfully run `pihole-cloudsync --pull` from the command line on each of your Secondary Pi-holes, do `sudo crontab -e` and create a cron entry that runs 5 minutes after your Primary pushes any changes, such as:

`05 01,07,13,19 * * * /usr/local/bin/pihole-cloudsync/pihole-cloudsync --pull > /dev/null 2>&1 #Pull Master Pi-hole Lists from remote Git repo`

# Disclaimer
You are totally responsible for anything this script does to your system. Whether it launches a nice game of Tic Tac Toe or global thermonuclear war, you're on your own. :)
