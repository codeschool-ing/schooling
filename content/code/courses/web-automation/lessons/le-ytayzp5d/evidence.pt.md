---
title: O que cada artefato responde
version: 1
---

O clique que falhou deixou uma pasta em `test-results/`, com o nome do arquivo e do teste, e quatro
arquivos dentro dela. **Cada um responde a uma pergunta diferente**, e o mais barato de abrir
raramente é o que resolve a questão:

```
ana@laptop:~/quitanda$ ls -la test-results/ssr-a-click-on-ssr-at-once/
total 288
drwxrwxr-x 2 ana ana   4096 Oct 15 22:10 .
drwxrwxr-x 3 ana ana   4096 Oct 15 22:10 ..
-rw-rw-r-- 1 ana ana   1510 Oct 15 22:10 error-context.md
-rw-rw-r-- 1 ana ana  43452 Oct 15 22:10 test-failed-1.png
-rw-rw-r-- 1 ana ana 124596 Oct 15 22:10 trace.zip
-rw-rw-r-- 1 ana ana 106675 Oct 15 22:10 video.webm
```

| arquivo | a pergunta que responde | tamanho aqui |
|---|---|---|
| `test-failed-1.png` | o que havia na tela quando o teste falhou | 43 KB |
| `error-context.md` | o que a página continha naquele momento, em texto | 1,5 KB |
| `video.webm` | como a tela chegou ali | 107 KB |
| `trace.zip` | o que aconteceu, em que ordem e quando | 125 KB |

## A captura de tela: o fim, como uma pessoa veria

```
ana@laptop:~/quitanda$ file test-results/ssr-a-click-on-ssr-at-once/test-failed-1.png test-results/ssr-a-click-on-ssr-at-once/video.webm
test-results/ssr-a-click-on-ssr-at-once/test-failed-1.png: PNG image data, 1280 x 720, 8-bit/color RGB, non-interlaced
test-results/ssr-a-click-on-ssr-at-once/video.webm:        WebM
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
acha as coisas. O arquivo é Markdown, com a árvore dentro de um bloco `yaml`, e as duas linhas que
abrem e fecham o bloco ficam de fora aqui, pelo `grep -v`:

```
ana@laptop:~/quitanda$ grep -v '^```' test-results/ssr-a-click-on-ssr-at-once/error-context.md
# Page snapshot

- main [ref=e2]:
  - heading "Fruit of the season" [level=1] [ref=e3]
  - paragraph [ref=e4]: "Basket: 0 items"
  - list [ref=e5]:
    - listitem [ref=e6]:
      - heading "Banana" [level=2] [ref=e7]
      - paragraph [ref=e8]: R$ 5,90
      - button "Add to basket" [active] [ref=e9] [cursor=pointer]
    - listitem [ref=e10]:
      - heading "Mango" [level=2] [ref=e11]
      - paragraph [ref=e12]: R$ 4,50
      - button "Add to basket" [ref=e13] [cursor=pointer]
    - listitem [ref=e14]:
      - heading "Papaya" [level=2] [ref=e15]
      - paragraph [ref=e16]: R$ 7,90
      - button "Add to basket" [ref=e17] [cursor=pointer]
    - listitem [ref=e18]:
      - heading "Guava" [level=2] [ref=e19]
      - paragraph [ref=e20]: R$ 12,90
      - button "Add to basket" [ref=e21] [cursor=pointer]
    - listitem [ref=e22]:
      - heading "Cashew fruit" [level=2] [ref=e23]
      - paragraph [ref=e24]: R$ 15,90
      - button "Add to basket" [ref=e25] [cursor=pointer]
    - listitem [ref=e26]:
      - heading "Passion fruit" [level=2] [ref=e27]
      - paragraph [ref=e28]: R$ 9,90
      - button "Add to basket" [ref=e29] [cursor=pointer]
    - listitem [ref=e30]:
      - heading "Acerola" [level=2] [ref=e31]
      - paragraph [ref=e32]: R$ 18,90
      - button "Add to basket" [ref=e33] [cursor=pointer]
    - listitem [ref=e34]:
      - heading "Pineapple" [level=2] [ref=e35]
      - paragraph [ref=e36]: R$ 6,90
      - button "Add to basket" [ref=e37] [cursor=pointer]
```

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
ana@laptop:~/quitanda$ du -sh test-results playwright-report
292K	test-results
2.1M	playwright-report
```

O relatório é o maior dos dois, 2,1 MB contra os 292 KB de que foi feito, então copiar os dois de
um servidor de build é uma decisão sobre disco além de conveniência; a seção sobre servidores de
build volta a isso.
