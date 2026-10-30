---
title: Quando a instalação falha
version: 1
---

Uma instalação que falha raramente diz "sua instalação falhou". Ela diz algo sobre um comando, uma
biblioteca ou uma assinatura, e a tentação é apagar tudo e começar de novo. **Cada falha abaixo tem
uma causa, e a mensagem a nomeia** se você ler até o fim. As três foram produzidas de propósito, no
mesmo Ubuntu 24.04.

## `swift: command not found`, logo depois de desempacotar

O toolchain está no disco, e o shell não o encontra. O shell procura um comando só nos diretórios
listados no `PATH`, e um terminal lê o `~/.bashrc`, onde a seção 02 acrescentou o novo, **quando
inicia**. Um terminal que já estava aberto antes do `echo` ainda tem a lista antiga:

```
ana@vm:~$ swift --version; echo $?
bash: line 1: swift: command not found
127
ana@vm:~$ ~/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin/swift --version
Swift version 6.4.2 (swift-6.4.2-RELEASE)
Target: x86_64-unknown-linux-gnu
ana@vm:~$ echo $PATH
/usr/local/bin:/usr/bin:/bin
```

**O status de saída 127 é o número do próprio shell para "comando não existe"**, então a mensagem
vem do `bash` e não do Swift. O caminho completo funciona, o que prova que o arquivo está lá. O
`echo $PATH` mostra a lista em que o shell procura, e o `usr/bin` do toolchain não está nela. Abra um
terminal novo, ou digite `source ~/.bashrc` neste, e o `swift` responde.

Se um terminal novo ainda não o encontra, olhe o fim do `~/.bashrc` com `tail -1 ~/.bashrc`. A linha
deve estar exatamente como a seção 02 a digitou. Aspas duplas por fora em vez de simples é o erro
comum: o shell então trocou `$HOME` e `$PATH` pelos valores que tinham no momento do `echo`, o que
ainda funciona mas congela o `PATH` antigo dentro do arquivo.

## O `swift` é encontrado, e uma biblioteca não

Os programas do toolchain foram construídos no Ubuntu 24.04 e esperam encontrar algumas bibliotecas
desse sistema. Desempacote-o pulando a linha do `apt`, e o programa é encontrado e então falha antes
de conseguir imprimir qualquer coisa sua:

```
ana@vm:~$ swift --version; echo $?
swift: error while loading shared libraries: libncurses.so.6: cannot open shared object file: No such file or directory
127
ana@vm:~$ ldd $(which swift) | grep "not found"
	libncurses.so.6 => not found
```

A mensagem é do **carregador dinâmico**, a parte do Linux que inicia um programa e o liga às
bibliotecas compartilhadas. Ela nomeia a primeira biblioteca que não achou, `libncurses.so.6`, e
desiste ali. **Leia uma mensagem pelo programa que a escreveu**: o `swift` foi encontrado e não rodou
uma linha. O `ldd` lista toda biblioteca que um programa pede e onde cada uma foi achada, e o
`grep "not found"` guarda as que faltam. A correção é a linha do `apt` da seção 02, inteira, porque
um toolchain que inicia ainda pode falhar ao ligar seu primeiro programa quando falta o `binutils`
ou o `libc6-dev`.

A mesma mensagem, com outra biblioteca, é o que você vê ao desempacotar um toolchain construído para
outra versão, como o arquivo do Ubuntu 22.04 numa máquina 24.04. **O nome do arquivo diz para qual
sistema ele é**, e precisa bater com o seu.

## Um download que parou no meio

Uma conexão que cai pode deixar um arquivo mais curto do que deveria, com o nome certo. Nada no nome
avisa, e o `tar` descobre tarde:

```
ana@vm:~/dl$ gpg --verify swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig swift-6.4.2-RELEASE-ubuntu24.04.tar.gz; echo $?
gpg: Signature made Wed Oct 28 11:36:39 2026 -03
gpg:                using RSA key EF80A866B47A981F
gpg: BAD signature from "Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>" [unknown]
1
ana@vm:~/dl$ tar -xzf swift-6.4.2-RELEASE-ubuntu24.04.tar.gz -C /tmp; echo $?

gzip: stdin: unexpected end of file
tar: Unexpected EOF in archive
tar: Unexpected EOF in archive
tar: Error is not recoverable: exiting now
2
ana@vm:~/dl$ ls -l swift-6.4.2-RELEASE-ubuntu24.04.tar.gz
-rw-r--r-- 1 ana ana 419430400 Oct 30 14:52 swift-6.4.2-RELEASE-ubuntu24.04.tar.gz
```

O `gpg --verify` disse `BAD signature` antes de qualquer coisa ser desempacotada, e é por isso que a
seção 02 confere o arquivo primeiro. O status de saída 1 quer dizer que a conferência falhou. O `tar`
então confirma com as palavras dele: um arquivo comprimido é lido do começo, e espera-se que o fim
dos dados esteja lá; num arquivo cortado, não está. **Apague o arquivo e baixe de novo**; não há nada
num arquivo danificado que valha guardar. O `ls -l` mostra a diferença como tamanho, 419.430.400
bytes contra os 1.124.819.616 do arquivo que passou na verificação, e essa é a comparação mais rápida
quando você não guardou a assinatura.

## Quando não é nenhuma destas

Três coisas para juntar antes de pedir ajuda a alguém, porque respondem à maioria das perguntas que
vão lhe fazer:

- `swift --version`, `which swift` e `cat /etc/os-release`, que juntos dizem o que você está rodando
  e em quê;
- `echo $PATH` e `ls ~/.local/share`;
- as **últimas** linhas da saída do comando que falha, não as primeiras. Um compilador que falha
  nomeia o problema com as palavras dele perto do fim, depois do que estava fazendo quando percebeu.
