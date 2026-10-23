---
title: Duas flags do linker e o `-trimpath`
version: 1
---

O `go build` compila cada pacote e depois chama o linker, `go tool link`, para juntá-los num arquivo
só. **O `-ldflags` repassa flags a esse linker**, e duas delas tiram o que a seção 02 descobriu que o
programa nunca lê: o `-w` descarta o DWARF, e o `-s` descarta a tabela de símbolos. Uma terceira flag,
`-trimpath`, é do próprio build e muda os caminhos registrados no binário. Cada uma é medida aqui
sozinha, e depois todas juntas.

## Uma flag de cada vez

Cinco builds do mesmo código-fonte, cada um com uma mudança:

```
ana@vm:~/small$ go build -ldflags="-w" -o hits-w . && go build -ldflags="-s" -o hits-s . && go build -ldflags="-s -w" -o hits-sw .
ana@vm:~/small$ go build -trimpath -o hits-trim . && go build -trimpath -ldflags="-s -w" -o hits-small .
ana@vm:~/small$ stat -c "%s bytes  %n" hits hits-w hits-s hits-sw hits-trim hits-small
4031935 bytes  hits
2869509 bytes  hits-w
2654368 bytes  hits-s
2654368 bytes  hits-sw
4026893 bytes  hits-trim
2650272 bytes  hits-small
```

| build | bytes | menor que o padrão em |
|---|---|---|
| `go build` | 4.031.935 | |
| `-ldflags="-w"` | 2.869.509 | 1.162.426 |
| `-ldflags="-s"` | 2.654.368 | 1.377.567 |
| `-ldflags="-s -w"` | 2.654.368 | 1.377.567 |
| `-trimpath` | 4.026.893 | 5.042 |
| `-trimpath -ldflags="-s -w"` | 2.650.272 | 1.381.663 |

**O `-w` economiza 1.162.426 bytes**, a 119 bytes do total de DWARF que o `size` imprimiu. O `-s`
economiza outros 215.141, a tabela de símbolos e seus nomes. Juntos tiram **34% do arquivo**, e nada do
que o programa faz em execução muda, porque ele nunca lia nenhuma das duas partes.

**O `-s` sozinho deu exatamente o tamanho do `-s -w`.** A ajuda curta do linker diz só que o `-s`
desliga a tabela de símbolos, mas a documentação diz mais, e um build que pede o contrário mostra isso:

```
ana@vm:~/small$ go doc cmd/link | grep -A2 "^    -s$"
    -s
    	Omit the symbol table and debug information.
    	Implies the -w flag, which can be negated with -w=0.
ana@vm:~/small$ go build -ldflags="-s -w=0" -o hits-dwarf . && stat -c "%s bytes  %n" hits-dwarf
3816730 bytes  hits-dwarf
ana@vm:~/small$ file hits-small | cut -d, -f1,2,7
hits-small: ELF 64-bit LSB executable, x86-64, stripped
```

O `-s` implica o `-w`, e o `-w=0` religa o DWARF, o que devolve 1.162.362 bytes. Você vai ver
`-ldflags="-s -w"` em quase todo script de build que ler, e não faz mal: com esta versão das
ferramentas o `-w` já está implícito. O `file` agora diz que o binário é `stripped`, a palavra para um
executável sem a tabela de símbolos.

O `-trimpath` economizou só 5.042 bytes, e tamanho não é o motivo de alguém usá-lo. O que ele faz está
na próxima parte.

## O que um binário enxugado ainda faz, e o que deixa de fazer

Comece pelas ferramentas que leem as partes que saíram. O `go tool nm` não tem nada a listar, e o
`gdb`, o depurador do GNU, não encontra uma função que encontrava no build padrão:

```
ana@vm:~/small$ go tool nm hits-small
reading hits-small: no symbol section
reading hits-small: no symbols
ana@vm:~/small$ gdb -batch -ex "info line example.com/hits/internal/tally.Parse" ./hits 2>&1 | tail -1
Line 26 of "/home/ana/small/internal/tally/tally.go" starts at address 0x528ac0 <example.com/hits/internal/tally.Parse> and ends at 0x528ad3 <example.com/hits/internal/tally.Parse+19>.
ana@vm:~/small$ gdb -batch -ex "info line example.com/hits/internal/tally.Parse" ./hits-small 2>&1 | tail -1
No symbol table is loaded.  Use the "file" command.
```

**Depuradores leem o DWARF e a tabela de símbolos, então um binário enxugado não pode ser depurado no
nível do código-fonte.** O gdb veio do repositório do Ubuntu (`sudo apt install gdb`) e já estava nesta
máquina; o Delve, o depurador feito para Go, lê o mesmo DWARF. Esse é o único custo real, e a resposta
de costume é guardar o build não enxugado de cada versão que você distribui, para que uma falha na
máquina de um cliente possa ser investigada com o binário que corresponde a ela.

Agora a tabela do próprio runtime. **O `SIGQUIT` faz um programa Go imprimir a pilha de cada goroutine
e sair**, o que é um jeito de ver um rastro de pilha sem bug nenhum. O `timeout -s QUIT 1` o envia
depois de um segundo, enquanto o `hits count` espera a entrada de um `sleep` que não escreve nada, e o
`grep` fica com os quadros que pertencem ao `hits`:

```
ana@vm:~/small$ sleep 3 | timeout -s QUIT 1 ./hits-small count 2>&1 | grep -A1 -E "^(main|example)"
example.com/hits/internal/tally.Count({0x674698, 0x1fb62db46028})
	example.com/hits/internal/tally/tally.go:59 +0x12f fp=0x1fb62dbacc40 sp=0x1fb62dbaca58 pc=0x528fef
main.summarise({0x1fb62db58070?, 0x1fb62db58070?, 0x4?}, {0x674698?, 0x1fb62db46028?}, {0x6746d8, 0x1fb62db46038})
	example.com/hits/main.go:111 +0x16b fp=0x1fb62dbacd00 sp=0x1fb62dbacc40 pc=0x52c2cb
main.count({0x1fb62db58070, 0x0, 0x0}, {0x674698, 0x1fb62db46028}, {0x6746d8, 0x1fb62db46030}, {0x6746d8, 0x1fb62db46038})
	example.com/hits/main.go:56 +0x1a5 fp=0x1fb62dbacdd8 sp=0x1fb62dbacd00 pc=0x52ba85
main.run({0x1fb62db58070?, 0x0?, 0x0?}, {0x674698?, 0x1fb62db46028?}, {0x6746d8?, 0x1fb62db46030?}, {0x6746d8, 0x1fb62db46038})
	example.com/hits/main.go:38 +0x12f fp=0x1fb62dbace60 sp=0x1fb62dbacdd8 pc=0x52b76f
main.main()
	example.com/hits/main.go:28 +0x6c fp=0x1fb62dbaceb8 sp=0x1fb62dbace60 pc=0x52b60c
ana@vm:~/small$ sleep 3 | timeout -s QUIT 1 ./hits count 2>&1 | grep -A1 "^main.main"
main.main()
	/home/ana/small/main.go:28 +0x6c fp=0x37eb90ec4eb8 sp=0x37eb90ec4e60 pc=0x52b60c
```

**O binário enxugado nomeou cada função, seu arquivo e sua linha**, de `tally.Count` até `main.main`:
essa informação está na `.gopclntab`, que nenhuma flag remove. A mesma tabela explica por que um perfil
de CPU, que registra os nomes das funções ao ser escrito, se lê tão bem de um binário enxugado quanto de
qualquer outro; a lição 12 trata de perfis.

Os dois rastros diferem nos caminhos. **O `-trimpath` escreve `example.com/hits/main.go` onde o build
padrão escreve `/home/ana/small/main.go`**, um caminho de módulo no lugar de um diretório da máquina de
build, e os arquivos da biblioteca padrão perdem o prefixo `/usr/local/go/src` do mesmo jeito. O
`strings` lista as sequências de bytes imprimíveis de um arquivo, e o build padrão contém o diretório
pessoal da Ana:

```
ana@vm:~/small$ strings hits | grep -c /home/ana; strings hits-trim | grep -c /home/ana
2
0
ana@vm:~/small$ go version -m hits-small | head -3
hits-small: go1.27.1
	path	example.com/hits
	mod	example.com/hits	(devel)	
```

**Um binário que você distribui não deveria levar o seu diretório pessoal**, que pode conter um nome de
usuário e diz como sua máquina está organizada. E sem os caminhos, duas pessoas que compilam o mesmo
commit em diretórios diferentes obtêm os mesmos caminhos no binário, o que é uma das condições para
builds que saem idênticos byte a byte. Por fim, o binário enxugado ainda responde ao `go version -m`,
porque a informação de build tem uma seção própria e o `-s` não mexe nela. O módulo principal diz
`(devel)` porque este diretório ainda não está sob controle de versão. A seção 04 muda isso.
