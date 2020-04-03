# Additional Instructions for Pi-hole v5 Users
The <a target="_blank" href="https://pi-hole.net/">Pi-hole</a> dev team announced the public beta of Pi-hole v5 on Jan 19, 2020. If you'd like more information (including instructions on how to upgrade to the new beta version AT YOUR OWN RISK), check out <a target="_blank" href="https://pi-hole.net/2020/01/19/announcing-a-beta-test-of-pi-hole-5-0/">the Pi-hole beta announcement</a>.

The biggest change in Pi-hole v5 is that blocklist, blacklist, whitelist, and regex info is no longer stored in individual text files -- they are now all stored in a single database file called `gravity.db`. As a result, the latest version of `pihole-cloudsync` needs to know which version of Pi-hole you're running to properly sync. `pihole-cloudsync` cannot synchronize multiple Pi-holes of different major versions. You can sync a v4 Pi-hole with unlimited v4 Pi-holes, or a v5 Pi-hole with unlimited v5 Pi-holes. But you **cannot sync a v4 Pi-hole to a v5 Pi-hole**.

**Before proceeding, verify that your Primary and *all* Secondary Pi-holes are running Pi-hole v5.**

# Configuring pihole-cloudsync to work with Pi-hole v5

Because Pi-hole v5 is still in beta, the default options for `pihole-cloudsync` are still configured for Pi-hole v4. Once v5 becomes the official release and sees wider adoption, I'll update `pihole-cloudsync` to work with Pi-hole v5 by default. For now, you'll have to make a few changes to the script to work with Pi-hole v5's new database.

## If you already have a previous version of `pihole-cloudsync` installed
To upgrade to the latest version of `pihole-cloudsync`, do the following on *all* Primary and Secondary Pi-holes. Note that this will completely over-write any previous modifications you've made to `pihole-cloudsync`.

1. Do `cd /usr/local/bin/pihole-cloudsync`
2. Do `git fetch --all`
3. Do `git reset --hard origin/master`

Your local version of `pihole-cloudsync` is now updated to the lastest release version.

## If you are installing `pihole-cloudsync` for the first time
Follow the instructions in the <a target="_blank" href="https://github.com/stevejenkins/pihole-cloudsync/blob/master/README.md">standard README</a> to clone a fresh install of `pihole-cloudsync` -- but do not run it until you've made the following changes:

1. Do `cd /usr/local/bin/pihole-cloudsync`
2. Edit `pihole-cloudsync` with a text editor
3. In the CONSTANTS section, change `pihole_version=4` to `pihole_version=5`

## Shared Hosts Mode with Pi-hole v5

The **Shared Hosts Mode** option is still available in `pihole-cloudsync` for users who wish to remain on Pi-hole v4.

One of the new features of Pi-hole v5 is a **Custom DNS** tool that replicates `pihole-cloudsync`'s Shared Hosts Mode. Custom DNS entries are now be stored in the `/etc/pihole/custom.list` file (and not in Pi-hole's new `gravity.db` file). When run in Pi-hole v5 mode, `pihole-cloudsync` also sychronizes this file between your Primary and Secondary Pi-holes so they can share Custom DNS host entries.

I recommend Pi-hole v5 users set the `enable_hosts` variable in the `pihole-cloudsync` script to **off** and manually enter their shared hosts into their Primary Pi-hole v5 server by using the Custom DNS page in Pi-hole's admin web UI.

# Known Issues
The only issue I know of currently is that because Pi-hole now stores nearly all its information in a single database file, that single file can easily be larger than the 50MB that Github recommends. I currently have it working just fine with a DB file that's currently over 70MB. Github allows it but throws a filesize warning when doing a "push." You can get rid of this error by adding GitHub's large file management system called "Git LFS," but you can't do it to only one or two hosts: **all** Secondary Pi-holes as well as your Primary Pi-hole must be configured to use Git LFS, or they will be unable to sync.

# Disclaimer
As always, you are totally responsible for anything this script does to your system. Whether it launches a nice game of Tic Tac Toe or global thermonuclear war, you're on your own. :)
