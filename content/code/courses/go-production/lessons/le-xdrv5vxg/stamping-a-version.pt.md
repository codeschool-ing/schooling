---
title: Uma versão que o binário sabe dizer
version: 1
---

Quando alguém relata um defeito numa ferramenta, a primeira pergunta é qual build a pessoa está
rodando, e o binário deveria saber responder. **Uma versão escrita num arquivo-fonte é uma segunda
cópia do nome da versão**, e alguém precisa se lembrar de editá-la antes de cada release. No dia em que
ninguém se lembra, o programa afirma com toda a confiança a versão do mês passado, o que é pior do que
não afirmar nenhuma. A versão pertence ao lugar onde o release é de fato nomeado, a tag do git. Dois
mecanismos a levam de lá para dentro do binário: o que o comando go registra sozinho, e o `-X`, uma
flag do linker que define uma variável string enquanto o programa é ligado.

## O que o comando go registra

O `go version -m` imprimiu uma linha `mod` terminando em `(devel)` na seção 03, porque `~/small` não era
um repositório. Agora passa a ser, com o git do repositório do Ubuntu (`sudo apt install git`, se o
`git --version` não encontrar nada). Primeiro um arquivo que mantém os builds e o log fora do
repositório, `.gitignore`:

```
/hits*
access.log
```

Depois o diretório entra no git, com um commit e uma tag:

```
ana@vm:~/small$ git init -q && git add . && git commit -q -m "hits as lesson 1 left it" && git tag v1.0.0
ana@vm:~/small$ git log --oneline --decorate
c8e4f11 (HEAD -> master, tag: v1.0.0) hits as lesson 1 left it
```

A revisão, `c8e4f11`, depende de quem fez o commit e quando, então a sua vai ser outra. Compilado de
novo, o binário leva a tag e o commit:

```
ana@vm:~/small$ go build -o hits . && go version -m hits
hits: go1.27.1
	path	example.com/hits
	mod	example.com/hits	v1.0.0	
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
	build	vcs.revision=c8e4f11b0e80eec15e63704cd47c43985015d274
	build	vcs.time=2026-10-01T12:00:00Z
	build	vcs.modified=false
```

**A linha `mod` agora diz `v1.0.0`, a tag do commit que foi compilado**, e quatro configurações `vcs`
registram que o código veio do git, qual revisão, quando foi feito o commit e se a árvore de trabalho
tinha mudanças. Nada no comando de build pediu isso. O `go help build` descreve a flag que controla
isso, `-buildvcs`. No modo padrão, `auto`, o comando go registra a informação sempre que o pacote main,
o módulo dele e o diretório atual estão no mesmo repositório, e o `-buildvcs=false` a deixa de fora.

## Um subcomando `version`

O `go version -m` lê tudo isso de fora. O programa também pode ler, pelo `runtime/debug`, e imprimir
junto com um nome próprio. Isso pede um arquivo novo, `version.go`, ao lado do `main.go`:

```schooling-example
{
  "language": "go",
  "file": "version.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"io\"\n\t\"runtime/debug\"\n\t\"strings\"\n)\n",
      "note": "Um segundo arquivo no pacote `main`, ao lado do `main.go` da lição 1. **O `runtime/debug` é onde um programa lê o que o comando go registrou sobre o próprio build.**"
    },
    {
      "code": "// version names the release. The source says \"dev\", and a release build\n// replaces it at link time: go build -ldflags=\"-X main.version=v1.1.0\".\nvar version = \"dev\"\n",
      "note": "**A variável que o `-X` define.** O linker consegue substituí-la porque ela é uma `string` de pacote iniciada com uma constante, que é exatamente a condição que o `go doc cmd/link` dá; uma `const`, ou um valor calculado por uma chamada de função, fica fora do alcance dele."
    },
    {
      "code": "// printVersion answers `hits version`: the name stamped at link time, then\n// what the go command recorded about the build.\nfunc printVersion(stdout io.Writer) int {\n\tfmt.Fprintf(stdout, \"hits %s\\n\", version)",
      "note": "A primeira linha é o que a ligação deixou em `version`: `dev`, do código-fonte, ou o nome que um build de release passou."
    },
    {
      "code": "\tinfo, ok := debug.ReadBuildInfo()\n\tif !ok {\n\t\treturn 0\n\t}\n\tfmt.Fprintf(stdout, \"module %s %s, %s\\n\", info.Main.Path, info.Main.Version, info.GoVersion)\n\tfor _, s := range info.Settings {\n\t\tif strings.HasPrefix(s.Key, \"vcs.\") {\n\t\t\tfmt.Fprintf(stdout, \"%s %s\\n\", s.Key, s.Value)\n\t\t}\n\t}\n\treturn 0\n}",
      "note": "O `ReadBuildInfo` devolve o mesmo registro que o `go version -m` imprime de fora: o caminho e a versão do módulo principal, a versão do Go e as configurações de build. **Cada configuração cuja chave começa com `vcs.` veio do git** na hora do build. O `ok` só é falso para um binário compilado sem suporte a módulos."
    }
  ]
}
```

E o `run` precisa conhecer a palavra. Duas linhas entram no `switch` dele, logo antes do caso `help`,
com um editor ou com o `sed`. O `git diff` mostra exatamente o que mudou:

```
ana@vm:~/small$ sed -i '/case "help"/i\\tcase "version":\n\t\treturn printVersion(stdout)' main.go
ana@vm:~/small$ git diff
diff --git a/main.go b/main.go
index a09baa8..0da35c1 100644
--- a/main.go
+++ b/main.go
@@ -38,6 +38,8 @@ func run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {
 		return count(args[1:], stdin, stdout, stderr)
 	case "top":
 		return top(args[1:], stdin, stdout, stderr)
+	case "version":
+		return printVersion(stdout)
 	case "help", "-h", "-help", "--help":
 		fmt.Fprint(stdout, usage)
 		return 0
```

Compilado e consultado, primeiro como está e depois com `-X`:

```
ana@vm:~/small$ go build -o hits . && ./hits version
hits dev
module example.com/hits v1.0.0+dirty, go1.27.1
vcs.revision c8e4f11b0e80eec15e63704cd47c43985015d274
vcs.time 2026-10-01T12:00:00Z
vcs.modified true
ana@vm:~/small$ go build -ldflags="-X main.version=v1.1.0" -o hits . && ./hits version
hits v1.1.0
module example.com/hits v1.0.0+dirty, go1.27.1
vcs.revision c8e4f11b0e80eec15e63704cd47c43985015d274
vcs.time 2026-10-01T12:00:00Z
vcs.modified true
```

**O `-X main.version=v1.1.0` substituiu o `dev` sem mudança no código-fonte.** O nome antes do `=` é o
caminho do pacote e a variável, e para o pacote `main` o caminho é simplesmente `main`. As outras linhas
mostram o registro em ação: a árvore tem uma mudança sem commit, então a versão do módulo é
`v1.0.0+dirty` e o `vcs.modified` é `true`. Um binário feito de uma árvore assim nunca é exatamente a
versão da tag, e o registro diz isso.

**O `-X` não reclama de um nome que não encontra.** Escreva a variável com maiúscula e o build dá
certo, e o binário continua `dev`:

```
ana@vm:~/small$ go build -ldflags="-X main.Version=v1.1.0" -o hits . && ./hits version | head -1
hits dev
```

Nomes em Go diferenciam maiúsculas de minúsculas, então `main.Version` é outra variável, e o linker não
achou nenhuma string com esse nome para definir. Por isso um script de release deve conferir o
resultado: `./hits version | grep -q v1.1.0` falha alto onde o build passou calado.

## A tag, e onde o `-X` ainda faz falta

Faça o commit da mudança, ponha a tag e compile mais uma vez sem `-X`:

```
ana@vm:~/small$ git add . && git commit -q -m "hits version" && git tag v1.1.0
ana@vm:~/small$ go build -o hits . && ./hits version
hits dev
module example.com/hits v1.1.0, go1.27.1
vcs.revision ab54a88f87bb0a40de5be75684eb66198f83d4ab
vcs.time 2026-10-02T12:00:00Z
vcs.modified false
```

**O comando go tirou `v1.1.0` da tag sozinho**, e a árvore está limpa de novo. Numa máquina que compila
a partir de um checkout do git, a versão do módulo responde à pergunta com que esta seção começou, e o
`version` fica em `dev`. Mas nem todo build roda num checkout. Um arquivo com o código-fonte não tem
diretório `.git`, e nem um build que copia só os arquivos-fonte para um lugar novo, o que é comum
dentro de um contêiner. O `git archive` escreve uma cópia assim da árvore da tag:

```
ana@vm:~/small$ mkdir /tmp/small-v1.1.0 && git archive v1.1.0 | tar -x -C /tmp/small-v1.1.0
ana@vm:~/small$ cd /tmp/small-v1.1.0 && go build -o hits . && ./hits version
hits dev
module example.com/hits (devel), go1.27.1
ana@vm:~/small$ cd /tmp/small-v1.1.0 && go build -ldflags="-X main.version=v1.1.0" -o hits . && ./hits version
hits v1.1.0
module example.com/hits (devel), go1.27.1
```

**Fora de um repositório, a versão do módulo volta a `(devel)` e as linhas `vcs` somem**, porque não há
de onde lê-las. O `-X` continua funcionando, porque o valor vem do comando de build e não do diretório.
É esse o argumento para registrar a versão na ligação. O comando de build pega o nome do único lugar
onde ele está escrito, a tag, e o `git describe --tags` o imprime, então o build de release é uma linha
só:

```
ana@vm:~/small$ git describe --tags
v1.1.0
ana@vm:~/small$ go build -trimpath -ldflags="-s -w -X main.version=$(git describe --tags)" -o hits . && ./hits version
hits v1.1.0
module example.com/hits v1.1.0, go1.27.1
vcs.revision ab54a88f87bb0a40de5be75684eb66198f83d4ab
vcs.time 2026-10-02T12:00:00Z
vcs.modified false
ana@vm:~/small$ stat -c "%s bytes  %n" hits
2666656 bytes  hits
```

O `git describe --tags` imprime a própria tag num commit com tag; num commit posterior, acrescenta o
número de commits desde a tag e a revisão abreviada, então até um build entre versões diz de onde veio.
**Este é o build para distribuir**: sem DWARF, sem tabela de símbolos, sem diretório pessoal, e um
binário de 2.666.656 bytes que sabe dizer exatamente qual commit é. Ele tem 16.384 bytes a mais que o
menor build da seção 03, o preço do `version.go`, do `runtime/debug` que ele importa e da revisão
registrada.
