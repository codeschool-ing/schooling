---
title: Um token por vez
version: 1
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

## Um modelo que dá para ver por dentro

Os modelos que você vai chamar por uma API têm bilhões de parâmetros e não podem ser
inspecionados de nenhum jeito útil. O laboratório tem um pequeno o bastante para ler. **O
`tinylm` é uma tabela de que token veio depois de qual**, contada sobre 78.351 tokens da
documentação que vem dentro da biblioteca padrão do Python. Ele prevê o próximo token a partir
dos dois últimos, e é um modelo de linguagem de verdade no sentido que importa aqui: o mesmo tipo
de entrada, o mesmo tipo de saída.

Pergunte o que vem depois de `Return the`:

```
ana@dev:~/shop$ python lab/next.py "Return the"
context used: 2 tokens
  5.0%  ' message'
  4.1%  ' number'
  4.1%  ' current'
  3.3%  ' string'
  3.3%  ' object'
```

Isso é uma distribuição de probabilidade. Os cinco tokens mais prováveis somam menos de 20%; o
resto está espalhado, bem fino, por todos os outros tokens que o modelo já viu depois daqueles
dois. Repare no espaço no começo de cada um: `' message'` é um único token que inclui o espaço
da frente, e a aula 1 seção 03 volta a isso.

Mude o contexto e a distribuição muda junto:

```
ana@dev:~/shop$ python lab/next.py "Return the number of"
context used: 2 tokens
  7.5%  ' data'
  7.5%  ' context'
  7.5%  ' lines'
  7.5%  ' threads'
  3.8%  ' types'
ana@dev:~/shop$ python lab/next.py "If the file does not"
context used: 2 tokens
 11.5%  ' have'
  7.7%  ' add'
  7.7%  ' check'
  7.7%  ' exist'
  7.7%  ' close'
```

`context used: 2 tokens` é toda a memória deste modelo. Depois de `If the file does not`, ele só
enxergou `does not`, então `exist` (a palavra que qualquer leitor espera) fica em quarto,
empatada com `add` e `close`. Um modelo grande calcula o mesmo tipo de distribuição, sobre um
vocabulário de uns 200 mil tokens, mas olha **tudo o que está na janela de contexto**: centenas de
milhares de tokens nos modelos atuais, contra dois aqui. É essa diferença que faz de um deles algo
útil e do outro um brinquedo. A saída tem a mesma forma nos dois.

## O laço, e como ele dá errado

A geração repete o passo. Esta execução sempre pega o token mais provável, o que se chama
**decodificação gulosa**:

```
ana@dev:~/shop$ python lab/generate.py "Return the" --tokens 40 --temperature 0
Return the message's header by summing up all threads started from the
        the type of the
        the type of the
        the type of the
        the type of the
        the type
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"O laço de geração com os números reais do tinylm. O contexto Return the entra no modelo, que dá uma probabilidade a cada próximo token possível: message 5,0%, number 4,1%, current 4,1%, string 3,3%, object 3,3%, e o resto espalhado. Um token é escolhido, message, acrescentado ao contexto, e o laço pergunta de novo.\"><defs><marker id=\"lp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">contexto</text><text x=\"95.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Return the</text><path d=\"M172 100 L218 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"222\" y=\"70\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"282.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o modelo</text><text x=\"282.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lê tudo</text><path d=\"M344 100 L380 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"384\" y=\"20\" width=\"200\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">distribuição do próximo token</text><text x=\"398\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; message&#x27;</text><rect x=\"478\" y=\"58\" width=\"70.0\" height=\"12\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"554.0\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5,0%</text><text x=\"398\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; number&#x27;</text><rect x=\"478\" y=\"80\" width=\"57.39999999999999\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"541.4\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4,1%</text><text x=\"398\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; current&#x27;</text><rect x=\"478\" y=\"102\" width=\"57.39999999999999\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"541.4\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4,1%</text><text x=\"398\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; string&#x27;</text><rect x=\"478\" y=\"124\" width=\"46.199999999999996\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"530.2\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3,3%</text><text x=\"398\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; object&#x27;</text><rect x=\"478\" y=\"146\" width=\"46.199999999999996\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"530.2\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3,3%</text><text x=\"484\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">… e todos os outros tokens</text><path d=\"M586 100 L604 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"608\" y=\"70\" width=\"96\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"656.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">escolhe um</text><text x=\"656.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&#x27; message&#x27;</text><path d=\"M656 132 L656 240 L95 240 L95 134\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><text x=\"376\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">acrescenta e pergunta de novo</text><text x=\"95\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Return the message</text></svg>", "caption": "Um passo da geração, com os números que o `tinylm` imprimiu para `Return the`. Uma resposta é este passo repetido até uma condição de parada."}
```

**Ele cai num laço e fica nele.** Depois que `the type of the` foi escrito, os dois últimos tokens
são `of the`, a continuação mais provável deles é a mesma da vez anterior, e nada num laço guloso
escolhe diferente. Modelos grandes também se repetem com decodificação gulosa, com menos
frequência e em trechos mais longos, e os padrões dos provedores sorteiam da distribuição em vez de
pegar sempre o topo. A aula 1 seção 04 mostra como essa escolha é controlada.

## O que decorre do laço

Quatro fatos sobre todo modelo que você vai chamar vêm direto disso, e cada um tem uma aula:

- **A saída é produzida um token por vez**, então uma resposta longa demora mais que uma curta, na
  mesma proporção. A aula 9 mostra os tokens ao usuário conforme chegam, em vez de fazê-lo esperar
  pelo último.
- **Você paga por token**, de entrada e de saída, porque tokens são o que o modelo processa. A aula
  2 faz a conta.
- **O modelo só vê o contexto dele.** Não tem memória entre requisições e não vê seus arquivos a
  menos que estejam na requisição. A aula 1 seção 06 mostra o que uma conversa realmente envia.
- **Nada no laço confere fatos.** O próximo token é o provável, e provável não é o mesmo que
  verdadeiro. A aula 1 seção 07 mostra o modelo pequeno fazendo isso, e a aula 11 trata disso em
  produção.
