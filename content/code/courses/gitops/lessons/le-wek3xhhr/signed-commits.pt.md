---
title: Commits assinados
version: 1
---

**Assinar o artefato prova quem o construiu. Assinar o commit prova quem escreveu o estado desejado.**
O campo de autor de um commit é um texto que qualquer um define, como toda captura deste curso faz com
o `GIT_AUTHOR_NAME`. Uma assinatura não é: ela é feita com uma chave que só o dono tem, e o Git
consegue conferi-la contra uma lista de chaves em que confia.

O Git assina com GPG ou, de forma mais simples, com uma chave SSH:

```
ana@laptop:~$ ssh-keygen -q -t ed25519 -N "" -C "ana@example.org" -f ~/.ssh/signing
ana@laptop:~$ git config --global gpg.format ssh
ana@laptop:~$ git config --global user.signingkey ~/.ssh/signing.pub
ana@laptop:~$ echo "ana@example.org $(cat ~/.ssh/signing.pub)" > ~/.ssh/allowed_signers
ana@laptop:~$ git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

O `gpg.format ssh` manda o Git assinar com SSH, o `user.signingkey` cita a metade pública da chave com
que assinar, e o arquivo de signatários permitidos é a lista de quem pode assinar: cada linha um
endereço e a chave que pode assinar por ele. É a raiz de confiança do lado da verificação, exatamente
como o `cosign.pub`.

```
ana@laptop:~/fleet$ git switch --quiet -c preview-0.1.0
ana@laptop:~/fleet$ git commit --quiet -S -am "preview: back to the signed chart"
ana@laptop:~/fleet$ git log --show-signature -2 --format="%h %an %s"
Good "git" signature for ana@example.org with ED25519 key SHA256:FoPKghSz0uyS83mfQbpA9Qc4YyCHzGJ+4AdtBLnzqXo
45f1c11 Ana Lima preview: back to the signed chart
f237f00 ana Merge pull request 'preview: chart 0.1.1' (#12) from preview-0.1.1 into main
```

`Good "git" signature for ana@example.org`, contra a chave da lista. O commit anterior não tem
assinatura nenhuma, e nada no Git impede alguém de escrever um no nome da Ana.

## Quem confere

Uma assinatura que ninguém confere é enfeite. Três lugares conseguem conferi-la:

- **o servidor Git**: o Gitea, o GitHub e o GitLab mostram um commit como verificado quando a chave dele
  pertence à conta que ele cita, e a proteção de branch pode exigir commits assinados na `main`;
- **o agente**: o `GitRepository` do Flux consegue verificar a assinatura do commit que busca, com o
  `spec.verify`, contra um conjunto de chaves OpenPGP num Secret, e o Argo CD consegue exigir
  assinaturas GPG por projeto. Os dois verificam assinaturas GPG e não SSH, e é por isso que um time
  que quer que o agente confira commits assina com GPG;
- **a revisão**: o autor do pull request é a conta que fez o push, e a aprovação é a conta que aprovou,
  as duas registradas pelo servidor, digam o que disserem os commits.

**Num fluxo com branches protegidos e revisões, o registro do servidor sobre quem enviou e quem aprovou
já é uma evidência forte**, e muitos times param aí. Commits assinados acrescentam a garantia de que o
conteúdo não foi alterado entre a máquina do autor e o servidor, o que importa mais onde um servidor
comprometido ou um espelho fazem parte da ameaça.
