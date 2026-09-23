---
title: Um-para-muitos, e onde a chave vai
version: 2
---

A relação entre clientes e pedidos tem um formato, e o formato tem nome. **Um cliente tem muitos
pedidos. Um pedido pertence a um cliente.** Isso é uma relação *um-para-muitos*, e é de longe a
coisa mais comum que você vai modelar.

A única decisão que ela força é pequena e as pessoas erram com regularidade:

> **A chave estrangeira vai do lado "muitos".**

Um pedido carrega o id do cliente dele. Um cliente **não** carrega uma lista de ids de pedidos.

## Por que não pode ser ao contrário

Tente e a razão fica óbvia. Para pôr a relação no cliente, você precisaria de uma coluna guardando
vários pedidos:

| id | nome | pedidos |
|---|---|---|
| 1 | Ana Lopes | 1001, 1003, 1004 |
| 2 | Bruno Sá | 1002 |

Tudo está errado nisso e é tudo a mesma coisa: **uma coluna pode guardar um valor, e "muitos" não é
um valor.**

- A lista é texto, então achar o cliente que fez o pedido 1003 significa procurar `1003` dentro de
  uma string — o que também casa com `11003` e `1003x`.
- O quarto pedido da Ana significa ler a linha dela, acrescentar à string e escrever de volta. Dois
  pedidos feitos no mesmo segundo e um deles se perde.
- Nada impede `1003` aparecer também na linha do Bruno. O pedido agora tem dois clientes, e nenhuma
  regra foi quebrada.

Ponha a chave no lado dos muitos e cada um desses problemas desaparece sem ser endereçado. Um
pedido, uma coluna `customer_id`, um valor. As regras de unicidade e de referência do banco fazem o
resto.

O teste, quando você não tiver certeza da direção de uma relação:

> Pergunte "este pode ter vários daqueles?" nas duas direções. O lado que responde **não** é onde a
> chave estrangeira mora.

Um cliente pode ter vários pedidos — sim. Um pedido pode ter vários clientes — não. Então a chave
vai em `orders`.

## Um-para-um, que é a mesma regra com o parafuso mais apertado

Às vezes as duas direções respondem "não". Um empregado tem um contrato; um contrato pertence a um
empregado. Isso é uma relação **um-para-um**, e é o formato um-para-muitos com um `UNIQUE`
acrescentado:

```sql
CREATE TABLE contracts (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id integer NOT NULL UNIQUE REFERENCES employees (id),
    signed_on   date    NOT NULL,
    salary      numeric(10,2) NOT NULL
);
```

`UNIQUE` na chave estrangeira é o que transforma "muitos" em "um": um segundo contrato para o mesmo
empregado é recusado.

**E a pergunta honesta sobre um-para-um é por que são duas tabelas.** Se todo empregado tem
exatamente um contrato, as colunas poderiam morar em `employees`. Três razões para às vezes ainda
ser certo separar:

- **As partes são lidas em momentos muito diferentes.** O nome de um empregado é lido o tempo todo;
  o salário dele é lido por duas pessoas por mês. Separar mantém estreita a tabela quente.
- **As partes têm regras de acesso diferentes.** `salary` pode ser legível pela folha de pagamento e
  por mais ninguém, e permissões em SQL são concedidas por tabela.
- **A segunda metade é opcional.** Nem todo empregado já assinou, e um contrato ausente é então uma
  linha ausente em vez de uma linha cheia de `NULL`.

Se nada disso se aplica, uma tabela é mais simples e mais simples é o certo.

## Opcional, obrigatório, e qual dos dois você está escolhendo

Existe uma segunda decisão escondida no formato um-para-muitos, e ela é tomada por uma palavra:

```sql
customer_id integer NOT NULL REFERENCES customers (id)   -- every order has a customer
customer_id integer          REFERENCES customers (id)   -- an order may have none
```

`NOT NULL` diz que a relação é **obrigatória**: não existe pedido sem cliente. Deixar de fora diz
que a relação é **opcional**: a coluna pode ficar vazia, e uma coluna vazia significa "sem cliente",
não "cliente zero".

Escolha deliberadamente, porque os dois produzem sistemas diferentes. Uma loja onde qualquer um pode
comprar sem conta precisa do segundo. Uma loja onde o checkout exige login precisa do primeiro, e
declará-lo significa que um pedido sem cliente nunca pode ser criado — nem pelo site, nem pelo
script de importação, nem por ninguém às 2 da manhã.

O padrão que vale segurar: **faça `NOT NULL` a menos que você consiga descrever a linha que não
tem.** Se você não consegue dizer em voz alta o que um pedido sem cliente significaria, não deveria
ser possível escrever um.

## O que esse formato te compra lá na frente

Vale ver, uma vez, para que serve todo o arranjo — mesmo que a consulta em si pertença às aulas 5
e 6.

Com `customers` e `orders` nesse formato, nenhuma destas perguntas precisou ser planejada:

- Todo pedido que a Ana já fez, em ordem de data.
- Quantos clientes pediram mais de uma vez em março.
- Clientes sem nenhum pedido — que é uma pergunta sobre *ausência*, e é respondível precisamente
  porque um pedido que não existe é uma linha que não está lá, e não um espaço em branco dentro de
  uma string.
- A média de pedidos por cliente, por cidade.

Nenhuma delas exigiu acrescentar uma coluna, e nenhuma foi antecipada quando as tabelas foram
criadas. Esse é o retorno do pequeno desconforto de pôr a Ana numa tabela só dela.
