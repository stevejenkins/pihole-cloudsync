# `pihole-cloudsync`

A script to help synchronize [Pi-hole][pihole] adlist/blocklist, blacklist,
whitelist, regex, custom DNS hostnames, and custom CNAME hostnames across
multiple Pi-holes using a Git repository.

## Why `pihole-cloudsync`?

I run multiple Pi-hole instances across different locations. I want them all to
share the same configuration, but manully keeping even one extra instance in
sync is both time-consuming and begging to have unexpected configuration drift
causing difficult to diagnose problems. By using `pihole-cloudsync`, I can use
the standard Pi-hole web UI to manage one single primary Pi-hole and let the
others automatically pick up all the changes---both additions and deletions.

`pihole-cloudsync` is simple and lightweight enough to use if you only need to
keep two Pi-hole servers on your home network in sync, but it's also powerful
enough to easily scale to as many Pi-hole servers as you need across as many
networks and even physical locations as you need. The limiting factor is what
the git server hosting the configuration can handle.

Feedback, suggestions, bug fixes, and code contributions are welcome.

## How `pihole-cloudsync` Works

`pihole-cloudsync` allows you to designate any Pi-hole on any network to act as
your primary Pi-hole. This is the only Pi-hole whose settings you will need to
manage using Pi-hole's built-in web UI. The primary Pi-hole then uses
`pihole-cloudsync` in **Push** mode to *upload* files to a private Git
repository that you control (such as GitHub) that contain:

1. Pi-hole Gravity tables (queried from Pi-hole's database at
   `/etc/pihole/gravity.db`)
2. Your domain lists: "exact match" and "regex" versions of your white and black
   lists (queried from Pi-hole's database at `/etc/pihole/gravity.db`)
3. Any custom DNS names you've configured via the Pi-hole UI (copied from
   `/etc/pihole/custom.list`)
4. Any custom CNAMEs you've configured via the Pi-hole UI (copied from
   `/etc/dnsmasq.d/05-pihole-custom-cname.conf`)

Note that if you run Pi-hole in Docker, your files will likely be located in
a different place. `pihole-cloudsync` will look for Docker running a container
with ancestor `pihole/pihole`. If found, `pihole-cloudsync` will look up the
locations where these files are mounted from the host system and use those paths
instead. It will also attempt to restart Pi-hole through `docker exec`. It is
assumed only one Docker container per host may run Pi-hole.

All other Secondary Pi-holes that you wish to keep synchronized use
`pihole-cloudsync` in **Pull** mode to *download* the above files from your
private Git repository. As with **Push** mode, `pihole-cloudsync` will look for
a Pi-hole Docker container and download files to the appropriate location for
your Docker container and use `docker exec` to restart Pi-hole.

The script is designed to work with any Git repo that your Pi-holes can access,
but I have only personally tested it with GitHub.

### Pi-hole v5 only

If you have been running Pi-hole prior to version 5, take note that this script
will only work with Pi-hole v5 and later.

**Before proceeding, verify that your Primary and *all* Secondary Pi-holes are
running Pi-hole v5 or later.**

## Setup

Prior to running `pihole-cloudsync`, you must first create a new dedicated git
respository to store your lists. When initializing in **Push** mode, if you have
not already cloned the repository to your primary Pi-hole you may pass `--remote
git-remote` to `pihole-cloudsync` and it will attempt to push the current
configuration to the git repository. This does require that the git repository
is currently empty; if you have an existing repository you want to use on your
primary Pi-hole, you must clone it before running `pihole-cloudsync`.

When initializing in **Pull** mode, you may pass `--remote git-remote` to
`pihole-cloudsync` and it will attempt to clone the git repository for you. It
is assumed you have already populated the repository by running
`pihole-cloudsync` in **Push** mode from your primary Pi-hole.

### On GitHub

1. Sign into GitHub.
1. [Create a new repository][githubnew] and choose a name and optional
   description.
1. *Optional but strongly resommended*: Select the **Private** option to make
   your new repository private.
1. Do not select any option under **Initialize this repository with**
1. On your new repository's main page, take note of the git remote for pushing
   to the new repository.

### On your Primary Pi-hole device

1. Install Git (on Raspberry Pi OS do `sudo apt install -y git`).
1. Clone `pihole-cloudsync` somewhere, for example to `/opt`: `sudo git clone
   https://github.com/jgoguen/pihole-cloudsync.git /opt/pihole-cloudsync`
1. Link to the `pihole-cloudsync` script: `cd /usr/local/bin && ln -s
   /opt/pihole-cloudsync/pihole-cloudsync`
1. Ensure you can push to your repository without entering a username or
   password. For Github, you can follow their directions for
   [creating a new SSH key][ghcreatekey] and
   [adding it to your account][ghaddkey].
1. Initialize in **Push** mode: `sudo pihole-cloudsync --init --push --remote
   git@github.com:yourgithub/pihole-settings.git` (remember to use the git
   remote from the repository you created earlier)
1. Run `sudo /usr/local/bin/pihole-cloudsync --push` to push/upload your Primary
   Pi-hole's lists from your local Git repo to your remote Git repo. You may run
   this manually or you may set up a systemd timer.

### On all Secondary Pi-hole devices

1. Install Git (on Raspberry Pi OS do `sudo apt install -y git`).
1. Clone `pihole-cloudsync` somewhere, for example to `/opt`: `sudo git clone
   https://github.com/jgoguen/pihole-cloudsync.git /opt/pihole-cloudsync`
1. Link to the `pihole-cloudsync` script: `cd /usr/local/bin && ln -s
   /opt/pihole-cloudsync/pihole-cloudsync`
1. Ensure you can push to your repository without entering a username or
   password. For Github, you can follow their directions for
   [creating a new SSH key][ghcreatekey] and
   [adding it to your account][ghaddkey].
1. Initialize in **Pull** mode: `sudo pihole-cloudsync --init --pull --remote
   git@github.com:yourgithub/pihole-settings.git` (remember to use the same
   remote you used for the primary Pi-hole).
1. Run `sudo /usr/local/bin/pihole-cloudsync --pull` to pull/download your
   Pi-hole's lists from your git repository. You may run this manually or you
   may set up a systemd timer.

## Automating `pihole-cloudsync`

Once `pihole-cloudsync` has been run on each Pi-hole, you can automate your
primary Pi-hole's "push" and your secondary Pi-holes' "pull" in any number of
ways. The simplest method is to run a [cron job](#Automating-with-cron) a few
times a day. If you want more flexibilty over schedule and resource use, you can
also use [systemd](#Automating-with-systemd) to automate. Both methods are
explained below.

### Automating with cron

The simplest way is to automate `pihole-cloudsync` is to set a "push" cron job
on your primary Pi-hole that runs regularly, then set a "pull" cron job on each
secondary Pi-hole that pulls in any changes a few minutes after your Primary
pushes them.

Once you can successfully run `pihole-cloudsync --push` from the command line on
your primary Pi-hole, do `crontab -e` (or `sudo crontab -e` if you're not logged
in as the root user) and create a cron entry such as:

```cron
00 * * * * sudo /usr/local/bin/pihole-cloudsync --push >/dev/null 2>&1
```

Once you can successfully run `pihole-cloudsync --pull` from the command
line on each of your secondary Pi-holes, do `sudo crontab -e` and create a cron
entry that runs 5 minutes after your Primary pushes any changes, such as:

```cron
05 * * * * sudo /usr/local/bin/pihole-cloudsync --pull >/dev/null 2>&1
```

**NOTE:** On Raspian, the script won't execute via cron without the `sudo`
command (as shown above). If you're having trouble getting the script to run
unattended on Raspian, try including `sudo` in the cron command.

### Automating with systemd

`pihole-cloudsync` can also be automated with systemd, if your Pi-hole is
running on a systemd-supported distro. Once you're able to successfully run
`pihole-cloudsync --push` from the command line on your primary Pi-hole and
`pihole-cloudsync --pull` from the command line on each of your secondary
Pi-holes, you can proceed with systemd setup. You must install four files on
your Pi-hole to ensure a stable and non-intrusve update process: a `.service`
file, a `.timer` file, a `.slice` file, and an environment file. Examples are
provided in the `systemd` directory.

1. Symlink the `.service`, `.timer`, and `.slice` files into
   `/etc/systemd/system` on your Pi-hole.
1. Copy the `.env` file into `/etc/default` on your Pi-hole. Make sure the
   `BRANCH` and `DESTDIR` settings are correct.
1. Tell systemd you changed its configuration files with `systemctl
   daemon-reload`.
1. Enable and start the timer.

```bash
# Assuming you cloned this repo to /opt/pihole-cloudsync
cd /etc/systemd/system
sudo ln -s /opt/pihole-cloudsync/systemd/pihole-cloudsync.slice
sudo ln -s /opt/pihole-cloudsync/systemd/pihole-cloudsync@.service
sudo ln -s /opt/pihole-cloudsync/systemd/pihole-cloudsync@.timer

# Copy the env file then modify for your environment
sudo cp /opt/pihole-cloudsync/systemd/pihole-cloudsync.env /etc/default/

# For your primary Pi-hole
systemctl enable pihole-cloudsync@push.timer
systemctl start pihole-cloudsync@push.timer

# For your secondary Pi-holes
systemctl enable pihole-cloudsync@pull.timer
systemctl start pihole-cloudsync@pull.timer
```

## Updating `pihole-cloudsync`

To upgrade to the latest version of `pihole-cloudsync`, do the following on
*all* primary and secondary Pi-holes. Note that this will completely over-write
any previous modifications you've made to `pihole-cloudsync`.

```bash
cd /opt/pihole-cloudsync
git fetch --all
git reset --hard origin/master
sudo systemctl daemon-reload
```

Your local version of `pihole-cloudsync` is now updated to the lastest release
version.

## Disclaimer

You are totally responsible for anything this script does to your system.
Whether it launches a nice game of Tic Tac Toe or global thermonuclear war,
you're on your own.

[pihole]: https://pi-hole.net
[githubnew]: https://github.com/new
[ghcreatekey]: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
[ghaddkey]: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account
