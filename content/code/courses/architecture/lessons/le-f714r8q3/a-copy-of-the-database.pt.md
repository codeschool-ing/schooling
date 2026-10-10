---
title: O índice é uma cópia
version: 1
---

O índice de busca nunca é a fonte de verdade. Preços, estoque e descrições são decididos no banco da loja,
e o índice guarda uma cópia com o formato bom para buscar. A aula 9 tem uma palavra para isso, e ela vale
aqui exatamente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O banco guarda os produtos e é a fonte de verdade. Um alimentador lê as linhas mudadas desde a última execução e as manda ao índice de busca em lote. A caixa de busca lê só do índice. Entre uma mudança no banco e a próxima execução do alimentador, mais até um segundo de refresh, o índice mostra a versão antiga.\"><defs><marker id=\"l17-copy-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17-copy-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"80\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">PostgreSQL</text><text x=\"105\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fonte de verdade</text><rect x=\"280\" y=\"80\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">feed.py</text><text x=\"355\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linhas mudadas</text><rect x=\"530\" y=\"80\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">OpenSearch</text><text x=\"610\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma cópia</text><path d=\"M182 110 L278 110\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-copy-ah-amber)\"></path><path d=\"M432 110 L528 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-copy-ah-phosphor)\"></path><text x=\"480\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">_bulk</text><rect x=\"530\" y=\"170\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">search.py</text><path d=\"M610 168 L610 142\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-copy-ah-phosphor)\"></path><text x=\"230\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">atraso: intervalo do alimentador + até 1 s de refresh</text></svg>", "caption": "O índice é uma cópia alimentada pelo banco. Ele atrasa o intervalo do alimentador mais o refresh do motor, e sempre pode ser reconstruído a partir da fonte.", "same": ["PostgreSQL", "OpenSearch"]}
```

Acrescente um produto ao banco, depois busque-o antes de o alimentador rodar:

```
ana@vm:~/lab/search$ docker compose exec -T db psql -U postgres -c "INSERT INTO products (id, name, category, description, cents) VALUES (25, 'Café gelado em lata', 'café', 'Café com leite gelado, lata de 250 ml.', 690)"
INSERT 0 1
ana@vm:~/lab/search$ $R search.py gelado
1 match
   2.64  Chá mate tostado
categories: chá (1)
```

O banco tem o café gelado; a caixa de busca nunca ouviu falar dele. Rode o alimentador, e busque na hora:

```
ana@vm:~/lab/search$ $R feed.py; $R search.py gelado; sleep 5; $R search.py gelado
fed 1 products
1 match
   2.64  Chá mate tostado
categories: chá (1)
2 matches
   7.07  Café gelado em lata
   2.21  Chá mate tostado
categories: café (1), chá (1)
```

O alimentador o mandou, e a primeira busca **ainda não o achou**. Cinco segundos depois achou. Esse é o
**refresh** do motor: documentos novos são gravados num buffer em memória e passam a ser buscáveis quando
o buffer vira um segmento novo, por padrão uma vez por segundo; o índice do laboratório espera cinco, para
a lacuna ser larga o bastante para ver. Os motores de busca se dizem **quase em
tempo real** (*near real-time*) por isso. Uma carga em lote pode desligar o refresh para ir mais rápido, e
um teste que indexa e busca no mesmo fôlego tem de pedir um refresh ou esperar por um.

Então o índice atrasa em relação ao banco **o intervalo do alimentador mais o refresh**, um segundo por padrão. O
alimentador do laboratório roda quando pedido. Em produção ele é uma de três coisas, da mais simples à
mais atual:

| como o índice é alimentado | atraso | o que custa |
| --- | --- | --- |
| uma tarefa a cada poucos minutos, lendo as linhas mudadas desde a última execução, como o laboratório faz | minutos | um `updated_at` que toda escrita tem de definir; exclusões precisam de uma marca de exclusão lógica para serem vistas |
| eventos da aplicação, por um outbox (aula 7) | segundos | toda mudança tem de publicar um evento |
| captura de mudanças a partir do log do banco, por exemplo o Debezium para o Kafka | segundos | mais uma peça móvel, mas nenhuma mudança na aplicação |

E por ser uma cópia, o índice sempre pode ser **reconstruído a partir da fonte**: criar um índice novo,
alimentá-lo com tudo, e apontar a caixa de busca para ele. Os motores apoiam isso com **aliases**, um nome
que a aplicação usa e que pode ser trocado do índice velho para o novo num passo só.
