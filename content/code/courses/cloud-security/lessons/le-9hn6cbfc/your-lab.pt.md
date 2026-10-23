---
title: Seu laboratório, no seu próprio computador
version: 1
---

**Todo comando deste curso é digitado no seu próprio computador.** A plataforma não roda nada por
você: nenhuma máquina, nenhum shell no navegador, nenhuma conta de nuvem emprestada. O que você
precisa é pouco, é gratuito, e nada pede cartão:

- **a linha de comando da AWS**, versão 2, o programa `aws`;
- **o moto**, instalado pelo instalador de pacotes do Python num diretório só dele;
- Python 3, `curl`, `jq` e `unzip`, que o Ubuntu fornece.

As aulas 12 e 13 acrescentam três programas próprios, Terraform, Checkov e pip-audit, e cada uma
dessas aulas instala o que usa antes do primeiro comando.

**Se você fez o `aws-foundations`, já tem este laboratório.** É o mesmo diretório, `~/aws`, as mesmas
versões e as mesmas configurações, e você pode ir direto à seção depois da próxima para conferir que
ele ainda responde. Se fez só o curso `cloud`, o moto dele morava em `~/cloud` e escutava na porta
5000; este é novo, e os dois não se atrapalham.

As aulas foram gravadas no **Ubuntu 24.04**, e há três jeitos de ter um terminal nele.

| | o que é | quanto custa ao seu computador |
|---|---|---|
| **instalado** (recomendado) | as ferramentas no seu próprio sistema: o próprio Ubuntu 24.04, ou o Ubuntu 24.04 no WSL do Windows | uns 600 MB de disco na aula 1 e uns 2 GB da aula 12 em diante, e 80 MB de memória ou mais enquanto o moto roda |
| uma máquina virtual | Ubuntu Server 24.04 num hipervisor, em qualquer sistema | 2 processadores, 2 GB de memória e 10 GB de disco enquanto roda |
| online | um shell Linux alugado no navegador | nada no seu computador; uma conta com alguém, e um limite de quanto tempo dura |

**Instale, a menos que você use um Mac.** No Linux é o terminal que você já tem. No Windows, o WSL
roda um Ubuntu de verdade ao lado do Windows: `wsl --install -d Ubuntu-24.04` num PowerShell de
administrador o instala, e o item Ubuntu do menu Iniciar abre o terminal dele. Nada que este curso
instala é um serviço ou muda uma configuração do sistema. Fora cinco pacotes do repositório do
Ubuntu, tudo fica em `~/aws` e `~/.local`, e apagar os dois desfaz tudo.

**Uma máquina virtual** é o caminho no Mac, e em qualquer computador em que você prefira não mexer. A
linha de comando da AWS e o moto rodam no macOS, mas as transcrições foram gravadas no Ubuntu, e as
mensagens do próprio sistema seriam diferentes. Instale o Ubuntu Server 24.04 no hipervisor que o
seu sistema oferece: Hyper-V ou VirtualBox no Windows, UTM num Mac com Apple silicon, GNOME Boxes ou
virt-manager no Linux. O Multipass, da Canonical, faz isso com um comando nos três:
`multipass launch 24.04 --name cloudsec --cpus 2 --memory 2G --disk 10G`, e depois
`multipass shell cloudsec`. **Esses dois comandos não foram executados para este curso**, porque a
máquina em que ele foi gravado não roda hipervisor; tudo depois deles foi.

**Online** quer dizer um shell que o computador de outra pessoa roda para você, como o GitHub
Codespaces ou uma pequena máquina Linux alugada por hora. Funciona, porque o curso precisa só de um
shell que alcance a internet para baixar as ferramentas. **Nenhuma aula depende da cota gratuita de
uma empresa**, porém: cada uma tem suas horas e seus termos, e eles mudam. O AWS CloudShell, o shell
dentro do console da AWS, não serve, porque exige a conta AWS que este curso foi feito para
dispensar.

## Dois terminais

O laboratório são dois programas conversando, então ele pede **duas janelas de terminal** lado a
lado, ou duas abas de uma:

- a primeira roda o **moto** e imprime uma linha para cada requisição que chega a ele;
- a segunda é onde você digita os comandos `aws`, e onde todas as transcrições destas aulas foram
  feitas.

**Mantenha a primeira à vista.** Ela é o mais perto que este laboratório tem de um log de auditoria,
e a aula 15 volta a ela exatamente por isso: toda requisição que você envia aparece ali, com a hora e
a resposta que recebeu.

O moto esquece tudo quando para. Isso é útil num curso de segurança, em que você vai passar seções
inteiras piorando uma conta de propósito: parar o moto joga o estrago fora, e a próxima aula começa
de uma AWS vazia. Cada aula diz o que criar antes do primeiro comando.
