---
title: When the lab does not answer
version: 1
---

These are the failures met while this lesson was recorded, in the order a student meets them, with
what each one says and what it means. Most of them are one forgotten line.

**`aws` is not found.** A new terminal starts without `~/.local/bin` on its path:

```
ana@laptop:~/aws$ PATH=/usr/bin:/bin; aws --version
bash: line 1: aws: command not found
```

The second line under "Every time you open a terminal" puts it back. `moto_server` disappears the
same way when the virtual environment is not active, and the same line fixes it.

**No credentials at all.** The terminal has the path and not the third line, so the command line has
no key to sign with and stops before sending anything:

```
ana@laptop:~/aws$ env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY aws s3 ls

aws: [ERROR]: An error occurred (NoCredentials): Unable to locate credentials. You can configure credentials by running "aws login".
```

**moto is not running.** The variables are set and nothing is listening on the port, because the
other terminal was closed, or `Ctrl+C` stopped the server:

```
ana@laptop:~/aws$ aws s3 ls

aws: [ERROR]: Could not connect to the endpoint URL: "http://localhost:4567/"
```

Start it again in its own terminal. It comes back empty, and the lesson you were on rebuilds what it
needs from its first command.

**The port is taken.** A second `moto_server -p 4567`, in a third terminal, or one left behind by a
terminal that was closed without stopping it:

```
ana@laptop:~/aws$ timeout 10 moto_server -p 4567 2>&1 | tail -2
Address already in use
Port 4567 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

`Address already in use` means a moto is already answering, so there is nothing to fix unless you
wanted an empty one. To stop the old one, find its process and end it: `pgrep -af moto_server` prints
its number, and `kill` followed by that number stops it.

**The endpoint was left out, and the request went to Amazon.** This is the one to recognise, because
it is the only failure here that leaves your computer. With the keys set to `test` and no
`AWS_ENDPOINT_URL`, the command line does exactly what it was built to do, and asks the real AWS:

```
ana@laptop:~/aws$ env -u AWS_ENDPOINT_URL aws s3 ls

aws: [ERROR]: An error occurred (InvalidAccessKeyId) when calling the ListBuckets operation: The AWS Access Key Id you provided does not exist in our records.
ana@laptop:~/aws$ env -u AWS_ENDPOINT_URL aws sts get-caller-identity

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid.
```

**AWS refused the word `test` as a key, which is the right answer**: there is no such key, and there
is no account behind it. Nothing was created and nothing was billed. Two things follow. If you ever
see `InvalidAccessKeyId` or `InvalidClientTokenId` in this course, the endpoint line is missing from
that terminal. And if a command ever succeeds while the endpoint is missing, your terminal holds real
credentials from somewhere else, an `~/.aws/credentials` file or a variable from another course, and
the command just ran against a real account. `aws sts get-caller-identity` names the account; moto's
is always `123456789012`.

**`moto_server` stops with a traceback naming a missing module.** The virtual environment was made
with a Python from outside Ubuntu's own, or `pip` was interrupted. Delete `~/aws/venv` and run the
two lines of "moto, in a virtual environment" again; nothing else lives in that directory.
