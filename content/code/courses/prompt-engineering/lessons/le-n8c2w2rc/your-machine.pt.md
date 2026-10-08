---
title: Sua máquina, e três jeitos de ter uma
version: 1
---

As duas seções antes desta leram o `toylm` em transcrições. Daqui em diante, rode os comandos
você mesmo. Engenharia de prompt se aprende como uma receita: mudando uma coisa e vendo o que saiu.
Esta seção prepara o computador, e a próxima monta o diretório em que toda lição trabalha.

A máquina precisa de três coisas:

- **um terminal Linux com Python 3 e Node.js**, para os programas pequenos que as lições imprimem
  inteiros: um modelo que dá para ler, um tokenizador de verdade, um verificador de esquema e mais
  alguns;
- **o Ollama**, um programa gratuito que roda um modelo de linguagem no seu próprio computador, sem
  conta e sem cartão;
- **um modelo para ele, o `llama3.2:3b`**: o Llama 3.2 da Meta com três bilhões de parâmetros,
  pequeno o bastante para um notebook comum. Todos os cursos de IA daqui usam o mesmo, então você o
  prepara uma vez só.

## Três jeitos de ter uma

| caminho | o que você ganha | quanto custa | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | Ubuntu 24.04 no seu computador, ou no WSL no Windows | uns 4 GB de disco, e 3 GB de memória enquanto o modelo responde | batem como impressas |
| **uma máquina virtual** | Ubuntu Server 24.04, separado do seu sistema | o mesmo, mais o sistema e a memória do próprio convidado | batem como impressas, mais devagar |
| **online** | uma máquina Linux alugada por hora | nada no seu computador; uma conta por hora | parecidas, não iguais |

**Instalado é o caminho recomendado**, o contrário do que diz a maioria dos cursos daqui, e o motivo
é o modelo. Ele é de longe a coisa mais pesada do curso, e roda mais rápido no computador sem nada
no meio. Uma máquina virtual fica com uma fatia fixa da memória e, na maioria dos hipervisores, não
alcança a placa de vídeo. O resto da preparação são dois pacotes comuns e um diretório na sua pasta
pessoal, e tudo isso sai depois sem deixar rastro.

- **No Linux**, rode os comandos abaixo. Eles rodaram no Ubuntu 24.04; outra distribuição tem os
  mesmos programas com outros nomes de pacote.
- **No Windows**, instale o WSL com o Ubuntu 24.04 (`wsl --install -d Ubuntu-24.04` num PowerShell
  aberto como administrador, depois reinicie) e digite tudo o que vem abaixo na janela do Ubuntu.
- **No macOS**, o Ollama tem um aplicativo próprio em ollama.com, e Python e Node.js vêm do Homebrew
  (`brew install python node`). Isso não foi rodado para este curso, então uma versão numa
  transcrição vai ser diferente da sua, e os programas funcionam do mesmo jeito.

**Uma máquina virtual** é o caminho para um computador em que você prefere não mexer. Use o Ubuntu
Server 24.04 LTS como convidado: VirtualBox no Windows e no Linux, UTM no macOS. Dê a ele pelo menos
6 GB de memória e 25 GB de disco, porque o modelo precisa de uns 3 GB dessa memória só para ele.
Espere respostas mais lentas do que fora dela.

**Online**, qualquer provedor de nuvem aluga uma máquina Linux por hora, e o GitHub Codespaces dá
uma no navegador. Escolha uma com pelo menos 8 GB de memória. Uma cota gratuita pode cobrir parte
do curso, em termos que a empresa define e pode mudar, então planeje como quem vai pagar. Isso não
foi rodado para este curso.

## Instalando

Tudo abaixo é digitado num terminal da máquina que você escolheu. Primeiro, os pacotes do próprio
Ubuntu:

```sh
sudo apt-get update
sudo apt-get install -y python3-venv nodejs npm curl zstd
```

Depois o Ollama, com o instalador que os autores dele publicam. Ele põe o programa em `/usr/local`
e o transforma num serviço que sobe junto com a máquina:

```sh
curl -fsSL https://ollama.com/install.sh | sh
```

Depois o modelo. Isto baixa 2,0 GB, uma vez:

```sh
ollama pull llama3.2:3b
```

Confira o que você tem:

```
ana@lab:~$ python3 --version; node --version; ollama --version
Python 3.12.3
v18.19.1
ollama version is 0.40.0
ana@lab:~$ ollama list
NAME           ID              SIZE      MODIFIED    
llama3.2:3b    a80c4f17acd5    2.0 GB    2 hours ago    
ana@lab:~$ ask "Say hello in three words." --temperature 0 --plain
Hello there friend.
ana@lab:~$ ollama ps
NAME           ID              SIZE      PROCESSOR          CONTEXT    RUNNER      UNTIL              
llama3.2:3b    a80c4f17acd5    2.9 GB    30%/70% CPU/GPU    4096       llamacpp    4 minutes from now    
ana@lab:~$ du -sh /usr/local/lib/ollama
2.1G	/usr/local/lib/ollama
```

`ollama list` é o que está no disco, e `ollama ps` é o que está na memória: o modelo é carregado na
primeira vez que alguém lhe faz uma pergunta, ocupa **2,9 GB** enquanto está carregado, e é
descarregado cinco minutos depois da última pergunta. Esse é o número para comparar com o seu
computador. O programa em si ocupou mais 2,1 GB, quase tudo bibliotecas para placas de vídeo
NVIDIA, que ele usa se houver uma.

A coluna `PROCESSOR` diz onde o trabalho rodou. O computador em que estas lições foram gravadas não
tem placa de vídeo, e o Ollama contou a unidade de matrizes do próprio processador como um
acelerador, por isso não aparece `100% CPU`. No seu aparece `100% CPU`, ou a fatia que a sua placa de
vídeo assumiu.

O `ask` é um programa que a próxima seção lhe dá. Até lá, `ollama run llama3.2:3b` abre uma conversa
com o modelo no terminal; digite uma pergunta, e Ctrl+D sai.

### Com menos memória

Num computador com 8 GB de memória ou menos, use o modelo menor da mesma família:

```sh
ollama pull llama3.2:1b
```

Ele baixa 1,3 GB e ocupou 2,0 GB de memória na mesma máquina. As respostas dele são visivelmente
piores, o que é uma lição por si só, e vão diferir mais das transcrições daqui. A próxima seção diz
como fazer o `ask` usá-lo.

### Com uma chave de API

O outro caminho é um modelo pago, de um provedor que você escolher. O `ask` fala o mesmo protocolo
que a maioria deles serve, chamado chat completions, e três variáveis no `~/.bashrc` o apontam para
outro lugar: `ASK_URL`, o endereço da API do provedor; `ASK_MODEL`, o nome do modelo lá; e `ASK_KEY`,
a sua chave. A documentação do provedor dá as duas primeiras. Cada pedido custa dinheiro, e a lição 3
mostra como calcular quanto antes de mandar qualquer coisa. **Nada no curso precisa disso.** O
modelo local basta para terminar todas as lições.
