---
title: O modelo é um retrato do esquema, não o esquema
version: 1
---

A maioria dos ORMs deixa você declarar a tabela na linguagem — uma classe com campos tipados — e
gerar a migração a partir da declaração. É conveniente, e convida a uma crença que custa: a de que
a classe **é** a tabela, e de que uma regra escrita na classe é uma regra que o dado obedece.

## O banco aplica; o modelo descreve

```
class Order:
    customer = ForeignKey(Customer)
    total    = Decimal(10, 2)
    status   = Choice('pending', 'paid', 'shipped', 'cancelled')
```

Três regras, e onde cada uma é aplicada decide se ela vale:

**A chave estrangeira** vira `REFERENCES customers (id)` no DDL gerado, e o banco recusa um pedido
de um cliente que não existe — de toda conexão, inclusive o script de relatório e a sessão do
`psql` que passa por fora do modelo.

**O decimal** vira `numeric(10,2)`, e o argumento da aula 3 a favor do tipo é preservado.

**A escolha** é a que merece atenção. Alguns mapeadores a transformam numa restrição `CHECK`;
muitos a mantêm só na classe, como validação que roda quando *este código* salva *este objeto*.
Uma linha inserida por qualquer outra coisa — uma carga em massa, outro serviço, uma migração, um
`UPDATE` escrito à mão — carrega o status que quiser. O ponto da aula 1 sobre restrições chega:
**uma regra que o banco não conhece é uma regra que algumas linhas não seguem.**

O mesmo vale para o `NOT NULL` que só existe como campo obrigatório, para a unicidade que só
existe como validação — a aula 8 mostrou que essa é um write skew esperando duas requisições — e
para tamanhos e faixas conferidos no formulário e em mais lugar nenhum. Ponha-os na tabela. A
validação do modelo ainda vale a pena, pela mensagem de erro, e é a segunda linha de defesa em vez
da primeira.

## O que o DDL gerado deixa de fora

Uma migração gerada de um modelo é uma tradução, e toda tradução tem padrões. Três coisas a
conferir em qualquer esquema que um ORM escreveu:

**O índice na chave estrangeira.** A frase mais valiosa da aula 9: o PostgreSQL não cria um.
Alguns mapeadores o acrescentam quando geram a coluna e alguns não, e os que não o fazem produzem a
exclusão de quatro minutos que a aula 9 descreveu, num esquema que parece completo. Rode a
consulta da aula 9 de chaves estrangeiras sem índice contra qualquer banco que um ORM construiu.

**Os tipos.** Um campo de texto sem tamanho vira `varchar(255)` em algumas ferramentas e `text`
em outras; um datetime vira `timestamp` sem fuso em algumas e `timestamptz` em outras. A aula 3
disse qual deles está certo e por quê, e a migração gerada é onde conferir se a ferramenta
concordou.

**As restrições que precisam de uma varredura.** Um índice único que o modelo pediu é construído
com bloqueio por padrão, porque o gerador não sabe que a tabela é grande. O `CONCURRENTLY` da aula
9 e a nota da seção de migrações sobre transações são seus para acrescentar, não do gerador.

O hábito é simples: **leia a migração gerada antes de rodá-la**. É SQL; a aula 3 cobre tudo o que
está nela; e um gerador que produziu algo surpreendente é um gerador que vai produzir de novo.

## Duas direções

Do modelo para o esquema — declarar a classe, gerar o DDL — é a direção que a maioria dos
tutoriais mostra, e serve a uma aplicação nova cujo banco tem um cliente só. Do esquema para o
modelo — escrever o DDL, e gerar ou introspectar as classes a partir dele — é a outra, e serve a um
banco que sobrevive às suas aplicações, tem várias, ou é dividido com gente que escreve SQL.

Nenhuma é errada. O erro é esquecer qual você escolheu. Um time que gera o esquema a partir do
modelo e depois edita o esquema à mão tem duas fontes de verdade, e a próxima migração gerada vai
tentar desfazer a edição. Escolha uma, e deixe a outra ser derivada.

## O esquema é o contrato

Uma aplicação é substituída; um banco é migrado. As linhas em `orders` vão ser lidas por código que
ainda não foi escrito, numa linguagem que ninguém do time escolheu, e a única coisa em que esse
código vai poder confiar é o que o banco aplicou. Uma restrição na classe é uma promessa a esta
aplicação. Uma restrição na tabela é uma promessa a toda aplicação que algum dia a abrir — e é por
isso que a aula 1 as pôs lá, e por isso a classe é um retrato disso e não um substituto.
