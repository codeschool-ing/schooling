---
title: Além do linker
version: 1
---

As flags do linker tiraram um terço do arquivo, e o que sobra é quase todo código e a tabela que o
descreve. **Há mais três alavancas, e só uma delas muda o que está no programa.** Um compressor espreme
o arquivo pronto, uma flag do compilador troca velocidade por bytes, e as importações decidem quanto da
biblioteca padrão e dos módulos dos outros está no programa para começo de conversa. Cada uma é medida
aqui no build de release da seção 04, que tem 2.666.656 bytes.

## Compactar o arquivo com o UPX

O UPX, o Ultimate Packer for eXecutables, reescreve um executável como um pequeno descompactador
seguido do programa original, compactado. O repositório do Ubuntu o tem como `upx-ucl`
(`sudo apt install upx-ucl`), e ele foi instalado assim aqui:

```
ana@vm:~/small$ upx --version | head -1
upx 4.2.2
ana@vm:~/small$ upx --best -q -o hits-upx hits
                       Ultimate Packer for eXecutables
                          Copyright (C) 1996 - 2024
UPX 4.2.2       Markus Oberhumer, Laszlo Molnar & John Reiser    Jan 3rd 2024

        File size         Ratio      Format      Name
   --------------------   ------   -----------   -----------
   2666656 ->   1140620   42.77%   linux/amd64   hits-upx

Packed 1 file.
ana@vm:~/small$ stat -c "%s bytes  %n" hits hits-upx
2666656 bytes  hits
1140620 bytes  hits-upx
ana@vm:~/small$ ./hits-upx top -n 2 access.log
path         requests
/login       2576
/api/orders  2542
ana@vm:~/small$ go version -m hits-upx; echo $?
hits-upx: could not read Go build info from hits-upx: not a Go executable
1
```

**1.140.620 bytes, 42,77% do original, e o programa continua contando.** O `go version -m` não consegue
mais lê-lo, nem qualquer outra ferramenta que leia a informação de build de um binário Go, porque essa
informação agora está dentro da parte compactada. O custo que importa é pago a cada partida, quando o
descompactador reconstrói o programa na memória antes de rodá-lo. Cem partidas do `hits version`, que
quase não faz mais nada:

```
ana@vm:~/small$ time (for i in $(seq 100); do ./hits version > /dev/null; done)

real	0m0.270s
user	0m0.116s
sys	0m0.047s
ana@vm:~/small$ time (for i in $(seq 100); do ./hits-upx version > /dev/null; done)

real	0m2.182s
user	0m1.591s
sys	0m0.187s
```

**0,270 segundo contra 2,182, menos de 3 milissegundos por partida contra 22.** Os números mudam de uma
execução para outra, e a razão, cerca de oito vezes, é a parte a guardar. Quem digita um comando não
vai notar 19 milissegundos; um script que chama o `hits` para cada um de dez mil arquivos vai.

A outra metade da comparação é que um arquivo raramente vai para algum lugar sem compressão. Um release
é baixado como arquivo compactado, e o `gzip`, o compressor de todo `.tar.gz`, faz quase o mesmo com o
binário comum:

```
ana@vm:~/small$ gzip -9 -c hits | wc -c; gzip -9 -c hits-upx | wc -c
1171128
1118110
```

**O `gzip -9` leva o binário comum a 1.171.128 bytes**, 30.508 a mais que o UPX, e o usuário o
descompacta uma vez em vez de a cada partida. Um arquivo UPX quase não compacta mais, porque bytes
compactados parecem aleatórios. O UPX compensa onde o binário é guardado e executado sem compressão e o
tamanho em disco é a restrição, o que é mais raro do que parece; para uma ferramenta que alguém baixa,
o arquivo compactado já fez a maior parte do trabalho.

## Flags do compilador

O `-gcflags` repassa flags ao compilador, `go tool compile`, como o `-ldflags` as repassa ao linker. Com
uma flag sozinha, ela vale só para os pacotes citados na linha de comando; com `all=` na frente, para
todo pacote do build, a biblioteca padrão inclusive. Duas flags do compilador mudam o tamanho, em
direções opostas:

```
ana@vm:~/small$ go build -trimpath -gcflags=all=-l -ldflags="-s -w" -o hits-noinline . && stat -c "%s bytes  %n" hits hits-noinline
2666656 bytes  hits
2543776 bytes  hits-noinline
ana@vm:~/small$ go build -o hits-default . && go build -gcflags="all=-N -l" -o hits-debug . && stat -c "%s bytes  %n" hits-default hits-debug
4055138 bytes  hits-default
4190697 bytes  hits-debug
```

**O `-l` desliga o inlining e economizou 122.880 bytes, 4,6%.** O inlining copia o corpo de uma função
pequena para cada lugar que a chama, o que custa bytes e economiza uma chamada. Veja o que desligá-lo
fez com o tempo que o `hits` leva sobre um milhão de linhas:

```
ana@vm:~/small$ go run ./tools/genlog -n 1000000 > big.log; wc -l big.log
1000000 big.log
ana@vm:~/small$ time ./hits count big.log > /dev/null

real	0m0.324s
user	0m0.287s
sys	0m0.048s
ana@vm:~/small$ time ./hits-noinline count big.log > /dev/null

real	0m0.431s
user	0m0.375s
sys	0m0.049s
```

**0,324 segundo com inlining e 0,431 sem, um terço mais lento**, por um arquivo 4,6% menor. É uma troca
ruim para quase todo programa. O `-N -l`, que também desliga o otimizador, deixou o binário 135.559
bytes *maior* que o build padrão. É o par para quando um depurador precisa percorrer o código
exatamente como foi escrito, e nunca o par para distribuir.

## O que o programa importa

**Todo pacote que um programa importa está no binário, junto com tudo o que esse pacote importa.** O
linker deixa de fora funções que ninguém chama, mas não pode deixar de fora o que o programa usa. Para
ver o custo de uma importação sozinha, eis três programas que imprimem `hello` e não fazem mais nada,
num diretório próprio, `~/sizes`, com `go mod init example.com/sizes`. O primeiro escreve direto na
saída padrão, `none/main.go`:

```go
package main

import "os"

func main() {
	os.Stdout.WriteString("hello\n")
}
```

O segundo usa o `fmt`, `fmtonly/main.go`:

```go
package main

import "fmt"

func main() {
	fmt.Println("hello")
}
```

O terceiro codifica a palavra como JSON, `withjson/main.go`:

```go
package main

import (
	"encoding/json"
	"os"
)

func main() {
	json.NewEncoder(os.Stdout).Encode("hello")
}
```

Cada um é compilado com `-s -w`, medido e perguntado de quantos pacotes depende, com o
`go list -deps`, que imprime um pacote por linha:

```
ana@vm:~/sizes$ for p in none fmtonly withjson; do go build -ldflags="-s -w" -o $p.bin ./$p; done
ana@vm:~/sizes$ stat -c "%s bytes  %n" none.bin fmtonly.bin withjson.bin
1310880 bytes  none.bin
1511584 bytes  fmtonly.bin
2568352 bytes  withjson.bin
ana@vm:~/sizes$ for p in none fmtonly withjson; do echo "$(go list -deps ./$p | wc -l) $p"; done
54 none
60 fmtonly
75 withjson
```

| programa | bytes, `-s -w` | pacotes |
|---|---|---|
| `none` | 1.310.880 | 54 |
| `fmtonly` | 1.511.584 | 60 |
| `withjson` | 2.568.352 | 75 |

**1.310.880 bytes é o piso**: o runtime e os pacotes de que ele precisa, com uma linha de programa por
cima. O `fmt` acrescenta 200.704 bytes e seis pacotes. O `encoding/json` acrescenta 1.257.472 bytes
sobre o piso, e um programa que codifica uma string chega a 97% dos 2.650.272 bytes do menor `hits` da
seção 03. A seção 02 achou o mesmo pacote como o segundo maior bloco de código do `hits`, e este é o
preço dele medido sozinho.

**As importações são a alavanca que move megabytes.** As lições 2 e 3 refizeram o `hits` sobre o Cobra
e sobre o urfave/cli, e cada versão saiu mais de um megabyte maior que a da lição 1, para os mesmos dois
subcomandos. Pode ser um preço justo por completação e ajuda gerada, e é um preço que nenhuma flag do
linker devolve. O `go list -deps` responde o que uma dependência traz antes de qualquer build; se o
`-json` vale um megabyte para o `hits` é uma pergunta sobre os usuários dele, e é a medida que faz dela
uma pergunta.
