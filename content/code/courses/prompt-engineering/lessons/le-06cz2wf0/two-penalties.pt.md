---
title: Dois jeitos de penalizar uma repetição
version: 1
---

Uma penalidade às vezes é descrita como uma instrução para "variar mais". O modelo não recebe
instrução nenhuma. **Uma penalidade é aritmética sobre as notas: antes de cada passo, toda palavra
que já apareceu na saída tem um valor subtraído da sua nota.** As duas penalidades só diferem no
jeito de calcular esse valor.

O `toylm` as aplica primeiro, antes de temperatura, top-k e top-p (lição 14), e conta só as palavras
que ele escreveu, não o prompt. Para cada palavra que já está na saída:

| penalidade | o que é subtraído da nota da palavra |
|---|---|
| penalidade de frequência F | F × o número de vezes que a palavra já apareceu |
| penalidade de presença P | P, uma vez, se a palavra apareceu ao menos uma vez |

A penalidade de frequência cresce a cada repetição. A de presença é uma taxa fixa por ter sido
usada, a mesma depois de um uso ou de dez.

## As duas quebram este laço

```
ana@lab:~/pe$ toylm generate "the cat" --temperature 0 --max-tokens 20 --frequency-penalty 0.5
sleeps and the cat sleeps on the chair by the window.
-- finish: end, prompt 2 tokens, output 12 tokens
ana@lab:~/pe$ toylm generate "the cat" --temperature 0 --max-tokens 20 --presence-penalty 1
sleeps and the cat sleeps on the chair by the window.
-- finish: end, prompt 2 tokens, output 12 tokens
```

Com qualquer uma das duas, na segunda vez que o texto chega a `cat sleeps` a palavra `and` já foi
usada uma vez. A nota dela cai abaixo de `on`, o laço pega `on`, e a frase termina do jeito que o
corpus a termina: `on the chair by the window`, e então o fim.

## E elas não são o mesmo controle

A distância que elas precisam fechar é fixa. Nas notas, `and` está à frente de `on` pelo logaritmo
de 60/40, cerca de 0,41. Uma penalidade só quebra o laço quando o que ela subtrai de `and` passa
disso. Ponha as duas em 0,2:

```
ana@lab:~/pe$ toylm generate "the cat" --temperature 0 --max-tokens 20 --frequency-penalty 0.2
sleeps and the cat sleeps and the cat sleeps and the cat sleeps on the chair by the window.
-- finish: length, prompt 2 tokens, output 20 tokens
ana@lab:~/pe$ toylm generate "the cat" --temperature 0 --max-tokens 20 --presence-penalty 0.2
sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat
-- finish: length, prompt 2 tokens, output 20 tokens
```

**A penalidade de frequência chegou lá depois do terceiro `and`; a de presença nunca chegou.** Depois de
um `and`, F = 0,2 subtrai 0,2; depois de dois, 0,4, ainda um pouco abaixo; depois de três, 0,6, e
`on` ganha. A penalidade de presença subtrai 0,2 depois do primeiro `and` e nunca mais que isso,
então `and` mantém a vantagem para sempre e o laço vai até o limite. A execução de frequência
calhou de terminar a frase no vigésimo token, e é por isso que ainda informa `length` (lição 15).

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Um gráfico de linhas. O eixo horizontal é quantas vezes and já foi escrita, de 0 a 4. O eixo vertical é quanto é subtraído da nota dela. Uma linha tracejada em 0,41 marca a vantagem de and sobre on. A penalidade de frequência de 0,2 sobe 0, 0,2, 0,4, 0,6, 0,8 e cruza a linha tracejada entre 2 e 3. A penalidade de presença de 0,2 vai a 0, depois 0,2 e fica parada, abaixo da linha.\"><path d=\"M90 45 L90 220 L580 220\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"210.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"330.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"450.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"570.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"82\" y=\"182.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,2</text><text x=\"82\" y=\"144.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,4</text><text x=\"82\" y=\"106.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,6</text><text x=\"82\" y=\"68.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,8</text><text x=\"330.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">vezes que “and” já foi escrita</text><text x=\"40\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">subtraído da nota dela</text><path d=\"M90 143.5 L570 143.5\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"576\" y=\"143.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a distância a vencer: 0,41</text><path d=\"M90.0 220.0 L210.0 182.2 L330.0 144.4 L450.0 106.7 L570.0 68.9\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M90.0 220.0 L210.0 182.2 L330.0 182.2 L450.0 182.2 L570.0 182.2\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"576.0\" y=\"68.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">frequência 0,2</text><text x=\"576.0\" y=\"182.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">presença 0,2</text><rect x=\"446.0\" y=\"102.7\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"450.0\" y=\"90.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">quebra aqui</text></svg>", "caption": "O que cada penalidade subtrai da nota de “and” conforme o laço a repete. A penalidade de frequência sobe além da vantagem de 0,41 que “and” tem sobre “on”, e o laço quebra na terceira repetição; a de presença fica em 0,2 e nunca quebra."}
```

Então a penalidade de frequência é a que pesa mais sobre uma palavra quanto mais ela se repete, e
serve para laços e listas que não param. A de presença empurra o texto para palavras que ele ainda
não usou, o que fica mais perto de "mudar de assunto".

## Qualquer uma em excesso

Uma penalidade não distingue uma repetição que é defeito de uma repetição que é a própria língua.
Palavras como `is` e `the` precisam aparecer de novo e de novo em frases comuns. Sem penalidade, o
`toylm` escreve isto depois de `question :`:

```
ana@lab:~/pe$ toylm generate "question :" --temperature 0
is the bread is fresh.
-- finish: end, prompt 2 tokens, output 6 tokens
```

Desajeitada, porque duas palavras de contexto não enxergam a pergunta inteira, e feita de pedaços do
arquivo dele. Com uma penalidade de presença de 5, toda palavra que ele usou é empurrada bem para
baixo:

```
ana@lab:~/pe$ toylm generate "question :" --temperature 0 --presence-penalty 5
is the bread comes out of the day? answer: yes.
-- finish: end, prompt 2 tokens, output 13 tokens
```

Depois de `the bread` a palavra mais provável é `is`, de longe:

```
ana@lab:~/pe$ toylm next "the bread"
context: trigram after 'the bread'
  is        76.5%  ###############################
  comes     11.8%  #####
  fresh     11.8%  #####
```

`is` já tinha sido usada no começo da pergunta, então a penalidade a empurrou para baixo de `comes`,
e dali o texto se perdeu: `comes out of the`, depois `day`, depois um ponto de interrogação onde
estaria `is`. **Uma penalidade alta demais tira o modelo das palavras de que a frase precisa e o
empurra para palavras de que ela não precisava**, e a saída fica mais estranha, não melhor.

O estrago é maior onde a repetição é o objetivo: uma resposta JSON repete aspas e chaves, um programa
repete os nomes das variáveis, e uma resposta sobre uma pessoa repete o nome dela. Nesses casos as
penalidades ficam em 0.

## Faixas e padrões

Onde uma API oferece esses dois controles, o comum é que os dois venham em 0, ou seja,
desligados, e que o provedor documente uma faixa, às vezes com valores negativos que tornam a
repetição mais provável. Nem toda API os oferece, e se eles contam só a saída, como no `toylm`, ou
também o prompt, é decisão do provedor. **Comece em 0, suba uma das duas em passos pequenos enquanto
lê a saída, e pare assim que a repetição parar.** Leia a referência da API que você chama, e a data
dela, para saber a faixa e o que ela conta.
