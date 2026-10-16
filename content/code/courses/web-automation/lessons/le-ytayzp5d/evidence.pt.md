---
title: O que cada artefato responde
version: 1
---

O clique que falhou deixou uma pasta em `test-results/`, com o nome do arquivo e do teste, e quatro
arquivos dentro dela. **Cada um responde a uma pergunta diferente**, e o mais barato de abrir
raramente é o que resolve a questão:

```
%%CAP evidence-ls%%
```

| arquivo | a pergunta que responde | tamanho aqui |
|---|---|---|
| `test-failed-1.png` | o que havia na tela quando o teste falhou | 43 KB |
| `error-context.md` | o que a página continha naquele momento, em texto | 1,5 KB |
| `video.webm` | como a tela chegou ali | 115 KB |
| `trace.zip` | o que aconteceu, em que ordem e quando | 149 KB |

## A captura de tela: o fim, como uma pessoa veria

```
%%CAP evidence-file%%
```

Uma foto da janela inteira, 1280 por 720, tirada depois que a asserção desistiu. Ela mostra os oito
cartões, cada um com seu botão, e *Basket: 0 items*. **Nada nela parece errado**, e isso é uma
descoberta: a página desenhou tudo, então a falha não é um elemento faltando nem um layout quebrado.
Uma captura de tela responde *o que a tela mostrava no fim* e nada sobre como ela chegou a mostrar
aquilo. É o artefato que as pessoas abrem primeiro, porque abre em qualquer coisa, e o que mais
vezes diz *para mim está normal*.

## O contexto de erro: o fim, em texto

O Playwright escreve o `error-context.md` ao lado de toda falha, diga a configuração o que disser.
Dentro há um **snapshot da árvore de acessibilidade da página**: cada elemento pelo seu papel e
pelo seu nome, do jeito que um leitor de tela encontra a página, que é também como o `getByRole`
acha as coisas:

````
%%CAP error-context%%
````

Leia procurando uma palavra. O botão do cartão da banana tem **`[active]`**, que marca o elemento
com o foco, e um botão ganha o foco quando é clicado. Então o clique chegou ao botão, e o contador
ao lado continua dizendo `0`. Das quatro histórias da seção anterior, *o clique errou* fica
descartada por um arquivo de 1,5 KB que você lê num terminal, procura com `grep` e compara com o
mesmo arquivo da execução de ontem. Uma captura de tela não faz nenhuma dessas três coisas.

## O vídeo: como chegou ali

O vídeo filma o navegador durante o teste inteiro. A documentação do Playwright diz que ele é
reduzido para caber em 800 por 800, a não ser que você dê um tamanho, o que o mantém pequeno.
**Ninguém assistiu a este para o curso**: a máquina em que estas aulas foram gravadas não tem tela.
Nesta falha ele mostraria uma página que aparece e depois não muda por cinco segundos, o que
concorda com o contexto de erro e acrescenta pouco. Um vídeo vale o tamanho quando a pergunta é a
ordem do que aparece na tela: um diálogo que cobriu um botão por um instante, uma página que rolou
enquanto o teste clicava. Ele não mostra o que o teste fez nem o que a rede estava fazendo; mostra
só o que foi pintado.

## O rastro: tudo, com horários

O rastro é o maior arquivo e o único que guarda **tempo**: cada ação que o teste fez, quando
começou, cada requisição e resposta com seus tempos, o console e um snapshot da página em torno de
cada ação. A captura, o vídeo e o contexto de erro dizem *o quê*; só o rastro diz *antes* e
*depois*, e uma corrida como esta é uma pergunta sobre ordem. A próxima seção o abre.

## O relatório ao lado

O reporter HTML do `evidence.config.js` escreveu também a pasta `playwright-report/`, uma página
que mostra cada teste com todos os seus anexos num lugar só:

```
%%CAP report-du%%
```

O relatório é o maior dos dois, 2,2 MB contra os 320 KB de que foi feito, então copiar os dois de
um servidor de build é uma decisão sobre disco além de conveniência; a seção sobre servidores de
build volta a isso.
