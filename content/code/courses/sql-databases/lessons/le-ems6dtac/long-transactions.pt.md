---
title: O que uma transação aberta custa enquanto está aberta
version: 1
---

Uma transação é barata de começar e barata de terminar. Segurá-la aberta é que custa, e o custo
cresce com o tempo de relógio e não com o trabalho feito — então a transação mais cara da maioria dos
sistemas é uma que não está fazendo nada.

## Quatro coisas que ela está segurando

**Todo bloqueio que ela tomou.** Até ela terminar, as linhas que escreveu estão bloqueadas. Quem
quiser escrevê-las espera, e a fila da aula 3 se forma atrás disso: um `ALTER TABLE` barrado por uma
transação longa barra tudo o que chegar depois, inclusive as leituras.

**Toda versão de linha que ela ainda possa precisar ver.** Esta é a específica do PostgreSQL e é a
que danifica um banco em vez de uma requisição. Um `UPDATE` não sobrescreve; ele escreve uma versão
nova e deixa a antiga para quem ainda possa estar olhando. O `VACUUM` recupera as mortas — mas só
pode recuperar versões mais velhas que a transação em execução mais antiga. Uma transação aberta
desde terça significa que nada escrito desde terça pode ser limpo:

```
linhas mortas se acumulam na tabela          → a tabela cresce e as varreduras ficam lentas
entradas mortas se acumulam em todo índice   → os índices crescem também
o autovacuum roda e não recupera nada        → e continua rodando
```

A tabela fica maior enquanto o número de linhas vivas fica igual. Isso é inchaço, não some quando a
transação finalmente termina, e consertar exige reescrever a tabela.

**Um lugar na sequência de ids de transação.** Deixada tempo suficiente — semanas, num sistema
movimentado — uma transação aberta impede o banco de avançar além de um ponto de reinício de
contagem, e o PostgreSQL passa a recusar escritas para se proteger. É raro e é o jeito pelo qual uma
transação longa derruba um sistema inteiro em vez de uma consulta.

**E a capacidade de uma réplica de aplicar mudanças**, se as réplicas estiverem configuradas para
esperar pelos leitores delas. Uma consulta longa numa réplica segura a aplicação, ou é cancelada; de
um jeito ou de outro a transação numa máquina está afetando outra.

O MySQL tem a versão dele da segunda: entradas de undo são mantidas enquanto qualquer transação
possa precisar delas, a lista de histórico cresce, e a limpeza fica para trás.

## `idle in transaction`, que é o culpado de sempre

```sql
SELECT pid, state, now() - xact_start AS open_for, left(query, 60)
FROM   pg_stat_activity
WHERE  state <> 'idle'
ORDER BY xact_start;
```

Rode isso num sistema com problema de inchaço e você em geral acha uma linha assim:

```
 pid  |        state        | open_for |            query
 8231 | idle in transaction | 02:14:37 | SELECT id FROM settings WHERE key = 'x'
```

Duas horas. A consulta terminou num milissegundo; a transação continua aberta porque ninguém
confirmou. **`idle in transaction` quer dizer que a conexão está segurando tudo o que está acima e
não está fazendo nada com isso.**

É quase sempre uma de três coisas: um driver com autocommit desligado, em que um `SELECT` perdido
abriu uma transação que ninguém queria abrir; um framework que abre uma no começo de uma requisição e
fecha no fim; ou código que chamou algo lento no meio.

O PostgreSQL tem um instrumento grosseiro para isso, e vale configurar:

```sql
ALTER SYSTEM SET idle_in_transaction_session_timeout = '60s';
```

Qualquer coisa parada dentro de uma transação por um minuto é morta. A aplicação vê uma conexão
derrubada, o que é um relato de bug, e um relato de bug ganha de inchaço.

## A regra que previne a maior parte disso

> **Não faça nada dentro de uma transação que espere por algo fora do banco.**

Uma chamada HTTP a um provedor de pagamento. Mandar um e-mail. Escrever num armazenamento de
objetos. Esperar uma pessoa clicar num botão. Cada uma transforma a duração da sua transação na
latência de outra pessoa, e um provedor que leva trinta segundos para responder acabou de segurar os
seus bloqueios por trinta segundos.

O formato que funciona é fazer a coisa lenta por fora, e usar o banco para registrar intenção:

```
BEGIN; INSERT INTO payments (status) VALUES ('pending') RETURNING id; COMMIT;
   → chama o provedor de pagamento, pelo tempo que for
BEGIN; UPDATE payments SET status = 'settled' WHERE id = $1; COMMIT;
```

Duas transações curtas com a parte lenta entre elas, e uma linha que registra em que estado o mundo
está se o processo morrer no meio. Essa última parte é o benefício real: a transação que envolvia
tudo também não sobreviveria a uma queda, ela só parecia que sobreviveria.

## E escritas grandes vão em lotes

O preenchimento da aula 3 ia em lotes exatamente por essas razões: um único `UPDATE` sobre dez
milhões de linhas é uma transação que segura bloqueios e versões mortas pela corrida inteira, e não
pode ser interrompida sem perder tudo. Em lotes de alguns milhares, cada um confirmando, os
bloqueios são breves, as linhas mortas ficam recuperáveis conforme a coisa anda, e um lote que falha
custa um lote.

A troca é honesta e vale dizer em voz alta: **você abriu mão da atomicidade sobre o trabalho
inteiro.** Metade das linhas fica atualizada se parar no meio, então o trabalho tem que ser escrito
para poder ser retomado — o que em geral quer dizer uma cláusula `WHERE` que pula as linhas já
feitas.
