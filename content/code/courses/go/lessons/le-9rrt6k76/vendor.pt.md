---
title: go mod vendor, e quanto custa uma cópia
version: 1
---

Quem chega do JavaScript espera um diretório cheio de dependências ao lado do código, e procura o do
Go. Não existe: a seção 03 compilou o programa com o `golang.org/x/text` morando no cache de
módulos, fora do módulo, compartilhado por todos os módulos da máquina. **Um diretório `vendor` é
opcional em Go**, uma cópia que você pede, e nenhum módulo deste curso precisou de uma até aqui.
Esta seção cria uma em `~/mods-vendor`, uma cópia de `~/mods-accents` depois do `tidy` dele, e
depois conta quanto ela custa.

```
ana@vm:~/mods-vendor$ go mod vendor
ana@vm:~/mods-vendor$ find vendor -type f | sort
vendor/golang.org/x/text/LICENSE
vendor/golang.org/x/text/PATENTS
vendor/golang.org/x/text/transform/transform.go
vendor/golang.org/x/text/unicode/norm/composition.go
vendor/golang.org/x/text/unicode/norm/forminfo.go
vendor/golang.org/x/text/unicode/norm/input.go
vendor/golang.org/x/text/unicode/norm/iter.go
vendor/golang.org/x/text/unicode/norm/normalize.go
vendor/golang.org/x/text/unicode/norm/readwriter.go
vendor/golang.org/x/text/unicode/norm/tables15.0.0.go
vendor/golang.org/x/text/unicode/norm/tables17.0.0.go
vendor/golang.org/x/text/unicode/norm/transform.go
vendor/golang.org/x/text/unicode/norm/trie.go
vendor/modules.txt
ana@vm:~/mods-vendor$ cat vendor/modules.txt
# golang.org/x/text v0.42.0
## explicit; go 1.26.0
golang.org/x/text/transform
golang.org/x/text/unicode/norm
```

O `go mod vendor` não imprimiu nada, como o comando go faz quando dá certo. Ele não copiou o módulo;
copiou **os pacotes de que o build precisa**: `norm` e o pacote `transform` que `norm` importa.
Junto vieram `LICENSE` e `PATENTS` da raiz do módulo, que o código-fonte do comando go lista entre
os "metadata files" que ele copia ao lado de qualquer pacote que põe no vendor. O
`vendor/modules.txt` é o índice. Uma linha `#` nomeia um módulo e a versão dele, `## explicit` diz
que o `go.mod` o exige pelo nome, e as linhas abaixo são os pacotes tirados dele.

```
ana@vm:~/mods-vendor$ du -sh vendor ~/go/pkg/mod/golang.org/x/text@v0.42.0
920K	vendor
30M	/home/ana/go/pkg/mod/golang.org/x/text@v0.42.0
ana@vm:~/mods-vendor$ find ~/go/pkg/mod/golang.org/x/text@v0.42.0 -type f | wc -l
487
ana@vm:~/mods-vendor$ du -k vendor/golang.org/x/text/unicode/norm/tables*
388	vendor/golang.org/x/text/unicode/norm/tables15.0.0.go
396	vendor/golang.org/x/text/unicode/norm/tables17.0.0.go
```

Catorze arquivos contra os 487 do módulo, e 920 KB contra 30 MB. Dos 920, 784 são os dois arquivos
`tables`: os dados do Unicode, de duas edições do padrão, escritos como Go.

## O build usa o vendor sem que ninguém peça

O `go build` pega os pacotes do `vendor` sempre que o diretório existe e a linha `go` do `go.mod`
diz 1.14 ou mais. Nada muda na linha de comando, então a evidência tem de ser pedida. O `go list`
imprime de onde vem o código-fonte de um pacote:

```
ana@vm:~/mods-vendor$ go list -f "{{.Dir}}" golang.org/x/text/unicode/norm
/home/ana/mods-vendor/vendor/golang.org/x/text/unicode/norm
ana@vm:~/mods-vendor$ GOPROXY=off GOMODCACHE=/nowhere go build -o accents . && ./accents
"cafe\u0301" is 6 bytes
"caf\u00e9" is 5 bytes
equal as typed:   false
equal after NFC:  true
ana@vm:~/mods-vendor$ go list -m all
go: can't compute 'all' using the vendor directory
	(Use -mod=mod or -mod=readonly to bypass.)
```

O segundo comando é a razão de o vendor existir. `GOPROXY=off` proíbe qualquer download e
`GOMODCACHE=/nowhere` aponta o cache de módulos para um diretório que não existe, e o build
funcionou mesmo assim. **Um módulo com vendor compila a partir do próprio diretório e de mais
nada**, que é o que uma máquina de build sem acesso à rede precisa. A regra do `go 1.14` está no
próprio código-fonte do comando go, em `modload/init.go`, que dá como motivo para passar ao
diretório vendor "Go version in go.mod is at least 1.14 and vendor directory exists": a versão Go no
go.mod é pelo menos 1.14 e o diretório vendor existe.

O terceiro comando é o preço aparecendo. O `vendor` guarda pacotes, não o grafo de módulos da seção
03, então uma pergunta sobre o grafo inteiro não tem o que ler. A mensagem diz como contornar:
`-mod=mod` manda um comando só ignorar o `vendor` e usar o cache de módulos.

## Quando o go.mod e o vendor discordam

Uma cópia pode ficar velha. A lição 40 muda requisitos com `go get`; aqui o `go mod edit` faz o
papel dele e move o requisito para uma release mais antiga sem tocar no `vendor`:

```
ana@vm:~/mods-vendor$ go mod edit -require=golang.org/x/text@v0.41.0
ana@vm:~/mods-vendor$ go build; echo $?
go: inconsistent vendoring in /home/ana/mods-vendor:
	golang.org/x/text@v0.41.0: is explicitly required in go.mod, but not marked as explicit in vendor/modules.txt
	golang.org/x/text@v0.42.0: is marked as explicit in vendor/modules.txt, but not explicitly required in go.mod

	To ignore the vendor directory, use -mod=readonly or -mod=mod.
	To sync the vendor directory, run:
		go mod vendor
1
ana@vm:~/mods-vendor$ go mod tidy && go mod vendor && head -2 vendor/modules.txt
# golang.org/x/text v0.41.0
## explicit; go 1.25.0
ana@vm:~/mods-vendor$ go build && echo built
built
```

O comando go comparou os dois arquivos linha a linha e se recusou a adivinhar qual deles você quis
dizer. Essa recusa é para isso que o `modules.txt` existe. Sem ele, um build poderia compilar a
v0.42.0 em silêncio enquanto o `go.mod` prometia a v0.41.0, e o binário não seria o programa que o
módulo descreve. Primeiro o `tidy`, porque a versão nova precisa das linhas dela no `go.sum`; depois
o `vendor`, para copiá-la.

## Vale a pena usar vendor?

Sem `vendor`, um build já é reproduzível: o `go.mod` fixa as versões, o `go.sum` fixa os bytes, e o
proxy e o banco de checksums dão a mesma resposta a todo mundo. O que o vendor acrescenta é
independência desses serviços, a um custo que você paga a cada mudança.

| | sem `vendor` | com `vendor` |
|---|---|---|
| o que o repositório guarda | `go.mod` e `go.sum`, poucas linhas | esses, mais uma cópia de cada pacote que o build usa |
| um build precisa de | o cache de módulos, ou a rede para enchê-lo | o repositório, e mais nada |
| uma atualização de dependência aparece na revisão como | uma linha mudada no `go.mod` e duas no `go.sum` | o mesmo, mais cada arquivo mudado da dependência |
| depois que um requisito muda | nada mais | também `go mod vendor`, ou o build recusa |

Então o padrão é **sem `vendor`**, e os motivos para ter um são específicos. Um build pode ter de
rodar sem rede, uma regra pode exigir que cada linha compilada no binário esteja no repositório,
onde um revisor a lê, ou uma dependência pode sumir de onde foi publicada. Os seus módulos neste
curso ficam sem.
