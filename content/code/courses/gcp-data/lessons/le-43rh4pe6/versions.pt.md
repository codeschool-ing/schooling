---
title: Versões e coleta de lixo
version: 1
---

**Uma escrita numa coluna que já tem valor não o substitui; ela acrescenta uma célula.** Numa tabela
relacional um `UPDATE` deixa um valor para trás. No Bigtable a célula antiga continua lá sob o seu
próprio timestamp, a nova fica acima dela, e uma leitura devolve todas as versões a não ser que peça
menos. O que remove as antigas é uma **política de coleta de lixo** (garbage collection) na família,
e enquanto a família não tem uma, nada é removido nunca.

## Quatro bairros

c-17 se mudou três vezes. Cada escrita abaixo leva o seu próprio timestamp depois do `@`, em
**microssegundos desde 1970**, para que as quatro mudanças caiam em quatro datas e não no segundo em
que você as digitou:

```
ana@laptop:~/gcp$ cbt deleterow customers c-17
ana@laptop:~/gcp$ cbt set customers c-17 p:name=Ana@1788000000000000 p:district=Lapa@1788000000000000
ana@laptop:~/gcp$ cbt set customers c-17 p:district=Mooca@1790000000000000
ana@laptop:~/gcp$ cbt set customers c-17 p:district=Pinheiros@1792000000000000
ana@laptop:~/gcp$ cbt set customers c-17 p:district=Santana@1792100000000000
ana@laptop:~/gcp$ cbt lookup customers c-17
----------------------------------------
"c-17"
  "p:district"                             @ 2026/10/15-18:33:20.000000
    "Santana"
  "p:district"                             @ 2026/10/14-14:46:40.000000
    "Pinheiros"
  "p:district"                             @ 2026/09/21-11:13:20.000000
    "Mooca"
  "p:district"                             @ 2026/08/29-07:40:00.000000
    "Lapa"
  "p:name"                                 @ 2026/08/29-07:40:00.000000
    "Ana"

ana@laptop:~/gcp$ cbt lookup customers c-17 cells-per-column=1
----------------------------------------
"c-17"
  "p:district"                             @ 2026/10/15-18:33:20.000000
    "Santana"
  "p:name"                                 @ 2026/08/29-07:40:00.000000
    "Ana"
```

**Uma coluna, quatro células, da mais nova para a mais antiga.** O `lookup` devolveu todas porque a
família `p` ainda não tem política. `cells-per-column=1` é um filtro: ele pede a célula mais recente
de cada coluna, e é assim que um programa lê "o bairro atual". As três células antigas continuam
guardadas e continuam na conta; o filtro só decidiu o que voltava.

**O timestamp é um número com unidade, e a unidade é microssegundo.** A mesma data em
milissegundos, `1788000000000`, é um valor mil vezes menor:

```
ana@laptop:~/gcp$ cbt set customers c-18 p:district=Lapa@1788000000000
ana@laptop:~/gcp$ cbt lookup customers c-18 columns=p:district
----------------------------------------
"c-18"
  "p:district"                             @ 1970/01/21-13:40:00.000000
    "Lapa"
```

**Janeiro de 1970.** Nada recusou, porque qualquer número de 64 bits é um timestamp válido. Um
programa que escreve milissegundos onde cabem microssegundos guarda cada célula cinquenta e seis anos
no passado, e a política do próximo bloco apaga primeiro esse tipo de célula. As tabelas do Bigtable
também guardam o tempo em milissegundos, então os três últimos dígitos de um timestamp são zero, como
em todos os de cima.

## Uma política, e o que ela levou junto

**Existem duas regras, e elas se combinam.** `maxversions=N` mantém as N células mais novas de cada
coluna. `maxage=D` apaga as células cujo timestamp é mais antigo que D, contado a partir de agora.
Ligadas com `or`, uma célula vai embora quando qualquer uma das regras a condena, o que é uma
**união**; ligadas com `and`, só quando as duas condenam, uma **interseção**. A política de uma
família é definida na tabela, e o `cbt` a imprime do jeito que a API a descreve:

```
ana@laptop:~/gcp$ cbt setgcpolicy customers p maxage=30d or maxversions=2
ana@laptop:~/gcp$ cbt ls customers
Family Name	GC Policy				Value Type
-----------	---------				----------
o							{}
p		(age() > 30d || versions() > 2)		{}
ana@laptop:~/gcp$ cbt lookup customers c-17
----------------------------------------
"c-17"
  "p:district"                             @ 2026/10/15-18:33:20.000000
    "Santana"
  "p:district"                             @ 2026/10/14-14:46:40.000000
    "Pinheiros"
  "p:district"                             @ 2026/09/21-11:13:20.000000
    "Mooca"
  "p:district"                             @ 2026/08/29-07:40:00.000000
    "Lapa"
  "p:name"                                 @ 2026/08/29-07:40:00.000000
    "Ana"

ana@laptop:~/gcp$ sleep 10 && cbt lookup customers c-17
----------------------------------------
"c-17"
  "p:district"                             @ 2026/10/15-18:33:20.000000
    "Santana"
  "p:district"                             @ 2026/10/14-14:46:40.000000
    "Pinheiros"

ana@laptop:~/gcp$ cbt lookup customers c-18
----------------------------------------
"c-18"
  "o:o-10004"                              @ 2026/10/30-15:11:47.796000
    "4290"
  "o:o-10005"                              @ 2026/10/30-15:11:47.796000
    "1380"
  "p:name"                                 @ 2026/10/30-15:11:47.796000
    "Bruno"
```

**`(age() > 30d || versions() > 2)` se lê como a condição para apagar**, não para manter: uma célula
com mais de trinta dias, ou além da segunda versão, é lixo. O primeiro lookup, logo depois de a
política ser definida, ainda devolveu as cinco células. O segundo, dez segundos depois, devolveu duas.

**Lapa e Mooca saíram pelos dois motivos, e o nome de Ana foi junto.** O bairro tinha quatro versões,
então as duas mais antigas estavam além da segunda; também tinham mais de trinta dias. Mas `p:name`
tinha uma versão, escrita em 29 de agosto, e **uma regra de idade é aplicada a toda célula da
família, inclusive à única versão**. Hoje é 30 de outubro, então o nome tinha 62 dias e foi apagado.
A política fez exatamente o que diz. O projeto é que estava errado: dado que nunca pode expirar não
pertence a uma família com `maxage`. O bairro de c-18, de janeiro de 1970, saiu na mesma passada, e
o nome Bruno só continua lá porque foi escrito hoje; em trinta dias ele vai também.

**O conserto é uma segunda família, porque a política mora na família.** Um perfil guarda o nome
numa família com `maxversions=1` e mais nada, e guarda o que é histórico, os endereços ou os cliques
da próxima seção, numa família cuja regra de idade bate com o tempo que a Quitanda pretende
guardá-los. Escolher famílias é escolher retenção.

## Coletado depois, não na hora

**A coleta de lixo roda em segundo plano, e uma leitura pode devolver uma célula que a política já
condenou.** O emulador aqui coletou em segundos, e o primeiro lookup acima mostra a janela que ele
deixou. A documentação do Google descreve a coleta do Bigtable como algo que acontece durante a
compactação, num calendário próprio que pode levar até uma semana. Ela diz que uma leitura não deve
contar com ela: se um programa precisa de no máximo uma versão, ele pede com um filtro, como fez
`cells-per-column=1`. A conta segue o mesmo calendário. A página de preços diz que versões expiradas
são cobradas até serem coletadas, e o mesmo vale para dados apagados até a tabela ser compactada.

**Mudar uma política é instantâneo e o efeito dela não é.** Apertar `maxversions` de 3 para 1 torna
lixo as células mais antigas no momento em que a mudança chega, e elas somem do armazenamento ao
longo dos dias seguintes. Afrouxar não traz de volta o que já foi coletado. Numa instância que replica
entre clusters, `cbt setgcpolicy` se recusa a afrouxar uma política sem `force`, porque cada cluster
pode ter coletado uma quantidade diferente e eles passariam a discordar.
