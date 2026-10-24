---
title: A registry of your own
version: 1
---

**A package registry is a server that stores published versions and answers `npm install`, and a private
one can run on your own computer.** Companies run one so internal packages are not public, using GitHub
Packages, GitLab's registry, a hosted service, or a server of their own. **Verdaccio** is an open-source
registry that speaks the same protocol as npm's, so the same `npm` commands work against it; this section
runs it locally, where it costs nothing and needs no account.

It gets a folder of its own and one configuration file:

```yaml
# ~/registry/config.yaml
storage: ./storage
auth:
  htpasswd:
    file: ./htpasswd
uplinks:
  npmjs:
    url: https://registry.npmjs.org/
packages:
  "@planner/*":
    access: $authenticated
    publish: $authenticated
  "**":
    access: $all
    proxy: npmjs
listen: 127.0.0.1:4873
log: { type: stdout, format: pretty, level: warn }
```

Read it from the bottom: it listens only on this computer, on port 4873. **Packages in the `@planner`
scope may be read and published only by a user who has logged in**, which is the point of a private
registry. Everything else may be read by anyone and is fetched from the public registry, its `uplink`,
when somebody asks for it, so the same registry can serve all of a project's dependencies. Users and their
passwords go in a file called `htpasswd` beside the configuration.

## Running it

`npx` runs a package without installing it into a project; the version is pinned like every other tool:

```
ana@dev:~/registry$ npx -y verdaccio@6.10.7 --config ./config.yaml
warn --- you are using Node.js v22.22.0, Verdaccio recommends Node.js v24 or higher, please consider upgrading your Node.js distribution
warn --- http address - http://127.0.0.1:4873/ - verdaccio/6.10.7
```

**Verdaccio 6.10.7** runs, and warns that it recommends Node 24. It works on the course's Node 22, and the
warning is the project telling you where it is heading. Leave it running in its own terminal.

## Logging in

Publishing needs a user. `npm adduser` creates one on a registry that allows it, as Verdaccio does by
default, and logs in:

```
ana@dev:~/planner-ui$ npm adduser --registry http://127.0.0.1:4873/ --auth-type=legacy
npm notice Log in on http://127.0.0.1:4873/
Username: ana
Password: 
Email: (this IS public) 
ana@example.org

Logged in on http://127.0.0.1:4873/.
```

The password was typed and not shown, as with any password prompt. **npm stored a token for that registry
in `~/.npmrc`**, in your home folder, which is where every later command reads it from. That file is now a
secret, of the kind lesson 2 was about: never copy it into a project, and never commit it. The project's
own `.npmrc`, in the next section, holds an address and nothing else.

`--auth-type=legacy` asks for the username and password at the terminal. Public npm defaults to signing in
through a browser instead, which a registry on your own computer does not offer.
