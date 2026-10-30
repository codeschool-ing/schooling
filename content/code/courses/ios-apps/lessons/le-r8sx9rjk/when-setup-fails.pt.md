---
title: Quando a instalação falha
version: 1
---

**Instalar é onde a maioria das pessoas para, e quase toda falha tem uma mensagem que diz a própria
causa.** Estas três foram provocadas de propósito na mesma máquina da seção 03, para você ver cada
uma antes que aconteça com você, e estão na ordem em que você as encontraria.

## `command not found` num terminal que já estava aberto

A linha do `export` foi para o `~/.bashrc`, e um terminal lê esse arquivo quando abre. Um que já
estava aberto antes de a linha entrar continua com o `PATH` antigo:

```
ana@vm:~$ swift --version
bash: swift: command not found
ana@vm:~$ echo $?
127
ana@vm:~$ source ~/.bashrc
ana@vm:~$ swift --version
Swift version 6.4.2 (swift-6.4.2-RELEASE)
Target: x86_64-unknown-linux-gnu
```

**O código de saída 127 é o jeito do próprio shell de dizer que não achou esse programa**, e ele vem
do shell antes de o Swift entrar na história. O `source ~/.bashrc` lê o arquivo neste terminal, e
abrir um novo faz o mesmo. Se um terminal novo ainda disser `command not found`, olhe a última linha
do `~/.bashrc` com `tail -1 ~/.bashrc`: a causa mais comum são as aspas, digitadas duplas por fora e
simples por dentro, o que grava o caminho como ele era quando você digitou, ou não grava nada.

## Um download que parou no meio

Uma conexão que cai sem `-C -` e `--retry` deixa um arquivo que parece o pacote e é só parte dele.
Aqui ele foi feito de propósito, cortando uma cópia em 300 MB:

```
ana@vm:~/downloads$ ls -lh cut.tar.gz
-rw-r--r-- 1 ana ana 300M Oct 30 15:04 cut.tar.gz
ana@vm:~/downloads$ gpg --verify swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig cut.tar.gz
gpg: Signature made Wed Oct 28 11:36:39 2026 -03
gpg:                using RSA key EF80A866B47A981F
gpg: BAD signature from "Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>" [unknown]
ana@vm:~/downloads$ tar xzf cut.tar.gz -C /tmp; echo $?

gzip: stdin: unexpected end of file
tar: Unexpected EOF in archive
tar: Unexpected EOF in archive
tar: Error is not recoverable: exiting now
2
```

**`BAD signature` é o gpg dizendo que esses bytes não são os bytes que o projeto Swift assinou.** Ele
não sabe dizer se foram cortados ou alterados, e nem precisa: nos dois casos a resposta é baixar de
novo. O `tar` falha também, no ponto em que os dados acabam, e o código de saída 2 é a palavra dele
para um erro fatal. Confira a assinatura antes de descompactar e você nunca vê a mensagem do `tar`.

Se o `gpg` disser `No public key`, a importação da seção 03 não aconteceu nesta conta: rode de novo a
linha `curl … | gpg --import -`.

## Um toolchain que não abre

Esta é uma máquina nova de novo, onde a estudante pulou a linha do `apt` e foi direto ao download:

```
ana@vm:~/downloads$ tar xzf swift-6.4.2-RELEASE-ubuntu24.04.tar.gz -C ~/.local/share
ana@vm:~/downloads$ echo 'export PATH="$HOME/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin:$PATH"' >> ~/.bashrc
ana@vm:~/downloads$ source ~/.bashrc; swift --version
swift: error while loading shared libraries: libncurses.so.6: cannot open shared object file: No such file or directory
```

**`error while loading shared libraries` vem do carregador do sistema, não do Swift.** O programa
`swift` está lá e está no `PATH`; ele precisa de uma biblioteca que este sistema não tem, e a mensagem
diz qual. Um Ubuntu de desktop costuma ter a `libncurses`, e aí o mesmo erro aparece mais tarde, como
um `swift build` que não acha um cabeçalho ou um linker. Os dois têm uma correção só, a linha do `apt
install` da seção 03, e é seguro rodá-la de novo: o `apt` pula o que já está instalado.

## Quando nada aqui bate

- **Leia o primeiro erro, não o último.** Uma compilação imprime primeiro o erro que causou os outros.
- **Confira a versão e o sistema.** O Swift 6.4.2 para Ubuntu 24.04 é outro download que o do 22.04,
  e que o de um processador ARM (`aarch64` no nome). O `uname -m` diz qual processador você tem, e o
  `cat /etc/os-release` diz qual Ubuntu.
- **Recomece o toolchain do zero.** Apague o diretório descompactado em `~/.local/share` e o arquivo
  baixado, e faça a seção 03 de novo. Nada mais no sistema depende deles.
- **Num Mac com Xcode**, `xcode-select -p` imprime qual diretório de desenvolvedor o comando `swift`
  está usando. Se ele citar `CommandLineTools` quando você esperava o Xcode, a documentação da Apple
  para o `xcode-select` explica como apontá-lo para o Xcode que você instalou. Esse comando não foi
  executado para este curso.
