---
title: O seu laboratório, no seu próprio computador
version: 1
---

**Cada comando deste curso é um que você digita no seu próprio computador.** A plataforma não roda
nada por você: nenhuma máquina, nenhum shell no navegador, nenhuma conta AWS emprestada. O que você
precisa é pouco, e nada disso custa dinheiro ou pede cartão:

- **a linha de comando da AWS**, versão 2, o programa `aws`. É a de verdade, publicada pela AWS, e
  neste curso ela nunca fala com a AWS;
- **o moto**, a imitação da AWS descrita na seção anterior, instalado com o instalador de pacotes do
  Python num diretório só dele;
- Python 3, `curl`, `jq` e `unzip`, que o Ubuntu fornece.

As lições foram gravadas no **Ubuntu 24.04**, e há três jeitos de ter um terminal nele.

| | o que é | o que custa ao seu computador |
|---|---|---|
| **instalado** (recomendado) | as ferramentas no seu próprio sistema: o Ubuntu 24.04 em si, ou o Ubuntu 24.04 no WSL do Windows | cerca de 600 MB de disco, e 80 MB de memória ou mais enquanto o moto roda, crescendo com o que você cria nele |
| uma máquina virtual | o Ubuntu Server 24.04 num hipervisor, em qualquer sistema | 2 processadores, 2 GB de memória e 10 GB de disco enquanto roda |
| online | um shell Linux alugado no navegador | nada no seu computador; uma conta com alguém, e um limite de quanto tempo dura |

**Instale, a menos que você use um Mac.** No Linux é o terminal que você já tem. No Windows, o WSL
roda um Ubuntu de verdade ao lado do Windows: `wsl --install -d Ubuntu-24.04` num PowerShell de
administrador o instala, e a entrada Ubuntu no menu Iniciar abre o terminal dele. Nada que este
curso instala é um serviço ou muda as configurações do seu sistema. Fora cinco pacotes do
repositório do Ubuntu, tudo mora em `~/aws`, `~/.local` e `~/.cache/aws-prices`, e apagá-los desfaz
tudo.

**Uma máquina virtual** é o caminho no Mac, e em qualquer computador em que você prefira não mexer.
A linha de comando da AWS e o moto rodam no macOS, mas as transcrições foram gravadas no Ubuntu, e
as mensagens do próprio sistema não bateriam. Instale o Ubuntu Server 24.04 no hipervisor que o seu
sistema oferece: Hyper-V ou VirtualBox no Windows, UTM num Mac com Apple silicon, GNOME Boxes ou
virt-manager no Linux. O Multipass, da Canonical, faz o mesmo com um comando nos três:
`multipass launch 24.04 --name aws --cpus 2 --memory 2G --disk 10G`, e depois `multipass shell aws`.
**Esses dois comandos não foram rodados para este curso**, porque a máquina em que ele foi gravado
não roda hipervisor; tudo o que vem depois deles foi.

**Online** é um shell que o computador de outra pessoa roda para você, como o GitHub Codespaces, ou
qualquer máquina Linux pequena alugada por hora. Funciona, porque o curso não precisa de nada além
de um shell que alcance a internet uma vez, para baixar as ferramentas. **Nenhuma lição depende da
franquia gratuita de uma empresa**, porém, e cada uma tem as próprias horas e termos, que mudam. O
CloudShell da própria AWS, um shell no console da AWS, não serve para este curso: ele exige uma
conta AWS, e a ideia é que você nunca precise de uma.

## Dois terminais

O laboratório são dois programas que conversam entre si, então ele precisa de **duas janelas de
terminal** lado a lado, ou duas abas de uma:

- a primeira roda o **moto**, e mostra uma linha para cada requisição que chega a ele;
- a segunda é onde você digita os comandos `aws`, e onde foi feita cada transcrição destas lições.

O moto guarda o que lhe dizem **na memória, e esquece tudo quando para**. Isso é uma vantagem: uma
lição começa de uma AWS vazia parando o moto e iniciando-o de novo, e um erro não custa nada para
jogar fora. Também quer dizer que nada do que você cria sobrevive ao fim de uma sessão, então cada
lição diz o que criar antes do primeiro comando.

Seja qual for o caminho, a próxima seção começa do mesmo lugar: um terminal no Ubuntu 24.04, com a
sua própria sessão. A seção depois dela, sobre falhas, é a que se lê quando um comando não responde
como a transcrição.
