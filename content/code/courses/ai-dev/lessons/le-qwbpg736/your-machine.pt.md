---
title: Um modelo no seu próprio computador
version: 2
---

Nada neste curso roda numa máquina nossa. **Você roda um modelo de linguagem no seu próprio
computador, com o Ollama, e todo programa do curso conversa com ele.** O Ollama é um programa
gratuito que baixa modelos abertos e responde a pedidos para eles na sua máquina, nos mesmos
formatos que os grandes provedores usam, então o código que você escreve aqui é o código que
escreveria contra eles. Ele não pede conta nem cartão.

Toda transcrição do curso foi gravada assim. A máquina roda Ubuntu 24.04 em quatro núcleos de
processador e 15 GB de memória, sem placa de vídeo, com um usuário chamado `ana` e o nome `dev`. O
Ollama 0.40.0 serve o **`llama3.2:3b`**, o Llama 3.2 da Meta com três bilhões de parâmetros. O seu prompt vai ter o seu nome. As respostas do modelo não vão bater com
as da aula palavra por palavra, nem num computador idêntico, e a seção 08 desta aula mostra por
quê; o que cada aula pede para você observar nelas vai estar lá.

## Três jeitos de ter isso

| | o que é | o que custa ao seu computador |
| --- | --- | --- |
| **instalado** (recomendado) | Ollama e Python no computador que você usa todo dia: direto no Linux ou num Mac, e no Windows dentro do WSL, a camada Linux da Microsoft | uns 4 GB de disco para o Ollama, o modelo e as bibliotecas; 2,6 GB de memória enquanto o modelo responde, devolvidos alguns minutos depois da última pergunta |
| numa máquina virtual | Ubuntu Server 24.04 LTS no VirtualBox no Windows ou no Linux, no UTM num Mac, ou no Hyper-V no Windows Pro, com os mesmos passos lá dentro | a fatia da própria VM, reservada enquanto ela roda: 4 núcleos, 8 GB de memória e 25 GB de disco; e o modelo roda só no processador, porque uma VM não enxerga a placa de vídeo |
| online | uma chave de API paga de um provedor como a Anthropic ou a OpenAI, e os mesmos programas com as variáveis trocadas | Python e as bibliotecas, mas nenhum modelo, então algumas centenas de megabytes; e **dinheiro**, por token, de um cartão que você cadastra no provedor |

**Instalado é a recomendação porque um modelo quer todo o computador que conseguir.** Uma máquina
virtual pega uma fatia fixa da memória e esconde a placa de vídeo, que muitas vezes é o que deixa
um modelo rápido: num Mac com Apple silicon ou com uma placa NVIDIA, o Ollama a usa sem ninguém
pedir. E o Ollama fica no canto dele. É um programa, um serviço e um diretório de modelos, e
removê-lo remove os três.

**A máquina virtual é o caminho se você prefere deixar o seu sistema intocado.** Dê a ela pelo
menos os tamanhos da tabela; com menos de 8 GB de memória o modelo e o Ubuntu brigam por ela. Os
passos da próxima seção então rodam dentro da VM, exatamente como estão escritos.

**Online funciona para a maior parte do curso, e é o único caminho daqui que custa dinheiro.** Os
programas leem o endereço e a chave do provedor de quatro variáveis (a próxima seção as define
para o Ollama), então você segue a próxima seção sem o Ollama, troca essas variáveis e o nome do
modelo, e mais nada. Defina um limite de gastos no console do provedor antes do primeiro pedido.
A aula 2 mostra quanto os pedidos custam, então você pode conferir a conta do curso com a sua
fatura. Algumas seções não dá para repetir assim, porque pedem ao Ollama algo que nenhuma API
hospedada entrega: as probabilidades que o modelo deu a cada próximo token, na seção 06 desta
aula, são uma delas. **Nenhuma aula depende de uma franquia gratuita de provedor**; pode existir
uma quando você ler isto, e ela é do provedor para mudar.

## Quanto computador basta

O modelo recomendado quer **8 GB de memória no computador inteiro**, para que 2,6 GB possam ir
para o modelo enquanto o navegador e o editor ficam com o resto. Com 4 GB, ou numa máquina velha
em que toda resposta se arrasta, use o modelo menor da mesma família:

```sh
ollama pull llama3.2:1b
```

```
ana@dev:~$ ollama run llama3.2:1b "Say hello to a developer in one short sentence."
Hello, how can I assist you today as a developer?
ana@dev:~$ ollama ps
NAME           ID              SIZE      PROCESSOR    CONTEXT    RUNNER      UNTIL              
llama3.2:1b    baf6a787fdff    1.5 GB    100% CPU     4096       llamacpp    4 minutes from now    
llama3.2:3b    a80c4f17acd5    2.6 GB    100% CPU     4096       llamacpp    4 minutes from now    
ana@dev:~$ ollama list
NAME           ID              SIZE      MODIFIED      
llama3.2:1b    baf6a787fdff    1.3 GB    7 minutes ago    
llama3.2:3b    a80c4f17acd5    2.0 GB    7 minutes ago    
```

Ele tem 1,3 GB para baixar e ocupa 1,5 GB de memória. Também é mais rápido, e as respostas são
piores: segue instruções com menos cuidado, como mostra o olá dele acima, e inventa mais coisas.
Pedindo a cada modelo as mesmas duas frases, e lendo a conta do próprio Ollama de quanto tempo a
escrita levou:

```
ana@dev:~$ curl -s http://127.0.0.1:11434/api/generate -d '{"model": "llama3.2:3b", "prompt": "Explain in two sentences what a unit test is.", "stream": false}' | python3 -c 'import json, sys; r = json.load(sys.stdin); print(r["eval_count"], "tokens in", round(r["eval_duration"] / 1e9, 1), "seconds")'
74 tokens in 7.0 seconds
ana@dev:~$ curl -s http://127.0.0.1:11434/api/generate -d '{"model": "llama3.2:1b", "prompt": "Explain in two sentences what a unit test is.", "stream": false}' | python3 -c 'import json, sys; r = json.load(sys.stdin); print(r["eval_count"], "tokens in", round(r["eval_duration"] / 1e9, 1), "seconds")'
78 tokens in 4.3 seconds
```

Uns 11 tokens por segundo contra 18, em quatro núcleos de processador. O ponto de cada aula
continua aparecendo no modelo menor. Para usá-lo, escreva `llama3.2:1b` onde um programa deste
curso disser `llama3.2:3b`.

A velocidade é o outro custo, e depende mais do seu computador que de qualquer coisa deste curso.
A 11 tokens por segundo, uma resposta de cem palavras leva uns doze segundos na máquina da
gravação. Com uma placa de vídeo, espere uma fração disso.
