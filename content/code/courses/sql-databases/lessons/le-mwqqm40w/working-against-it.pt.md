---
title: Ser o desenvolvedor, não o administrador
version: 1
---

Você está num projeto, o banco é Oracle, outra pessoa o roda, e você tem um esquema e um login.
Esta seção é o que de fato está nas suas mãos — e há mais coisa do que as restrições da seção
anterior sugerem, porque o maior fator de desempenho num sistema Oracle é uma propriedade do SQL
que você manda.

## Variáveis de ligação, que importam mais aqui do que em qualquer outro ponto deste curso

Esta é a coisa mais valiosa da aula, e é a mesma prática que a aula 11 ensinou por outro motivo.

O Oracle parseia uma instrução e guarda o resultado — o plano e tudo em volta dele — numa área de
memória compartilhada. Uma instrução que chega com os valores colados no texto é **uma instrução
diferente a cada vez**:

```sql
SELECT id, name FROM customers WHERE email = 'ana@example.com'
SELECT id, name FROM customers WHERE email = 'bruno@example.com'
```

Dois textos, dois parses pesados, duas entradas no shared pool. Em quatrocentos endereços são
quatrocentos de cada. Parse pesado é caro, toma travas internas que todo o resto também quer, e um
pool cheio de instruções de uso único não tem espaço para nada que valha guardar. Num sistema
movimentado isso aparece como o banco inteiro ficando lento, sem nenhuma consulta parecer lenta.

Com uma variável de ligação é uma instrução só:

```sql
SELECT id, name FROM customers WHERE email = :email
```

Um texto, um parse, uma entrada, e os valores fornecidos à parte. Essa é **exatamente** a instrução
parametrizada que a aula 11 pediu para tornar impossível a injeção de SQL — a mesma prática, e no
Oracle ela é também a diferença entre um sistema que escala e um que não.

**Todo ORM e todo driver fazem isso por padrão.** Os sistemas que sofrem são os que têm SQL montado
por concatenação de strings, que a aula 11 já nomeou como a coisa a não fazer.

Há uma exceção honesta. Uma coluna cujos valores são muito desbalanceados — um status em que
noventa e nove por cento das linhas são `done` — pode querer um plano *diferente* por valor, e uma
variável de ligação esconde o valor do planejador na hora do parse. O Oracle tem maquinaria para
isso, chamada adaptive cursor sharing e bind peeking. Vale saber que a exceção existe; não é motivo
para concatenar.

## Leia o plano, com o vocabulário que você já tem

O método da aula 10 atravessa inteiro. Pegue o plano da instrução que rodou, o
`DBMS_XPLAN.DISPLAY_CURSOR` com `ALLSTATS LAST`, ponha estimado contra real em cada linha, e ache a
primeira linha em que eles divergem feio. Um `TABLE ACCESS FULL` numa tabela grande sob um
`NESTED LOOPS` é a forma do índice faltante da aula 10 nas palavras do Oracle.

## O que pedir, e como

**Um índice.** Traga a instrução, o plano, as contagens de linha e a seletividade da coluna, e diga
o que você espera que mude. Os avisos da aula 9 são os avisos do DBA também: um índice custa em toda
escrita, e uma tabela com quinze deles tem um problema em vez de uma solução.

**Estatísticas.** O planejador do Oracle depende de estatísticas como o do PostgreSQL, e uma tabela
carregada em massa durante a noite pode ser planejada sobre os números de ontem. "As estatísticas
foram coletadas nesta tabela depois da carga?" é uma pergunta legítima e específica.

**Uma olhada no histórico de desempenho.** Peça o relatório do AWR sobre a janela, e aceite "a
gente não licencia isso" como uma resposta com um desdobramento em vez de um beco sem saída: o
`V$SQL` para a instrução, e o tempo decorrido e a contagem de execuções nela.

## O que é inteiramente seu

A lista é maior do que parece na primeira semana:

- **o SQL que você escreve**, que é a maior parte do desempenho
- **as variáveis de ligação**, que são a maior parte do resto
- **as fronteiras da transação**: o que está numa, e por quanto tempo ela fica aberta
- **as restrições no seu próprio esquema**, que a aula 3 defendeu e que nenhuma licença afeta
- **confirmar o que você começou** numa janela de cliente, que é o chamado de suporte da seção
  anterior
- **não pôr uma função sobre uma coluna indexada** num `WHERE`, que é a aula 9 e é de graça

Nada disso precisa de um privilégio, de uma licença ou de uma reunião.

## E a coisa a segurar

Um sistema Oracle numa organização grande pode parecer um lugar onde nada pode ser mudado. Parte
disso é verdade e é contratual. Mas a consulta que você está prestes a escrever é sua, é a parte do
sistema que decide a maior parte do comportamento dele, e toda aula deste curso se aplica a ela.
