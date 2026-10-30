---
title: O seu laboratório, no seu próprio computador
version: 1
---

**Todo comando deste curso é um que você digita no seu próprio computador.** A plataforma não roda
nada por você: nenhuma máquina, nenhum shell no navegador, nenhuma conta do Google emprestada. O que
você precisa é pouco, e nada disso custa dinheiro ou pede cartão:

- **a Google Cloud CLI**, versão 589.0.0, com dois dos seus componentes: o emulador do Pub/Sub e os
  comandos `beta` que o iniciam;
- **o Terraform** 1.16.4, que baixa o provider do Google na primeira vez que uma lição pede;
- Python 3 com duas bibliotecas num diretório só delas, Java para o emulador, e `curl`, `jq` e
  `unzip`, que o Ubuntu fornece.

As lições foram gravadas no **Ubuntu 24.04**, e há três jeitos de ter um terminal nele.

| | o que é | quanto custa ao seu computador |
|---|---|---|
| **instalado** (recomendado) | as ferramentas no seu próprio sistema: o Ubuntu 24.04, ou o Ubuntu 24.04 no WSL do Windows | cerca de 1,3 GB de disco, e uns 180 MB de memória enquanto o emulador roda |
| uma máquina virtual | o Ubuntu Server 24.04 num hipervisor, em qualquer sistema | 2 processadores, 4 GB de memória e 15 GB de disco enquanto ela roda |
| online | um shell Linux alugado no navegador | nada no seu computador; uma conta com alguém, e um limite de quanto tempo dura |

Os números de disco e de memória da primeira linha são medidos: o último bloco da próxima seção os
imprime. A segunda linha é o que o Ubuntu Server pede mais a primeira linha, com folga.

**Instale, a não ser que você use Mac.** No Linux é o terminal que você já tem. No Windows, o WSL roda
um Ubuntu de verdade ao lado do Windows: `wsl --install -d Ubuntu-24.04` num PowerShell de
administrador o instala, e a entrada Ubuntu do menu Iniciar abre o terminal dele. Nada que este curso
instala é um serviço ou mexe nas configurações do sistema. Fora seis pacotes do repositório do Ubuntu,
tudo mora em `~/gcp` e `~/.local`, e apagá-los desfaz a instalação.

**Uma máquina virtual** é o caminho no Mac, e em qualquer computador em que você prefira não mexer. A
CLI, o Terraform e o emulador rodam no macOS, mas as transcrições foram gravadas no Ubuntu, e as
mensagens do sistema não bateriam. Instale o Ubuntu Server 24.04 no hipervisor que o seu sistema
oferece: Hyper-V ou VirtualBox no Windows, UTM num Mac com Apple silicon, GNOME Boxes ou virt-manager
no Linux. O Multipass, da Canonical, faz o mesmo com um comando nos três:
`multipass launch 24.04 --name gcp --cpus 2 --memory 4G --disk 15G`, depois `multipass shell gcp`.
**Esses dois comandos não foram rodados para este curso**, porque a máquina em que ele foi gravado não
roda hipervisor; tudo depois deles foi.

**Online** é um shell que o computador de outra pessoa roda para você, como o GitHub Codespaces, ou
qualquer máquina Linux pequena alugada por hora. Funciona, porque o curso não precisa de mais que um
shell que alcance a internet, para baixar as ferramentas. **Nenhuma lição depende da cota gratuita de
uma empresa**, porém, e cada uma tem as suas horas e os seus termos, que mudam. O Cloud Shell, do
próprio Google, é um shell no navegador com o `gcloud` já instalado, e a lição 23 é sobre ele. Ele
não serve como laboratório deste curso: exige uma conta do Google, e a ideia é que você nunca precise
de uma.

## Dois terminais

O laboratório são dois programas que conversam, então ele precisa de **duas janelas de terminal** lado
a lado, ou duas abas de uma:

- a primeira roda **o emulador do Pub/Sub**, e mostra o que ele diz ao iniciar e ao parar;
- a segunda é onde você digita `gcloud`, `terraform` e `python3`, e onde toda transcrição destas lições
  foi feita.

O emulador guarda o que lhe dizem **na memória, e esquece tudo quando para**. Isso é uma vantagem: uma
lição começa de um Pub/Sub vazio parando o emulador e iniciando-o de novo, e um erro não custa nada
para ser jogado fora. O Terraform é diferente. Ele escreve o que fez num arquivo ao lado da sua
configuração, e as lições que o usam dizem em que diretório trabalhar, para que os arquivos de uma
lição nunca encontrem os de outra.

Qualquer que seja o caminho, a próxima seção começa no mesmo lugar: um terminal no Ubuntu 24.04, com
você logado como você mesmo. A seção depois dela, sobre falhas, é a que se lê quando um comando não
responde como a transcrição.
