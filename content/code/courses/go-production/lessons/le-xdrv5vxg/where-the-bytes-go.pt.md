---
title: Para onde vão os quatro megabytes
version: 1
---

Um programa que conta as linhas de um log sai do `go build` com quatro megabytes, e o palpite comum é
que binários Go são simplesmente gordos. **A maior parte desse arquivo não é o `hits`, e mais de um
terço dele nem é código.** Há o runtime e as partes da biblioteca padrão que o programa alcança, uma
tabela que o runtime lê para saber em que função está, e informação escrita para depuradores, que o
programa nunca consulta enquanto roda. Cada parte pode ser medida, e esta seção usa três ferramentas
para isso: `size`, `readelf` e `go tool nm`.

Esta lição trabalha no `hits` como a lição 1 o deixou, num diretório novo, `~/small`: o pacote
`tally`, o `main.go`, o `main_test.go` e o `genlog`, com `go mod init example.com/hits` e o
`access.log` de 20.000 linhas que o `go run ./tools/genlog -n 20000` escreve. O primeiro build, e o que
o `file` acha dele:

```
ana@vm:~/small$ go build -o hits . && stat -c "%s bytes  %n" hits
4031935 bytes  hits
ana@vm:~/small$ file hits | cut -d, -f1,2,7,8
hits: ELF 64-bit LSB executable, x86-64, with debug_info, not stripped
```

**4.031.935 bytes aqui, contra 4.031.903 na lição 1, do mesmo código-fonte.** Um binário Go registra os
caminhos dos arquivos de que foi compilado, e `~/small` não é `~/hits`. O build nativo da lição 16 em
`~/cross`, um nome de diretório do mesmo tamanho, também deu 4.031.935. Então meça o seu próprio ponto
de partida antes de comparar com qualquer número desta página; a seção 03 mostra os caminhos e a flag
que os tira. O `cut` deixou os dois campos do `file` de que esta lição trata: `with debug_info` e
`not stripped`.

## As seções de um executável

Um arquivo ELF, o formato que o Linux executa, é um cabeçalho seguido de seções com nome. O `size -A`
as lista com o tamanho em bytes e o endereço em que cada uma é carregada:

```
ana@vm:~/small$ size -A hits
hits  :
section                 size      addr
.note.go.buildid         100   4198264
.note.gnu.build-id        36   4198364
.text                1227441   4198400
.rodata                85890   5427200
.gopclntab           1049995   5513096
.go.type              213872   6563104
.go.func                1504   6776976
.go.buildinfo            320   6778880
.go.fipsinfo             120   6779200
.go.module               568   6779328
.noptrdata             41634   6779904
.data                  25522   6821568
.bss                  133112   6847104
.noptrbss              87624   6980224
.debug_abbrev            368         0
.debug_line           275035         0
.debug_frame           50663         0
.debug_gdb_scripts        42         0
.debug_info           468388         0
.debug_loclists       238976         0
.debug_rnglists       120986         0
.debug_addr             7849         0
Total                4030045


ana@vm:~/small$ readelf -S -W hits | grep -E "debug_info|symtab|strtab"
  [19] .debug_info       PROGBITS        0000000000000000 2d79dc 0725a4 00   C  0   0  1
  [23] .symtab           SYMTAB          0000000000000000 3a3c48 016c68 18     24 639  8
  [24] .strtab           STRTAB          0000000000000000 3ba8b0 01dbed 00      0   0  1
  [25] .shstrtab         STRTAB          0000000000000000 3d849d 000122 00      0   0  1
```

A lista se lê em três grupos.

**O que o programa executa.** `.text` é o código de máquina, 1.227.441 bytes dele: cada função do
`hits`, do runtime e de cada pacote padrão que o programa alcança. `.rodata`, `.data` e `.noptrdata`
guardam constantes e variáveis com valor inicial, e `.go.type` guarda os 213.872 bytes de descritores
de tipo que interfaces, `fmt` e `encoding/json` consultam em execução. `.bss` e `.noptrbss` são memória
que o programa recebe zerada. Elas têm endereço e tamanho e **nenhum byte no arquivo**, e é por isso
que a linha `Total` não é o tamanho do arquivo.

**O que o runtime lê sobre o programa.** `.gopclntab` tem 1.049.995 bytes, um quarto do arquivo. Ela
liga cada endereço de instrução à sua função, ao seu arquivo-fonte e à sua linha, e registra o tamanho
do quadro de pilha de cada função. O runtime a lê para percorrer a pilha de uma goroutine: para
imprimir um rastro de pilha, para aumentar uma pilha que ficou sem espaço e para que o coletor de lixo
encontre os ponteiros nela. Um programa Go não roda sem ela.

**O que só outros programas leem.** As oito seções `.debug_` são DWARF, o formato padrão em que um
compilador conta a um depurador sobre tipos, variáveis e linhas; somam 1.162.307 bytes. O endereço delas
é 0 porque nunca são carregadas na memória, e o `C` que o `readelf -S` imprime ao lado de `.debug_info`
quer dizer que o linker já as compactou. `.symtab` e `.strtab` nem aparecem na lista do `size`. O
`readelf` as encontra, com tamanhos em hexadecimal: `16c68` são 93.288 bytes de tabela de símbolos e
`1dbed` são 121.837 bytes dos nomes para os quais ela aponta. Essa é a lista de nomes que o `nm`, o
`gdb` e outras ferramentas consultam, e o programa também não a lê.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 240\" role=\"img\" aria-label=\"Duas barras em escala. O build padrão do hits, 4.031.935 bytes: código de máquina 1.227.441, a tabela de funções .gopclntab 1.049.995, tipos e dados 377.067, a tabela de símbolos 215.125 e a informação de depuração DWARF 1.162.307. O build com -s -w, 2.654.368 bytes, mantém as três primeiras partes intactas e perde as duas últimas, 1.377.567 bytes.\"><rect x=\"131.0\" y=\"50.0\" width=\"165.4\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"213.7\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">código de máquina</text><text x=\"213.7\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.text</text><text x=\"213.7\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.227.441</text><rect x=\"298.4\" y=\"50.0\" width=\"141.2\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"369.1\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tabela de funções</text><text x=\"369.1\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.gopclntab</text><text x=\"369.1\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.049.995</text><rect x=\"441.7\" y=\"50.0\" width=\"49.4\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"493.1\" y=\"50.0\" width=\"27.3\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"522.4\" y=\"50.0\" width=\"156.6\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.7\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">DWARF, para depuradores</text><text x=\"600.7\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.debug_*</text><text x=\"600.7\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.162.307</text><text x=\"20.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">build padrão</text><text x=\"20.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4.031.935</text><path d=\"M466.4 50.0 V30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"466.4\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tipos e dados  377.067</text><path d=\"M506.8 104.0 V122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"506.8\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tabela de símbolos  215.125</text><rect x=\"131.0\" y=\"165.0\" width=\"165.4\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"213.7\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">código de máquina</text><text x=\"213.7\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.227.441</text><rect x=\"298.4\" y=\"165.0\" width=\"141.2\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"369.1\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tabela de funções</text><text x=\"369.1\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.049.995</text><rect x=\"441.7\" y=\"165.0\" width=\"49.4\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"493.1\" y=\"165.0\" width=\"185.9\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"586.1\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">removido pelo -s</text><text x=\"586.1\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.377.567 bytes</text><text x=\"20.0\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">-s -w</text><text x=\"20.0\" y=\"201.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2.654.368</text></svg>", "caption": "O build padrão do hits por parte, em escala, segundo o size -A e o readelf -S. A flag -s leva as duas últimas partes, que o programa nunca lê; a tabela de funções fica, porque o runtime a lê."}
```

## De quem é o código

O `go tool nm` lê a tabela de símbolos, uma linha por símbolo: o endereço, o tamanho com `-size`, uma
letra para o tipo e o nome. `T` é código, `D` dado com valor inicial, `B` dado zerado e `R` dado só de
leitura, com minúscula para o que o `go doc cmd/nm` chama de símbolo estático, um que o linker mantém
local. Eis quantos são, os oito maiores e as dez funções com que o próprio `hits` contribuiu:

```
ana@vm:~/small$ go tool nm hits | wc -l
3886
ana@vm:~/small$ go tool nm -size -sort size hits | sed -n 1,8p
  60fb08     201376 r go:func.*
  691560      93464 B runtime.mheap_
  6ac880      69632 B runtime.cgroupScratch
  68d6a0      16064 B runtime.semtable
  4a91a0      11688 T time.parse
  67eb20      11136 D internal/strconv.pow10Tab
  6a9fa0      10440 B runtime.memstats
  4f7ea0      10399 T encoding/json/v2.parseFieldOptions
ana@vm:~/small$ go tool nm -size hits | grep -E " T (main|example.com/hits)"
  528ec0        901 T example.com/hits/internal/tally.Count
  528ac0       1005 T example.com/hits/internal/tally.Parse
  529260        568 T example.com/hits/internal/tally.Top
  52b8e0       1079 T main.count
  52c5e0        347 T main.encode
  52c520        165 T main.flush
  52b5a0        138 T main.main
  52b640        671 T main.run
  52c160        941 T main.summarise
  52bd20       1083 T main.top
```

**3.886 símbolos, e o `hits` escreveu dez deles.** O maior, `go:func.*`, fica num endereço dentro da
`.gopclntab`: são 201.376 bytes dos dados por função dessa tabela. O maior pedaço de código é
`time.parse`, com 11.688 bytes, que é o que o `tally.Parse` chama para cada linha. O laço abaixo soma o
código, `T` e `t`, cujos nomes começam com cada prefixo:

```
ana@vm:~/small$ for p in runtime encoding/json time fmt example.com/hits main.; do go tool nm -size hits | awk -v p=$p '$3 ~ /^[Tt]$/ && index($4, p) == 1 { s += $2 } END { print s, p }'; done
438417 runtime
265797 encoding/json
68117 time
40012 fmt
2703 example.com/hits
4468 main.
```

**O runtime tem 438.417 bytes de código, e o pacote `tally` e o `main` juntos têm 7.171**: pouco mais de
meio por cento da `.text`. A segunda maior coisa no binário é o `encoding/json`, com 265.797 bytes, e os
símbolos mostram que no Go 1.27 ele traz junto o `encoding/json/v2` e o `encoding/json/jsontext`. Esse
é o preço das duas flags `-json`. A seção 05 compila um programa que só codifica uma string, para ver
quanto a importação custa sozinha.

## Duas tabelas que nomeiam funções

As duas tabelas que guardam nomes se confundem com facilidade, e a diferença decide o que pode sair.
**A tabela de símbolos ELF é para ferramentas de fora do programa**; o linker a escreve, o `nm` e os
depuradores a leem do arquivo, e o programa em execução nunca a abre. **A `.gopclntab` é para o
runtime**, dentro do programa, e um panic nomeia suas funções lendo-a. Tirar a primeira, e o DWARF ao
lado dela, custa então o depurador e não custa nada em execução. Nenhuma flag tira a segunda, e a seção
03 mostra um binário enxugado ainda nomeando cada função num rastro de pilha.
