---
title: PL/SQL, e por que a lógica está no banco
version: 1
---

Abra um sistema Oracle corporativo de vinte anos e boa parte do que um desenvolvedor de aplicação
esperaria achar no código da aplicação está dentro do banco: validação, fluxo de trabalho,
processamento em lote, relatórios, às vezes um processo de negócio inteiro. Isso não é preguiça e
não é um erro que alguém cometeu. É PL/SQL, e havia razões.

## O que é PL/SQL

Uma linguagem de programação procedural que roda dentro do servidor de banco. Ela tem variáveis,
laços, condicionais, exceções e procedimentos, e instruções SQL fazem parte da sintaxe em vez de
serem strings passadas a um driver:

```sql
CREATE OR REPLACE PROCEDURE cancel_order (p_order_id IN NUMBER) IS
  v_status  orders.status%TYPE;
BEGIN
  SELECT status INTO v_status FROM orders WHERE id = p_order_id FOR UPDATE;

  IF v_status = 'shipped' THEN
    RAISE_APPLICATION_ERROR(-20001, 'a shipped order cannot be cancelled');
  END IF;

  UPDATE orders SET status = 'cancelled' WHERE id = p_order_id;
  INSERT INTO order_events (order_id, kind) VALUES (p_order_id, 'cancelled');
  COMMIT;
END;
```

Três coisas nesse bloco merecem ser nomeadas, porque são para o que a linguagem serve.

**`orders.status%TYPE`** declara a variável como sendo do tipo que a coluna tiver. Mude a coluna e
o procedimento acompanha, que é o oposto do descolamento que a aula 11 descreveu entre uma classe e
uma tabela.

**`SELECT … INTO`** põe uma única linha em variáveis, e levanta `NO_DATA_FOUND` se não houver
nenhuma e `TOO_MANY_ROWS` se houver mais de uma. Uma classe inteira de erro silencioso vira uma
exceção aqui.

**A transação é do procedimento.** O `UPDATE` e o `INSERT` são uma transação, e a garantia da aula
8 vale sobre o par. Nada atravessa uma rede entre os dois.

## Pacotes, que são a unidade que importa

Um **pacote** é um grupo nomeado de procedimentos e funções com uma especificação e um corpo,
compilado e guardado no banco:

```sql
CREATE OR REPLACE PACKAGE orders_api AS
  PROCEDURE cancel (p_order_id IN NUMBER);
  FUNCTION  total  (p_order_id IN NUMBER) RETURN NUMBER;
END orders_api;
```

A especificação é a interface e o corpo é privado, então um pacote é um módulo com uma fronteira. A
*API* de um sistema corporativo muitas vezes é um conjunto de pacotes, e a aplicação — em Java, em
.NET, em COBOL — chama `orders_api.cancel(42)` e não escreve SQL nenhum.

## Por que foi construído assim

Quatro razões, e três delas eram boas na época:

**Um lugar só para uma regra.** Seis aplicações e um lote noturno chegam nas mesmas tabelas. Uma
regra no banco é uma regra para todas elas; uma regra numa aplicação é uma regra para uma delas. É
o mesmo argumento que a aula 11 fez a favor de uma restrição sobre uma validação de classe, levado
adiante.

**Sem idas e voltas.** Um laço sobre dez mil linhas que roda dentro do servidor não manda dez mil
instruções pela rede. É o problema N+1 da aula 11 resolvido movendo o laço em vez de corrigindo a
consulta, e no hardware de 1998 era um ganho grande.

**A licença já está paga.** O banco é a máquina cara e está comprada. Trabalho feito ali é trabalho
em hardware que a organização possui, e a seção anterior é por que esse argumento segue sendo
feito.

**E uma que não era boa:** era o que a ferramenta incentivava. O Oracle Forms e a geração de
ferramentas construída sobre ele supunham que o banco era onde a lógica morava, e boa parte do
PL/SQL existente existe porque aquele era o caminho de menor resistência, e não porque alguém pesou
as opções.

## O que isso custa

Vale dizer com clareza, porque um desenvolvedor que chega hoje vai sentir as quatro:

**É difícil de testar.** Um pacote roda num banco com estado. Testá-lo em unidade significa um
framework como o utPLSQL e um banco contra o qual rodar, que é um ciclo bem mais pesado que o da
aplicação.

**É difícil de revisar.** A versão implantada mora no banco. Manter o fonte no git e o banco em dia
um com o outro é disciplina e não uma propriedade, e um sistema em que alguém compilou uma mudança
direto é um sistema em que o git está errado e nada diz isso.

**É a linguagem de um fornecedor.** O SQL da aula 12 é portátil e o PL/SQL não é. Um sistema cuja
lógica está em pacotes é um sistema cujo custo de migração é a lógica, que é o assunto da última
seção.

**E as pessoas são mais escassas.** Contratar alguém que escreva PL/SQL bem fica mais difícil a
cada ano, e isso é um risco de verdade para um sistema, e não uma questão de gosto.

## O que fazer com isso

Se você entrar num sistema construído assim, **os pacotes são a documentação do negócio**, e em
geral são documentação melhor do que qualquer coisa escrita. Leia-os.

Não tente mover a lógica para fora por ela estar fora de moda. Mova um pedaço quando houver um
motivo — uma regra que muda com frequência, um fluxo que quer ser testado — e deixe o resto. E o
que quer que você escreva no código da aplicação, as restrições ficam nas tabelas: essa regra é da
aula 11 e não se tornou falsa por haver um pacote ao lado.
