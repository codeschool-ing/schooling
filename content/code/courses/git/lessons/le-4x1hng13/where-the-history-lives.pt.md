---
title: Onde o histórico mora, e por que Git não é GitHub
version: 1
---

Controle de versão é décadas mais velho que o Git, e os sistemas anteriores fizeram uma escolha que
o Git inverteu. Saber qual escolha explica boa parte de como é usar o Git.

## Um servidor, ou todas as cópias

**O CVS, de 1990, e o Subversion, de 2000, guardam o histórico num servidor.** A sua máquina tem uma
cópia de trabalho: uma versão dos arquivos, a que você baixou. Tudo o que toca no histórico passa
pela rede. Ler o log pergunta ao servidor. Salvar uma mudança a envia para o servidor, que é onde ela
passa a fazer parte do histórico. Se o servidor cai, ninguém salva nada. Se o disco dele morre sem
backup, o histórico se foi, e cada cópia de trabalho só tem a versão em que por acaso estava.

**O Git guarda o histórico inteiro em cada cópia.** Quando você pega um projeto, você recebe todos os
commits que já foram feitos nele, e a sua máquina responde sozinha a qualquer pergunta sobre o
histórico. Salvar uma mudança é local. A rede só entra quando você decide compartilhar, que é a
aula 7.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 318\" role=\"img\" aria-label=\"Dois arranjos lado a lado. À esquerda, um servidor central guarda o histórico inteiro e cada pessoa guarda só uma versão dos arquivos, então todo log e todo commit é um pedido ao servidor. À direita, toda máquina guarda o histórico inteiro, incluindo a cópia hospedada que todos combinam de compartilhar, então log e commit acontecem localmente.\"><defs><marker id=\"wh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">central — CVS, Subversion</text><rect x=\"95\" y=\"44\" width=\"170\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"180.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o servidor</text><text x=\"180.0\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o histórico inteiro</text><rect x=\"20\" y=\"200\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">você</text><text x=\"95.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma versão dos arquivos</text><rect x=\"190\" y=\"200\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">um colega</text><text x=\"265.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma versão dos arquivos</text><path d=\"M95 198 L150 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\" marker-start=\"url(#wh-ah)\"></path><path d=\"M265 198 L210 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\" marker-start=\"url(#wh-ah)\"></path><text x=\"180\" y=\"284\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">todo log e todo commit perguntam ao servidor</text><path d=\"M360 20 L360 296\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></path><text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">distribuído — Git</text><rect x=\"455\" y=\"44\" width=\"170\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">GitHub, GitLab…</text><text x=\"540.0\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o histórico inteiro</text><text x=\"540\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">compartilhado por acordo</text><rect x=\"380\" y=\"200\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"455.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">você</text><text x=\"455.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o histórico inteiro</text><rect x=\"550\" y=\"200\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">um colega</text><text x=\"625.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o histórico inteiro</text><path d=\"M455 198 L510 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\" marker-start=\"url(#wh-ah)\"></path><path d=\"M625 198 L570 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\" marker-start=\"url(#wh-ah)\"></path><text x=\"540\" y=\"284\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">log e commit nunca saem da máquina</text></svg>", "caption": "Num sistema central o histórico mora num lugar só. No Git toda cópia é completa, e a compartilhada é compartilhada por acordo, não por projeto.", "same": ["central — CVS, Subversion", "GitHub, GitLab…"]}
```

## Apague o original

Essa afirmação é fácil de testar. `git clone` faz uma cópia de um repositório — aqui, o da seção
anterior — e depois o original é removido por completo:

```
ana@vm:~$ git clone ~/notes ~/copy
Cloning into '/home/ana/copy'...
done.
ana@vm:~$ rm -rf ~/notes
ana@vm:~$ cd ~/copy
ana@vm:~/copy$ git log --oneline
d03056f Name the quarter in the title
3c94cf5 Say by how much the north missed, and add the table it comes from
084e07d Use the corrected sales figure from finance
32507e0 Start the quarterly report
```

**Os quatro commits sobreviveram**, com os mesmos ids, porque a cópia nunca dependeu do original. Ela
era o histórico, não uma janela para ele.

Três coisas decorrem disso, e você vai se apoiar em cada uma.

- Dá para trabalhar sem conexão. No trem, no avião, com a rede do escritório fora do ar: salvar, ler
  o log e comparar versões funcionam, porque não há nada a perguntar a ninguém.
- Ler o histórico é rápido. Não há servidor no caminho, então uma pergunta como "como era este
  arquivo em março" é respondida a partir do seu próprio disco.
- Toda cópia é um backup. Uma equipe de cinco pessoas tem o histórico em cinco máquinas e no
  servidor compartilhado. Perder uma delas não perde nada que não esteja também em outro lugar.

## Então o que é o GitHub?

Uma equipe ainda precisa de um lugar para se encontrar. Se a cópia de todo mundo é completa, alguém
tem de decidir de qual cópia os outros pegam as mudanças, e na prática essa é uma cópia mantida num
servidor sempre ligado. **O Git não sabe que essa cópia é especial.** Ela é um repositório como o
seu, para o qual todo mundo combinou de mandar o próprio trabalho e de onde busca o trabalho dos
outros. O acordo é da equipe, não do programa.

**GitHub, GitLab e Bitbucket são empresas que hospedam essa cópia compartilhada.** Em volta dela
elas constroem o que o Git em si não tem: contas e permissões, uma página web para cada arquivo, e
issues para acompanhar o trabalho. Elas também acrescentam o pull request, que é como uma equipe
propõe e revisa uma mudança antes de ela entrar no histórico compartilhado. A aula 8 é sobre eles.

A distinção importa porque as pessoas dizem "GitHub" quando querem dizer Git, e depois procuram as
respostas do Git no lugar errado. **O Git é um programa na sua máquina.** Ele funcionou na captura
acima sem conta, sem site e sem rede. O GitHub é um serviço que guarda mais uma cópia e acrescenta
um lugar para as pessoas conversarem sobre ela.

A própria história do Git mostra o mesmo. Ele foi escrito por Linus Torvalds em 2005, para o kernel
Linux, depois que o kernel perdeu o uso gratuito do sistema proprietário em que era mantido. O que
ele precisava era de centenas de desenvolvedores trabalhando em paralelo, a maioria sem nunca falar
com um servidor. O GitHub veio três anos depois, como um negócio construído em cima dele.
