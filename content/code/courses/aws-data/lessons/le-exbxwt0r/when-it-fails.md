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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two roads for one command. Inside your computer, aws s3 ls with AWS_ENDPOINT_URL set goes to moto_server on localhost:4567, which answers as AWS would, for account 123456789012. Without the endpoint, the same command goes over the internet to the real AWS at s3.sa-east-1.amazonaws.com, which refuses the key test with InvalidAccessKeyId.\" data-fig=\"l01-endpoint\"><defs><marker id=\"l01-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><rect x=\"14\" y=\"14\" width=\"452\" height=\"232\" rx=\"8\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 5\"/><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">your computer</text><rect x=\"40\" y=\"96\" width=\"170\" height=\"66\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"125\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">aws s3 ls</text><text x=\"125\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the AWS command line</text><rect x=\"290\" y=\"96\" width=\"156\" height=\"66\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"368\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">moto_server</text><text x=\"368\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">localhost:4567</text><line x1=\"210\" y1=\"118\" x2=\"288\" y2=\"118\" stroke=\"var(--wire)\" stroke-width=\"1.6\" marker-end=\"url(#l01-ah)\"/><text x=\"249\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">with</text><text x=\"249\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">AWS_ENDPOINT_URL</text><text x=\"368\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">answers as AWS would</text><text x=\"368\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Account 123456789012</text><rect x=\"520\" y=\"96\" width=\"186\" height=\"66\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"/><text x=\"613\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the real AWS</text><text x=\"613\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">s3.sa-east-1.amazonaws.com</text><line x1=\"125\" y1=\"162\" x2=\"125\" y2=\"280\" stroke=\"var(--wire)\" stroke-width=\"1.6\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-ah)\"/><path d=\"M125,280 L540,280 L540,166\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-ah)\"/><text x=\"333\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">without the endpoint: over the internet</text><text x=\"613\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">refuses the key test</text><text x=\"613\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">InvalidAccessKeyId</text></svg>", "caption": "One variable decides where every request goes. With it, moto answers; without it, the real AWS refuses the key."}
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
