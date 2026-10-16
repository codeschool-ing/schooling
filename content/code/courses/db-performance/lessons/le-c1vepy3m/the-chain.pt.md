---
title: Seguindo a cadeia até a raiz
version: 1
---

Um problema de bloqueio é um grafo: toda sessão que espera aponta para as sessões pelas quais
espera. A crença que desperdiça os primeiros dez minutos de um incidente é que **a sessão a tratar é
a que espera há mais tempo, ou aquela cuja consulta a aplicação reclama.** Não é nenhuma das duas.
Cancele a janela C, cujo update do pedido 2 é o que um usuário está olhando, e a janela B continua
esperando a janela A, e o próximo update do pedido 2 entra na fila atrás da janela B de novo. A
única sessão sobre a qual vale agir é a **raiz**: uma que bloqueia alguém e não espera ninguém.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"O grafo de espera da cadeia da aula. A janela A, pid 5792, está idle in transaction e segura o pedido 1. A janela B, pid 5794, segura o pedido 2 e espera a transação de A liberar o pedido 1. A janela C, pid 5796, espera a transação de B liberar o pedido 2. A é a raiz: não espera ninguém, e as outras duas esperam por causa dela.\"><rect x=\"14\" y=\"60\" width=\"188\" height=\"96\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"26\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">janela A</text><text x=\"190\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--phosphor)\">5792</text><text x=\"26\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">idle in transaction</text><text x=\"26\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">segura o pedido 1</text><rect x=\"266\" y=\"60\" width=\"188\" height=\"96\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"278\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">janela B</text><text x=\"442\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--phosphor)\">5794</text><text x=\"278\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">active, esperando</text><text x=\"278\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">segura o pedido 2</text><rect x=\"518\" y=\"60\" width=\"188\" height=\"96\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"530\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">janela C</text><text x=\"694\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--phosphor)\">5796</text><text x=\"530\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">active, esperando</text><text x=\"530\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ainda não segura linha</text><path d=\"M266 108 L206 108\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M206.0 108.0 L212.0 104.0 L212.0 112.0 Z\" fill=\"var(--amber)\"></path><text x=\"236\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">espera o pedido 1</text><path d=\"M518 108 L458 108\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M458.0 108.0 L464.0 104.0 L464.0 112.0 Z\" fill=\"var(--amber)\"></path><text x=\"488\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">espera o pedido 2</text><text x=\"14\" y=\"36\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a raiz: bloqueia alguém, não espera ninguém</text></svg>", "caption": "Quem espera por quem. As setas vão da sessão que espera para aquela pela qual espera; a raiz é a que não tem seta saindo dela.", "same": ["idle in transaction"]}
```

Com três sessões dá para seguir as setas do `blocked.sql` a olho. Com quarenta sessões em duas
cadeias, uma delas com cinco níveis atrás de um `ALTER TABLE` que por sua vez espera um relatório,
não dá, e o incidente não é o momento de tentar.

## A árvore, como consulta

O `pg_blocking_pids` dá um passo do grafo por sessão, então uma **consulta recursiva** consegue
percorrê-lo. Ela começa pelas raízes, as sessões com `blocked_by` vazio que aparecem no de outra, e
acrescenta, a cada passo, toda sessão cujo `blocked_by` contém uma sessão já encontrada. Ela guarda
o caminho desde a raiz, o que ordena o resultado como árvore, recua cada nível e impede que um ciclo
rode para sempre:

```sh
cat > ~/lock-tree.sql <<'SQL'
-- lock-tree.sql: who blocks whom, as a tree. Each root is a session that
-- blocks somebody and waits for nobody; under it, everybody waiting for
-- it, and everybody waiting for them.
WITH RECURSIVE tree AS (
    SELECT pid, ARRAY[pid] AS path
    FROM pg_stat_activity
    WHERE cardinality(pg_blocking_pids(pid)) = 0
      AND pid IN (SELECT unnest(pg_blocking_pids(pid)) FROM pg_stat_activity)
  UNION ALL
    SELECT a.pid, t.path || a.pid
    FROM tree AS t
    JOIN pg_stat_activity AS a ON t.pid = ANY (pg_blocking_pids(a.pid))
    WHERE a.pid <> ALL (t.path)
)
SELECT repeat('   ', cardinality(t.path) - 1) || t.pid AS pid,
       a.state,
       date_trunc('second', now() - a.xact_start) AS in_transaction,
       left(a.query, 45) AS last_query
FROM tree AS t
JOIN pg_stat_activity AS a USING (pid)
ORDER BY t.path;
SQL
```

O `WITH RECURSIVE` tem duas metades unidas por `UNION ALL`: o primeiro `SELECT` produz as linhas
iniciais, e o segundo é rodado de novo e de novo sobre as linhas que a rodada anterior produziu, até
uma rodada não produzir nenhuma. `ARRAY[pid]` começa cada caminho, `t.path || a.pid` o estende, e
`a.pid <> ALL (t.path)` recusa uma sessão que já está no caminho. Ordenar por `t.path` põe cada
sessão logo abaixo daquela pela qual espera, porque um array se ordena elemento por elemento, como
uma lista de números de capítulo.

Na janela D:

```
market=# \i ~/lock-tree.sql
    pid     |        state        | in_transaction |                  last_query                   
------------+---------------------+----------------+-----------------------------------------------
 5792       | idle in transaction | 00:00:34       | UPDATE orders SET status = 'shipped' WHERE id
    5794    | active              | 00:00:32       | UPDATE orders SET status = 'shipped' WHERE id
       5796 | active              | 00:00:27       | UPDATE orders SET status = 'cancelled' WHERE 
(3 rows)

Time: 3.882 ms
```

**5792 na raiz, 5794 abaixo dela, 5796 abaixo dessa.** A raiz está idle in transaction há 34
segundos; tudo abaixo dela está ativo e esperando. Esse é o formato mais comum de um incidente de
trava, e a árvore o mostra numa tela só, seja qual for o número de sessões envolvidas.

## Dois formatos que a árvore pode ter

Uma sessão pode esperar por **mais de uma** sessão ao mesmo tempo: um `ALTER TABLE` que precisa de
`ACCESS EXCLUSIVE` espera toda sessão que segura qualquer trava na tabela, e o `blocked_by` dele
lista todas. Ele então aparece na árvore uma vez debaixo de cada uma delas, o que está certo:
encerrar uma só não basta para deixá-lo passar.

Um **deadlock** nunca aparece como árvore por muito tempo. Toda sessão num ciclo espera alguém,
então nenhuma tem `blocked_by` vazio, nenhuma é raiz, e a consulta não devolve nada para elas.
Dentro do `deadlock_timeout`, um segundo aqui, o próprio servidor quebra o ciclo, como a seção 06 da
aula 12 mostrou. Uma árvore que persiste nunca é um deadlock: **é uma sessão na raiz que não vai
terminar sozinha**, e a próxima seção trata do que fazer com ela.

## Por que `pg_blocking_pids` e não um join

Você vai achar na internet versões desta consulta que juntam o `pg_locks` com ele mesmo por
`transactionid`, `relation` e o resto. Elas perdem casos que o servidor não perde: uma sessão
esperando na fila atrás de outra que espera, que a seção 04 da aula 12 mostrou com três janelas,
aparece no `pg_blocking_pids` e em nenhum auto-join. A função tem um custo, já que trava por um
instante as tabelas de travas do servidor para lê-las de forma consistente, então ela é para um
incidente ou para uma consulta de monitoramento uma vez por minuto, não para cada carregamento de
página.
