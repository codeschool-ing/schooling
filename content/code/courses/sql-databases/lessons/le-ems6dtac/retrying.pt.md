---
title: Repetir, que é a metade que as pessoas deixam de fora
version: 1
---

Duas seções desta aula terminam com o banco recusando uma transação e lhe dizendo para rodá-la de
novo. Isso não é uma condição de erro para registrar e seguir em frente: é como esses recursos
funcionam, e uma aplicação sem um laço de repetição transformou um mecanismo de concorrência numa
página de erro.

## Quais erros querem dizer "rode de novo"

O padrão resolveu isso e os dois bancos seguem. **A classe 40 do SQLSTATE é a classe de desfazimento
de transação**, e é a regra inteira:

| código | nome | de onde vem |
|---|---|---|
| `40001` | falha de serialização | `SERIALIZABLE`, ou um update conflitante em `REPEATABLE READ` |
| `40P01` | deadlock detectado | PostgreSQL, um ciclo de bloqueios |
| `1213` | deadlock | o número do MySQL para a mesma coisa, classe `40001` |

Qualquer coisa começando com `40` quer dizer: nada foi escrito, ninguém tem culpa, e a mesma
transação bem pode dar certo numa segunda tentativa.

Igualmente importante é o que **não** está na lista:

```
23505  violação de unicidade         a linha é genuinamente duplicada — repetir insere de novo
23503  violação de chave estrangeira o pai está genuinamente ausente
23514  violação de check             o valor está genuinamente fora da faixa
42601  erro de sintaxe               a consulta vai estar errada para sempre
```

Repetir um erro de classe 23 é um laço que roda até algo desistir. Repetir um `42` é um laço que não
termina. **Repita pela classe, e não pelo fato de que algo falhou** — um `except: repita` em volta de
uma transação inteira é um dos jeitos mais caros de esconder um bug.

O `1205` do MySQL, lock wait timeout, fica no meio. Repetir uma vez é razoável, e se acontece muito a
resposta está na seção anterior e não num laço.

## Repita a transação, não a instrução

```
tentativa 1
    BEGIN
    SELECT …            ← os valores que esta tentativa leu
    UPDATE …
    COMMIT              → 40001

tentativa 2
    BEGIN               ← desde o começo
    SELECT …            ← releia: o mundo mudou, e é esse o ponto
    UPDATE …
    COMMIT              → ok
```

Duas razões, e a segunda é a que importa.

A transação já está morta — no PostgreSQL toda instrução depois da falha é recusada até você
desfazer, então não há o que retomar.

E a repetição tem que **tomar a decisão de novo**. Uma falha de serialização quer dizer que a
premissa que a sua transação leu acabou sendo falsa. Rodar de novo a última instrução com os valores
que você leu na primeira vez escreve a resposta errada mais rápido. Tudo o que a transação lê precisa
ser lido de novo, então o laço tem que passar por volta das leituras tanto quanto das escritas.

É por isso que isto é uma questão estrutural e não um bloco de captura: seja qual for o código que
decide o que escrever, ele tem que ficar dentro da unidade repetível.

## O formato do laço

```
para tentativa em 1 … 5:
    começa
    roda o trabalho, leituras e escritas
    confirma
    → sucesso, para

    em SQLSTATE de classe 40:
        desfaz
        espera um tempo curto e aleatório, maior a cada tentativa
        segue

    em qualquer outro erro:
        desfaz e desiste — este não vai melhorar

depois de 5 tentativas:
    desiste, e registra alto
```

Quatro detalhes que vale anotar:

**Limite as tentativas.** Uma transação que conflita todas as vezes — duas tarefas brigando
permanentemente pela mesma linha — repetiria para sempre e consumiria uma conexão fazendo isso.

**Espere, e acrescente aleatoriedade.** Duas transações que repetem na hora colidem de novo, e de
novo. Uma espera curta que cresce, com um componente aleatório para elas não ficarem em compasso,
transforma uma colisão numa fila.

**Registre as repetições.** Elas são invisíveis quando funcionam, e *"esta transação dá certo na
quarta tentativa todas as vezes"* é um problema de projeto que um laço silencioso esconde por um ano.
Conte-as; uma taxa é um sinal.

**E desista alto.** Esgotar as tentativas é uma falha de verdade e merece a mesma atenção que
qualquer outra, com o SQLSTATE na mensagem para a próxima pessoa saber de qual tipo era.

## A repetição tem que ser segura de rodar duas vezes

Que é o segundo argumento para a regra da seção anterior. Se a transação manda um e-mail, cobra um
cartão ou publica numa fila, a tentativa 1 fez essas coisas antes de falhar — e a tentativa 2 as faz
de novo. O banco desfez o trabalho dele e não tem visão de mais nada.

Então: mantenha efeitos colaterais fora da transação, e onde o trabalho precisar ser repetível,
torne-o idempotente — uma chave natural com a qual um segundo insert colida, um
`ON CONFLICT DO NOTHING`, um identificador que o sistema receptor reconheça como já visto.

## Onde isso deve morar

Uma vez, num lugar só: um auxiliar que recebe um bloco de trabalho e o roda dentro do laço. Espalhar
lógica de repetição pelo código garante que a transação que alguém acrescentar mês que vem não vai
ter uma.

Vários frameworks fornecem um — e vários não fornecem, e alguns fornecem um que repete a instrução em
vez da transação, que é a versão que não funciona. Vale ler o que você tem em vez de supor.

E para fechar o laço que esta aula abriu: **escolher `SERIALIZABLE` e escolher escrever isto são a
mesma decisão.** O nível não é mais difícil de usar que os outros por ser mais lento. Ele é mais
difícil porque entrega a você um erro que quer dizer *tente de novo*, e responder a isso é trabalho
da aplicação.
