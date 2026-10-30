---
title: Assinando um download para o desktop
version: 1
---

**No Windows uma assinatura é um certificado que alguém lhe vende**, e no Linux é uma que você mesmo faz. As
duas respondem à mesma pergunta para quem baixa: este é o arquivo que o autor publicou?

## Windows: Authenticode, e uma reputação

Um instalador do Windows é assinado com um **certificado de assinatura de código** comprado de uma autoridade
certificadora, que confere quem você é antes de emitir um. O `signtool`, do Windows SDK da Microsoft, assina o
`.exe` ou o `.msi`, e o electron-builder e o Tauri o chamam quando recebem o certificado. *Não executado, por
falta de uma máquina Windows e de um certificado.*

**Só a assinatura não impede o aviso do SmartScreen.** O SmartScreen decide pela reputação: quantas pessoas
baixaram arquivos assinados por aquele certificado sem problema. Um certificado novo começa sem nenhuma, então os
primeiros downloads de um app novo ainda mostram "O Windows protegeu o computador", com o nome do editor embaixo
em vez de "Editor desconhecido". As regras das autoridades certificadoras hoje mantêm a chave privada num
dispositivo de hardware ou num serviço de assinatura na nuvem, nunca num arquivo, e é também por isso que a
assinatura no Windows dentro da CI passa por um serviço desses.

## Linux: um checksum, e uma assinatura nele

O Linux não confere um `.deb` ou um AppImage baixado. O que um projeto cuidadoso publica ao lado dos pacotes é
uma lista com os checksums deles e uma assinatura nessa lista, para quem baixa conferir as duas coisas. Um
**checksum** é uma impressão digital curta dos bytes de um arquivo; o `sha256sum` a calcula:

```
ana@dev:~/planner/release$ sha256sum planner-0.1.0-x86_64.AppImage planner-0.1.0-amd64.deb > SHA256SUMS && cat SHA256SUMS
180cd8ba75dde288d5bc48a6c5606ec33cd8445cf5b8b8254027a500b4170961  planner-0.1.0-x86_64.AppImage
d717802a934e74a120b59498e647e71a372c9d6c64b78ee60fce26c205c97635  planner-0.1.0-amd64.deb
```

**Um byte mudado dá outro checksum**, e esse é o ponto todo. Aqui uma cópia do `.deb` com um caractere a mais no
fim, ao lado do original, os dezesseis primeiros caracteres de cada um:

```
ana@dev:~/planner/release$ cp planner-0.1.0-amd64.deb /tmp/copy.deb && printf x >> /tmp/copy.deb && sha256sum /tmp/copy.deb planner-0.1.0-amd64.deb | cut -c1-16
9fce823710bad8bc
d717802a934e74a1
```

Um checksum na mesma página do arquivo prova pouco, porque quem conseguisse mudar o arquivo conseguiria mudar a
página. **Então a lista é assinada**, com uma chave GnuPG que é sua. O `gpg` vem com o Ubuntu Desktop; num
sistema mínimo é `sudo apt install gnupg`. No seu computador, deixe de fora
`--batch --pinentry-mode loopback --passphrase "$KEY_PASS"` e o gpg pede a frase-senha numa janela própria, que é
a forma mais segura; a máquina de gravação não tinha teclado para digitar uma:

```
ana@dev:~/planner/release$ gpg --batch --pinentry-mode loopback --passphrase "$KEY_PASS" --quick-generate-key "Ana <ana@example.com>" ed25519 sign 2y 2>&1 | grep -v "^gpg: directory"
gpg: keybox '/home/ana/.gnupg/pubring.kbx' created
gpg: /home/ana/.gnupg/trustdb.gpg: trustdb created
gpg: revocation certificate stored as '/home/ana/.gnupg/openpgp-revocs.d/EACD08FC9452E9C6A31F6E6016E3ED681D265E99.rev'
ana@dev:~/planner/release$ gpg --list-keys --keyid-format short 2>&1 | grep -v "^gpg: "
/home/ana/.gnupg/pubring.kbx
----------------------------
pub   ed25519/1D265E99 2026-10-24 [SC] [expires: 2028-10-23]
      EACD08FC9452E9C6A31F6E6016E3ED681D265E99
uid         [ultimate] Ana <ana@example.com>
```

```
ana@dev:~/planner/release$ gpg --batch --pinentry-mode loopback --passphrase "$KEY_PASS" --armor --detach-sign SHA256SUMS
ana@dev:~/planner/release$ ls SHA256SUMS*
SHA256SUMS
SHA256SUMS.asc
ana@dev:~/planner/release$ gpg --armor --export ana@example.com > planner-signing-key.asc && head -n 1 planner-signing-key.asc
-----BEGIN PGP PUBLIC KEY BLOCK-----
```

**`SHA256SUMS.asc` é a assinatura, e `planner-signing-key.asc` é a chave pública** que você publica uma vez, no
seu site ou no README do projeto, para as pessoas conferirem cada release com ela. Conferir são dois comandos,
primeiro a assinatura e depois as somas:

```
ana@dev:~/planner/release$ gpg --verify SHA256SUMS.asc SHA256SUMS 2>&1 | grep -E "Good|BAD"
gpg: Good signature from "Ana <ana@example.com>" [ultimate]
ana@dev:~/planner/release$ sha256sum -c SHA256SUMS
planner-0.1.0-x86_64.AppImage: OK
planner-0.1.0-amd64.deb: OK
```

`[ultimate]` é o gpg confiando na chave do próprio dono. No computador de outra pessoa, depois de
`gpg --import planner-signing-key.asc`, a mesma linha vem com um aviso de que a chave não está certificada por
uma assinatura confiável: o gpg conferiu a assinatura, e está lembrando que foi a própria pessoa quem decidiu que a
chave é sua. E uma lista que alguém editou depois de assinada é recusada pelo nome, seja qual for a edição:

```
ana@dev:~/planner/release$ sed "s/^./0/" SHA256SUMS > SHA256SUMS.edited
ana@dev:~/planner/release$ gpg --verify SHA256SUMS.asc SHA256SUMS.edited 2>&1 | grep -E "Good|BAD"
gpg: BAD signature from "Ana <ana@example.com>" [ultimate]
```

As linhas do `.gitignore` da seção do Android entram no repositório do planner num commit só, já que os arquivos
de chave são a única coisa desta aula que nunca pode ir para um commit:

```
ana@dev:~/planner$ git add .gitignore && git commit -q -m "Keep signing keys out of the repository" && git log --oneline -1
531775b Keep signing keys out of the repository
```
