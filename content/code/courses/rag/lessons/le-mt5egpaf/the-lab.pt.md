---
title: A máquina em que você vai digitar
version: 2
---

Nada neste curso roda numa máquina nossa. **Você monta uma máquina Linux com um modelo de linguagem,
um modelo de embeddings e um banco de dados, e desta seção em diante todo comando é digitado nela.**
Toda transcrição do curso foi gravada numa assim: Ubuntu 24.04, um usuário chamado `ana` e uma
máquina chamada `vm`. O seu prompt vai trazer os seus próprios nomes.

Quem está no teclado nas transcrições é a ana, desenvolvedora na Marginalia, uma livraria online que
não existe. Este curso constrói o assistente que responde aos clientes da Marginalia a partir dos
documentos da própria loja.

## O que roda nela

| | o que é | por que este |
| --- | --- | --- |
| **Ollama** | um programa que baixa modelos abertos e os serve na sua própria máquina, na porta 11434 | grátis, sem conta e sem cartão, e fala o mesmo formato da API da OpenAI e da Anthropic, então os SDKs das próprias empresas conversam com ele sem mudança |
| **llama3.2:3b** | o Llama 3.2 da Meta com três bilhões de parâmetros, o modelo que escreve toda resposta | pequeno o bastante para rodar sem placa de vídeo, bom o bastante para responder a partir de uma fonte e citá-la |
| **all-minilm** | o all-MiniLM-L6-v2, o modelo de embeddings que o `embeddings-vectors` usou, servido pelo Ollama | 384 números por texto, e rápido em qualquer processador |
| **PostgreSQL 16 com pgvector** | o banco que guarda os trechos e seus vetores, da aula 5 em diante | o Ubuntu empacota os dois, e é o banco que o `embeddings-vectors` usou |
| **Python 3.12** | a linguagem de todo programa, num ambiente virtual só dele | o Ubuntu 24.04 já traz |

**Toda resposta deste curso veio do llama3.2:3b nessa máquina, e a sua vai ter outras palavras.** Um
modelo escolhe cada palavra com alguma aleatoriedade. Os programas aqui pedem `temperature=0`, que
tira quase toda ela, então o mesmo programa rodado duas vezes na mesma máquina em geral imprime a
mesma resposta. Nem sempre: o Ollama reaproveita o trabalho de uma requisição anterior que começou do
mesmo jeito, e uma conta que segue outro caminho pode mudar uma palavra, e todas as palavras depois
dela. Outro processador, outra versão do Ollama ou outro modelo mudam mais. O que uma
aula tira de uma resposta é um padrão: uma citação que está lá ou falta, um número citado ou um
número inventado. É o padrão que você procura na sua.

## Três jeitos de ter a máquina

| | o que é | quanto custa ao seu computador |
| --- | --- | --- |
| **uma máquina virtual** (recomendado) | Ubuntu Server 24.04 LTS numa VM criada com o Multipass, com tudo instalado dentro dela | 4 processadores, 8 GB de memória e 30 GB de disco enquanto ela roda; no seu sistema, só o hipervisor |
| instalado | os mesmos comandos num computador que já roda Ubuntu 24.04; ou o instalador do próprio Ollama para Windows ou macOS, ao lado de PostgreSQL e Python instalados à mão | o mesmo disco, e a memória do modelo sai do que você usa para todo o resto |
| online | uma máquina virtual alugada de um provedor de nuvem, ou um GitHub Codespace | nada no seu computador; um preço por hora, ou uma cota mensal que a empresa que oferece decide, e nenhuma placa de vídeo, então é tão lento quanto uma VM |

**A máquina virtual tem o mesmo formato da máquina de onde vieram as transcrições**, então quando a
sua saída difere da aula, a diferença é do modelo e não da instalação. Ela também é descartável: um
banco apagado sem querer na aula 14 não custa nada que os comandos abaixo não possam repor.

**Instalado é mais rápido se o seu computador tiver placa de vídeo.** O Ollama no Windows, no macOS
com Apple silicon e no Linux usa a placa quando a encontra, e uma resposta que leva segundos numa VM
chega quase na hora. No Ubuntu 24.04 os comandos abaixo são tudo. No Windows ou no macOS, instale o
Ollama pelo ollama.com, e o PostgreSQL com pgvector e o Python 3.12 pelos instaladores deles; o resto
do curso é igual.

**Online fica citado para você saber que existe, não recomendado.** Toda aula precisa do modelo, o
modelo precisa de vários gigabytes de memória, e uma cota grátis grande o bastante para isso é uma
decisão que uma empresa toma e pode mudar. Nenhuma aula aqui depende de uma.

## A máquina virtual

Instale o Multipass pelo site da Canonical. Ele usa um hipervisor que o sistema já tem: Hyper-V no
Windows, ou VirtualBox nas edições sem Hyper-V; QEMU sobre o hipervisor da própria Apple no macOS; e
QEMU com KVM no Linux. Depois, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name vm --cpus 4 --memory 8G --disk 30G
multipass shell vm
```

**Esses dois comandos não foram rodados para este curso**, porque a máquina em que ele foi gravado é
ela mesma uma máquina virtual e não consegue iniciar outra. O primeiro cria a VM e o segundo abre um
shell dentro dela. Tudo daqui em diante acontece nesse shell. Qualquer outro hipervisor serve no
lugar do Multipass, VirtualBox, UTM num Mac com Apple silicon, Hyper-V ou GNOME Boxes, com um
instalador do Ubuntu Server 24.04 LTS e os mesmos tamanhos. Custa meia hora de telas de instalação em
vez de um comando.

## Os pacotes, e o Ollama

```sh
sudo apt-get update
sudo apt-get install -y zstd python3-venv postgresql-16 postgresql-16-pgvector
curl -fsSL https://ollama.com/install.sh | sh
```

As duas primeiras linhas instalam o banco, a extensão de vetores dele, os ambientes virtuais do
Python e o `zstd`, de que o instalador do Ollama precisa para se descompactar e que ele não instala.
A terceira é o instalador do próprio Ollama, do site do Ollama: ele põe o `ollama` em
`/usr/local/bin` e o inicia como serviço. Leia um script antes de mandá-lo para um shell. Este tem
algumas centenas de linhas e diz o que cada passo faz.

Depois, os dois modelos. O primeiro é um download de dois gigabytes:

```sh
ollama pull llama3.2:3b
ollama pull all-minilm
```

## O banco de dados

```sh
sudo -u postgres createuser --superuser $USER
createdb rag
psql -d rag -c "CREATE EXTENSION vector"
```

O PostgreSQL só conhece o próprio administrador, `postgres`, até você dar a ele um papel com o nome
do seu login. Superusuário é demais para qualquer coisa que não seja uma máquina sua. Aqui é o que
deixa a aula 14 criar os papéis com que ela testa.

## O diretório de trabalho

Tudo o que o curso escreve fica em `~/rag`, com um Python só dele:

```sh
mkdir ~/rag && cd ~/rag
python3 -m venv .venv
```

Salve o próximo bloco como `~/rag/requirements.txt`. Ele lista toda biblioteca que uma aula importa,
na versão com que as transcrições foram gravadas:

```
# requirements.txt: the libraries this course imports, at the versions it was recorded with
numpy==2.4.6
tiktoken==0.14.0
psycopg[binary]==3.3.6
pgvector==0.3.6
openai==2.54.0
anthropic==1.11.0
rank-bm25==0.2.2
langchain-core==1.6.6
langchain-text-splitters==1.1.3
langchain-openai==1.6.7
langchain-postgres==0.0.18
llama-index-core==0.14.25
llama-index-embeddings-openai==0.7.0
llama-index-llms-openai==0.8.2
llama-index-llms-openai-like==0.8.1
haystack-ai==3.3.0
```

E este como `~/rag/env.sh`. Todo programa do curso encontra o modelo e o banco por ele:

```sh
# env.sh: where this course's programs find the model and the database
. ~/rag/.venv/bin/activate
export OPENAI_BASE_URL=http://localhost:11434/v1
export OPENAI_API_KEY=ollama
export ANTHROPIC_BASE_URL=http://localhost:11434
export ANTHROPIC_API_KEY=ollama
export PGDATABASE=rag
export HAYSTACK_TELEMETRY_ENABLED=False
```

As duas URLs base mandam o SDK da OpenAI e o da Anthropic para o Ollama em vez dos servidores das
empresas. O Ollama ignora as chaves, e os SDKs se recusam a começar sem uma, então cada um ganha uma
palavra. A última linha impede o Haystack, o framework da aula 11, de mandar dados de uso para quem o
faz. Depois:

```sh
. ./env.sh
pip install -r requirements.txt
echo '. ~/rag/env.sh' >> ~/.bashrc
```

A última linha roda o `env.sh` em todo terminal que você abrir daqui em diante. A instalação leva
alguns minutos e uns 400 MB.

## Um módulo que toda aula importa

O modelo de embeddings é chamado pelo mesmo SDK que o gerador. O `vectors.py` embrulha essa chamada
para que o resto do curso possa escrever `embed(textos)` e receber números que dá para multiplicar.
Salve como `~/rag/vectors.py`:

```schooling-example
{
  "language": "python",
  "file": "vectors.py",
  "parts": [
    {
      "code": "\"\"\"vectors: the embedding model, all-MiniLM-L6-v2, as Ollama serves it.\"\"\"\nimport numpy as np\nfrom openai import OpenAI\n\nMODEL = \"all-minilm\"\nclient = OpenAI()",
      "note": "O cliente lê `OPENAI_BASE_URL` do ambiente, então fala com o Ollama. `all-minilm` é o nome que o Ollama dá ao all-MiniLM-L6-v2."
    },
    {
      "code": "def embed(texts):\n    \"\"\"One unit-length vector of 384 numbers per text, as the rows of a matrix.\"\"\"\n    if isinstance(texts, str):\n        texts = [texts]\n    data = client.embeddings.create(model=MODEL, input=list(texts)).data\n    vectors = np.array([d.embedding for d in data], dtype=np.float32)\n    return vectors / np.linalg.norm(vectors, axis=1, keepdims=True)",
      "note": "Uma requisição para qualquer quantidade de textos. Todo vetor é dividido pelo próprio comprimento, então o produto de dois deles é a similaridade de cosseno, a medida que o `embeddings-vectors` usou do começo ao fim."
    }
  ]
}
```

## Conferindo se funciona

Quatro conferências, uma para cada peça. Se uma delas imprimir outra coisa, a seção depois da
próxima trata exatamente disso.

```
ana@vm:~/rag$ ollama list
NAME                 ID              SIZE      MODIFIED       
all-minilm:latest    1b226e2802db    45 MB     52 minutes ago    
llama3.2:3b          a80c4f17acd5    2.0 GB    52 minutes ago    
llama3.2:1b          baf6a787fdff    1.3 GB    55 minutes ago    
ana@vm:~/rag$ ollama run --nowordwrap llama3.2:3b "In one sentence, what are you?"
I'm an artificial intelligence model designed to provide information, answer questions, and engage in conversation to the best of my abilities, based on my training data and knowledge.

ana@vm:~/rag$ python -c "from vectors import embed; v = embed(\"hello\"); print(v.shape, round(float((v ** 2).sum()), 3))"
(1, 384) 1.0
ana@vm:~/rag$ psql -c "SELECT extversion FROM pg_extension WHERE extname = 'vector'"
 extversion 
------------
 0.6.0
(1 row)
```

O `ollama list` é o que está em disco: o gerador com 2,0 GB e o modelo de embeddings com 45 MB. A
máquina em que o curso foi gravado também tem o `llama3.2:1b`, menor, assunto da última parte desta
seção. O vetor tem 384 números e comprimento 1, que é o que o `vectors.py` prometeu. O banco tem o
pgvector 0.6.0.

```
ana@vm:~/rag$ ollama ps
NAME                 ID              SIZE      PROCESSOR    CONTEXT    RUNNER      UNTIL              
llama3.2:1b          baf6a787fdff    1.5 GB    100% CPU     4096       llamacpp    4 minutes from now    
all-minilm:latest    1b226e2802db    48 MB     100% CPU     256        llamacpp    4 minutes from now    
llama3.2:3b          a80c4f17acd5    2.6 GB    100% CPU     4096       llamacpp    4 minutes from now    
```

**O `ollama ps` é o que um modelo carregado ocupa de memória**: 2,6 GB para o llama3.2:3b, com o espaço
que o Ollama reserva para o prompt. A primeira requisição depois de uma pausa carrega o modelo, e por
isso essa resposta demora vários segundos a mais que a seguinte. Depois de cinco minutos sem
requisição, o Ollama descarrega o modelo e devolve a memória.

## Com menos, ou com uma chave

**Um computador com menos de 8 GB de memória** dá 6 à VM e usa o `llama3.2:1b`, com 1,5 GB de memória e
1,3 GB em disco: `ollama pull llama3.2:1b`, e troque o nome do modelo onde um programa o escreve. Ele
segue instruções com menos confiabilidade que o 3b. A metade de busca de toda aula é idêntica, porque
o modelo de embeddings é o mesmo.

**Com a sua própria chave de API paga**, todo programa deste curso roda contra um provedor: troque
`OPENAI_BASE_URL` e `OPENAI_API_KEY` no `env.sh`, e o nome do modelo no programa. A conta é sua, e
pequena no tamanho deste acervo. O modelo de embeddings é a única coisa que não deve ir junto. O modelo
de embeddings de um provedor faz vetores de outro comprimento, então mantenha o `all-minilm` no Ollama
dando ao `vectors.py` um cliente só dele, `OpenAI(base_url="http://localhost:11434/v1")`, ou troque
384 onde a aula 5 cria a tabela.
