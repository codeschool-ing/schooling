---
title: Um instantâneo não é uma cópia, e esta é a distinção que mais importa
version: 2
---

A aula 1 pôs `unit_price` na linha do pedido enquanto `price` ficava no produto, e prometeu que o
argumento chegaria aqui. É este, e é a distinção mais útil da aula inteira — porque é a que impede
a seção anterior de virar desculpa.

```sql
CREATE TABLE products (
    id    integer PRIMARY KEY,
    price numeric(10,2) NOT NULL
);

CREATE TABLE order_lines (
    order_id   integer NOT NULL REFERENCES orders   (id),
    product_id integer NOT NULL REFERENCES products (id),
    unit_price numeric(10,2) NOT NULL,
    PRIMARY KEY (order_id, product_id)
);
```

Duas colunas de dinheiro guardando o mesmo número. Parece exatamente a redundância que esta aula
passou cinco seções removendo, e não é redundância nenhuma.

## A pergunta que as separa

> **Se a origem mudar, isto deve mudar também?**

É todo o teste.

`teacher_room` na tabela `courses`: se a Reis muda de sala, todo curso que ela leciona passa a ser
na sala nova. **Sim, deve mudar também** — então era uma cópia, e uma cópia que pode ficar para
trás é uma anomalia. Foi embora.

`unit_price` na linha do pedido: se o preço da chaleira subir amanhã, a Ana foi cobrada mais caro
pela que comprou em março? **Não.** Não pode mudar. Então não é cópia do preço — é um fato
diferente que por acaso foi igual ao preço num dia.

## Dois fatos que soam como um

Diga-os lado a lado e a diferença fica óbvia:

| coluna | o que diz |
|---|---|
| `products.price` | quanto isto custa |
| `order_lines.unit_price` | quanto isto custou, no dia em que foi comprado |

São fatos independentes sobre coisas diferentes. Um é sobre um produto, agora. O outro é sobre uma
venda, então. Nada no modelo relacional diz que dois fatos independentes não podem ter o mesmo
valor ao mesmo tempo — o que ele diz é que **um** fato não pode ser guardado duas vezes.

Guardar só `products.price` não economiza espaço; **destrói informação**. O preço que a Ana pagou
deixa de existir no momento em que alguém edita o produto, e nenhuma junção o traz de volta. A
fatura que você imprimiu em março deixa de bater com o banco em abril, e nada deu errado que alguém
possa apontar.

## Onde mais isso aparece

Uma vez que você tem o teste, vê em todo lugar, e a resposta é sempre a mesma:

| guardado | por que é instantâneo e não cópia |
|---|---|
| o endereço de entrega no pedido | o cliente mudou; a encomenda foi para o antigo mesmo assim |
| a alíquota na nota | a alíquota mudou; o que foi cobrado não |
| o nome do aluno no certificado | ela casou; o certificado diz o que dizia |
| a taxa de câmbio no pagamento | câmbio se move o tempo todo e o pagamento aconteceu uma vez |
| os termos aceitos, no aceite | os termos foram reescritos; aquela pessoa concordou com os antigos |

Este repositório faz exatamente isso, o que vale saber porque é um sistema real e não um exercício.
A migração do certificado dele diz que tudo no documento é capturado na emissão — o nome, o título,
a escola — e nada lido ao vivo, porque *"um curso pode ser renomeado ou removido do catálogo por
completo… e um certificado que lesse o título ao vivo passaria silenciosamente a nomear outra
coisa, ou nada."*

Mesmo teste, mesma resposta: **o certificado deve mudar quando o curso é renomeado? Não. Então o
título nele não é uma cópia.**

## Por que isso importa mais do que parece

Duas razões, e a segunda é a importante.

**É um bug de correção, não de desempenho.** Errar não deixa nada lento — faz registros passados
silenciosamente virarem falsos conforme o presente anda. Ninguém recebe erro. Os números
simplesmente deixam de ser o que eram, e no dia em que alguém reconciliar as faturas de março
contra o banco de março, elas não batem e ninguém sabe dizer por quê.

**E é a metade honesta da seção anterior.** Desnormalização é uma troca com custo real, e as
pessoas recorrem a ela fácil demais. Instantâneos não são essa troca: não custam nada, não são um
meio-termo, e são simplesmente o modelo correto de um fato que trata de um momento.

Então quando alguém diz *"desnormalizamos o preço na linha do pedido"*, a resposta certa é que não
desnormalizaram. Modelaram corretamente. Manter os dois separados é o que te permite recusar uma
desnormalização de verdade na segunda-feira e ainda guardar o total de uma fatura na terça sem se
contradizer.

## As três perguntas, juntas

A aula inteira, como as perguntas a fazer de qualquer coluna que apareça em dois lugares:

1. **É o mesmo fato?** Se é um fato sobre outra coisa, não é duplicação nenhuma.
2. **Se a origem mudar, isto deve mudar também?** Não significa instantâneo: guarde e esteja certo.
   Sim significa cópia: remova, ou aceite um custo medido e diga como ela permanece verdadeira.
3. **Se é uma cópia que você vai manter mesmo assim, o que a mantém correta?** Um gatilho, um
   caminho de código, uma reconstrução. Sem resposta significa não.
