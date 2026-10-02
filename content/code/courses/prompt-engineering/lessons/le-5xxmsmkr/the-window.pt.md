---
title: Tudo o que o modelo consegue ver de uma vez
version: 1
---

Um chat longo parece uma conversa com alguém que se lembra dela, então é natural achar que o modelo
guarda o que você disse uma hora atrás. Ele não guarda nada. A lição 2 mostrou que a aplicação
envia a conversa inteira de novo a cada pedido; **a janela de contexto é o máximo que o modelo
consegue receber num pedido, contado em tokens**, e o que fica fora dela não tem efeito nenhum
sobre o que vem depois.

## Uma janela de duas palavras

O `toylm` tem a menor janela possível que ainda forma frases: as duas últimas palavras (lição 1). O
arquivo de onde ele aprendeu diz quando o café abre, e diz de dois jeitos:

```
ana@lab:~/pe$ grep "opens at" corpus.txt | sort | uniq -c
      2 the café opens at eight on sunday .
      6 the café opens at seven .
```

Seis vezes às sete, duas vezes às oito no domingo. Pergunte sobre o domingo:

```
ana@lab:~/pe$ toylm generate "on sunday the café opens at" --temperature 0
seven.
-- finish: end, prompt 6 tokens, output 2 tokens
ana@lab:~/pe$ toylm next "on sunday the café opens at"
context: trigram after 'opens at'
  seven     75.0%  ##############################
  eight     25.0%  ##########
```

`seven`, e a linha de contexto diz por quê. **O `toylm` viu `opens at` e mais nada.** A única
palavra que deveria decidir a resposta, `sunday`, está quatro palavras atrás, fora da janela, e
para o modelo ela nunca foi escrita. Ele respondeu à pergunta que conseguia ver, e essa pergunta era
sobre um dia comum.

A janela de um modelo grande é enorme em comparação, e a regra na borda dela é a mesma: o texto que
não entrou na janela não existe para o modelo. Nada na resposta avisa que faltou alguma coisa; a
resposta sai fluente do mesmo jeito.

## O que precisa caber

A janela é dividida entre tudo o que está no pedido, inclusive a parte que ainda não foi escrita:

| | o que é | cresce quando |
|---|---|---|
| prompt de sistema | as instruções da aplicação (lição 22) | alguém acrescenta uma regra |
| histórico | todas as vezes anteriores, dos dois lados | a conversa continua |
| entrada | a mensagem nova, e o que for colado ou buscado nela | um documento ou o resultado de uma ferramenta entra junto |
| saída | **a resposta, token por token** | o modelo escreve |

A última linha pega muita gente de surpresa. **A resposta é escrita dentro da mesma janela**, então
um pedido cuja entrada enche a janela não deixa espaço para responder. No momento em que este curso
foi escrito (2026), os provedores publicam dois números para cada modelo, o tamanho da janela e um
limite separado, menor, de quantos tokens uma resposta pode ter, e os dois estão na documentação do
modelo. Eles mudam entre modelos e versões, então leia-os na página do modelo que você está usando,
com a data dela, nunca numa lista que alguém fez no ano passado.

## O que acontece na borda

Três coisas diferentes, dependendo de quem percebe primeiro:

- uma **API** que recebe um pedido longo demais o recusa com um erro, e nada é gerado;
- uma resposta que fica sem espaço **para no meio**, e a API informa por que parou, o motivo
  `length` de que trata a lição 15;
- uma **aplicação de chat** em geral evita os dois cortando ela mesma a conversa antes de enviá-la,
  em silêncio, que é o assunto da próxima seção.

Os dois primeiros fazem barulho. O terceiro é o perigoso, porque o modelo responde normalmente, com
o que sobrou.
