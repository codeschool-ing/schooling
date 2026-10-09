---
title: O que quebra um cache
version: 2
---

**Qualquer mudança no começo de um prompt torna novo tudo o que vem depois.** O cache acha o começo
guardado mais longo que casa; o primeiro token diferente encerra a correspondência, e todo token
depois dele é lido de novo, mesmo onde o texto não mudou. Caches hospedados também casam um começo, e
a consequência é a mesma.

O `v17-message-first` foi o caso extremo, um começo diferente em toda chamada. Edições comuns fazem a
mesma coisa com menos barulho:

- Uma palavra mudada no guia torna novo tudo a partir dela. A próxima chamada lê tudo de novo, e só
  então o cache passa a ter a versão nova.
- Um exemplo novo inserido perto do topo desloca todo token depois dele, então tudo depois dele muda
  mesmo sem o texto ter mudado.
- Uma data, o nome de um cliente ou o número de um chamado postos cedo, *"Today is 14 August.
  Customer: Maria Souza."*, variam por chamada exatamente como a mensagem, e custam ao cache tudo o
  que vem depois.
- Cinco minutos ociosos no Ollama descarregam o modelo, e o cache vai junto.

Então mantenha o que varia no fim, e mude a parte fixa de propósito e raramente, sabendo que cada
mudança é paga uma vez, pela primeira chamada que a lê.

## O cache não deveria mudar as respostas

Um cache deveria mudar custo e tempo e mais nada. A aula 8 mostrou que nesta máquina isso não é bem
verdade: três respostas ao mesmo prompt com temperatura 0, uma lida do zero e duas do cache, e a
primeira diferiu das outras duas depois de trinta palavras. **Um prompt em cache é calculado por outro
caminho pela mesma aritmética**, e um quase empate pode sair para o outro lado. É mais um motivo para
medir num conjunto de teste em vez de confiar que uma mudança no cache não mudou nada.

## Reordenar não é uma configuração do cache

Pôr a mensagem na frente é uma mudança maior. Muda o texto que o modelo lê, então é um prompt novo, e
as respostas dele podem diferir por motivos que não têm nada a ver com o cache:

```
ana@lab:~/triage$ pl compare runs/static.jsonl runs/first.jsonl
runs/static.jsonl        passes 23/40
runs/first.jsonl         passes 18/40
fixed 0, broken 5
broken: t10 t14 t17 t27 t34
sign test on the 5 that changed: p = 0.062
ana@lab:~/triage$ pl compare runs/static.jsonl runs/first.jsonl --answers
40 cases, same answer 30, different answer 10
  t10    other -> delivery
  t14    account -> other
  t16    billing -> other
  t17    delivery -> None
  t18    returns -> delivery
  t25    account -> delivery
  t33    returns -> delivery
  t34    account -> other
  t38    None -> returns
  t39    account -> other
```

Vinte e três contra dezoito, nenhuma consertada e cinco quebradas, p = 0.062. Dez categorias
mudaram, e o `t17` e o `t38` trocaram de lugar no formato: o `t38`, o ebook cujo apóstrofo quebra o
JSON, saiu válido com a mensagem primeiro, e o `t17` deixou de sair. **O prompt com a mensagem
primeiro é mais lento e, neste conjunto, pior**, e o teste do sinal em cinco mensagens para pouco antes
de chamar isso de mais que acaso. Uma reordenação feita por causa do cache passa pela trava da aula 14
como qualquer outra mudança no texto; aqui ela não teria poupado nada e teria custado cinco mensagens.
