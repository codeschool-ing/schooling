---
title: Qual build é este? Traces vindos de produção
version: 1
---

Um trace de produção chega com uma pergunta junto: linha 20 de `main.go`, mas **qual** `main.go`? O
código na sua máquina já andou desde que o binário foi compilado. E quem aprendeu com C ou C++ traz
uma segunda preocupação, a de que um binário entregue sem símbolos e otimizado imprime endereços em
vez de linhas. **Em Go as duas respostas estão dentro do binário.** Ele registra o commit e o Go a
partir dos quais foi compilado, e tirar os símbolos dele não remove a tabela de arquivos e linhas.

## O binário sabe o seu commit

`~/stacks-release` é o programa de pedidos da seção 02 num repositório git com um commit, mais uma
função, `version`, que `main` chama primeiro para imprimir de onde o binário veio:

```go
// version says which commit and which Go this binary was built from.
func version() string {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return "unknown"
	}
	rev := "unknown"
	for _, s := range info.Settings {
		if s.Key == "vcs.revision" {
			rev = s.Value[:12]
		}
	}
	return info.Main.Version + " " + rev + " " + info.GoVersion
}

func main() {
	fmt.Println("stacks", version())
	order := []line{{"coffee", 2}, {"cake", 4}}
	fmt.Println(orderTotal(order))
}
```

```
ana@vm:~/stacks-release$ git log --oneline
d569db7 Total an order
ana@vm:~/stacks-release$ go build && ./stacks 2>/dev/null; echo $?
stacks v0.0.0-20261006130000-d569db795b44 d569db795b44 go1.27.1
2
```

O trace foi para `/dev/null` aqui, então só aparece a primeira linha, e essa linha é o que importa:
a versão do módulo, o commit e a versão do Go, impressos pelo programa sobre si mesmo antes de
fazer qualquer outra coisa. `debug.ReadBuildInfo` lê o que o comando go escreveu dentro do binário
ao compilá-lo:

```
ana@vm:~/stacks-release$ go doc runtime/debug.ReadBuildInfo
package debug // import "runtime/debug"

func ReadBuildInfo() (info *BuildInfo, ok bool)
    ReadBuildInfo returns the build information embedded in the running binary.
    The information is available only in binaries built with module support.

```

`go version -m` lê o mesmo registro de fora, de qualquer binário Go, sem executá-lo:

```
ana@vm:~/stacks-release$ go version -m stacks
stacks: go1.27.1
	path	example.com/stacks
	mod	example.com/stacks	v0.0.0-20261006130000-d569db795b44	
	build	-buildmode=exe
	build	-compiler=gc
	build	CGO_ENABLED=1
	build	CGO_CFLAGS=
	build	CGO_CPPFLAGS=
	build	CGO_CXXFLAGS=
	build	CGO_LDFLAGS=
	build	GOARCH=amd64
	build	GOOS=linux
	build	GOAMD64=v1
	build	vcs=git
	build	vcs.revision=d569db795b44a1fd42d691bd80c40be2d01226db
	build	vcs.time=2026-10-06T13:00:00Z
	build	vcs.modified=false
```

`path` é o pacote principal e `mod` é o módulo dele. Sem uma tag de versão no commit, o comando go
inventou uma versão a partir dele: `v0.0.0`, o horário do commit em UTC e os doze primeiros
caracteres do hash, o commit que o `git log` mostrou como `d569db7`. As linhas `build` são
as configurações que o build usou, e as quatro últimas são as que um incidente precisa:

```
ana@vm:~/stacks-release$ go doc runtime/debug.BuildSetting | sed -n 27,32p
      - vcs: the version control system for the source tree where the build ran
      - vcs.revision: the revision identifier for the current commit or checkout
      - vcs.time: the modification time associated with vcs.revision, in RFC3339
        format
      - vcs.modified: true or false indicating whether the source tree had local
        modifications
```

**`vcs.revision` é o commit exato, e `vcs.modified=false` diz que o binário foi compilado a partir
dele e de mais nada.** Um build a partir de uma árvore com mudanças não commitadas diz `true`, e aí
o commit sozinho não descreve o código. É por isso que o `.gitignore` deste diretório cita os três
binários compilados aqui: um binário largado na árvore também conta como mudança. O comando go
grava tudo isso sozinho quando compila dentro de um repositório; nada no programa nem no comando de
build pediu isso.

## `-trimpath`: nenhum diretório pessoal no binário

Os nomes de arquivo num trace são os que o compilador viu, e num notebook isso quer dizer o
diretório pessoal de quem compilou:

```
ana@vm:~/stacks-release$ ./stacks 2>&1 | tail -2
main.main()
	/home/ana/stacks-release/main.go:53 +0x1c8
ana@vm:~/stacks-release$ go build -trimpath -o trim . && ./trim 2>&1 | tail -2
main.main()
	example.com/stacks/main.go:53 +0x1c8
ana@vm:~/stacks-release$ go version -m trim | grep trimpath
	build	-trimpath=true
```

O `-trimpath` trocou `/home/ana/stacks-release` pelo caminho do módulo, e o `go version -m`
registra que ele foi usado. A ajuda dele diz o que faz:

```
ana@vm:~/stacks-release$ go help build | sed -n 167,171p
	-trimpath
		remove all file system paths from the resulting executable.
		Instead of absolute file system paths, the recorded file names
		will begin either a module path@version (when using modules),
		or a plain import path (when using the standard library, or GOPATH).
```

Para o módulo principal, a execução mostra só o caminho do módulo, sem `@version`. De um jeito ou
de outro, **o binário deixa de carregar um caminho da máquina que o compilou**, o que deixa nomes de
usuário e a organização de diretórios fora do que você entrega, e faz duas máquinas que compilam o
mesmo commit produzirem os mesmos nomes de arquivo nos seus traces. Builds destinados à máquina de
outras pessoas costumam usá-lo.

## Sem símbolos, e ainda legível

`-ldflags` passa flags para o linker, e `-s` é a que tira os símbolos:

```
ana@vm:~/stacks-release$ go doc cmd/link | sed -n 118,120p
    -s
    	Omit the symbol table and debug information.
    	Implies the -w flag, which can be negated with -w=0.
ana@vm:~/stacks-release$ go build -ldflags=-s -o small . && ./small 2>&1 | head -6
stacks v0.0.0-20261006130000-d569db795b44 d569db795b44 go1.27.1
panic: runtime error: index out of range [4] with length 4

goroutine 1 [running]:
main.unitPrice(...)
	/home/ana/stacks-release/main.go:20
```

O binário sem símbolos ainda imprimiu `main.unitPrice` e `main.go:20`. O tamanho dele e o registro
do build:

```
ana@vm:~/stacks-release$ wc -c stacks small
2430545 stacks
1568928 small
3999473 total
ana@vm:~/stacks-release$ go version -m small | head -3
small: go1.27.1
	path	example.com/stacks
	mod	example.com/stacks	v0.0.0-20261006130000-d569db795b44	
```

Um terço menor, e o módulo e a versão dele continuam no registro. **Tirar os símbolos remove a
tabela de símbolos e as informações DWARF que os depuradores leem; a tabela que o runtime lê para
imprimir um trace faz parte do programa e fica.** Um binário Go em produção, compilado do jeito que
um script de release preferir, ainda transforma uma queda em nomes de função, arquivos e linhas.

## De um trace a uma linha de código

O binário deu um commit, e o trace deu um arquivo e uma linha. Juntos, eles são um endereço no
repositório, e o git consegue abri-lo sem ninguém fazer checkout de nada:

```
ana@vm:~/stacks-release$ git show d569db795b44:main.go | sed -n 20p
	return prices[item] * (100 - discount[qty]) / 100
```

Essa é a linha 20 de `main.go` como estava no commit a partir do qual o binário foi compilado, com
`discount[qty]` e tudo, que é o bug que a seção 02 encontrou. **Registre a versão na inicialização,
mantenha o `GOTRACEBACK` padrão, e um trace de uma máquina em que você não consegue entrar aponta
para uma linha de um commit.**
