---
title: O que a sincronia de fato faz, que é menos do que se supõe
version: 1
---

Uma pasta sincronizada é **uma pasta que também está num servidor, e também em todo outro
aparelho logado na mesma conta.** Um arquivo muda; a mudança é enviada; o servidor a empurra para
todo o resto. Esse é o mecanismo inteiro.

Não é uma cópia, não é um backup e não é uma versão do arquivo — é **o mesmo arquivo, em vários
lugares, mantido idêntico.** Toda consequência desta aula vem da palavra *idêntico*.

## Os estados em que um arquivo pode estar

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 302\" role=\"img\" aria-label=\"Cinco linhas descrevendo os estados em que um arquivo de uma pasta sincronizada pode estar. Só na nuvem: não ocupa disco e abrir exige conexão. Baixado: ocupa o tamanho inteiro e abre offline. Alterado aqui: ocupa o tamanho inteiro e está esperando para subir. Subindo: o mesmo, com a mudança a caminho. Em conflito: duas cópias inteiras no disco e ninguém decidiu qual delas é o arquivo.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Cinco estados, e só um deles é o que as pessoas imaginam</text><text x=\"44\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o estado</text><text x=\"300\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que ocupa no disco</text><text x=\"676\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para que a conexão é necessária</text><rect x=\"24\" y=\"62\" width=\"672\" height=\"32\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"44\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">só na nuvem</text><text x=\"300\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nada</text><text x=\"676\" y=\"78\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">abrir o arquivo</text><rect x=\"24\" y=\"102\" width=\"672\" height=\"32\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"44\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">baixado</text><text x=\"300\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o tamanho inteiro</text><text x=\"676\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada</text><rect x=\"24\" y=\"142\" width=\"672\" height=\"32\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"44\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">alterado aqui</text><text x=\"300\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o tamanho inteiro</text><text x=\"676\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">enviar a mudança</text><rect x=\"24\" y=\"182\" width=\"672\" height=\"32\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"44\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">subindo</text><text x=\"300\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o tamanho inteiro</text><text x=\"676\" y=\"198\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">terminar</text><rect x=\"24\" y=\"222\" width=\"672\" height=\"32\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"44\" y=\"238\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">em conflito</text><text x=\"300\" y=\"238\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">duas cópias inteiras</text><text x=\"676\" y=\"238\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma pessoa, não uma conexão</text><text x=\"24\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Uma pasta guarda os cinco ao mesmo tempo, e o ícone ao lado de cada nome é o único lugar que diz isso.</text></svg>", "caption": "A terceira e a quarta linhas são a razão de uma pasta que se diz sincronizada ainda poder estar perdendo trabalho quando a máquina fecha."}
```

**Arquivos sob demanda** é a primeira linha: o nome e o tamanho do arquivo estão no seu disco e o
conteúdo não, até você abrir. É assim que uma conta de `2 TB` cabe num notebook de `256 GB`, e vem
ligado por padrão no OneDrive e no Drive e é opção no iCloud.

Isso produz três efeitos que vale conhecer:

- **Uma pasta pode reportar 400 GB e usar 4 GB.** Que é a coisa que a aula sete mandou conferir
  antes de confiar num número de espaço em disco.
- **Uma ferramenta de backup pode copiar os substitutos**, que têm uns poucos kilobytes cada, e
  produzir um backup de nada. Toda ferramenta de backup hoje tem um ajuste para isso e ele nem
  sempre vem certo.
- **Abrir um arquivo sem conexão falha**, num arquivo que está visivelmente ali. *Manter sempre
  neste dispositivo* é o conserto por arquivo ou por pasta, e arranjar isso dentro do avião não
  funciona pelo mesmo motivo da aula anterior.

## O ícone é a interface

Todo serviço põe uma marquinha em cada arquivo e cada pasta, e é o único lugar em que o estado
está escrito:

| | mais ou menos |
|---|---|
| um contorno de nuvem | só na nuvem. Nada no disco |
| um visto verde, vazado | baixado e atual |
| um círculo verde, cheio | baixado e fixado. Não vai ser removido |
| duas setas num círculo | subindo ou baixando agora |
| um x vermelho ou uma exclamação | algo está errado. Normalmente conflito ou cota |

**As duas setas são as de vigiar.** Fechar um notebook enquanto um arquivo sobe não perde a
mudança — ela continua depois — mas fechar e então editar o mesmo arquivo em outro lugar é
exatamente a situação da próxima seção.

## E a frase que surpreende todo mundo

**Apagar um arquivo apaga em todo lugar, em segundos.** Inclusive do notebook dentro de uma
mochila, inclusive da máquina do seu companheiro se a pasta for compartilhada, e inclusive em
aparelhos a quem nunca ninguém vai perguntar nada.

Existe uma lixeira, e ela guarda arquivos apagados por trinta dias nos três serviços, e essa é a
proteção inteira. Um arquivo apagado e esvaziado da lixeira se foi de cada cópia dele que existia
— que é exatamente o oposto do que um backup faz, e a razão de a última seção desta aula existir.
