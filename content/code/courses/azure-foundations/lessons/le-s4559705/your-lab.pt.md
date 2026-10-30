---
title: O seu laboratório, no seu próprio computador
version: 1
---

**Todo comando deste curso é um que você digita no seu próprio computador.** A plataforma não roda
nada por você: nenhuma máquina, nenhum shell no navegador, nenhuma conta do Azure emprestada. O que
você precisa é pouco, e nada disso custa dinheiro ou pede cartão:

- **a CLI do Azure**, o programa `az`, que a Microsoft publica como pacote Python, instalada num
  diretório só dela;
- **a CLI do Bicep**, que a CLI do Azure baixa para você na primeira vez;
- **Terraform**, um programa da HashiCorp, e os providers que ele baixa quando uma lição pede;
- Python 3, `curl`, `jq`, `unzip` e `dig`, que o Ubuntu fornece.

As lições foram gravadas no **Ubuntu 24.04**, e há três jeitos de ter um terminal nele.

| | o que é | o que custa ao seu computador |
|---|---|---|
| **instalado** (recomendado) | as ferramentas no seu próprio sistema: o próprio Ubuntu 24.04, ou o Ubuntu 24.04 no WSL do Windows | cerca de 1,1 GB de disco quando tudo estiver instalado; nada roda em segundo plano |
| uma máquina virtual | Ubuntu Server 24.04 num hipervisor, em qualquer sistema | 2 processadores, 2 GB de memória e 10 GB de disco enquanto roda |
| online | um shell Linux alugado no navegador | nada no seu computador; uma conta com alguém, e um limite de quanto tempo dura |

**Instale, a não ser que você use Mac.** No Linux é o terminal que você já tem. No Windows, o WSL roda
um Ubuntu de verdade ao lado do Windows: `wsl --install -d Ubuntu-24.04` num PowerShell de
administrador o instala, e o item Ubuntu do menu Iniciar abre o terminal dele. Nada que este curso
instala é um serviço ou muda as configurações do seu sistema. Fora seis pacotes do arquivo do Ubuntu,
tudo mora em `~/azure`, `~/.local/bin` e `~/.terraform.d`, e apagá-los desfaz tudo.

**Uma máquina virtual** é o caminho no Mac, e em qualquer computador que você prefira não mexer. A
CLI do Azure, o Bicep e o Terraform rodam no macOS, mas as transcrições foram gravadas no Ubuntu, e as
mensagens do próprio sistema não iam bater. Instale o Ubuntu Server 24.04 no hipervisor que o seu
sistema oferece: Hyper-V ou VirtualBox no Windows, UTM num Mac com Apple silicon, GNOME Boxes ou
virt-manager no Linux. O Multipass, da Canonical, faz o mesmo com um comando nos três:
`multipass launch 24.04 --name azure --cpus 2 --memory 2G --disk 10G`, depois `multipass shell azure`.
**Esses dois comandos não foram executados para este curso**, porque a máquina onde ele foi gravado
não roda hipervisor; tudo depois deles foi.

**Online** é um shell que o computador de outra pessoa roda para você, como o GitHub Codespaces, ou
qualquer máquina Linux pequena alugada por hora. Funciona, porque o curso não precisa de nada além de
um shell que alcance a internet, para baixar as ferramentas e para perguntar aos poucos serviços
públicos que as lições perguntam. **Nenhuma lição depende da cota gratuita de uma empresa**, porém, e
cada uma tem as suas horas e as suas condições, que mudam. O Cloud Shell do próprio Azure, um
terminal no portal do Azure com o `az` já dentro, não serve para este curso: ele precisa de uma conta
do Azure, e a ideia é você nunca precisar de uma. A lição 24 diz para que ele serve.

## Um terminal, e nada rodando

Um laboratório que imitasse uma nuvem deixaria essa imitação rodando numa segunda janela. **Este
laboratório não tem com que imitar o Azure, então precisa de um terminal e de nada em segundo
plano.** Cada ferramenta começa quando você digita o nome dela e para quando terminou de responder.

O que o laboratório lembra entre uma sessão e outra é pouco e mora em arquivos: as configurações da
CLI do Azure em `~/azure/.azure`, os providers do Terraform em `~/.terraform.d`, e os arquivos Bicep
e Terraform que uma lição pedir para você escrever, cada um num diretório próprio dentro de `~/azure`.
Cada lição diz qual diretório criar antes do primeiro comando, e apagar esse diretório recomeça a
lição.

Seja qual for o caminho, a próxima seção começa no mesmo lugar: um terminal no Ubuntu 24.04, com você
logado como você mesmo. A seção depois dela, sobre falhas, é a que se lê quando um comando não
responde do jeito que a transcrição mostra.
