---
title: O caminho de um módulo, e o que o go.mod diz
version: 1
---

A lição 4 rodou `go mod init example.com/hello` e chamou o argumento de **caminho** do módulo. Ele
parece um endereço da web, e a conclusão de costume é que o comando go vai visitá-lo, então você
precisaria de um repositório em algum lugar antes de começar. **O `go mod init` não pergunta nada à
rede.** O caminho é um nome, conferido quanto ao formato e mais nada, e só vira um endereço no dia
em que outra pessoa pede para baixar o seu módulo.

O módulo desta lição é o programa que a lição 8 prometeu: ele compara duas grafias de `café`, e a
seção 03 dá a ele a sua primeira dependência. Ele começa como um arquivo só em `~/mods-accents`. Sem
argumento, o `init` recusa, e recusa também um nome com espaço:

```
ana@vm:~/mods-accents$ go mod init
go: cannot determine module path for source directory /home/ana/mods-accents (outside GOPATH, module path must be specified)

Example usage:
	'go mod init example.com/m' to initialize a v0 or v1 module
	'go mod init example.com/m/v2' to initialize a v2 module

Run 'go help mod init' for more information.
ana@vm:~/mods-accents$ go mod init "my accents"
go: malformed module path "my accents": invalid char ' '
```

A primeira mensagem fala de `GOPATH` porque, no arranjo que a lição 3 descreveu, o diretório onde um
pacote ficava era o nome dele. Fora do `GOPATH` não há de onde deduzir o nome, então você o diz. O
exemplo de uso também insinua uma regra sobre `v2` à qual esta seção volta no final.

```
ana@vm:~/mods-accents$ go mod init example.com/accents
go: creating new go.mod: module example.com/accents
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/mods-accents$ cat go.mod
module example.com/accents

go 1.27.1
```

## Escolhendo o caminho

O que você escreve depende de quem um dia vai importar o código.

| o código é | escreva | por quê |
|---|---|---|
| seu, e ninguém mais o importa | `example.com/accents`, ou qualquer nome no formato certo | `example.com` é reservado para exemplos, então nunca colide com um módulo de verdade |
| para ser publicado | onde ele vai morar: `github.com/ana/accents` | o comando go acha um módulo pedindo pelo caminho dele, e a lição 40 publica um |
| uma palavra sem ponto, como `hello` | permitido, e melhor evitar | o comando go lê um primeiro elemento sem ponto como biblioteca padrão |

A última linha é fácil de conferir. Outro módulo que importa um pacote de um módulo chamado `hello`
recebe isto:

```
ana@vm:~/mods-dotless$ go build
main.go:3:8: package hello/greet is not in std (/usr/local/go/src/hello/greet)
```

O comando go procurou `hello/greet` dentro de `/usr/local/go/src`, onde moram `fmt` e `strings`, e
não foi adiante. Um caminho que começa com um domínio nunca esbarra nisso, e é por isso que quase
todo caminho de módulo que você vai ler começa com um.

**Renomear um módulo depois significa editar cada import dos pacotes dele**, porque, como a lição 39
mostra, um caminho de importação começa pelo caminho do módulo. Escolher o endereço de publicação
no primeiro dia não custa nada, mesmo que o repositório ainda não exista.

## As linhas que o go.mod comporta

O arquivo que o `init` escreveu tem duas linhas. `module` dá nome ao módulo. `go` é a versão da
linguagem em que o módulo está escrito, a que a lição 2 mostrou decidindo como uma variável de laço
se comporta. A seção 03 acrescenta uma terceira, `require`, e essas três são o que a maioria dos
arquivos `go.mod` contém.

O formato comporta mais. `go help mod edit` lista uma flag para cada tipo de linha, e são dez:
`module`, `go`, `toolchain`, `godebug`, `require`, `exclude`, `replace`, `retract`, `tool` e
`ignore`. A lição 2 apresentou `toolchain`, a release com que um módulo prefere ser compilado, e a
lição 40 escreve `retract` quando publica uma versão. **Todo tipo de linha tem um comando que o
escreve**, no mínimo o `go mod edit`, e é o comando que você deve usar: ele confere o que escreve.

## Lendo um caminho e uma versão

A lição 1 pediu ao proxy de módulos a versão mais nova de quatro programas e imprimiu linhas como
estas:

```
k8s.io/kubernetes v1.37.1
github.com/prometheus/prometheus v0.315.0
github.com/docker/docker v28.5.2+incompatible
```

Cada linha é um caminho de módulo e uma versão. Os caminhos começam com um domínio, como a tabela
acima recomenda: o Kubernetes usa um domínio curto próprio, `k8s.io`, e os outros dois nomeiam o
GitHub. As versões são **versões semânticas**, `vMAJOR.MINOR.PATCH`. Um PATCH novo corrige alguma
coisa, um MINOR novo acrescenta alguma coisa, e um MAJOR novo tem permissão para quebrar o código
que usava o anterior. O Kubernetes está no major 1. O Prometheus está no major 0, minor 315, e o
major 0 não promete compatibilidade nenhuma de uma release para a seguinte; a lição 40 diz o que um
módulo deve aos seus usuários em cada major.

A linha do Docker é a estranha. O repositório dele recebeu a tag `v28.5.2`, e um módulo Go no major
2 ou acima termina o caminho nesse major: `/v2` para o major 2, `/v28` para o do Docker. Essa é a
regra que o exemplo `v2` da mensagem do `init` insinuava. O caminho do Docker não termina assim,
então o comando go aceita a tag e a marca. `go list -m -json` mostra de onde a versão veio, e o
arquivo que o comando go usa como o `go.mod` dela:

```
ana@vm:~/mods-accents$ go list -m -json github.com/docker/docker@v28.5.2+incompatible
{
	"Path": "github.com/docker/docker",
	"Version": "v28.5.2+incompatible",
	"Time": "2025-11-05T14:19:32Z",
	"GoMod": "/home/ana/go/pkg/mod/cache/download/github.com/docker/docker/@v/v28.5.2+incompatible.mod",
	"Origin": {
		"VCS": "git",
		"URL": "https://github.com/docker/docker",
		"Hash": "89c5e8fd66634b6128fc4c0e6f1236e2540e46e0",
		"Ref": "refs/tags/v28.5.2"
	}
}
ana@vm:~/mods-accents$ cat ~/go/pkg/mod/cache/download/github.com/docker/docker/@v/v28.5.2+incompatible.mod
module github.com/docker/docker
```

A tag é `refs/tags/v28.5.2`, um commit num repositório git. O `go.mod` é uma linha só, sem linha
`go` e sem requisitos, porque aquele commit não tem `go.mod` próprio e um substituto de uma linha
ocupa o lugar. O código-fonte do comando go diz a condição num comentário, em
`modfetch/coderepo.go`: uma tag simples num caminho sem sufixo de major só é aceita com
`+incompatible` **"if the underlying file tree has no go.mod"**, se a árvore de arquivos não tem
go.mod. Então `+incompatible` quer dizer um repositório que passou da v1 sem nunca adotar módulos.
O código continua compilando; o sufixo avisa que as versões dele não trazem nenhuma das promessas
que as versões de um módulo trazem.
