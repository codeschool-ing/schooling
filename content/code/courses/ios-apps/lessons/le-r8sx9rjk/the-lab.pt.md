---
title: Duas máquinas, e três formas de ter cada uma
version: 1
---

Este curso usa dois ambientes, e você pode ter um deles ou os dois. **O toolchain do Swift** compila
e testa o pacote do planner; foi com ele que cada transcrição do curso foi gravada, e ele roda no
Linux e no macOS. **O Xcode num Mac** compila o app SwiftUI e o roda no simulador; nada no curso foi
gravado com ele. A plataforma não dá nenhum dos dois, então esta seção é sobre ter os seus.

## O toolchain do Swift: três caminhos

O toolchain é o que o curso `swift` instala, e a aula 1 dele faz isso por inteiro. Esta é a mesma
instalação em resumo, para que este curso fique de pé sozinho:

| caminho | o que você ganha | o que custa ao seu computador | as transcrições do curso |
|---|---|---|---|
| **instalado no Ubuntu 24.04** (recomendado sem Mac) | Swift 6.4.2 do swift.org, descompactado no seu diretório pessoal | uns 110 MB de pacotes do Ubuntu e um download de 1,1 GB, 3,5 GB de disco depois de descompactado | rodam como impressas, byte a byte |
| **uma máquina virtual** | o mesmo Ubuntu numa janela no Windows ou no macOS | o disco de um sistema operacional inteiro, e memória presa enquanto roda | rodam como impressas, depois que o Ubuntu estiver nela |
| **online** | um ambiente de desenvolvimento numa aba do navegador, com um contêiner onde dá para instalar | nada no seu computador, mas uma conta e uma cota mensal com alguém | parecidas, com outros caminhos de diretório |

**Num Mac com Xcode você já tem esse toolchain**, numa versão que acompanha o Xcode, e `swift build`
e `swift test` funcionam no Terminal exatamente como aqui. As transcrições vão diferir nos caminhos e
na linha da versão, e nada mais no curso depende de nenhum dos dois.

A Ana, cujo prompt aparece em toda transcrição, começou num Ubuntu 24.04 novo que nunca tinha visto
Swift. Os pacotes são os que o swift.org lista para o Ubuntu 24.04: o linker, os cabeçalhos da
biblioteca C e as bibliotecas contra as quais o próprio compilador é ligado.

```
ana@vm:~$ swift --version; echo $?
bash: line 1: swift: command not found
127
ana@vm:~$ sudo apt install -y binutils git gnupg2 libc6-dev libcurl4-openssl-dev libedit2 libgcc-13-dev libncurses-dev libpython3-dev libsqlite3-0 libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata unzip zlib1g-dev curl 2>&1 | grep -E '^(Need to get|After this operation)'
Need to get 110 MB of archives.
After this operation, 340 MB of additional disk space will be used.
```

O `apt` imprime algumas centenas de linhas enquanto trabalha, e o `grep` guarda as duas que dizem
quanto custa. **Na sua máquina, digite o comando sem o pipe e sem o `-y`**, para que o `apt` pare e
mostre essas duas linhas antes de baixar qualquer coisa.

Depois, o próprio toolchain, e a assinatura que prova quem o fez:

```
ana@vm:~$ mkdir -p ~/downloads ~/.local/share && cd ~/downloads
ana@vm:~/downloads$ curl -fsSLO -C - --retry 5 --retry-all-errors https://download.swift.org/swift-6.4.2-release/ubuntu2404/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE-ubuntu24.04.tar.gz
ana@vm:~/downloads$ curl -fsSLO https://download.swift.org/swift-6.4.2-release/ubuntu2404/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig
ana@vm:~/downloads$ ls -lh
total 1.1G
-rw-r--r-- 1 ana ana 1.1G Oct 30 15:03 swift-6.4.2-RELEASE-ubuntu24.04.tar.gz
-rw-r--r-- 1 ana ana  819 Oct 30 15:03 swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig
```

`-C -` e `--retry 5 --retry-all-errors` estão ali porque o arquivo passa de um gigabyte. Se a conexão
cair no meio, o `curl` tenta de novo e continua do byte onde parou, em vez de recomeçar. O arquivo
`.sig` é uma assinatura feita com a chave de release do projeto Swift.

```
ana@vm:~/downloads$ curl -fsSL https://www.swift.org/keys/all-keys.asc | gpg --import -
gpg: directory '/home/ana/.gnupg' created
gpg: keybox '/home/ana/.gnupg/pubring.kbx' created
gpg: /home/ana/.gnupg/trustdb.gpg: trustdb created
gpg: key D441C977412B37AD: public key "Swift Automatic Signing Key #1 <swift-infrastructure@swift.org>" imported
gpg: key 9F597F4D21A56D5F: public key "Swift 2.2 Release Signing Key <swift-infrastructure@swift.org>" imported
gpg: key 63BC1CFE91D306C6: public key "Swift 3.x Release Signing Key <swift-infrastructure@swift.org>" imported
gpg: key EF5430F071E1B235: public key "Swift 4.x Release Signing Key <swift-infrastructure@swift.org>" imported
gpg: key 7638F1FB2B2B08C4: public key "Swift Automatic Signing Key #2 <swift-infrastructure@swift.org>" imported
gpg: key 925CC1CCED3D1561: public key "Swift 5.x Release Signing Key <swift-infrastructure@swift.org>" imported
gpg: key FAF6989E1BC16FEA: public key "Swift Automatic Signing Key #3 <swift-infrastructure@swift.org>" imported
gpg: key 925CC1CCED3D1561: "Swift 5.x Release Signing Key <swift-infrastructure@swift.org>" 1 new signature
gpg: key F167DF1ACF9CE069: public key "Swift Automatic Signing Key #4 <swift-infrastructure@forums.swift.org>" imported
gpg: key 925CC1CCED3D1561: "Swift 5.x Release Signing Key <swift-infrastructure@swift.org>" 1 new signature
gpg: key F167DF1ACF9CE069: "Swift Automatic Signing Key #4 <swift-infrastructure@forums.swift.org>" 1 new signature
gpg: key EF80A866B47A981F: public key "Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>" imported
gpg: key F167DF1ACF9CE069: "Swift Automatic Signing Key #4 <swift-infrastructure@forums.swift.org>" 1 new signature
gpg: key EF80A866B47A981F: "Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>" 1 new signature
gpg: Total number processed: 14
gpg:               imported: 9
gpg:         new signatures: 5
ana@vm:~/downloads$ gpg --verify swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig
gpg: assuming signed data in 'swift-6.4.2-RELEASE-ubuntu24.04.tar.gz'
gpg: Signature made Wed Oct 28 11:36:39 2026 -03
gpg:                using RSA key EF80A866B47A981F
gpg: Good signature from "Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: 52BB 7E3D E28A 71BE 22EC  05FF EF80 A866 B47A 981F
```

**`Good signature` é a única resposta que deixa você seguir em frente.** O primeiro comando importa
as chaves públicas do projeto Swift a partir do swift.org; o segundo confere o arquivo contra a
assinatura com elas. O `WARNING` embaixo diz que você não certificou pessoalmente que aquela chave
pertence ao projeto Swift, o que é verdade e é normal: você confiou nela porque a buscou em
`swift.org` por HTTPS. A seção 04 mostra o que um arquivo danificado recebe em vez disso.

Descompacte em `~/.local/share` e coloque o `usr/bin` dele no seu `PATH`, para que o shell ache o
`swift` sem o caminho completo:

```
ana@vm:~/downloads$ tar xzf swift-6.4.2-RELEASE-ubuntu24.04.tar.gz -C ~/.local/share
ana@vm:~/downloads$ echo 'export PATH="$HOME/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin:$PATH"' >> ~/.bashrc
ana@vm:~/downloads$ source ~/.bashrc
ana@vm:~/downloads$ du -sh ~/.local/share/swift-6.4.2-RELEASE-ubuntu24.04
3.5G	/home/ana/.local/share/swift-6.4.2-RELEASE-ubuntu24.04
```

O `echo` acrescenta uma linha ao `~/.bashrc`, que todo terminal novo lê, e o `source` lê o arquivo no
terminal que você já tem aberto. **Digite a linha exatamente, aspas simples por fora e duplas por
dentro**: as simples mantêm `$HOME` e `$PATH` como texto até um terminal ler o arquivo. Depois
pergunte ao toolchain quem ele é:

```
ana@vm:~$ swift --version
Swift version 6.4.2 (swift-6.4.2-RELEASE)
Target: x86_64-unknown-linux-gnu
ana@vm:~$ which swift
/home/ana/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin/swift
```

`Swift version 6.4.2` é a resposta com que toda transcrição deste curso foi gravada. A linha `Target`
diz para o que ele compila por padrão, o processador e o sistema desta máquina. Num computador ARM
ela diz `aarch64`, e num Mac cita `apple-macosx`.

## Xcode: três caminhos, nenhum de graça

| caminho | o que você precisa | quanto custa |
|---|---|---|
| **um Mac, instalado** (recomendado) | um Mac recente o bastante para o macOS atual, e o Xcode da Mac App Store | o Mac; o Xcode em si é gratuito, e pede dezenas de gigabytes de disco com um simulador |
| **uma máquina virtual** | o macOS dentro de uma máquina virtual, num Mac | a licença da Apple permite o macOS numa máquina virtual só em hardware da Apple, então isto é um segundo Mac dentro do primeiro, para manter uma configuração limpa ou mais antiga |
| **online** | um Mac alugado num data center e acessado por área de trabalho remota | uma tarifa por hora ou por mês para a empresa de quem você aluga |

Nada disso foi executado para o curso. Quanto cada um custa vem das páginas da Apple sobre o Xcode e
sobre a licença do macOS, lidas em 30 de outubro de 2026, e a página da Mac App Store dá o tamanho
atual. **Se você tem um Mac, instale o Xcode antes da aula 2**: o download é grande, e a primeira
abertura instala mais componentes e pergunta quais simuladores você quer.

Pagar não faz parte desta aula. O Xcode compila e roda um app no simulador, e no seu próprio iPhone
por alguns dias de cada vez, com uma Apple Account gratuita. A aula 21 diz o que a assinatura paga
acrescenta e quanto custa, antes de qualquer coisa no curso pedir por ela.
