---
title: Signed commits
version: 1
---

**Signing the artefact proves who built it. Signing the commit proves who wrote the desired state.**
A commit's author field is text that anybody can set, as every capture in this course does with
`GIT_AUTHOR_NAME`. A signature is not: it is made with a key only its owner holds, and Git can check
it against a list of keys it trusts.

Git signs with GPG or, more simply, with an SSH key:

```
ana@laptop:~$ ssh-keygen -q -t ed25519 -N "" -C "ana@example.org" -f ~/.ssh/signing
ana@laptop:~$ git config --global gpg.format ssh
ana@laptop:~$ git config --global user.signingkey ~/.ssh/signing.pub
ana@laptop:~$ echo "ana@example.org $(cat ~/.ssh/signing.pub)" > ~/.ssh/allowed_signers
ana@laptop:~$ git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

`gpg.format ssh` tells Git to sign with SSH, `user.signingkey` names the public half of the key to
sign with, and the allowed-signers file is the list of who may sign: each line an address and the key
that may sign for it. It is the verification side's trust root, exactly like `cosign.pub`.

```
ana@laptop:~/fleet$ git switch --quiet -c preview-0.1.0
ana@laptop:~/fleet$ git commit --quiet -S -am "preview: back to the signed chart"
ana@laptop:~/fleet$ git log --show-signature -2 --format="%h %an %s"
Good "git" signature for ana@example.org with ED25519 key SHA256:FoPKghSz0uyS83mfQbpA9Qc4YyCHzGJ+4AdtBLnzqXo
45f1c11 Ana Lima preview: back to the signed chart
f237f00 ana Merge pull request 'preview: chart 0.1.1' (#12) from preview-0.1.1 into main
```

`Good "git" signature for ana@example.org`, against the key in the list. The commit before it carries
no signature at all, and nothing in Git stops anybody from writing one in Ana's name.

## Who checks

A signature nobody checks is decoration. Three places can check it:

- **the Git server**: Gitea, GitHub and GitLab show a commit as verified when its key belongs to the
  account it names, and branch protection can require signed commits on `main`;
- **the agent**: Flux's `GitRepository` can verify the signature of the commit it fetches, with
  `spec.verify`, against a set of OpenPGP keys in a Secret, and Argo CD can require GPG signatures
  per project. Both verify GPG signatures and not SSH ones, which is the reason a team that wants the
  agent to check commits signs with GPG;
- **the review**: the pull request's author is the account that pushed, and the approval is the
  account that approved, both recorded by the server whatever the commits say.

**In a flow with protected branches and reviews, the server's record of who pushed and who approved
is already strong evidence**, and many teams stop there. Signed commits add the guarantee that the
content was not altered between the author's machine and the server, which matters most where a
compromised server or a mirror is part of the threat.
