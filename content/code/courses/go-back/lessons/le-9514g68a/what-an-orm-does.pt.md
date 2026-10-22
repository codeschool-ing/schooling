---
title: O que um ORM faz, e o que ele esconde
version: 1
---

A aula 6 escreveu à mão cada comando SQL que o boxoffice manda, e leu à mão cada coluna para um
campo. **Um ORM, um mapeador objeto-relacional, escreve esses comandos por você a partir dos seus
tipos.** Você descreve uma struct, e ele cria a tabela, insere um valor dessa struct como linha, lê
linhas de volta para valores e segue os relacionamentos entre elas. O GORM é o mais usado em Go, e
esta aula usa a versão atual dele, a v1.31.2, com o driver de PostgreSQL, que é construído sobre o
mesmo pgx da aula 6.

A troca é simples de enunciar e fácil de subestimar:

| um ORM te dá | e te custa |
|---|---|
| nada de SQL nas operações comuns: criar, buscar por id, atualizar um campo, apagar | o SQL que ele escreve não está no seu código, então ler o código não diz o que se pede ao banco |
| relacionamentos carregados pelo nome, `Preload("Tickets")` | um laço inocente manda cem consultas, o assunto da seção 06 |
| um schema feito a partir das structs | um schema que só sabe o que as tags das structs dizem, que é menos do que a tabela da aula 6 dizia |
| uma API para vários bancos | regras próprias, que são o assunto da seção 07 |

**Nada nesta aula muda o boxoffice.** O GORM ganha um projeto próprio, o `gormlab`, com um banco
próprio, para poder criar tabelas à vontade e para que a comparação com o código pgx da aula 6 fique
lado a lado em vez de virar uma reescrita. A aula 8 mostra a abordagem oposta, e a seção 08 daqui diz
quando o GORM é a escolha certa.

## O projeto

O `gormlab` é um módulo com um pacote de modelos e vários programas pequenos, cada um um comando em
`cmd/`, cada um mostrado inteiro na seção que o roda:

```localised
gormlab/
  models/models.go        os dois modelos e uma função para conectar
  cmd/migrate/main.go     seção 03
  cmd/crud/main.go        seção 04
  cmd/relations/main.go   seção 05
  cmd/nplus1/main.go      seção 06
  cmd/pitfalls/main.go    seção 07
```

Ele usa um banco próprio, criado do jeito que a aula 6 criou o `boxoffice`. Com os arquivos da seção
03 no lugar, o `go mod tidy` busca o GORM:

```
ana@vm:~/gormlab$ createdb gormlab
ana@vm:~/gormlab$ export DATABASE_URL='postgres:///gormlab?host=/var/run/postgresql'
ana@vm:~/gormlab$ go mod init example.com/gormlab
go: creating new go.mod: module example.com/gormlab
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/gormlab$ go mod tidy
go: finding module for package gorm.io/driver/postgres
go: finding module for package gorm.io/gorm
go: finding module for package gorm.io/gorm/logger
go: found gorm.io/gorm in gorm.io/gorm v1.31.2
go: found gorm.io/gorm/logger in gorm.io/gorm v1.31.2
go: found gorm.io/driver/postgres in gorm.io/driver/postgres v1.6.3
ana@vm:~/gormlab$ sed -n 1,8p go.mod
module example.com/gormlab

go 1.27.1

require (
	gorm.io/driver/postgres v1.6.3
	gorm.io/gorm v1.31.2
)
```

**Duas dependências diretas**, o GORM e o driver dele. O `go mod tidy` também baixou o driver de
SQLite e o `go-sqlite3`, que os testes do próprio driver de PostgreSQL usam; eles não entram no
binário, e mostram até onde um grafo de módulos vai além do que um programa chama.
