---
title: Linhas, famílias de colunas e células
version: 1
---

**Uma tabela do Bigtable parece uma planilha e não é uma.** O hábito que `sql-databases` deixa é uma
tabela com uma lista fixa de colunas, um tipo para cada uma e um planejador que acha linhas por
qualquer uma delas. O Bigtable não tem nenhum dos três. Uma tabela é um mapa ordenado: a **chave de
linha** (row key) é uma sequência de bytes, as linhas ficam na ordem desses bytes, e a chave de linha
é a única coisa pela qual alguma coisa é buscada. Tudo dentro de uma linha também é um mapa, e pode
ser diferente em cada linha.

**Dentro de uma linha há três níveis, e só o primeiro é declarado.** Uma **família de colunas** é
declarada na tabela, com um nome e uma política de quanto tempo seus dados ficam guardados. Dentro de
uma família, um **qualificador de coluna** é qualquer string que um programa escreva, e a tabela
nunca ouve falar dele antes. Dentro de uma coluna há **células**, uma por versão, cada uma com um
timestamp. Então o endereço de um único valor tem quatro partes: chave de linha, família,
qualificador e timestamp. O Firestore da aula 10 tinha documentos com campos; aqui o mais próximo de
um campo é um qualificador, e ele é dado, não esquema.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 306\" role=\"img\" aria-label=\"Uma linha, de chave c-17, guarda duas famílias de colunas. A família p tem a coluna name com uma célula, Ana, e a coluna district com três células, Santana, Pinheiros e Mooca, da mais nova à mais antiga, cada uma com seu timestamp. A família o tem duas colunas com nomes de ids de pedido, o-10001 e o-10002, com 4290 e 1380.\" data-fig=\"l11-model\"><rect x=\"16\" y=\"30\" width=\"688\" height=\"250\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"30\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">chave de linha</text><text x=\"110\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c-17</text><rect x=\"32\" y=\"62\" width=\"420\" height=\"204\" rx=\"5\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"46\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">família de colunas</text><text x=\"150\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">p</text><text x=\"46\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">name</text><rect x=\"150\" y=\"98\" width=\"290\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"162\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana</text><text x=\"428\" y=\"112\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2026-08-29</text><text x=\"46\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">district</text><rect x=\"150\" y=\"138\" width=\"290\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"162\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Santana</text><text x=\"428\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2026-10-15</text><rect x=\"150\" y=\"172\" width=\"290\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"162\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Pinheiros</text><text x=\"428\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2026-10-14</text><rect x=\"150\" y=\"206\" width=\"290\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"162\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Mooca</text><text x=\"428\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2026-09-21</text><text x=\"150\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">células, da mais nova à mais antiga</text><rect x=\"468\" y=\"62\" width=\"220\" height=\"204\" rx=\"5\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"482\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">família de colunas</text><text x=\"586\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">o</text><text x=\"482\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">o-10001</text><rect x=\"560\" y=\"98\" width=\"116\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"572\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4290</text><text x=\"482\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">o-10002</text><rect x=\"560\" y=\"138\" width=\"116\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"572\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1380</text><text x=\"482\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qualificadores com</text><text x=\"482\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nomes tirados dos dados</text><text x=\"30\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">As famílias são declaradas na tabela; qualificadores e células são escritos com cada linha.</text></svg>", "caption": "O endereço de um valor é chave de linha, família, qualificador e timestamp. Desenhado para ilustrar; o emulador guarda as linhas em memória e não tem disposição própria."}
```

**O nome disso é coluna larga (wide column), e ele descreve os qualificadores.** Uma linha pode ter
um punhado de colunas ou centenas de milhares, e duas linhas da mesma tabela não compartilham nada
além das famílias. Uma coluna que a linha não tem não custa nada, porque nada é guardado para ela. É
por isso que o Bigtable é chamado de esparso, e é nisso que o resto da aula se apoia: um qualificador
pode ter o nome de um id de pedido ou de uma data, o que uma coluna relacional nunca pode.

## O emulador, e um arquivo que poupa digitação

O emulador do Bigtable vem com a linha de comando do Google Cloud da aula 1. Num terminal só dele,
depois das duas linhas de "Toda vez que você abrir um terminal":

```sh
cd ~/gcp
gcloud beta emulators bigtable start --host-port=localhost:8086
```

**`cbt` é a linha de comando do próprio Bigtable**, instalada na aula 1 ao lado do `gcloud`, e ela
acha o emulador por `BIGTABLE_EMULATOR_HOST`, que o seu outro terminal já exporta. Ela precisa de um
projeto e de uma instância em toda chamada, e contra o emulador qualquer nome serve:

```
ana@laptop:~/gcp$ cbt -project planner-dev -instance quitanda ls
2026/10/30 15:11:47 -creds flag unset, will use gcloud credential
```

`ls` lista as tabelas, e um emulador vazio não tem nenhuma, então a única linha é uma mensagem de log:
o `cbt` procurou credenciais e caiu nas que o `gcloud` usaria. **O `cbt` lê suas flags de
`~/.cbtrc` quando ele existe**, então escreva as três uma vez. `~/.cbtrc`:

```ini
project = planner-dev
instance = quitanda
creds = /dev/null
```

`creds = /dev/null` aponta o `cbt` para um arquivo de credenciais vazio, o que cala aquela linha.
Funciona porque o emulador não confere credencial nenhuma. **Contra o Google seria uma configuração
quebrada**, e lá o arquivo nomeia um projeto real, uma instância real e o seu login.

## Uma tabela, suas famílias, e uma linha com o que ela quiser

A Quitanda guarda seus clientes numa tabela própria enquanto aprende o formato: uma família `p` para
o perfil e uma família `o` para os pedidos do cliente, uma coluna por pedido.

```
ana@laptop:~/gcp$ cbt createtable customers families=p,o
ana@laptop:~/gcp$ cbt ls customers
Family Name	GC Policy	Value Type
-----------	---------	----------
o				{}
p				{}
ana@laptop:~/gcp$ cbt ls
customers
```

**`createtable` nomeou as famílias e mais nada**, e `ls` na tabela as lista com a política de GC
vazia, que a próxima seção preenche. Não há lista de colunas, porque ainda não há colunas. Elas
aparecem quando uma linha é escrita:

```
ana@laptop:~/gcp$ cbt set customers c-17 p:name=Ana p:district=Lapa
ana@laptop:~/gcp$ cbt set customers c-18 p:name=Bruno o:o-10004=4290 o:o-10005=1380
ana@laptop:~/gcp$ cbt read customers
----------------------------------------
"c-17"
  "p:district"                             @ 2026/10/30-15:11:47.782000
    "Lapa"
  "p:name"                                 @ 2026/10/30-15:11:47.782000
    "Ana"

----------------------------------------
"c-18"
  "o:o-10004"                              @ 2026/10/30-15:11:47.796000
    "4290"
  "o:o-10005"                              @ 2026/10/30-15:11:47.796000
    "1380"
  "p:name"                                 @ 2026/10/30-15:11:47.796000
    "Bruno"

ana@laptop:~/gcp$ cbt set customers c-18 x:note=vip
2026/10/30 15:11:47 Applying mutation: rpc error: code = Unknown desc = unknown family "x"
```

**Duas linhas, e elas não têm as mesmas colunas.** c-17 tem nome e bairro; c-18 tem nome e duas
colunas de pedido cujos qualificadores são ids de pedido, `o-10004` e `o-10005`, com o total de cada
pedido em centavos. Nada avisou a tabela sobre `district` ou `o-10004` antes. Cada célula voltou com
um timestamp, a hora em que o emulador recebeu a escrita, porque o `cbt set` não recebeu nenhum.

**A família é a única coisa que precisa existir.** A escrita em `x:note` foi recusada com `unknown
family "x"`, e nada na linha mudou. A mensagem é do emulador; o Bigtable recusa a mesma mutação com
uma frase própria. Famílias são poucas, um punhado por tabela, e é nelas que moram as decisões: o que
é guardado, por quanto tempo, e o que é lido junto.

## O valor não tem tipo

**Todo valor é bytes**, e também toda chave de linha e todo qualificador. O `4290` acima são os
quatro caracteres `4`, `2`, `9` e `0`, não um número; o `cbt` escreve o que recebeu como string. Um
programa que quer um número o guarda com largura fixa, sendo um inteiro big-endian de 8 bytes a
escolha comum, e o lê de volta do mesmo jeito. O Bigtable tem, sim, famílias de colunas agregadas que
somam inteiros dentro da célula conforme são escritos, e elas são citadas aqui para que a palavra não
seja nova quando você a encontrar; esta aula fica nos bytes simples.

**Não há join, nem índice secundário, nem transação entre linhas.** Uma escrita numa linha é atômica,
por mais células que toque, e duas linhas são duas escritas que podem dar meio certo. Uma leitura
nomeia uma chave de linha, um intervalo de chaves ou um prefixo, e filtra o que volta dentro desse
intervalo. Qualquer outra coisa é uma leitura da tabela inteira. As próximas seções tratam de escolher
a chave para que as leituras de que a Quitanda precisa sejam do primeiro tipo.
