---
title: Um token por vez
version: 2
---

Um modelo de linguagem faz uma coisa só, de novo e de novo: **dado o texto até ali, ele dá uma
probabilidade a cada próximo token possível.** Gerar uma resposta é um laço em volta desse único
passo: escolher um token, acrescentá-lo ao texto e perguntar de novo. Os parágrafos fluentes, o
código que funciona e as respostas erradas ditas com confiança saem todos do mesmo laço. Quase
tudo o que este curso ensina a controlar (custo, limites, streaming, alucinação) é consequência
dele.

::: track ai
Você desmontou esse mecanismo no `ai-models`, camada por camada. Esta aula é a versão curta com
que um desenvolvedor trabalha, e as aulas 6 e 7 comprimem o `rag` e o `agents-mcp` do mesmo jeito.
Leia essas três pelo código em volta do modelo, que é o que os cursos anteriores deixaram para
este, e passe rápido pelas explicações que você já tem.
:::

::: track *
Você não precisa da matemática de uma rede neural para trabalhar com uma, assim como não precisa
das entranhas de um compilador para escrever um programa. Precisa do laço, porque todo limite que
você vai encontrar neste curso é uma propriedade dele.
:::

## Pedindo ao modelo um passo só

As APIs dos grandes provedores devolvem o texto pronto e escondem o passo. O Ollama mostra: quando
você pede um token, ele pode devolver também os cinco candidatos mais bem avaliados e a
probabilidade de cada um, como logaritmo. O `~/shop/scratch/next.py` pede exatamente isso e
imprime as probabilidades em porcentagem:

```python
import json
import math
import sys
import urllib.request

# Ollama's own API rather than an SDK: it can return the probabilities the model
# gave each candidate for the next token, which no provider's API shows.
body = {"model": "llama3.2:3b", "prompt": sys.argv[1], "raw": True, "stream": False,
        "logprobs": True, "top_logprobs": 5, "options": {"num_predict": 1}}
request = urllib.request.Request("http://127.0.0.1:11434/api/generate", json.dumps(body).encode())
step = json.load(urllib.request.urlopen(request))["logprobs"][0]
for candidate in step["top_logprobs"]:
    print(f"{math.exp(candidate['logprob']):6.1%}  {candidate['token']!r}")
```

`"raw": True` manda o texto exatamente como está escrito. Sem isso, o Ollama embrulha o texto no
template de uma conversa, e o modelo responde a ele em vez de continuá-lo. Pergunte o que vem
depois de `Return the`:

```
ana@dev:~/shop$ python scratch/next.py "Return the"
  7.6%  ' sum'
  5.5%  ' number'
  2.5%  ' first'
  2.4%  ' value'
  2.1%  ' count'
```

Isso é uma distribuição de probabilidade, e esses são os seus cinco maiores itens. Juntos dão
mais ou menos um quinto; o resto se espalha fino pelos outros 128 mil tokens, mais ou menos, do
vocabulário deste modelo. Repare no espaço no começo de cada um: `' sum'` é um token só, que
inclui o espaço da frente, e a seção 07 volta a isso.

**Nada foi sorteado ainda**, então os seus números vão ficar perto destes. Não iguais: entre duas
execuções na máquina da gravação eles se moveram até três pontos, e a seção 08 volta a isso. Mude
o contexto e a distribuição muda junto:

```
ana@dev:~/shop$ python scratch/next.py "Return the number of"
 24.4%  ' elements'
  5.1%  ' nodes'
  4.6%  ' unique'
  4.1%  ' ways'
  3.4%  ' days'
ana@dev:~/shop$ python scratch/next.py "If the file does not"
 72.3%  ' exist'
 10.4%  ' have'
  7.4%  ' contain'
  1.2%  ' already'
  0.7%  ' open'
```

Depois de `If the file does not`, uma continuação leva quase três quartos da probabilidade, porque
o modelo leu a frase inteira e `exist` é o que essa frase quase sempre diz em seguida. Depois de
`Return the`, nada é tão claro, e o modelo divide as apostas. **As duas são o mesmo tipo de
saída**: uma nota para cada token, calculada a partir de tudo o que está no contexto. Um modelo
com janela de alguns milhares de tokens e um com um milhão produzem exatamente isso; a janela
maior só muda de quanto texto as notas são calculadas.

## O laço, e o que ele escreve

A geração repete o passo. O `~/shop/scratch/generate.py` pede ao Ollama que rode o laço inteiro
por um número de tokens, com os ajustes do sorteio de que trata a seção 08:

```python
import argparse
import json
import urllib.request

ap = argparse.ArgumentParser()
ap.add_argument("prompt")
ap.add_argument("--tokens", type=int, default=20)
ap.add_argument("--temperature", type=float, default=0.8)
ap.add_argument("--top-p", type=float, default=1.0)
ap.add_argument("--seed", type=int, default=1)
a = ap.parse_args()

# "raw" sends the text as it is, so the model continues it rather than replying to it.
body = {"model": "llama3.2:3b", "prompt": a.prompt, "raw": True, "stream": False,
        "options": {"num_predict": a.tokens, "temperature": a.temperature,
                    "top_p": a.top_p, "top_k": 0, "seed": a.seed}}
request = urllib.request.Request("http://127.0.0.1:11434/api/generate", json.dumps(body).encode())
print(a.prompt + json.load(urllib.request.urlopen(request))["response"])
```

Com a temperatura em 0, cada passo fica com o token mais provável, o que se chama
**decodificação gulosa**:

```
ana@dev:~/shop$ python scratch/generate.py "Return the" --tokens 40 --temperature 0
Return the sum of all the elements in the list.

## Step 1: Define the problem
We need to write a function that takes a list of numbers as input and returns the sum of all the elements
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"O laço de geração com os números reais do llama3.2:3b. O contexto Return the entra no modelo, que dá uma probabilidade a cada próximo token possível: sum 7,6%, number 5,5%, first 2,5%, value 2,4%, count 2,1%, e o resto espalhado. Um token é escolhido, sum, acrescentado ao contexto, e o laço pergunta de novo.\"><defs><marker id=\"lp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">contexto</text><text x=\"95.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Return the</text><path d=\"M172 100 L218 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"222\" y=\"70\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"282.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o modelo</text><text x=\"282.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lê tudo</text><path d=\"M344 100 L380 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"384\" y=\"20\" width=\"200\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">distribuição do próximo token</text><text x=\"398\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; sum&#x27;</text><rect x=\"478\" y=\"58\" width=\"76.0\" height=\"12\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7,6%</text><text x=\"398\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; number&#x27;</text><rect x=\"478\" y=\"80\" width=\"55.0\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"539.0\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5,5%</text><text x=\"398\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; first&#x27;</text><rect x=\"478\" y=\"102\" width=\"25.0\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"509.0\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2,5%</text><text x=\"398\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; value&#x27;</text><rect x=\"478\" y=\"124\" width=\"24.0\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"508.0\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2,4%</text><text x=\"398\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; count&#x27;</text><rect x=\"478\" y=\"146\" width=\"21.0\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"505.0\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2,1%</text><text x=\"484\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">… e todos os outros tokens</text><path d=\"M586 100 L604 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"608\" y=\"70\" width=\"96\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"656.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">escolhe um</text><text x=\"656.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&#x27; sum&#x27;</text><path d=\"M656 132 L656 240 L95 240 L95 134\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><text x=\"376\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">acrescenta e pergunta de novo</text><text x=\"95\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Return the sum</text></svg>", "caption": "Um passo da geração, com os números que o `llama3.2:3b` deu para `Return the`. Uma resposta é este passo repetido até uma condição de parada."}
```

**Nada nesse texto foi pedido.** `Return the` virou um exercício de programação com um passo
numerado e um título em Markdown, porque um texto que começa assim, no material de treino do
modelo, muitas vezes continua assim. Parou no meio da frase porque podia escrever quarenta tokens
e usou todos. O modelo não decidiu escrever um exercício; a cada passo, mais um token de
exercício era a coisa mais provável de vir em seguida.

## O que decorre do laço

Quatro fatos sobre todo modelo que você vai chamar saem direto disso, e cada um tem uma aula:

- **A saída sai um token por vez**, então uma resposta longa demora mais que uma curta, na mesma
  proporção. A aula 9 mostra os tokens ao usuário à medida que chegam, em vez de fazê-lo esperar
  pelo último.
- **Você paga por token**, na entrada e na saída, porque tokens são o que o modelo processa. A
  aula 2 faz a conta.
- **O modelo só vê o contexto.** Não tem memória entre pedidos nem visão dos seus arquivos, a não
  ser que estejam no pedido. A seção 10 mostra o que uma conversa realmente envia.
- **Nada no laço confere fatos.** O próximo token é o provável, e provável não é o mesmo que
  verdadeiro. A seção 11 mostra este modelo fazendo isso, e a aula 11 trata disso em produção.
