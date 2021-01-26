# `pihole-cloudsync`

A script to help synchronize <a target="_blank"
href="https://pi-hole.net/">Pi-hole</a> adlist/blocklist, blacklist, whitelist, regex, custom DNS hostnames, and custom CNAME hostnames across multiple Pi-holes using a Git repository.

# Why `pihole-cloudsync`?

I was running six Pi-holes on three different networks at three different physical locations. I wanted all six Pi-holes to share the same adlists, blacklists, whitelists, and regex files, but it was time-consuming to manually synchronize all of them (modify the local Pi-holes, VPN into the second network and modify those, then VPN into the third network and modify those). I also wanted the ability to share custom DNS hostnames between multiple Pi-holes so that the Pi-hole UI stats display the proper local hostnames instead of IP addresses.

I wanted to use Pi-hole's built-in web UI to manage only *one* set of lists on *one* Pi-hole -- and then securely synchronize an unlimited number of additional Pi-holes. I couldn't find an existing script that did exactly what I wanted... so I wrote `pihole-cloudsync`.

`pihole-cloudsync` is lightweight enough to use if you're only syncing 2 Pi-holes on a home network, but powerful enough to synchronize virtually *unlimited* Pi-holes on an *unlimited* number of networks.

Feedback, suggestions, bug fixes, and code contributions are welcome.

# How `pihole-cloudsync` Works

`pihole-cloudsync` allows you to designate any Pi-hole on any network to act as your "Master" or "Primary." This is the only Pi-hole whose list settings you will need to manage using Pi-hole's built-in web UI. The Primary Pi-hole then uses `pihole-cloudsync` in **Push** mode to *upload* four files to a private Git repository that you control (such as GitHub) that contain:

1. Your adlists/blocklists (queried from Pi-hole's database at `/etc/pihole/gravity.db`)
2. Your domain lists: "exact match" and "regex" versions of your white and black lists (queried from Pi-hole's database at `/etc/pihole/gravity.db`)
3. Any custom DNS names you've configured via the Pi-hole UI (copied from `/etc/pihole/custom.list`)
4. Any custom CNAMEs you've configured via the Pi-hole UI (copied from `/etc/dnsmasq.d/05-pihole-custom-cname.conf`)

All other Secondary Pi-holes that you wish to keep synchronized use `pihole-cloudsync` in **Pull** mode to *download* the above files from from your private Git repository.

The script is designed to work with any Git repo that your Pi-holes can access, but I have only personally tested it with GitHub.

## No more Pi-hole v4 support

This script was originally written to work on Pi-hole version 4. However, as of Pi-hole version 5, most of the settings needed for sync between Pi-holes is no longer stored in individual text files -- they are now all stored in a single database file called `gravity.db`. The changes required to `pihole-cloudsync` to work with Pi-hole v5 means it will no longer with with version of Pi-hole earlier than v5.

**Before proceeding, verify that your Primary and *all* Secondary Pi-holes are running Pi-hole v5 or later.**

## Docker Support

This script supports docker containers running the `pihole/pihole` image.
The container must be started when the script is run. The `pihole-cloudsync` should work out of the box with no changes required.

# Setup

Prior to running `pihole-cloudsync`, you must first create a new dedicated Git repository to store your lists, then clone that new repository to all Pi-holes (both Primary and Secondary) that you wish to keep in sync. The easiest way to do that is to fork my own <a target="_blank" href="https://github.com/stevejenkins/my-pihole-lists">`my-pihole-lists`</a> GitHub repository. Don't worry if the example lists in that repo are different than yours. You'll overwrite your forked version of the repo with your own Pi-hole lists the first time you run `pihole-cloudsync` in **Push** mode.

**On GitHub**

1. Sign into GitHub.
1. Go to https://github.com/stevejenkins/my-pihole-lists.
1. Press **Fork**.
1. *Optional:* If you wish to make your forked version of the repo private, press **Settings**, scroll down to the **Danger Zone**, then press **Make private**.
1. On your new repo's main page, press the **Clone or download** button and copy the **Clone with HTTPS** link to your clipboard.

**On your Primary Pi-hole device**

1. Install Git (on Raspbian/Debian do `sudo apt-get install git`).
1. Do `cd /usr/local/bin`.
1. Install `pihole-cloudsync` with `sudo git clone https://github.com/stevejenkins/pihole-cloudsync.git`.
1. Create your private local Git repo with `sudo git clone https://github.com/<yourusername>/my-pihole-lists.git` (paste the URL you copied from GitHub).
1. Run `/usr/local/bin/pihole-cloudsync/pihole-cloudsync --initpush` to initialize the local Pi-hole in "Push" mode. It will grab your Primary Pi-hole's list files (both from the `gravity.db` database and `/etc/pihole`) and add them to your new local Git repo. The `--initpush` mode should only need to be run once on your Primary Pi-hole.
1. Run `/usr/local/bin/pihole-cloudsync/pihole-cloudsync --push` to push/upload your Primary Pi-hole's lists from your local Git repo to your remote Git repo. You will have to manually enter your GitHub email address and password the first time you do this, but read below for how to save your login credentials so you can run this script unattended.

**On all Secondary Pi-hole devices**

1. Install Git (on Raspbian/Debian do `sudo apt-get install git`)
1. Do `cd /usr/local/bin`
1. Install `pihole-cloudsync` with `sudo git clone https://github.com/stevejenkins/pihole-cloudsync.git`
1. Create your private local Git repo with `sudo git clone https://github.com/<yourusername>/my-pihole-lists.git` (paste the URL you copied from GitHub)
1. Run `/usr/local/bin/pihole-cloudsync/pihole-cloudsync --initpull` to initialize the local Pi-hole in Pull/Download mode. You will have to manually enter your GitHub email address and password the first time you do this, but read below for how to save your login credentials so you can run this script unattended. The `--initpull` option will also perform your first pull automatically and only needs to be run once on each Secondary Pi-hole. All future pulls can be performed with `/usr/local/bin/pihole-cloudsync/pihole-cloudsync --pull`.
1. Running `pihole-cloudsync --pull` will pull/download your Primary Pi-hole's lists from your remote Git repo to your Secondary Pi-hole's local Git repo. The `--pull` option will automatically copy the downloaded file(s) to your Pi-hole directory and tell Pi-hole to do a `pihole -g` command to update its lists.

# Running `pihole-cloudsync` Unattended

**The following steps must be performed on each Pi-hole you wish to use with `pihole-cloudsync`.**

In order to automate or run `pihole-cloudsync` unattended, you will need to either store your GitHub login credentials locally or create an SSH key for your Pi-hole's root user and upload the public key to GitHub. You will need to do this on the Primary Pi-hole as well as all Secondary Pi-holes.

The SSH key approach is for more advanced users who don't need me to explain how to do it. To store your Git credentials locally, do the following on each Pi-hole:

`cd /usr/local/bin/my-pihole-lists`

`sudo git config --global credential.helper store`

The next time you pull from or push to the remote repository, you'll be prompted for your username and password. But you won't have to re-enter them after that. So do a simple:

`sudo git pull`

to enter and save your credentials. Now you can run `pihole-cloudsync` unattended on this Pi-hole device.

Again, **the above steps must be performed on each Pi-hole you wish to use with `pihole-cloudsync`.**

# Automating `pihole-cloudsync`

Once each Pi-hole's local Git repo has been configured to save your login credentials, you can automate your Primary Pi-hole's "push" and your Secondary Pi-holes' "pull" in any number of ways. The simplest method is to run a [cron job](#Automating-with-cron) a few times a day. If you want more flexibility over schedule and resource use, you can also use [systemd](#Automating-with-systemd) to automate. Both methods are explained below.

## Automating with cron

The simplest way is to automate `pihole-cloudsync` is to set a "push" cron job on your Primary Pi-hole that runs a few times a day, then set a "pull" cron job on each Secondary Pi-hole that pulls in any changes a few minutes after your Primary pushes them.

Once you can successfully run `pihole-cloudsync --push` from the command line on your Primary Pi-hole, do `crontab -e` (or `sudo crontab -e` if you're not logged in as the root user) and create a cron entry such as:

`00 01,07,13,19 * * * sudo /usr/local/bin/pihole-cloudsync/pihole-cloudsync --push > /dev/null 2>&1 #Push Master Pi-hole Lists to remote Git repo`

And once you can successfully run `pihole-cloudsync --pull` from the command line on each of your Secondary Pi-holes, do `sudo crontab -e` and create a cron entry that runs 5 minutes after your Primary pushes any changes, such as:

`05 01,07,13,19 * * * sudo /usr/local/bin/pihole-cloudsync/pihole-cloudsync --pull > /dev/null 2>&1 #Pull Master Pi-hole Lists from remote Git repo`

**NOTE:** On Raspbian/Raspberry Pi OS, the script won't execute via cron without the `sudo` command (as shown above). If you're having trouble getting the script to run unattended on Raspbian/Raspberry Pi OS, try including `sudo` in the cron command.

## Automating with systemd

`pihole-cloudsync` pulls can also be automated with systemd, if your Pi-hole is running on a systemd-supported distro. Once you're able to successfully run `pihole-cloudsync --pull` from the command line on each of your Secondary Pi-holes, you can proceed with systemd setup. You must install three `[Unit]` files on your Pi-hole to ensure a stable and non-intrusive update process: a `.service` file, a `.timer` file, and a `.slice` file.

### Quick Start

1. Copy the each of the three `[Unit]` files in the **systemd Details** section below into `/etc/systemd/system` on your Pi-hole
1. Tell systemd you changed its configuration files with `systemctl daemon-reload`
1. Enable and start the service/timer

```bash
# Enable the relevant configs
systemctl enable pihole-cloudsync-update.service
systemctl enable pihole-cloudsync-update.timer

# Start the timer
systemctl start pihole-cloudsync-update.timer
```

### systemd Details

1. **.service** - `/etc/systemd/system/pihole-cloudsync-update.service` - The core service file.  Configured as a 'oneshot' in order to be run via a [systemd timer](https://wiki.archlinux.org/index.php/Systemd/Timers).

```ini
[Unit]
Description=PiHole Cloud Sync Data Puller service
Wants=pihole-cloudsync-update.timer

[Service]
Type=oneshot
ExecStart=/usr/local/bin/pihole-cloudsync --pull
Slice=pihole-cloudsync-update.slice

[Install]
WantedBy=multi-user.target
```

2. **.timer** - `/etc/systemd/system/pihole-cloudsync-update.timer` - The timer file.  Determines when the `.service` file is executed. systemd timers are highly flexible and can be executed under a variety of timed and trigger-based circumstances. The [ArchLinux systemd/Timer documentation](https://wiki.archlinux.org/index.php/Systemd/Timers) is some of the best around. See their [examples](https://wiki.archlinux.org/index.php/Systemd/Timers#Examples) for many more ways to configure this systemd timer unit.

```ini
[Unit]
Description=PiHole Cloud Synd Data Puller timer
Requires=pihole-cloudsync-update.service

[Timer]
Unit=pihole-cloudsync-update.service
OnBootSec=15
OnUnitActiveSec=1h

[Install]
WantedBy=timers.target
```

3. **.slice** - `/etc/systemd/system/pihole-cloudsync-update.slice` - The slice file.  Determines how much of the total system resources the `.service` is allowed to consume. This slice is in place to keep the update process in check and ensure that there will always be *plenty* of room for the Pi-hole service to answer DNS queries without being obstructed by potential `pihole-cloudsync` updates. If you'd like to learn more about systemd slices, check out [this wiki page](https://wikitech.wikimedia.org/wiki/Systemd_resource_control).

```ini
[Unit]
Description=PiHole Cloud Sync Puller resource limiter slice
Before=slices.target

[Slice]
CPUQuota=50%
```

*Special thanks to [Conroman16](https://github.com/Conroman16) for contributing the systemd automation instructions*

# Updating `pihole-cloudsync`

To upgrade to the latest version of `pihole-cloudsync`, do the following on *all* Primary and Secondary Pi-holes. Note that this will completely over-write any previous modifications you've made to `pihole-cloudsync`.

1. Do `cd /usr/local/bin/pihole-cloudsync`
1. Do `git fetch --all`
1. Do `git reset --hard origin/master`

Your local version of `pihole-cloudsync` is now updated to the latest release version.

# Disclaimer

You are totally responsible for anything this script does to your system. Whether it launches a nice game of Tic Tac Toe or global thermonuclear war, you're on your own. :)
