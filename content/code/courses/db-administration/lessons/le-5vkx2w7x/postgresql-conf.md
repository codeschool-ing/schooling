---
title: The file, and the directory beside it
version: 1
---

The configuration of a PostgreSQL server is **one file of parameters, read from top to bottom,
where the last value given for a name is the one that counts**. Everything else in this lesson
follows from that sentence: the directory of extra files, the file `ALTER SYSTEM` writes, and the
reason a change you made can be quietly overruled by another one further down.

Lesson 3 asked the server where the file is. Ask every time: on Ubuntu it is not inside the data
directory, where upstream keeps it.

```
ana@db:~$ psql
ana=# SHOW config_file;
               config_file               
-----------------------------------------
 /etc/postgresql/16/main/postgresql.conf
(1 row)

ana=# SHOW hba_file;
              hba_file               
-------------------------------------
 /etc/postgresql/16/main/pg_hba.conf
(1 row)

ana=# SHOW work_mem;
 work_mem 
----------
 4MB
(1 row)

ana=# \q
```

`hba_file` is the other half of the configuration, the one that decides who may connect, and it
has a section of its own in this lesson. `work_mem` is here for a reason that appears in a moment.

## Mostly comments

The file looks like a lot to read. It is not:

```
ana@db:~$ wc -l /etc/postgresql/16/main/postgresql.conf
828 /etc/postgresql/16/main/postgresql.conf
ana@db:~$ grep -Ev '^\s*(#|$)' /etc/postgresql/16/main/postgresql.conf
data_directory = '/var/lib/postgresql/16/main'		# use data in another directory
hba_file = '/etc/postgresql/16/main/pg_hba.conf'	# host-based authentication file
ident_file = '/etc/postgresql/16/main/pg_ident.conf'	# ident configuration file
external_pid_file = '/var/run/postgresql/16-main.pid'			# write an extra PID file
port = 5432				# (change requires restart)
max_connections = 100			# (change requires restart)
unix_socket_directories = '/var/run/postgresql' # comma-separated list of directories
ssl = on
ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
shared_buffers = 128MB			# min 128kB
dynamic_shared_memory_type = posix	# the default is usually the first option
max_wal_size = 1GB
min_wal_size = 80MB
log_line_prefix = '%m [%p] %q%u@%d '		# special values:
log_timezone = 'America/Sao_Paulo'
cluster_name = '16/main'			# added to process titles if nonempty
datestyle = 'iso, mdy'
timezone = 'America/Sao_Paulo'
lc_messages = 'C.UTF-8'			# locale for system error message
lc_monetary = 'C.UTF-8'			# locale for monetary formatting
lc_numeric = 'C.UTF-8'			# locale for number formatting
lc_time = 'C.UTF-8'			# locale for time formatting
default_text_search_config = 'pg_catalog.english'
include_dir = 'conf.d'			# include files ending in '.conf' from
```

Of 828 lines, **25 are active**, and the last of them is a directive rather than a setting.
`grep -Ev` printed every line that is neither blank nor a comment, and what is left is what the
installer decided: the paths, the port, the locale and
time zone it found on the machine, a certificate so that `ssl = on` has something to use, and a
log prefix. Every other parameter has the value compiled into the server, which is why
`work_mem` said `4MB` above and appears nowhere in this list.

The comments are the documentation of the defaults. A parameter appears commented out with its
default value beside it, and the ones that need a restart say so:

```
ana@db:~$ sed -n 129,135p /etc/postgresql/16/main/postgresql.conf

shared_buffers = 128MB			# min 128kB
					# (change requires restart)
#huge_pages = try			# on, off, or try
					# (change requires restart)
#huge_page_size = 0			# zero for system default
					# (change requires restart)
```

That makes the commented lines tempting to treat as switches. **Putting a `#` back in front of a
line does not restore the default** until the server reads the file again, and even then only
because the line is gone, not because of what the comment says. The header of the file warns
about exactly this.

## The format

Each setting is `name = value`, one per line, and the rest of the line after a `#` is a comment.
Three details catch people:

- **Units are case-sensitive.** `128MB` is 128 megabytes; `128mb` is an error. The memory units
  are `B`, `kB`, `MB`, `GB` and `TB`, the time units `us`, `ms`, `s`, `min`, `h` and `d`, and the
  header of the file lists them.
- **A string goes in single quotes**, like the paths above. A bare word works for simple values
  such as `on`, and quoting everything that is not a number is the habit that never fails.
- **A name may appear twice, and the later one wins.** Nothing warns you. That is a hazard in a
  file of 828 lines and the basis of the arrangement below.

## conf.d: the place for your changes

The last active line is the one that matters most:

```ini
include_dir = 'conf.d'
```

It tells the server to read, after this file, **every file ending in `.conf` in the directory
`/etc/postgresql/16/main/conf.d`, in the order of their names**. Because they come later, what
they set overrides the main file. On a new server the directory is empty:

```
ana@db:~$ ls -l /etc/postgresql/16/main/conf.d
total 0
```

So there are two places to change a parameter, and this course uses the second. You could edit
`postgresql.conf` in place, among 800 lines of comments. Or you can leave it as the installer
wrote it and **put your changes in small files under `conf.d`**, named so their order is
obvious: `10-memory.conf`, `20-logging.conf`, `50-course.conf`. A change is then a file you can
read in full, undoing it is deleting the file, and lesson 23 puts those files under version
control. The main file stays a record of what the package did.

Edit them with `sudo nano`, as the files belong to `postgres` and the directory is not yours.
Nothing changes when you save: the server reads its configuration at start and when it is told
to, and the next two sections are about telling it.
