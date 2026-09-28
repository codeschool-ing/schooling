---
title: "User data: instructions for the first boot"
version: 1
---

**User data is a piece of text you hand to the provider when you launch an instance.** The provider
keeps it, and the instance can read it back from a metadata service that only it can reach. On its
own that does nothing. What makes it useful is a program inside nearly every published Linux image,
**cloud-init**, which runs early in the first boot, fetches the user data and acts on it.

If the text starts with `#!`, cloud-init runs it as a script. If it starts with `#cloud-config`, it
reads it as a YAML file of declarations, and each top-level key is handed to one of cloud-init's
modules. The second form is the one to prefer: instead of a script that does things in an order you
have to get right, it is a list of what the machine should end up with, and cloud-init knows the
order.

Here is one for a small web server. Every part of it is a real key of cloud-init's format:

```schooling-example
{"language": "yaml", "file": "web.yaml", "parts": [{"code": "#cloud-config\n", "note": "The first line is not a comment to cloud-init: it is how it knows the text is a configuration file rather than a script. Without it the file is not read as one."}, {"code": "package_update: true\npackages:\n  - nginx\n\n", "note": "Refresh the package lists, then install nginx. The name is whatever the image's package manager calls it, so this line is specific to Debian and Ubuntu images."}, {"code": "users:\n  - default\n  - name: ana\n    groups: [sudo]\n    shell: /bin/bash\n    sudo: \"ALL=(ALL) NOPASSWD:ALL\"\n    ssh_authorized_keys:\n      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoLEfVeFZ0GWJ/mCzAhS1R8EN1CAw6s4HI4sjd7Yuay ana@laptop\n\n", "note": "`default` keeps the user the image already defines, such as `ubuntu`. `ana` gets a shell, the `sudo` group and the public half of her SSH key. She has no password, so `sudo` is allowed without one; that line is a choice, and a stricter setup leaves it out."}, {"code": "write_files:\n  - path: /var/www/html/index.html\n    content: |\n      <h1>served by HOST</h1>\n    permissions: \"0644\"\n    defer: true\n\n", "note": "A file written from the configuration itself. `defer: true` holds it until after the packages are installed, so it lands in the directory nginx has set up rather than before nginx exists."}, {"code": "runcmd:\n  - sed -i \"s/HOST/$(hostname)/\" /var/www/html/index.html\n", "note": "Commands run once, at the end of the first boot, in the order given. This one writes the machine's own hostname into the page, so each instance in a group says which one answered."}]}
```

The order in which you write the keys is not the order in which they run. Cloud-init runs in
stages, and its own default configuration lists which module belongs to which: the users and their
SSH keys are set up in the first stage, and the packages, the deferred files and then the commands of `runcmd` in
the last one. That is why `write_files` carries `defer: true`, and why `runcmd` can rely on the file
it edits.

## Check it before you boot anything

A mistake in user data does not stop a machine from booting. **Cloud-init logs the problem and
carries on**, so a misspelt key is skipped and the instance comes up without whatever that key was
for. If the key was the one that installs your SSH key, you are now locked out of a machine whose
log would tell you why.

Cloud-init can check a file against its schema without booting anything. It is not published on
PyPI, so it was run here from its own source tree, version 26.2, on the laptop; **nothing was
booted, in any cloud**:

```
ana@laptop:~/cloud$ cloud-init schema -c web.yaml
Valid schema web.yaml
ana@laptop:~/cloud$ cloud-init schema -c typo.yaml 2>&1 | cut -c1-120
Error: Cloud config schema errors: users.1: Additional properties are not allowed ('ssh_authorised_keys' was unexpected)

Error: Invalid schema: user-data

Invalid user-data typo.yaml
```

The first file is the one above. The second is the same file with one word respelt in British
English, `ssh_authorised_keys`, and the schema refuses it: that key does not exist, and the one
that does is spelt with a *z*. The message was cut at 120 characters by the command, which is where
the part worth reading ends. On a real boot the same mistake would be a warning in the instance's
log, and the machine would come up without the key.

Two more things about user data that decide how you use it.

**It runs once.** The modules above act on the first boot of each instance and not on a reboot,
which is right for installing packages and creating users. Something that has to happen at every
start belongs in the system's own service manager, installed by the user data.

**It is not a secret.** Any process on the instance can read the user data back from the metadata
service, and anybody allowed to describe the instance in the account can read it too. A password or an API key written into it is written into a place many things can read. The other way is to fetch the secret at boot from the provider's secret store,
with the permissions lesson 7 builds; `cloud-security` goes further.

When a machine does not come up the way its user data says, the instance's own log is where to
look: `cloud-init status --wait` waits for the first boot to finish and says whether it failed,
and `/var/log/cloud-init-output.log` holds what every command printed.
