---
title: Nada se propaga
version: 1
---

Você muda um registro. Alguém diz que vai levar até quarenta e oito horas para **propagar**. Essa
palavra está errada, e acreditar nela impede você de fazer a única coisa que teria tornado a mudança
rápida.

Nada se espalha. Nada é empurrado a lugar nenhum. Nenhum servidor é avisado de que você mudou algo.

O que de fato acontece é que resolvedores pelo mundo estão segurando uma resposta velha, cada um por
um tempo que **você** especificou, e cada um pergunta de novo quando a própria cópia acaba.

## O número está em cada registro

Cada registro leva um **tempo de vida** em segundos. É uma instrução a quem receber a resposta: você
pode usar isto por este tempo.

```
www.example.com.   300   A   203.0.113.7
```

Trezentos: cinco minutos. Um resolvedor que perguntar às 14:00 vai responder da própria cópia até
14:05 e então perguntar de novo. Mude o registro às 14:01 e aquele resolvedor serve o endereço velho
por mais quatro minutos — não por causa de distância, não por causa de propagação, mas porque você
disse que ele podia.

## É por isso que aparece para uns e não para outros

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Três resolvedores têm a resposta velha, cada um tendo perguntado num momento diferente. Depois de o registro mudar, cada um serve o valor velho até a própria cópia acabar, então a mudança aparece em três horários diferentes.\"> <text x=\"20\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">o registro muda às 14:01, com um TTL de cinco minutos</text> <rect x=\"20\" y=\"40\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">você faz a mudança — e ninguém é avisado</text> <rect x=\"20\" y=\"90\" width=\"420\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"230\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">resolvedor A perguntou às 14:00 — resposta velha até 14:05</text> <text x=\"460\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">nova às 14:05</text> <rect x=\"20\" y=\"132\" width=\"560\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"300\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">resolvedor B perguntou às 14:03 — resposta velha até 14:08</text> <text x=\"600\" y=\"149\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">nova às 14:08</text> <rect x=\"20\" y=\"174\" width=\"240\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"140\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">resolvedor C não tinha nada</text> <text x=\"280\" y=\"191\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">nova na hora</text> <text x=\"360\" y=\"240\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">não é uma onda se espalhando — são cronômetros independentes</text> <text x=\"360\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">e o máximo que alguém espera é um TTL, que é um número que você escolheu</text> </svg>", "caption": "Três pessoas veem a mudança em três momentos diferentes, e nada disso tem a ver com distância."}
```

Cada resolvedor começou o relógio num momento diferente: quando a primeira pessoa daquela rede por
acaso perguntou. Então as cópias deles expiram em momentos diferentes, espalhados pelo TTL inteiro.

Essa é a forma real do fenômeno que as pessoas descrevem como propagação. Não é uma onda se movendo
para fora. É um conjunto de cronômetros independentes, nenhum dos quais você vê, todos terminando
dentro de um TTL contado da mudança.

E isso dá a garantia que vale lembrar: **o máximo que alguém espera é um TTL**, contado da sua
mudança. Não quarenta e oito horas, a menos que quarenta e oito horas seja o que você definiu.

## Então baixe antes de mudar, não depois

O roteiro tem três passos e transforma um dia em alguns minutos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três passos: baixar o tempo de vida pelo menos um TTL antigo antes da mudança, fazer a mudança para que toda cópia expire em um minuto, e depois voltar a subir o tempo de vida.\"> <rect x=\"20\" y=\"36\" width=\"216\" height=\"104\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"128\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">no dia anterior</text> <text x=\"128\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">baixe o TTL para 60</text> <text x=\"128\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">esta mudança espera o</text> <text x=\"128\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">TTL antigo, que é o ponto</text> <rect x=\"252\" y=\"36\" width=\"216\" height=\"104\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a mudança</text> <text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">altere o registro</text> <text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">toda cópia do mundo</text> <text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">expira em um minuto</text> <rect x=\"484\" y=\"36\" width=\"216\" height=\"104\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"592\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">depois</text> <text x=\"592\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">volte a subir o TTL</text> <text x=\"592\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">menos perguntas, e uma</text> <text x=\"592\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">folga se seus servidores caírem</text> <text x=\"360\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">a primeira caixa é o passo que todo mundo pula</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">e pular isso é toda a razão de uma mudança levar um dia em vez de um minuto</text> </svg>", "caption": "Três passos. O que não custa nada e é sempre deixado de fora é o primeiro."}
```

**No dia anterior**, baixe o TTL dos registros que você vai mudar — para sessenta segundos, digamos.
Essa mudança está ela mesma sujeita ao TTL *antigo*, e é por isso que precisa acontecer pelo menos
com essa antecedência. É o passo que todo mundo pula, e pulá-lo é o que deixa a mudança lenta.

**Faça a mudança.** Agora as cópias do mundo expiram com um minuto de diferença entre si.

**Volte a subir o TTL** quando estiver satisfeito, porque um TTL baixo custa algo: mais perguntas aos
seus servidores autoritativos, e uma folga menor se eles um dia ficarem inalcançáveis. Um dia é um
valor de repouso razoável para um registro que raramente se move.

## O que você não controla

Há um TTL neste sistema que não é seu: o que o registro põe nos seus `NS` nos servidores de TLD. É
comumente um ou dois dias, e é por isso que *trocar servidores de nomes* realmente leva muito mais
tempo que mudar um registro.

Essa é a origem verdadeira do folclore das quarenta e oito horas. Ele é exato para exatamente um tipo
de mudança — mover o domínio inteiro para outro provedor de DNS — e vem sendo repetido desde então
sobre mudanças que levam cinco minutos.

## Um nome que não existe também é cacheado

Este surpreende as pessoas, e tem um formato memorável.

Quando um resolvedor é informado de que um nome não existe, ele cacheia isso também — é o **cache
negativo**, e a duração vem de um campo do registro `SOA` do domínio em vez de qualquer TTL que você
tenha posto no registro que está criando, porque o registro não existia para carregar um.

Então: consulte um nome antes de criá-lo, e você pode esperar mais tempo para ele aparecer do que se
nunca tivesse perguntado. A inexistência está num cache, com uma duração escolhida pelos padrões do
domínio, e criar o registro não alcança lá dentro para removê-la.

A regra prática é o oposto do instinto: **não fique conferindo um nome que você está prestes a
criar.** Crie, e depois confira.

## Escolhendo um número

Um resumo curto, porque esta é uma decisão de verdade e costuma ser tomada por acidente.

**De sessenta segundos a cinco minutos** para qualquer coisa que você está ativamente movendo, e para
registros na frente de um sistema que troca de servidor mudando-os.

**De uma hora a um dia** para o caso comum: um site que fica onde fica.

**Um dia ou mais** para registros que genuinamente nunca mudam, e para registros `MX` em particular,
onde a folga durante uma queda de DNS vale mais do que a velocidade de uma mudança que você faz uma
vez por década.

E uma coisa que não é questão de gosto: o TTL é uma promessa sobre o passado tanto quanto sobre o
futuro. O que ele disser agora é o que alguém pode ainda estar usando daqui a uma hora, então a hora
de pensar nele é antes de precisar da mudança, e não durante.
