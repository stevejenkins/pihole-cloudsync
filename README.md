# pihole-cloudsync
A script to help synchronize <a target="_blank" 
href="https://pi-hole.net/">Pi-hole</a> blocklist, blacklist, whitelist, regex (and optionally `/etc/hosts` files) across multiple Pi-holes using a Git repository.

# Why pihole-cloudsync?
I was running six Pi-holes on three different networks at three different physical locations. I wanted all six Pi-holes to share the same blocklists, blacklists, whitelists, and regex files, but it was time-consuming to manually synchronize all of them (modify the local Pi-holes, VPN into the second network and modify those, then VPN into the third network and modify those). I also wanted the ability to share a common section of `/etc/hosts` between multiple Pi-holes so that the Pi-hole UI stats display the proper local hostnames instead of IP addresses.

I wanted to use Pi-hole's built-in web UI to manage only *one* set of lists on *one* Pi-hole -- and then securely synchronize an unlimited number of additional Pi-holes. I couldn't find an existing script that did exactly what I wanted... so I wrote `pihole-cloudsync`.

`pihole-cloudsync` is lightweight enough to use if you're only syncing 2 Pi-holes on a home network, but powerful enough to synchronize virtually *unlimited* Pi-holes on an *unlimited* number of networks.

Feedback, suggestions, bug fixes, and code contributions are welcome.

# How pihole-cloudsync Works
`pihole-cloudsync` allows you to designate any Pi-hole on any network to act as your "Master" or "Primary." This is the only Pi-hole whose list settings you will need to manage using Pi-hole's built-in web UI. The Primary Pi-hole then uses `pihole-cloudsync` in **Push** mode to *upload* its blocklist, blacklist, whitelist, and regex files to a private Git repository that you control (such as GitHub).

All other Secondary Pi-holes that you wish to keep synchronized use `pihole-cloudsync` in **Pull** mode to *download* your Primary Pi-hole's blocklist, blacklist, whitelist, and regex files from your private Git repository.

If you enable the optional **Shared Hosts** mode (more details on that below), `pihole-cloudsync` will also scan for a specially marked section of your Primary Pi-hole's `/etc/hosts` file and push it to your private Git repository. Your Secondary Pi-holes can then pull the shared hosts data from the repo and insert it into their existing `/etc/hosts` files.

The script is designed to work with any Git repo that your Pi-holes can access, but I have only personally tested it with GitHub.

# Setup
Prior to running `pihole-cloudsync`, you must first create a new dedicated Git respository to store your lists, then clone that new repository to all Pi-holes (both Primary and Secondary) that you wish to keep in sync. The easiest way to do that is to fork my own <a target="_blank" href="https://github.com/stevejenkins/my-pihole-lists">`my-pihole-lists`</a> GitHub repository. Don't worry if my personal lists in that repo are different than yours. You'll overwrite your forked version of the repo with your own Pi-hole lists the first time you run `pihole-cloudsync` in **Push** mode.

**On GitHub**
1. Sign into GitHub.
2. Go to https://github.com/stevejenkins/my-pihole-lists.
3. Press **Fork**.
4. *Optional:* If you wish to make your forked version of the repo private, press **Settings**, scroll down to the **Danger Zone**, then press **Make private**.
5. On your new repo's main page, press the **Clone or download** button and copy the **Clone with HTTPS** link to your clipboard.

**On your Primary Pi-hole device**
1. Install Git (on Raspbian/Debian do `sudo apt-get install git`).
2. Do `cd /usr/local/bin`.
3. Install `pihole-cloudsync` with `sudo git clone https://github.com/stevejenkins/pihole-cloudsync.git`.
4. Create your private local Git repo with `sudo git clone https://github.com/<yourusername>/my-pihole-lists.git` (paste the URL you copied from GitHub).
5. If you're using a repo name other than `my-pihole-lists`, edit `/usr/local/bin/pihole-cloudsync/pihole-cloudsync` and edit the `personal_git_dir` variable to match your local Git repo location.
6. If you want to enable **Shared Hosts** mode, edit `/usr/local/bin/pihole-cloudsync/pihole-cloudsync` and change the `enable_hosts` option to `on` (you could also use `1`, `y`, `yes`, or `true` in upper or lower case). Refer to the **Shared Hosts Mode** section below to add two required comment lines to your local Pi-hole's `/etc/hosts` file before proceeding to the next step and running `pihole-cloudsync` for the first time.
7. Run `/usr/local/bin/pihole-cloudsync/pihole-cloudsync --initpush` to initialize the local Pi-hole in "Push" mode. It will grab your Primary Pi-hole's list files from `/etc/pihole` (as well as the designated portion of your `/etc/hosts` file if **Shared Hosts Mode** is enabled) and add them to your new local Git repo. The `--initpush` mode should only need to be run once on your Primary Pi-hole.
8. Run `/usr/local/bin/pihole-cloudsync/pihole-cloudsync --push` to push/upload your Primary Pi-hole's lists from your local Git repo to your remote Git repo. You will have to manually enter your GitHub email address and password the first time you do this, but read below for how to save your login credentials so you can run this script unattended.

**On all Secondary Pi-hole devices**
1. Install Git (on Raspbian/Debian do `sudo apt-get install git`)
2. Do `cd /usr/local/bin`
3. Install `pihole-cloudsync` with `sudo git clone https://github.com/stevejenkins/pihole-cloudsync.git`
4. Create your private local Git repo with `sudo git clone https://github.com/<yourusername>/my-pihole-lists.git` (paste the URL you copied from GitHub)
5. If you're using a repo name other than `my-pihole-lists`, edit `/usr/local/bin/pihole-cloudsync/pihole-cloudsync` and edit the `personal_git_dir` variable to match your local Git repo location.
6. If you want to enable **Shared Hosts** mode, edit `/usr/local/bin/pihole-cloudsync/pihole-cloudsync` and change the `enable_hosts` option to `on` (you could also use `1`, `y`, `yes`, or `true` in upper or lower case). Make sure you've added the necessary comments to your Primary Pi-hole's `/etc/hosts` file (explained in the **Shared Hosts Mode** section of this README) before proceeding to the next step and running `pihole-cloudsync` for the first time.
6. Run `/usr/local/bin/pihole-cloudsync/pihole-cloudsync --initpull` to initialize the local Pi-hole in Pull/Download mode. You will have to manually enter your GitHub email address and password the first time you do this, but read below for how to save your login credentials so you can run this script unattended. The `--initpull` option will also perform your first pull automatically and only needs to be run once on each Secondary Pi-hole. All future pulls can be performed with `/usr/local/bin/pihole-cloudsync/pihole-cloudsync --pull`.
7. Running `pihole-cloudsync --pull` will pull/download your Primary Pi-hole's lists from your remote Git repo to your Secondary Pi-hole's local Git repo. The `--pull` option will automatically copy the downloaded file(s) to your Pi-hole directory and tell Pi-hole to do a `pihole -g` command to update its lists.

## Shared Hosts Mode
Because the local hostname information is unique to each Pi-hole, it's impractical to simply clone the Primary Pi-hole's entire `/etc/hosts` file to all Secondary Pi-holes. However, `pihole-cloudsync` allows you to designate a portion of your Primary Pi-hole's `/etc/hosts` file that can be inserted into each Secondary Pi-hole's `/etc/hosts` file by enabdling **Shared Hosts** mode on your Primary and Secondary Pi-holes.

Here's an example `/etc/hosts` file on a **Primary** Pi-hole:
```
127.0.0.1	localhost
::1		localhost ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters
127.0.1.1	Pi-hole

192.168.1.1     gateway.local
192.168.1.105   pihole1.local
192.168.1.106   pihole2.local
192.168.1.117   desktop1.local
192.168.1.118   laptop1.local
192.168.1.200   iot1.local
fe80::e123:74ed:b5e:34a2        pihole1.local
fe80::f123:73d6:fe15:f5dd       pihole2.local
```

To allow `pihole-cloudsync` to know which hosts you want to sync to your Secondary Pi-holes, enclose the shared host information in your Primary Pi-hole's `/etc/hosts` file between the following exact comments:
```
# SHARED HOSTS - START
(shared host entries go here)
# SHARED HOSTS - END
```

So your **Primary** Pi-hole's `/etc/hosts` file should look something like this:

```
127.0.0.1	localhost
::1		localhost ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters
127.0.1.1	Pi-hole

# SHARED HOSTS - START
192.168.1.1     gateway.local
192.168.1.105   pihole1.local
192.168.1.106   pihole2.local
192.168.1.117   desktop1.local
192.168.1.118   laptop1.local
192.168.1.200   iot1.local
fe80::e123:74ed:b5e:34a2        pihole1.local
fe80::f123:73d6:fe15:f5dd       pihole2.local
# SHARED HOSTS - END
```
On all **Secondary** Pi-holes, simply insert the **START** and **END** comments at the bottom of their `/etc/hosts` files like this:

```
127.0.0.1	localhost
::1		localhost ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters
127.0.1.1	Pi-hole2

# SHARED HOSTS - START
# SHARED HOSTS - END
```
When `pihole-cloudsync` runs in **Pull** mode with the Shared Hosts mode enabled, it will insert the shared hosts between those comments.

**IMPORTANT:** You must enter the comments exactly as shown, since `pihole-cloudsync` searches for those exact comments in order to syncronize properly.

Enable Shared Hosts mode by editing `/usr/local/bin/pihole-cloudsync/pihole-cloudsync`. Change the `enable_hosts` option to `on` (you could also use `1`, `y`, `yes`, or `true` in upper or lower case). Make sure you've added the necessary comments to your Primary Pi-hole's `/etc/hosts` file running `pihole-cloudsync` in Shared Hosts mode.

If you decide to enable Shared Hosts mode after you've already been running `pihole-cloudsync` for a while, simply re-run in `--initpush` or `--initpull` mode (depending on whether you are configuring a Primary or Secondary Pi-hole) after setting `enable_hosts` to `on` in  `/usr/local/bin/pihole-cloudsync/pihole-cloudsync`.

## Alternative Configuration: All Secondary (no Primary) Pi-holes
Once you've successfully pushed your Primary Pi-hole's lists to your remote Git repo, you could optionally choose to edit/manage your whitelist, blacklists, and regex files directly on your Git repo using your cloud-based Git provider's built-in editing tools. If you go this route, you'll need to re-configure what was previously your Primary Pi-hole to run in Pull mode (which will turn it into a Secondary). Do:

`/usr/local/bin/pihole-cloudsync/pihole-cloudsync --initpull`

That will re-initialize the local Pi-hole in Pull/Download mode. If you had previously automated your Primary Pi-hole's periodic pushes, be sure to edit your `crontab` so that `pihole-cloudsync` runs in Pull mode instead of Push mode.

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
Once each Pi-hole's local Git repo has been configured to save your login credentials, you can automate your Primary Pi-hole's "push" and your Secondary Pi-holes' "pull" in any number of ways. The simplest way is to run a simple cron job a few times a day.

Once you can successfully run `pihole-cloudsync --push` from the command line on your Primary Pi-hole, do `crontab -e` (or `sudo crontab -e` if you're not logged in as the root user) and create a cron entry such as:

`00 01,07,13,19 * * * sudo /usr/local/bin/pihole-cloudsync/pihole-cloudsync --push > /dev/null 2>&1 #Push Master Pi-hole Lists to remote Git repo`

And once you can successfully run `pihole-cloudsync --pull` from the command line on each of your Secondary Pi-holes, do `sudo crontab -e` and create a cron entry that runs 5 minutes after your Primary pushes any changes, such as:

`05 01,07,13,19 * * * sudo /usr/local/bin/pihole-cloudsync/pihole-cloudsync --pull > /dev/null 2>&1 #Pull Master Pi-hole Lists from remote Git repo`

**NOTE:** On Raspian, the script won't execute via cron without the `sudo` command (as shown above). If you're having trouble getting the script to run unattended on Raspian, try including `sudo` in the cron command.

# Disclaimer
You are totally responsible for anything this script does to your system. Whether it launches a nice game of Tic Tac Toe or global thermonuclear war, you're on your own. :)
