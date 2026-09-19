---
title: Quatro jeitos de perder, e são quatro problemas diferentes
version: 1
---

"Fazer backup" soa como uma coisa e são quatro. Dados se perdem de quatro jeitos distintos, e um
arranjo que resolve três deles ainda perde tudo no dia em que o quarto acontece.

1. **Você apaga.** Ou sobrescreve, ou salva por cima da versão boa com uma ruim. Esse é de longe
   o mais comum e é o único em que a máquina está funcionando perfeitamente.
2. **O hardware falha.** Um disco para. O controlador de um SSD morre, que é o tipo repentino —
   ele funciona e então não está mais lá, sem barulho de aviso.
3. **A máquina vai embora.** Roubo, incêndio, alagamento, uma bebida derramada. Tudo no cômodo
   some de uma vez, inclusive o disco externo na mesa ao lado.
4. **Algo muda os arquivos com eles ainda na sua mão.** Um ransomware os criptografa, um disco em
   falha os corrompe em silêncio, uma sincronia ruim sobrescreve a cópia boa com uma vazia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 284\" role=\"img\" aria-label=\"Uma grade de quatro jeitos de perder dados contra três arranjos. Apagar sem querer: talvez sobreviva com um serviço de sincronia, sobrevive com um disco externo e com o três dois um. Um disco que falha: sobrevive nos três. Uma máquina roubada ou queimada: sobrevive com um serviço de sincronia e com o três dois um, perdida só com um disco externo. Algo que criptografa tudo: perdido com um serviço de sincronia, talvez sobreviva com um disco externo, sobrevive com o três dois um. Uma nota diz que só a última coluna tem um sim em toda linha.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Quatro jeitos de perder, e o que cada arranjo sobrevive</text><text x=\"385\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um serviço de sincronia</text><text x=\"505\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um disco externo</text><text x=\"625\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">três, dois, um</text><text x=\"24\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">você apaga sem querer</text><rect x=\"330\" y=\"66\" width=\"110\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">talvez</text><rect x=\"450\" y=\"66\" width=\"110\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"505\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sobrevive</text><rect x=\"570\" y=\"66\" width=\"110\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sobrevive</text><text x=\"24\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o disco falha</text><rect x=\"330\" y=\"110\" width=\"110\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sobrevive</text><rect x=\"450\" y=\"110\" width=\"110\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"505\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sobrevive</text><rect x=\"570\" y=\"110\" width=\"110\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sobrevive</text><text x=\"24\" y=\"172\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a máquina é roubada ou queima</text><rect x=\"330\" y=\"154\" width=\"110\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sobrevive</text><rect x=\"450\" y=\"154\" width=\"110\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"505\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">perdido</text><rect x=\"570\" y=\"154\" width=\"110\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sobrevive</text><text x=\"24\" y=\"216\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">algo criptografa tudo</text><rect x=\"330\" y=\"198\" width=\"110\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">perdido</text><rect x=\"450\" y=\"198\" width=\"110\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"505\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">talvez</text><rect x=\"570\" y=\"198\" width=\"110\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sobrevive</text><text x=\"24\" y=\"264\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Só a última coluna responde a todas as linhas, e é essa a razão de a regra ter três números.</text></svg>", "caption": "A linha interessante é a última, porque um serviço de sincronia é o arranjo que a maioria das pessoas de fato tem."}
```

## A frase pela qual esta aula existe

**Sincronizar não é fazer backup.**

Um serviço de sincronia — Drive, OneDrive, iCloud, Dropbox — mantém dois lugares idênticos. É
para isso que ele serve e é genuinamente útil. Também significa que **uma exclusão é copiada**, e
que **um arquivo criptografado um segundo atrás é copiado**, e os dois em questão de segundos,
para todo aparelho que você tem.

Ele responde à segunda e à terceira linha daquela grade perfeitamente e à primeira e à quarta
mal. O que é uma pena, porque a primeira e a quarta são as que acontecem.

O que o resgata em parte é o **histórico de versões**: a maioria dos serviços guarda versões
anteriores e arquivos apagados por algo entre trinta dias e um ano. Essa é uma rede de segurança
real e é um recurso diferente da sincronia, tem de ser procurado e usado de propósito, e não está
sempre ligado em todo plano.

## O que um backup de fato é

Um backup é **uma cópia que não muda quando o original muda.** Essa propriedade sozinha é o que o
separa de todo tipo de espelho, sincronia e duplicata, e é o que torna a primeira e a quarta
linhas sobrevivíveis.

Tudo no resto desta aula é um jeito de tornar essa cópia barata o bastante para você de fato
continuar fazendo.

## E a falha que não está na lista

**Um backup do qual ninguém nunca restaurou é uma hipótese.** Um programa de backup que roda há
dois anos para um disco com o sistema de arquivos quebrado produz um visto verde toda noite e
nada no fim.

Restaure um arquivo. Não a máquina inteira — um arquivo, do mês passado, para a área de trabalho,
e abra. Leva quatro minutos e converte a hipótese num fato. Faça quando armar o backup e uma vez
por ano depois disso.
