---
title: Contexto é um limite, depois um custo
version: 1
---

A **janela de contexto** de um modelo é o máximo de tokens que uma requisição pode ter: o prompt e,
na maioria dos provedores, também a resposta. É o único critério em que os números da tabela podem
ser usados direto, e eles cresceram tanto que a pergunta mudou de "cabe?" para "quanto custa encher?".

Quantas entradas de chat com preço chegam a cada tamanho:

```
ana@desk:~/desk$ sheet pick --min-window 1000000 | sed -n 2p
761 entries pass
```

```
ana@desk:~/desk$ sheet pick --min-window 200000 | sed -n 2p
1666 entries pass
```

```
ana@desk:~/desk$ sheet pick --min-window 32000 | sed -n 2p
2722 entries pass
```

Das 2.990 entradas de chat com preço, 2.722 aceitam 32.000 tokens, 1.666 aceitam 200.000 e
761 aceitam um milhão ou mais. A requisição mais longa da ana, a política mais uma conversa longa
por e-mail, fica abaixo de 10.000 tokens. **Todo modelo que ela poderia razoavelmente pôr na lista
curta comporta isso muitas vezes**, o que faz da janela um limite que ela passa com folga e nada mais.

## O que uma janela grande não compra

Uma janela é um limite, não uma promessa de bom uso. Três coisas a saber antes de enchê-la:

- **Você paga por cada token que manda**, cada vez que manda. Um prompt de 200.000 tokens a US$ 1
  o milhão custa 20 centavos antes de o modelo escrever uma palavra, em toda requisição. O cache
  (seção 05) suaviza isso para um prefixo repetido; nada suaviza para um documento diferente a cada
  vez.
- **Prompts longos demoram mais para começar.** O prompt inteiro é lido antes do primeiro token, e
  o tempo até o primeiro token da seção 06 cresce junto.
- **Os modelos usam o meio de um contexto longo com menos confiabilidade que as pontas**, um padrão
  visto em muitos modelos e o motivo de a recuperação (aula 1 seção 11) continuar existindo na era
  das janelas de um milhão de tokens: mandar a página relevante é melhor que mandar o livro inteiro.

## O outro teto

A janela tem um irmão mais fácil de esquecer: **o máximo que um modelo escreve numa resposta**. Para
cinco dos candidatos da seção 05, lado a lado:

```
ana@desk:~/desk$ sheet compare claude-haiku-4-5 gemini/gemini-3.5-flash-lite gpt-5.4-mini mistral/mistral-small-latest deepseek/deepseek-v3.2
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
claude-haiku-4-5                                200,000    64000        1        5  VFSCRP
gemini/gemini-3.5-flash-lite                  1,048,576    65536      0.3      2.5  VFSCRP
gpt-5.4-mini                                    272,000   128000     0.75      4.5  VFSCRP
mistral/mistral-small-latest                    262,144   262144     0.15      0.6  VFS.R.
deepseek/deepseek-v3.2                          163,840   163840     0.28      0.4  .F.CR.
```

A coluna `max out` vai de 64.000 a 262.144 tokens, mais do que qualquer resposta dela vai precisar.
Ela importa para tarefas que escrevem documentos longos de uma vez, e vale saber que alguns
provedores contam a resposta dentro da janela e outros não.

A última coluna são as funcionalidades que a tabela registra para cada um, e ela já tem algo a dizer.
**A DeepSeek V3.2 não tem `S`**: a tabela não registra suporte a saída estruturada. Para a tarefa de
extração da ana isso é um limite, e a seção 08 trata disso.
