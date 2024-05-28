# Restic Backup Scripts

Forked from [mhw/restic-backup-scripts](https://github.com/mhw/restic-backup-scripts)

This repository contains a set of shell scripts to maintain backups of a server
using [restic](https://restic.net/).
Main features:

* Filesystem backups with restic
* SQL backups of MySQL databases using `mysqldump`
* SQL backups of PostgreSQL databases using `pgdump`
* Intended to run daily from `cron`
* Will purge old backups to a retention policy
* Optional integration with [healthchecks.io](https://healthchecks.io/)
* Handles transient files with a separate retention policy

Currently in use in production backing up an Ubuntu 18.04 server to
[Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html).

## Install Restic

https://restic.readthedocs.io/en/latest/020_installation.html

```
sudo apt-get update
apt-get install restic
```

## Security Considerations

- https://restic.readthedocs.io/en/latest/080_examples.html#backing-up-your-system-without-running-restic-as-root
- https://forum.restic.net/t/any-downsides-to-running-restic-as-root/5908

## MySQL Client Credentials 

To avoid needing to insert the mysql password directly into the bash scripts follow https://tecadmin.net/mysql-commands-without-password-prompt/ 

```
touch ~/.my.cnf 
nano ~/.my.cnf 
```

```
[client]
user=your_username
password=your_password
```

## Clone the Repo

```
cd /home
git clone https://github.com/perrelet/restic-backup-scripts.git
```

Create a `~/.env.restic` file and fill it in with the key needed to
access your storage, and the restic repository in it:

```
cd restic-backup-scripts
cp sample.env.restic ~/.env.restic
dd if=/dev/urandom bs=15 count=1 2>/dev/null | openssl enc -a >~/.restic.pwd
chmod o-r ~/.restic.pwd
nano ~/.env.restic
```

> [!NOTE]  
> Note that `~/` is equivalent to the current users home directoy, in this case `/root`.

> [!IMPORTANT]  
> Be sure to save the restic password in `.restic.pwd` to your password vault.

## Sourcing the Variables

We can source export our variables with `source /root/.env.restic` (or equivalently `. /root/.env.restic`). However it is recommended to source them from .bashrc so they are loaded when ever the user logs in:

```
nano ~/.bashrc

>>> source /root/.env.restic

source ~/.bashrc
```

## Initializing

```
restic init
```

## Configure

Make a copy of `sample.run-files.sh`:

```
cp sample.run-files.sh run-files.sh
chmod +x run-files.sh
```

Customise `run-all.sh`, `run-files.sh`, `backup-mysql.sh`, `purge.sh`, etc as required and run to them to test they are working correctly. Note that the `purge.sh` will dry unless the the `--really` flag is present.

> [!NOTE]  
> Run `chmod +x *.sh` to make the bash files executable

## Scheduling

Add a cron task with `crontab -e`:

```
30 2 * * * /home/restic-backup-scripts/run-all.sh
```

To use [healthchecks.io](https://healthchecks.io/) to monitor your backups
use the `Makefile` to download a copy of
[runitor](https://github.com/bdd/runitor).
Just run `make` and it should pull a release down.
Update the variables in the Makefile to choose a different platform or version.

Then use a crontab line like this:

```
30 2 * * * cd /home/restic-backup-scripts; ./runitor -uuid {UUID} -silent -- ./run-all.sh
```

Substitute a valid check UUID from healthchecks.io in the command above.

## Transient Files

You might have files that change entirely between backups, such as a log
file that is rotated nightly and compressed a day or so later.
Backing this file up every day will make your restic repository grow
rapidly and should be excluded from primary file backups. 

See [Dealing With Transient Files](https://github.com/mhw/restic-backup-scripts?tab=readme-ov-file#dealing-with-transient-files) for another approach.

## Useful Commands

`restic snapshots` View all the snapshots

`restic snapshots --tag tag-name` Filter snapshots by tag

`restic forget {snapshot-id}` Forget a snapshot (files reamain in repo until prune)

`restic prune` Purge forgotten / expired backups

`restic unlock` Unlock files