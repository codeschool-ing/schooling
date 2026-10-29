---
title: Alertas que alguém lê
version: 1
---

**Um monitor só é útil se alguém age sobre o que ele diz, e o jeito de ele falhar é dizer demais.** Toda
extensão de navegador que lança erros dentro da página, toda rede que derruba um pedido num túnel, toda aba
antiga rodando o build da semana passada manda um relatório. Uma equipe avisada de tudo isso para de ler,
e perde o aviso que importa.

## Contar, em vez de ler

O primeiro passo é parar de ler relatórios um a um e contá-los pelo que dizem. Até o arquivo do planner
pode ser contado, com um pipe:

```
ana@dev:~/planner$ grep -o '"message":"[^"]*"' api/errors.jsonl | sort | uniq -c | sort -rn
      1 "message":"Response not successful: Received status code 502"
      1 "message":"A bug, on purpose"
```

Dois relatórios, duas mensagens. Num site de verdade, essa lista tem milhares de linhas, e o topo dela é o
trabalho da semana. Um serviço hospedado faz esse agrupamento com a pilha além da mensagem, para que dois
bugs diferentes que por acaso lançam o mesmo `TypeError` fiquem separados.

## O que merece um alerta

Um alerta interrompe uma pessoa, então fica reservado ao que não pode esperar. Três regras cobrem a maior
parte das equipes:

- **Novo nesta release.** Uma issue que nunca tinha aparecido, relatada pela primeira vez pelo build
  publicado há uma hora, é quase sempre culpa desse deploy, e o momento mais barato de consertá-la é agora.
- **Um aumento súbito.** Uma issue que costuma chegar dez vezes por hora e agora chega mil é uma queda do
  serviço, diga a mensagem o que disser.
- **Voltou.** Uma issue marcada como consertada que reaparece numa release mais nova.

Todo o resto vai para uma lista lida com hora marcada, e não empurrada para ninguém.

## Ruído, filtrado na origem

Alguns relatórios são sabidamente bug de ninguém, e filtrá-los na página poupa todo mundo:

- erros cuja pilha está só nos arquivos de uma extensão de navegador, `chrome-extension://` e parecidos;
- *Script error.* sem pilha, de um script de outra origem que não é do planner;
- `ResizeObserver loop completed with undelivered notifications`, que os navegadores relatam e que quase
  nunca afeta um usuário;
- pedidos que falharam porque o aparelho ficou offline, o que o `navigator.onLine` consegue distinguir.

Cada filtro é uma decisão de que um tipo de erro não importa, então cada um fica escrito no código com o
motivo, e é revisado como qualquer outra mudança. **Um filtro que ninguém sabe explicar é um bug escondido
de propósito.**

Esse é o fim do último assunto do curso. O planner agora é construído, vai para o ar, tem a mesma cara em
todo lugar, lê de um servidor e avisa a equipe quando quebra.
