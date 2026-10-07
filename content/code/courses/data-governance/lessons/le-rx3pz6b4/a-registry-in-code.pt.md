---
title: A mesma ideia, nesta plataforma
version: 1
---

A plataforma em que você está lendo isto mantém a própria classificação, e vale olhar para ela
porque é o mesmo desenho da seção anterior, com um passo a mais. Ela mora no repositório da
plataforma, num pacote chamado `privacy`, e toda tabela do banco da plataforma tem uma entrada numa
lista chamada `Registry`. As classes são declaradas primeiro:

```go
// Holding is what a table has in it. Three values and no more — a fourth would
// be a judgement call, and a judgement call is what this is here to remove.
type Holding string

const (
	// Nothing about a person.
	HoldsNothing Holding = "none"
	// Identifiers and no name: meaningless once the identity rows are gone.
	HoldsPseudonymous Holding = "pseudonymous"
	// A name, an address, an e-mail — a person without being joined to anything.
	HoldsIdentifying Holding = "identifying"
)
```

Três valores, e um comentário dizendo por que não são quatro. Cada tabela recebe então uma entrada,
com o que guarda, de quem é o dado, o que acontece com ela quando uma pessoa pede para ser eliminada,
e por quê:

```go
	{
		Name: "accounts", Holds: HoldsIdentifying, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "the e-mail and the name. It is the row that makes every account_id in the database " +
			"mean a person, so deleting it is what the whole erase path is for",
	},
```

**E um teste compara a lista com o schema em uso.** `TestEveryTableInTheDatabaseIsClassified` lê
toda tabela de `information_schema.tables` e falha se uma faltar no registro, ou se o registro
nomear uma tabela que não existe mais. Uma migração que acrescenta uma tabela sem entrada não entra
— a mesma propriedade do `unclassified.sql` da Ipê, garantida pelo build em vez de por um passo de
pipeline.

## O passo além da versão da Ipê

O registro da plataforma faz mais uma coisa, e ela é o motivo de o desenho existir: **a exportação e
a eliminação dos dados de uma pessoa são construídas a partir dele.** Cada entrada diz se eliminar
uma pessoa apaga as linhas (`EraseDelete`), as deixa apontando para ninguém (`EraseOrphan`) ou as
mantém de propósito (`EraseKeep`) — e o código que atende o pedido de um titular percorre o registro
em vez de uma lista que alguém mantém à mão. Acrescentar uma tabela quer dizer decidir, na mesma
mudança, o que o pedido de uma pessoa faz com ela.

A aula 7 constrói o começo disso para a Ipê — uma exportação de tudo sobre um cliente — e a tabela de
classificação da seção anterior é o que diz a ela onde procurar.

*Os dois trechos são citados do código-fonte da plataforma como estava quando este curso foi
escrito; o arquivo muda junto com a plataforma.*
