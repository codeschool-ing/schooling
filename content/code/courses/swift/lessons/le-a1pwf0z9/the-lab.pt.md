---
title: Três jeitos de ter o Swift
version: 1
---

Da seção 04 desta aula até o fim da aula 20, este curso pede que você digite programas, compile-os
e leia o que volta. Para isso você precisa de uma coisa: **o toolchain do Swift**, que é o
compilador, a biblioteca padrão, o gerenciador de pacotes e os executores de testes, distribuídos
juntos num único arquivo. A plataforma não lhe dá máquina nenhuma onde digitar, então a primeira
tarefa é ter uma sua.

**Há três lugares para colocá-lo, e o curso recomenda o primeiro**: instalado num Ubuntu 24.04, seu
próprio computador ou uma máquina virtual rodando nele.

| caminho | o que você ganha | quanto custa ao seu computador | as transcrições do curso |
|---|---|---|---|
| **instalado no Ubuntu 24.04** (recomendado) | o toolchain do Swift 6.4.2 do swift.org, desempacotado no seu diretório pessoal, e as bibliotecas de que ele precisa vindas do arquivo do Ubuntu | cerca de 110 MB do Ubuntu e 1,1 GB do swift.org, e cerca de 3,5 GB de disco depois de desempacotado | rodam como impressas, byte a byte |
| **uma máquina virtual** | o mesmo Ubuntu, dentro de uma janela no Windows ou no macOS | o disco de um sistema operacional inteiro, e memória presa enquanto roda | rodam como impressas, byte a byte, depois que o Ubuntu estiver nela |
| **online** | um ambiente de desenvolvimento numa aba do navegador | nada no seu computador, mas uma conta e uma cota mensal com alguém | parecidas, com outros caminhos e talvez outro Swift |

## O que este curso pode e não pode mostrar

**Todo programa destas vinte aulas roda no Linux, e você pode reproduzir cada transcrição.** O
Swift é a linguagem da Apple, e é também um projeto de código aberto que publica o mesmo compilador
para Linux e Windows. Opcionais, structs, protocolos, genéricos, `Codable`, `async`/`await`, atores,
os dois frameworks de teste e o gerenciador de pacotes funcionam no Linux exatamente como num Mac.

O que não existe no Linux é **a plataforma da Apple**: o Xcode, o simulador do iOS, o SwiftUI e o
UIKit. Três aulas encontram esse muro, e cada uma diz isso onde acontece. A caça a um vazamento de
memória da aula 11 descreve o grafo de memória que o Xcode desenha, e faz a busca com as ferramentas
do próprio compilador. A aula 16 mostra como o SwiftUI usa property wrappers e result builders
construindo versões pequenas dos dois, já que o SwiftUI não está lá para ser importado. A aula 20
descreve o que muda num Mac sem rodá-lo. Nada nessas três é transcrição de algo que não rodou.

O curso depois deste no caminho, `ios-apps`, constrói o planner de estudos como app de iPhone, e esse
curso precisa de um Mac com Xcode desde a primeira aula. **O muro cai entre os dois cursos**, e este
fica inteiro do lado em que você pratica em qualquer computador.

## Instalado: o caminho recomendado

A versão é fixa, e o curso foi gravado exatamente com esta: **Swift 6.4.2**, a versão que o swift.org
publicou em 29 de outubro de 2026, que é também o Swift de dentro do Xcode 27.2. O Ubuntu não
empacota o Swift, então ele chega como um arquivo do `download.swift.org`. O que o Ubuntu fornece é o
conjunto de bibliotecas do sistema com que o toolchain se liga, e a página de instalação do
swift.org as lista por distribuição. A Ana, a estudante cujo prompt você verá em toda transcrição,
começou num Ubuntu 24.04 novo que nunca tinha visto Swift:

```
ana@vm:~$ swift --version; echo $?
bash: line 1: swift: command not found
127
ana@vm:~$ sudo apt install -y binutils git gnupg2 libc6-dev libcurl4-openssl-dev libedit2 libgcc-13-dev libncurses-dev libpython3-dev libsqlite3-0 libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata unzip zlib1g-dev curl 2>&1 | grep -E '^(Need to get|After this operation|Setting up (git|gnupg2|curl|binutils|libz3-dev)[: ])'
Need to get 111 MB of archives.
After this operation, 345 MB of additional disk space will be used.
Setting up libz3-dev:amd64 (4.8.12-3.1build1) ...
Setting up curl (8.5.0-2ubuntu10.16) ...
Setting up gnupg2 (2.4.4-2ubuntu17.6) ...
Setting up binutils (2.42-4ubuntu2.10) ...
Setting up git (1:2.43.0-1ubuntu7.4) ...
```

O `apt` imprime algumas centenas de linhas enquanto trabalha. O `grep` guarda as duas que dizem
quanto custa e cinco das linhas que dizem o que chegou, para você comparar a sua tela com esta.
**Na sua máquina, digite o comando sem o pipe e sem o `-y`**, para que o `apt` pare e pergunte antes
de baixar qualquer coisa. A lista é longa porque o compilador é construído sobre o LLVM e liga os
programas com as ferramentas do próprio sistema. O `binutils` é o linker; o `libc6-dev` e os dois
pacotes `-13-dev` são as bibliotecas de C e C++ que todo programa Swift no Linux acaba chamando; e o
`git` é com o que o gerenciador de pacotes busca dependências na aula 19.

Depois, o toolchain em si. Crie um diretório para o download, baixe o arquivo e a assinatura
publicada ao lado dele, e confira um contra o outro antes de desempacotar qualquer coisa:

```
ana@vm:~$ mkdir -p ~/downloads ~/.local/share && cd ~/downloads
ana@vm:~/downloads$ curl -fsSLO https://download.swift.org/swift-6.4.2-release/ubuntu2404/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE-ubuntu24.04.tar.gz
ana@vm:~/downloads$ curl -fsSLO https://download.swift.org/swift-6.4.2-release/ubuntu2404/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig
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
ana@vm:~/downloads$ gpg --verify swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig swift-6.4.2-RELEASE-ubuntu24.04.tar.gz
gpg: Signature made Wed Oct 28 11:36:39 2026 -03
gpg:                using RSA key EF80A866B47A981F
gpg: Good signature from "Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: 52BB 7E3D E28A 71BE 22EC  05FF EF80 A866 B47A 981F
ana@vm:~/downloads$ ls -lh
total 1.1G
-rw-r--r-- 1 ana ana 1.1G Oct 30 14:42 swift-6.4.2-RELEASE-ubuntu24.04.tar.gz
-rw-r--r-- 1 ana ana  819 Oct 30 14:42 swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig
```

O swift.org **assina** cada arquivo em vez de publicar um checksum. O `gpg --import` lê as chaves
públicas do projeto em `swift.org/keys/all-keys.asc`; o `gpg --verify` então confere que o arquivo é
exatamente o que o dono da chave privada correspondente assinou. **`Good signature` é a única
resposta que deixa você seguir.** O aviso abaixo dela diz que você não certificou a chave
pessoalmente, o que é verdade e esperado: você confiou nela porque veio do swift.org por HTTPS. O que
você pode conferir é o nome na assinatura, `Swift 6.x Release Signing Key`, que é a chave desta
família de versões e foi uma das nove recém-importadas. A seção 03 mostra como fica um download
danificado.

Desempacote em `~/.local/share` e ponha o `usr/bin` dele no seu `PATH`, para o shell achar o `swift`
sem caminho completo:

```
ana@vm:~/downloads$ tar -xzf swift-6.4.2-RELEASE-ubuntu24.04.tar.gz -C ~/.local/share
ana@vm:~/downloads$ echo 'export PATH="$HOME/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin:$PATH"' >> ~/.bashrc
ana@vm:~/downloads$ source ~/.bashrc
ana@vm:~/downloads$ ls ~/.local/share
swift-6.4.2-RELEASE-ubuntu24.04
ana@vm:~/downloads$ du -sh ~/.local/share/swift-6.4.2-RELEASE-ubuntu24.04
3.5G	/home/ana/.local/share/swift-6.4.2-RELEASE-ubuntu24.04
```

O `echo` acrescenta uma linha ao `~/.bashrc`, que todo terminal novo lê. O `source` a lê no terminal
que você já tem aberto. **Digite a linha exatamente assim, com aspas simples por fora e duplas por
dentro**: as aspas simples mantêm `$HOME` e `$PATH` como texto até um terminal ler o arquivo. O
arquivo em `~/downloads`, 1,1 GB, pode ser apagado depois que a próxima verificação passar.

## Confira que ele responde

```
ana@vm:~$ swift --version
Swift version 6.4.2 (swift-6.4.2-RELEASE)
Target: x86_64-unknown-linux-gnu
ana@vm:~$ which swift swiftc
/home/ana/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin/swift
/home/ana/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin/swiftc
```

**Se o `swift --version` responde, o laboratório está pronto.** A primeira linha dá a versão, e a
segunda o **alvo**: o processador e o sistema operacional para os quais o compilador gera programas.
O `which` mostra que `swift` e `swiftc` vêm do diretório que você acabou de desempacotar, e de nenhum
outro lugar da máquina.

A página de instalação do próprio swift.org oferece uma ferramenta chamada `swiftly`, que baixa um
toolchain e mantém vários lado a lado. É um bom jeito de instalar o Swift e a aula 19 volta a ela.
O curso fixa o arquivo em vez disso porque a versão e a conferência da assinatura viram linhas que
você consegue ler, e o resultado é o mesmo toolchain num diretório diferente.

## Uma máquina virtual

Se o seu computador roda Windows ou macOS, rode o Ubuntu 24.04 dentro dele e siga o caminho
instalado lá. Toda transcrição então bate com o que você vê, prompt incluído.

- **No Windows**, o WSL é o Linux que o próprio Windows sabe rodar. Numa janela do PowerShell aberta
  como administrador, `wsl --install -d Ubuntu-24.04` o instala, e o terminal do Ubuntu que ele abre
  é onde você digita tudo acima.
- **No Windows, no macOS ou no Linux**, o Multipass inicia máquinas virtuais Ubuntu com um comando.
  Depois de instalá-lo pelo site dele, `multipass launch 24.04 --name swift --memory 4G --disk 20G`
  cria uma e `multipass shell swift` abre um terminal nela.

Nenhum dos dois comandos foi rodado para este curso, porque a máquina de gravação era ela mesma um
contêiner e não consegue iniciar outro. Os números do segundo são uma recomendação, não uma medida: o
toolchain desempacota para cerca de 3,5 GB, um build de pacote na aula 19 acrescenta algumas
centenas de megabytes de cache, e quatro gigabytes de memória evitam que o compilador use swap. Uma
máquina virtual prende a memória enquanto roda, então pare-a com `multipass stop swift` quando
terminar.

**Num Mac você também pode dispensar a máquina virtual.** Instalar o Xcode, ou só as Command Line
Tools, lhe dá um compilador Swift, e o swift.org publica um pacote para macOS da mesma versão. Todo
programa deste curso roda então no próprio Mac. O que muda é tudo em volta dos programas: caminhos, a
saída do `file` na seção 04 e algumas linhas da saída do gerenciador de pacotes. A aula 20 trata do
que mais muda, e nada disso toca as aulas 1 a 19.

## Online

Um ambiente de desenvolvimento na nuvem abre uma máquina Linux numa aba do navegador, com editor e
terminal. Várias empresas oferecem um, e elas mudam os termos com frequência, então este curso não
depende de nenhuma. **Não custa nada ao seu computador e custa uma conta**, uma cota mensal de horas
e uma conexão de rede a cada minuto de estudo. Alguns já vêm com um Swift instalado, na versão que a
empresa escolheu; digite `swift --version` antes de tudo, e se não for a 6.4.2, instale esta como
acima.

Então: **instale no Ubuntu se puder, use uma máquina virtual quando o computador não for Ubuntu, e
deixe o navegador para um computador que não é seu.**

## Por que não o Xcode

Num Mac, a maior parte do Swift é escrita no Xcode, e o `ios-apps` o instala no primeiro dia. Este
curso digita comandos em vez disso, por duas razões. Os comandos funcionam em qualquer computador,
então o curso funciona para qualquer estudante. E quando um build falha dentro de uma IDE, a
mensagem de que você precisa é a que estes comandos imprimem, e fica mais fácil de ler depois que
você a viu sozinha.
