---
title: Um modelo no seu próprio computador
version: 2
---

Nada neste curso roda numa máquina nossa. **Você roda um modelo de linguagem no seu próprio
computador, com o Ollama, e todo programa do curso conversa com ele.** O Ollama é um programa
gratuito que baixa modelos abertos e responde a pedidos para eles na sua máquina, no mesmo formato
que os grandes fornecedores usam, então o código que você escreve aqui é o código que escreveria
contra eles. Ele não pede conta nem cartão.

Toda transcrição do curso foi gravada assim. A máquina roda Ubuntu 24.04 em quatro núcleos de
processador e 15 GB de memória, sem placa de vídeo, com um usuário chamado `ana` e o nome `dev`. O
Ollama 0.40.0 serve o **`llama3.2:3b`**, o Llama 3.2 da Meta com três bilhões de parâmetros, que
escreve as respostas. O seu prompt vai ter o seu nome.

O assistente deste curso pergunta ao modelo com **temperatura 0**, o que o faz escolher sempre a
palavra mais provável, então num mesmo computador a mesma pergunta recebe a mesma resposta. No seu
ela pode sair com outras palavras, e de vez em quando vai ser outra resposta: a aritmética por baixo
arredonda de outro jeito noutro processador. O que cada aula pede para você observar nas respostas vai
estar lá, e onde uma aula conta alguma coisa sobre muitas respostas, as suas contagens vão ficar
perto das da aula em vez de iguais a elas.

## Três jeitos de ter isso

| | o que é | o que custa ao seu computador |
| --- | --- | --- |
| **instalado** (recomendado) | Ollama e Python no computador que você usa todo dia: direto no Linux ou num Mac, e no Windows dentro do WSL, a camada Linux da Microsoft | uns 4,5 GB de disco para o Ollama, os dois modelos e as primeiras bibliotecas, e algumas centenas de megabytes a mais conforme as aulas seguintes acrescentam as delas; 2,9 GB de memória enquanto o modelo responde, devolvidos alguns minutos depois da última pergunta |
| numa máquina virtual | Ubuntu Server 24.04 LTS no VirtualBox no Windows ou no Linux, no UTM num Mac, ou no Hyper-V no Windows Pro, com os mesmos passos lá dentro | a fatia da própria VM, reservada enquanto ela roda: 4 núcleos, 8 GB de memória e 30 GB de disco; e o modelo roda só no processador, porque uma VM não enxerga a placa de vídeo |
| online | uma chave de API paga da OpenAI, e os mesmos programas com as variáveis e os nomes de modelo trocados | Python e as bibliotecas, algumas centenas de megabytes, mas nenhum modelo; e **dinheiro**, por token, de um cartão que você cadastra no fornecedor |

**Instalado é a recomendação porque um modelo quer todo o computador que conseguir.** Uma máquina
virtual pega uma fatia fixa da memória e esconde a placa de vídeo, que muitas vezes é o que deixa um
modelo rápido: num Mac com Apple silicon ou com uma placa NVIDIA, o Ollama a usa sem ninguém pedir. E
o Ollama fica no canto dele. É um programa, um serviço e um diretório de modelos, e removê-lo remove
os três.

**A máquina virtual é o caminho se você prefere deixar o seu sistema intocado.** Dê a ela pelo menos
os tamanhos da tabela; com menos de 8 GB de memória o modelo e o Ubuntu brigam por ela. Os passos da
próxima seção então rodam dentro da VM, exatamente como estão escritos.

**Online funciona para a maior parte do curso, e é o único caminho daqui que custa dinheiro.** Os
programas usam o SDK da OpenAI e leem o endereço e a chave de duas variáveis, que a próxima seção
define para o Ollama. Deixe o endereço de fora e defina a sua própria chave, e eles conversam com a
OpenAI. Dois nomes mudam também: o modelo de chat no `releases.json`, e o modelo de embeddings no
`index.py`, onde o `text-embedding-3-small` da OpenAI toma o lugar do `all-minilm`. Toda similaridade
do curso então sai diferente, e o piso do `releases.json` tem de ser escolhido de novo; a aula 5
mostra como. Defina um limite de gastos no console do fornecedor antes do primeiro pedido. **Nenhuma
aula depende de uma franquia gratuita de fornecedor**; pode existir uma quando você ler isto, e ela é
do fornecedor para mudar.

As aulas 6 e 7 também rodam o Docker, para as ferramentas de trace cujas telas elas mostram. A aula 6
diz o que isso acrescenta, e as duas aulas podem ser lidas sem ele.

## Quanto computador basta

O modelo recomendado quer **8 GB de memória no computador inteiro**, para que 2,9 GB possam ir para
o modelo enquanto o navegador e o editor ficam com o resto. Com 4 GB, ou numa máquina velha em que
toda resposta se arrasta, use o modelo menor da mesma família:

```sh
ollama pull llama3.2:1b
```

```
ana@dev:~$ ollama run llama3.2:1b "Say hello to a customer in one short sentence."
"Hello, how can I assist you today?"
ana@dev:~$ ollama ps
NAME           ID              SIZE      PROCESSOR          CONTEXT    RUNNER      UNTIL              
llama3.2:1b    baf6a787fdff    2.0 GB    25%/75% CPU/GPU    4096       llamacpp    4 minutes from now    
llama3.2:3b    a80c4f17acd5    2.9 GB    30%/70% CPU/GPU    4096       llamacpp    4 minutes from now    
ana@dev:~$ ollama list
NAME                 ID              SIZE      MODIFIED       
llama3.2:1b          baf6a787fdff    1.3 GB    7 seconds ago     
all-minilm:latest    1b226e2802db    45 MB     29 seconds ago    
llama3.2:3b          a80c4f17acd5    2.0 GB    33 seconds ago    
```

Ele tem 1,3 GB para baixar e ocupa 2,0 GB na memória. Também é mais rápido, e as respostas dele são
piores: segue instruções com menos cuidado, como mostram as aspas que pôs em volta do olá, e inventa
mais coisas. Pedindo a cada modelo as mesmas duas frases, e lendo a própria contagem do Ollama de
quanto tempo a escrita levou:

```
ana@dev:~$ curl -s http://127.0.0.1:11434/api/generate -d '{"model": "llama3.2:3b", "prompt": "Explain in two sentences what a gift card is.", "stream": false}' | python3 -c 'import json, sys; r = json.load(sys.stdin); print(r["eval_count"], "tokens in", round(r["eval_duration"] / 1e9, 1), "seconds")'
66 tokens in 6.2 seconds
ana@dev:~$ curl -s http://127.0.0.1:11434/api/generate -d '{"model": "llama3.2:1b", "prompt": "Explain in two sentences what a gift card is.", "stream": false}' | python3 -c 'import json, sys; r = json.load(sys.stdin); print(r["eval_count"], "tokens in", round(r["eval_duration"] / 1e9, 1), "seconds")'
85 tokens in 2.3 seconds
```

Uns 11 tokens por segundo contra 37, em quatro núcleos. O ponto de cada aula ainda aparece com o
modelo menor, embora as contagens das aulas seguintes fiquem mais longe das da aula. Para usá-lo,
escreva `llama3.2:1b` no `releases.json` onde estiver `llama3.2:3b`.

A semana de tráfego da aula 3 é a espera mais longa do curso: umas trezentas perguntas, que a máquina
da gravação respondeu em dezoito minutos com o modelo recomendado. Com uma placa de vídeo, conte com
uma fração disso.
