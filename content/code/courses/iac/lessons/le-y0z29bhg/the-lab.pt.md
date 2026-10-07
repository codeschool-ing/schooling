---
title: O seu laboratório, e três jeitos de ter um
version: 2
---

A partir da aula 2, este curso pede que você digite. Aquilo em que você digita é **o seu
laboratório**: o seu próprio computador, ou um virtual dentro dele, rodando o Terraform, o AWS CLI e
uma AWS emulada. A plataforma não lhe dá máquina nenhuma. Estas últimas seções da aula 1 montam o
laboratório, e nada antes delas precisou dele, porque as transcrições desta aula são da Ana e estão
aqui para serem lidas.

**Não há conta de nuvem neste curso, e nada nele é cobrado.** A AWS com que o Terraform conversa é o
**moto**, o emulador que o curso de nuvem usou para o S3. É um programa em Python que responde às
APIs da AWS numa porta do seu computador, guarda na memória o que lhe dizem e esquece tudo quando
para. É uma imitação fiel da *API*: confere argumentos, inventa ids, lembra o que foi criado e
responde a perguntas sobre isso. Não roda máquina nenhuma nem carrega pacote nenhum. Uma instância
que ele lança é um registro com um id e um estado, que é exatamente o que o Terraform lê de volta;
então todo plan, apply, arquivo de estado e erro que você produzir é o que o Terraform produziria
contra a AWS. O que você não vai ver é um servidor web respondendo numa máquina que o Terraform
criou; as aulas 18 e 20, que precisam de máquinas que rodam, usam contêineres Docker no lugar, e a
aula 18 os constrói.

## Três caminhos

| | o que é | quanto custa ao seu computador |
|---|---|---|
| **uma máquina virtual** (recomendado) | Ubuntu Server 24.04 num hipervisor no seu computador | 2 processadores, 4 GB de memória e 25 GB de disco enquanto roda; um computador com 8 GB de memória a roda com folga |
| **instalado** | as ferramentas direto no Linux, no macOS, ou no Windows dentro do WSL 2 | cerca de 3 GB de disco até a aula 20, e uma dúzia de programas no seu próprio sistema |
| **online** | um ambiente de desenvolvimento na nuvem, ou um pequeno servidor Linux alugado por hora | nada localmente; dinheiro, quando acabar o que é gratuito |

**A máquina virtual é a que este curso recomenda**, por três motivos. Toda transcrição dele foi
gravada no Ubuntu 24.04, então uma VM com o mesmo sistema imprime as mesmas linhas. Ao longo de vinte
aulas você instala cerca de uma dúzia de ferramentas, e numa VM elas vão para uma máquina que você
pode apagar, e não para aquela em que você trabalha. E a aula 18 roda três contêineres Docker como
servidores e os alcança pelos seus endereços, o que funciona dentro de uma VM Linux e não funciona
com o Docker Desktop no macOS ou no Windows, onde os contêineres vivem numa VM escondida do próprio
Docker.

Qual hipervisor depende do seu computador:

- **Windows**: o Hyper-V, que vem nas edições Pro, Enterprise e Education, ou o VirtualBox em
  qualquer edição.
- **macOS**: o UTM. Num Mac com Apple silicon, baixe a imagem ARM (`arm64`) do Ubuntu Server; toda
  ferramenta deste curso publica essa versão.
- **Linux**: o virt-manager, a janela na frente do libvirt e do QEMU, ou o VirtualBox.

Nos três, o **Multipass**, da Canonical, cria uma VM Ubuntu com um comando, sem instalador para ir
clicando: `multipass launch 24.04 --name iac --cpus 2 --memory 4G --disk 25G`, e depois
`multipass shell iac` para abrir um terminal nela. Seja qual for o que você usar, instale o sistema
com o OpenSSH quando o instalador oferecer, para poder trabalhar na VM a partir do terminal do seu
próprio computador.

**Instalado** é a escolha certa se você já trabalha no Linux ou no WSL 2, e custa só disco. No macOS
os comandos de pacote são outros, a próxima seção diz quais, e a aula 18 precisa da VM de qualquer
jeito, pelo motivo do Docker acima.

**Online** quer dizer um ambiente de desenvolvimento na nuvem, como o GitHub Codespaces ou o Gitpod,
ou um pequeno servidor Linux de qualquer provedor. Os dois rodam Ubuntu, e os passos da próxima
seção funcionam neles sem mudança. Cada um vem com algumas horas ou algum crédito gratuito, e as
condições disso são do provedor e mudam; **nenhuma aula deste curso precisa de nenhum deles**, então
trate-os como uma comodidade pela qual você talvez pague, e nunca como um requisito.

**E uma conta real da AWS é opcional.** As configurações destas aulas são escritas para a AWS, e
apontá-las para ela é questão de desfazer uma variável, o que as próximas seções mostram. A partir
daí, todo `apply` cria algo que custa dinheiro até um `destroy` removê-lo, e a aula 16 é sobre esse
custo.
