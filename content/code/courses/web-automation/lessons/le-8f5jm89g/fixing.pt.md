---
title: Corrigir, e por que um timeout maior não é correção
version: 1
---

**A correção de um teste instável quase nunca é um timeout maior.** É a primeira coisa que as
pessoas tentam, porque a tentativa que falha costuma terminar numa mensagem de tempo esgotado, e
aumentar o número faz a mensagem sumir por um tempo. Um timeout é um limite de quanto uma
verificação pode esperar por algo que vai acontecer. Ele só ajuda quando a coisa acontece mesmo, só
que depois do que o limite permitia, e essa é a mais rara das seis causas.

Olhe a tentativa que falhou na seção de diagnóstico. Ela levou 6,1 s, porque o `toHaveText` esperou
os seus cinco segundos diante de uma lista que já dizia três frutas e nunca ia mudar. Um limite de
trinta segundos faria essa tentativa levar trinta segundos e falhar exatamente do mesmo jeito.
**Esperar mais por um estado final errado só o observa por mais tempo.** O mesmo vale para a cesta
compartilhada: uma contagem de 2 não vira 1 se você esperar.

## A correção é da causa

| causa | a correção | onde este curso a faz |
|---|---|---|
| tempo | esperar por um estado que é falso até a página terminar, nunca por um intervalo de tempo | aula 3, e aula 13 |
| estado compartilhado | cada teste recebe dados em que ninguém mais mexe | aula 15 |
| ordem | cada teste prepara o seu próprio ponto de partida | o reset das aulas 6 e 10, e a aula 15 |
| ambiente | tirar a diferença entre as máquinas, ou fazer o teste dizer qual recebeu | as fontes da plataforma |
| o próprio teste | nada de aleatoriedade sem explicação: valores fixos ou com semente, e uma taxa escrita onde uma é aceita | os ids de teste da aula 2 |
| a aplicação | corrigir a página; o teste estava certo | abaixo |

Os casos da plataforma cabem na mesma tabela. A corrida do cartão de curso foi corrigida esperando
que o título nomeasse o curso pedido. Os pacotes em Go pararam de colidir quando nenhum teste
semeava mais um nome fixo. A diferença de fontes sumiu quando as fontes passaram a ser servidas pelo
próprio endereço da plataforma, e o teste de grafo ainda imprime quais carregaram. O embaralhamento
da tela de treino parou de decidir a verificação de acessibilidade quando a suíte passou a pedir
cada resultado pelo nome; o roteiro da plataforma diz isso como *um estado que ela só alcança por
sorte é uma falha, e não um pulo*. Mais duas regras dela são a quinta linha da tabela na prática. O
corretor que confere uma resposta algébrica a avalia em pontos fixos, *nunca aleatórios*. O desenho
do grafo das trilhas usa um embaralhamento com semente, para que uma trilha não mude de forma entre
uma visita e outra.

## A busca, corrigida

A busca da loja é a última linha. A aula 3 mostrou uma correção: lembrar o que foi perguntado e
descartar qualquer resposta a uma pergunta que a caixa não faz mais. Com esse listener no lugar do
antigo em `app/public/search.js`, o job da quarentena:

```
ana@laptop:~/quitanda$ npx playwright test --config quarantine.config.js --repeat-each 20 | grep -E '^  [0-9]+ (failed|flaky|passed)'
  20 passed (20.8s)
```

Vinte de vinte. Quanto isso prova depende da taxa que ficou para trás. Antes da correção este teste
falhou 5, 6 e 8 tentativas em vinte em três execuções, cerca de uma em quatro. Nessa taxa, vinte
aprovações seguidas aconteceriam por sorte com chance de 0,75 elevado a 20, cerca de 3 em 1.000, o
que é uma evidência forte. **Uma sequência verde curta prova pouco sobre uma falha rara**, porém. Se
o teste falhasse uma tentativa em vinte, vinte aprovações seguidas ainda aconteceriam cerca de 36%
das vezes, já que 0,95 elevado a 20 dá cerca de 0,36. Então meça uma correção onde o teste mais
falhava, muitas vezes, e prefira uma correção que você consegue explicar pelo código, como esta. Ponha o `search.js` original de volta depois de testar isso: as falhas da loja
ficam de propósito para as aulas que as usam.

## Sair da quarentena

Quando a correção está na aplicação, o teste volta para `tests/` sem mudança, porque estava certo o
tempo todo. Quando a correção está no teste, é o teste alterado que volta. De um jeito ou de outro a
pasta da quarentena fica com um teste a menos, e a anotação vai junto. Uma quarentena que só cresce
é a exclusão lenta da seção anterior.

Neste projeto o `quarantine/typing.spec.js` fica onde está, porque o defeito da busca fica: a aula 3
o deixou de propósito, e esta aula também. O teste é o registro de que ele está lá, e de que só
aparece em certas velocidades.
