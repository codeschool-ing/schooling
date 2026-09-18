---
title: Desvio de escrita, o que o isolamento por instantâneo não impede
version: 1
---

Uma regra de hospital: **pelo menos um médico tem que estar de plantão o tempo todo.** Alice e Bruno
estão os dois de plantão e os dois querem a noite livre. A aplicação confere a regra antes de deixar
alguém sair.

```sql
BEGIN;
SELECT count(*) FROM doctors WHERE on_call;        -- 2, então um pode sair
UPDATE doctors SET on_call = false WHERE id = 1;
COMMIT;
```

Código correto. Rode duas vezes ao mesmo tempo e a ala fica vazia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Uma linha do tempo de duas transações rodando lado a lado, com o tempo correndo para baixo em cinco passos numerados. No passo um, a transação T1 conta os médicos de plantão e obtém dois. No passo dois, a transação T2 roda a mesma contagem e também obtém dois, porque não consegue ver nenhuma mudança da T1. No passo três a T1 tira o médico um do plantão. No passo quatro a T2 tira o médico dois do plantão. No passo cinco as duas confirmam. Abaixo, uma nota diz que, como as duas transações escreveram em duas linhas diferentes, as escritas delas nunca colidiram e nenhum conflito foi detectado, e ainda assim cada conferência era verdadeira quando rodou e depois ninguém está de plantão.\"><text x=\"44\" y=\"30\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">T1</text>\n<text x=\"380\" y=\"30\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">T2</text>\n<text x=\"16\" y=\"57\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text>\n<rect x=\"44\" y=\"40\" width=\"300\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"54\" y=\"57\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT count(*) WHERE on_call  =&gt;  2</text>\n<text x=\"16\" y=\"99\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2</text>\n<rect x=\"380\" y=\"82\" width=\"300\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"390\" y=\"99\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT count(*) WHERE on_call  =&gt;  2</text>\n<text x=\"16\" y=\"141\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text>\n<rect x=\"44\" y=\"124\" width=\"300\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"54\" y=\"141\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">UPDATE doctors SET on_call=false id=1</text>\n<text x=\"16\" y=\"183\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4</text>\n<rect x=\"380\" y=\"166\" width=\"300\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"390\" y=\"183\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">UPDATE doctors SET on_call=false id=2</text>\n<text x=\"16\" y=\"225\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">5</text>\n<rect x=\"44\" y=\"208\" width=\"300\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"54\" y=\"225\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">COMMIT</text>\n<rect x=\"380\" y=\"208\" width=\"300\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"390\" y=\"225\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">COMMIT</text>\n<line x1=\"14\" y1=\"258\" x2=\"706\" y2=\"258\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n<text x=\"14\" y=\"282\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Duas linhas diferentes, então as escritas não colidiram</text>\n<text x=\"14\" y=\"304\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Cada conferência era verdadeira quando rodou. Depois, ninguém de plantão.</text>\n</svg>", "caption": "Duas transações leem as mesmas linhas, decidem separadamente e escrevem em linhas diferentes. Não existe conflito de escrita a detectar, e a regra que as duas conferiam é quebrada pelo par."}
```

## Por que as defesas óbvias erram

**`REPEATABLE READ` não ajuda.** Cada transação recebe uma visão consistente dos dados, e as duas
visões estão corretas — dois médicos realmente estavam de plantão quando cada uma olhou. Isolamento
por instantâneo detecta transações que escrevem na mesma linha. Estas escreveram em linhas
**diferentes**, então não há o que detectar.

**Nem um bloqueio de linha sobre o que você atualiza.** A linha 1 e a linha 2 estão bloqueadas por
transações diferentes e nenhuma espera pela outra.

**Nem uma restrição `CHECK`.** Um `CHECK` vê uma linha, e nenhuma linha sozinha está errada: o médico
1 fora do plantão está certo, o médico 2 fora do plantão está certo. A regra é sobre o conjunto.

O formato, dito de modo geral:

> **Leia um conjunto de linhas, tome uma decisão a partir do que leu, e depois escreva numa linha
> que teria mudado a decisão.** Duas transações fazem isso ao mesmo tempo, cada uma agindo sobre uma
> premissa que a outra desmentiu.

## Onde você vai encontrar de verdade

Os médicos são um exemplo didático. Estes não são:

- **O último assento.** Conte as reservas de um voo, ache 199 de 200, insira uma. Duas vezes.
- **Um saldo espalhado por várias linhas.** Some os lançamentos de uma conta, confira que fica acima
  de zero, insira um saque. Duas vezes, de dois aparelhos.
- **Uma regra de unicidade imposta na aplicação.** `SELECT` para conferir que o nome de usuário está
  livre, depois `INSERT`. Isto é desvio de escrita, e é por isso que esse padrão está errado mesmo
  dentro de uma transação.
- **Reservas sobrepostas.** Confira que nenhuma reserva se sobrepõe a esta sala e horário, depois
  insira uma. Duas pessoas reservam a mesma sala para as duas e meia.

Cada uma delas lê como uma conferência cuidadosa. Cada uma delas são duas transações concordando com
um fato que deixa de ser verdade por causa do que a outra fez.

## Três correções, a melhor primeiro

**Uma — declare a regra.** O caso do nome de usuário tem uma resposta que você já conhece da aula 3:
um índice único. O confere-depois-insere desaparece por inteiro, você insere e trata a violação, e a
garantia vale contra toda conexão em todo nível de isolamento.

O caso das reservas sobrepostas também tem uma, no PostgreSQL:

```sql
ALTER TABLE reservations ADD CONSTRAINT no_overlap
EXCLUDE USING gist (room_id WITH =, during WITH &&);
```

Uma restrição de exclusão: duas linhas não podem ter a mesma sala e faixas de horário que se
sobreponham. É um índice único generalizado para além da igualdade, e é a ferramenta certa para uma
família inteira desses bugs.

**Duas — faça as leituras conflitarem.** Se a regra não pode ser declarada, bloqueie o que você lê
para que as duas transações de fato colidam:

```sql
BEGIN;
SELECT count(*) FROM doctors WHERE on_call FOR UPDATE;
…
```

`FOR UPDATE` bloqueia as linhas que o `SELECT` devolveu, então a segunda transação espera, e quando
segue vê um médico de plantão e recusa. A próxima seção trata disso. Funciona, é explícito, e
serializa os turnos de todo médico do hospital atrás de um bloqueio, que é um custo que vale enxergar.

**Três — `SERIALIZABLE`.** O PostgreSQL rastreia o que cada transação leu além do que escreveu, e
aborta uma de um par cujo desfecho nenhuma ordem serial poderia ter produzido:

```
ERROR:  could not serialize access due to read/write dependencies among transactions
HINT:  The transaction might succeed if retried.
```

Ele pega todos os formatos acima, inclusive os em que você não pensou, que é o argumento de verdade
dele — é a única correção desta lista que funciona contra um bug que você ainda não percebeu.

O preço está naquela dica. **A transação é recusada e a sua aplicação tem que rodá-la de novo**, o
que não é opcional e não é de graça escrever. A seção `retrying` é a outra metade dessa escolha, e
escolher sem a outra metade é publicar uma página de erro em vez de um bug.
