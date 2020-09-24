# Backup Scripts

## Getting Started

Create a Unix user who will execute the backup jobs:

```
adduser --disabled-password restic
```

Log in as that user and clone this repository:

```
su - restic
git clone https://github.com/mhw/restic-backup-scripts
```

Download the latest restic binary from the project's
[releases page](https://github.com/restic/restic/releases/latest).
Install it in the `bin` directory of the user you just created.
Give the binary permission to access the filesystem as explained
[in the restic documentation](https://restic.readthedocs.io/en/stable/080_examples.html#backing-up-your-system-without-running-restic-as-root).

Create a `~/.env.restic` file and fill it in with the key needed to
access your storage, and the restic repository in it:

```
cd restic-backup-scripts
cp sample.env.restic ~/.env.restic
dd if=/dev/urandom bs=15 count=1 2>/dev/null | openssl enc -a >~/.restic.pwd
vi ~/.env.restic
```

The sample assumes Backblaze B2 is being used as restic storage provider;
replace setting as appropriate for your chosen storage provider.

Source `.env.restic` from `.bashrc` if you want to be able to run restic
easily from the command line.

## MySQL Set Up

Create a MySQL user for the Unix user, and grant the necessary
privileges:

```
grant lock tables, select, show view, event, trigger, process on app_production.* to 'restic'@'localhost';
```

## PostgreSQL Set Up

Create a PostgreSQL role for the Unix user, and grant the necessary
privileges. Connecting as the `postgres` user:

```
create role restic with login;
```

For each database to be dumped (`app_production` below):

```
grant connect on database app_production to restic;
\c app_production
set role app_production;
```

(This assumes your data is stored in a database named `app_production`,
and that the role `app_production` owns the schema objects within the
database.)

Typically all an application's schema objects will be in the `public` schema.
To give `restic` access to these objects run the following commands for the
`public` schema and any additional schemas used in your database.

```
grant usage on schema public to restic;
grant select on all tables in schema public to restic;
alter default privileges in schema public grant select on tables to restic;
grant select on all sequences in schema public to restic;
alter default privileges in schema public grant select on sequences to restic;
```

The `alter default privileges` commands included above will grant the
necessary privileges on schema objects created in the future,
but **only** when those schema objects are created by the `app_production`
role.

## Scheduling

Edit the user's crontab: `crontab -e`. Use a line like this:

```
30 2 * * * /home/restic/restic-backup-scripts/all-backups.sh
```

## Healthchecks.io (Optional)

To use [healthchecks.io](https://healthchecks.io/) to monitor your backups
use the `Makefile` to download a copy of
[runitor](https://github.com/bdd/runitor).
Just run `make` and it should pull a release down.
Update the variables in the Makefile to choose a different platform or version.

Then use a crontab line like this:

```
30 2 * * * cd /home/restic/restic-backup-scripts; ./runitor -uuid 2f9-a5c-0123 -silent -- ./all-backups.sh
```

Substitute a valid check UUID from healthchecks.io in the command above.

## Dealing With Transient Files

You might have files that change entirely between backups, such as a log
file that is rotated nightly and compressed a day or so later.
Backing this file up every day will make your restic repository grow
rapidly.
One strategy is to list these transient files in a file that is passed
to restic's `--exclude-file` option,
then run a second backup with an additional `transient` tag passing the same
file to the `--files-from` option.
This is illustrated in the `sample.files-backup.sh` script.
