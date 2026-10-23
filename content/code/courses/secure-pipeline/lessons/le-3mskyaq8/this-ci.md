---
title: What a job on this machine can do
version: 1
---

The hook in `~/ci/linkbox.git/hooks/post-receive` runs every stage as the user who owns the
repository, which on this machine is Ana. A stage is whatever script the pushed commit contains. So
the honest question about this course's CI is not what the stages do, but **what any script running
as Ana could do**. The answer turns on one line of output.

@@CAPTURE this-ci@@

### The docker group is root

Ana is in the group `docker` (gid 990 here), because lesson 1 put her there so the pipeline could
build images without `sudo`. The daemon's socket is owned by root and writable by that group, and
the daemon itself runs as root. Whoever can write to the socket can ask the daemon, which is root,
to start a container with any options it accepts, including a container that mounts the host's
filesystem.

Docker's own documentation says it plainly. Its post-installation steps for Linux, the ones that add
a user to the group, carry the warning: **"The docker group grants root-level privileges to the
user."** Its page on the daemon's attack surface adds that only trusted users should be allowed to
control the daemon. **On this laptop, membership of `docker` is equivalent to root**, and so is every
script the CI runs, because it runs as a member.

This lesson does not demonstrate the step from the group to root, and you do not need to see it to
act on it. The two lines above, `id` and the socket's permissions, are the whole finding.

@@FIGURE socket@@

### What follows for the pipeline

Put the pieces of this course together. `ci/sign.sh` comes from the commit; the signing key sits in
`~/ci/keys`, readable by Ana; the CI runs as Ana; Ana can become root. **Anyone who can push a branch
to this CI can, in principle, do anything on this machine**, including sign with the CI's key and
read `~/ci/keys`. For a laboratory with one user, that is the same person, and it is fine. For a
team, the remedies are the ones this lesson has been naming:

- **The build runs where it cannot reach the key.** The signing moves out of the job, to a service
  that signs on request, which is the L3 requirement of lesson 14.
- **The build runs on a fresh machine**, so nothing a job does survives it.
- **The build does not hold root-equivalent access to the host.** That means not giving the CI
  user the `docker` group on a shared machine, or making that group mean less.

### Rootless Docker, from the documentation

Docker can run its daemon **rootless**: the daemon and the containers run as an ordinary user,
inside a user namespace, so root inside a container maps to that unprivileged user outside it.
Docker's documentation installs it with `dockerd-rootless-setuptool.sh install`, after which the
socket lives in the user's runtime directory, `$XDG_RUNTIME_DIR/docker.sock`, and `DOCKER_HOST`
points there. Access to that socket is then worth what the user is worth, not what root is.

The documentation also lists its limits: ports below 1024 need extra configuration, some storage
drivers and some features, such as AppArmor and certain networking modes, are not supported, and
resource limits need cgroup v2 with delegation. **It was not set up for this course**: the recording
machine's Docker is the ordinary root daemon that lesson 1 installed, and every capture in the course
depends on it. Podman, which runs rootless by default, is the other common answer.

The local CI stays as it is, with this section as its written threat model: a single-user laboratory
whose CI is as powerful as its owner, and no more trusted than that.
