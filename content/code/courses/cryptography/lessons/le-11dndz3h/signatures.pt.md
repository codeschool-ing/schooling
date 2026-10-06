---
title: Assinaturas, quando os dois lados não compartilham nada
version: 1
---

**Quando quem confere uma mensagem não compartilha um segredo com o autor, a verificação precisa
ser uma assinatura: feita com a chave privada do autor, verificada com uma chave pública que todos
podem ter.** A aula 3 mostrou a operação com o `openssl pkeyutl`. Esta seção usa a ferramenta que
muitas equipes já têm instalada para isso: o `ssh-keygen -Y` do OpenSSH, que assina qualquer arquivo
com uma chave SSH e que o Git usa para assinar commits e tags.

## A chave da Ana, e a quem ela pertence

A chave Ed25519 da Ana, a mesma das aulas 2 e 3, no formato do OpenSSH:

```
ana@lab:~/lab$ cat keys/ana_ssh.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKbrVbLEHhq6u+cmCobYboWrP2Yp4hGI5xXLgb45i5Jn ana@vereda.example
```

Uma chave pública não diz de quem é, como a aula 2 avisou, então a verificação precisa de uma lista
que amarre nomes a chaves. O OpenSSH a chama de arquivo de *allowed signers* (signatários
permitidos), e o da Vereda tem uma linha:

```
ana@lab:~/lab$ cat data/allowed_signers
ana@vereda.example ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKbrVbLEHhq6u+cmCobYboWrP2Yp4hGI5xXLgb45i5Jn
```

Esse arquivo é a decisão de confiança. Quem o controla decide quais chaves contam como da Ana, e é
por isso que numa equipe real ele fica no repositório, muda por revisão e é lido de um branch
protegido.

## Assinando as notas da versão

```
ana@lab:~/lab$ ssh-keygen -Y sign -f keys/ana_ssh -n file data/release/NOTES.txt
Signing file data/release/NOTES.txt
Write signature to data/release/NOTES.txt.sig
ana@lab:~/lab$ cat data/release/NOTES.txt.sig
-----BEGIN SSH SIGNATURE-----
U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgputVssQeGrq75yYKhthuhas/Zi
niEYjnFcuBvjmLkmcAAAAEZmlsZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtzc2gtZWQyNTUx
OQAAAEADd1SxSwEYGJ/0ZgrdyQP7euO/cAIriRPu0ZVod9poXFyFyZFoK9OvCm2gzkRTfY
idFunf2DuuDHYxa9Om1a8D
-----END SSH SIGNATURE-----
```

`-n file` é o **namespace**, um rótulo assinado junto com o conteúdo, para que uma assinatura feita
para um propósito não possa ser reaproveitada em outro: uma assinatura sobre um arquivo no namespace
`file` não verifica como assinatura de commit do Git, que usa `git`. O bloco de assinatura traz a
chave pública, o namespace, o algoritmo de hash (`sha512`) e a assinatura Ed25519 em si. A Ed25519 é
determinística, então assinar as mesmas notas de novo dá exatamente esses bytes.

## Verificando, e uma alteração

Qualquer um com o arquivo de signatários permitidos consegue verificar, e ninguém precisa da chave
privada da Ana:

```
ana@lab:~/lab$ ssh-keygen -Y verify -f data/allowed_signers -I ana@vereda.example -n file -s data/release/NOTES.txt.sig < data/release/NOTES.txt
Good "file" signature for ana@vereda.example with ED25519 key SHA256:WQC0xcZGw6I14/kTQfeosQeRcxSG8diqypQPqXgm3DI
```

`SHA256:WQC0…` é a **impressão digital** (*fingerprint*) da chave, o SHA-256 da chave pública, curta
o bastante para ser lida em voz alta num telefonema quando alguém quer confirmar que a chave do
arquivo é mesmo da Ana. Mude uma palavra das notas e a mesma assinatura falha:

```
ana@lab:~/lab$ sed 's/SMS/e-mail/' data/release/NOTES.txt | ssh-keygen -Y verify -f data/allowed_signers -I ana@vereda.example -n file -s data/release/NOTES.txt.sig
Signature verification failed: incorrect signature
Could not verify signature.
```

## Escolhendo entre os dois

| situação | use | porque |
|---|---|---|
| um gateway avisando o seu servidor | HMAC | os dois lados já compartilham uma chave, e a velocidade importa |
| um cookie de sessão que o seu próprio servidor emitiu | HMAC | quem emite e quem verifica são a mesma parte |
| uma versão de software, uma imagem de contêiner | uma assinatura | milhares verificam, nenhum compartilha segredo com o autor |
| um commit, um contrato, uma nota fiscal | uma assinatura | um terceiro pode precisar saber quem assinou |
| um token que um serviço emite e outros verificam | uma assinatura | quem verifica não pode conseguir emitir |

A última linha é a que os projetos erram. Se vários serviços verificam tokens com uma chave HMAC
compartilhada, cada um deles também consegue fabricar tokens, e o serviço mais fraco guarda a chave
de todos os outros. Uma assinatura separa os dois poderes: um serviço assina, os demais só
verificam.
