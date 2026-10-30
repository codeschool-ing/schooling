---
title: Quando a instalação falha
version: 1
---

É aqui que um curso costuma ser abandonado, num erro sobre uma ferramenta que o aluno ainda não
terminou de instalar. Estas são as falhas encontradas enquanto esta lição foi gravada, na ordem em que
a instalação as encontra, e o que cada uma quer dizer. **Três delas foram produzidas de propósito e
estão citadas como a máquina as imprimiu; as outras são descritas, e cada uma diz por quê.**

**O ambiente virtual não foi criado.** O Ubuntu entrega o Python sem a parte que cria ambientes
virtuais. O `python3 -m venv` então para com uma mensagem que começa por *The virtual environment was
not created successfully because ensurepip is not available* e cita o pacote a instalar. O remédio é
`sudo apt-get install -y python3-venv`, o pacote que o primeiro bloco da instalação instala. A
tentativa que falhou deixa para trás um `~/azure/venv` feito pela metade, então remova-o com
`rm -rf ~/azure/venv` e rode o segundo bloco de novo. **Esta não foi produzida aqui**, porque a
máquina onde as lições foram gravadas tem o pacote e a falha precisa dele ausente.

**O `apt-get` diz que não conseguiu uma trava.** O Ubuntu instala as próprias atualizações nos
primeiros minutos depois que uma máquina liga, e só um programa por vez pode instalar pacotes. Espere
alguns minutos e rode o comando de novo. Apagar o arquivo de trava é o conselho que você vai achar na
internet, e é assim que um banco de pacotes se estraga.

**O `pip` para no meio com um erro de rede.** A CLI do Azure são uns cem pacotes, buscados um depois
do outro, e uma conexão que cai no meio para a instalação inteira. Rode a mesma linha do `pip` de
novo: o que ele já buscou fica guardado, e ele continua de onde parou.

**O `az` não é encontrado.** As ferramentas estão instaladas e este terminal não sabe onde:

```
ana@laptop:~$ az version
bash: line 1: az: command not found
```

Todo terminal novo começa fora do ambiente virtual e sem o `~/.local/bin` no caminho. O
`source ~/azure/env.sh` devolve os dois, e a mesma linha conserta um `terraform` que não é
encontrado. Num Ubuntu com interface gráfica a mensagem pode sugerir instalar o `azure-cli` de um
pacote. Ignore: a versão de que o curso precisa já está em `~/azure/venv`.

**O Terraform não executa.** O arquivo zip era o de outro processador:

```
ana@laptop:~/azure$ terraform version
bash: line 1: /home/ana/.local/bin/terraform: cannot execute binary file: Exec format error
```

*Exec format error* quer dizer que o arquivo é um programa para outro tipo de processador, e o shell
não consegue rodá-lo de jeito nenhum. Acontece numa máquina Arm que recebeu o arquivo `amd64` e num PC
comum que recebeu o `arm64`. O `uname -m` diz qual é o seu: `x86_64` leva o `amd64`, `aarch64` leva o
`arm64`. Baixe o zip certo e desempacote-o por cima do errado com o terceiro bloco.

**O `az bicep install` não consegue baixar.** O compilador do Bicep vem de
`downloads.bicep.azure.com`, e uma rede que bloqueia esse endereço, como algumas redes de empresa e
de universidade, deixa o comando esperando e depois falhando com um erro de conexão. **Esta não foi
produzida aqui**, porque a máquina de gravação alcança o endereço. A Microsoft também publica o mesmo
arquivo no GitHub, nas releases do repositório `Azure/bicep`, como `bicep-linux-x64`: baixe-o lá,
torne-o executável com `chmod +x` e ponha-o em `~/azure/.azure/bin/bicep`, que é onde a CLI do Azure
procura.

**Um comando pede para você fazer login.** Tudo o que precisa do próprio Azure recusa na hora:

```
ana@laptop:~/azure$ az group list
ERROR: Please run 'az login' to setup account.
```

**Isto não é uma falha do laboratório; é o laboratório.** Listar grupos de recursos quer dizer
perguntar ao Resource Manager, o Resource Manager precisa de uma identidade logada, e este curso nunca
faz login. A CLI consultou a própria memória, não achou ninguém e parou sem mandar pedido nenhum. Onde
uma lição mostra um comando como este, ela o mostra para ser lido, e diz isso.

**Não rode `az login` para a mensagem sumir.** Sem conta, ele abre um navegador na página de login da
Microsoft, que oferece criar uma. Com conta, a CLI do laboratório ficaria logada nela, e o próximo
comando digitado de uma lição rodaria contra uma assinatura de verdade. A seção depois desta diz como
manter as duas separadas, se você quiser ter as duas.

**Outra coisa.** Rode o mesmo comando de novo com `--debug` no fim, para a CLI do Azure, ou com
`TF_LOG=debug` na frente, para o Terraform. Os dois então imprimem cada passo que dão, e o erro quase
sempre está nas últimas dez linhas. Leia essas linhas antes de procurar a mensagem na internet,
porque a primeira página de resultados costuma ser sobre outra versão.
