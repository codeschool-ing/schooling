---
title: Captura de dados de mudança, ou ler o que o banco anotou
version: 1
---

**Um banco escreve cada mudança num log antes de mudar a tabela, e a captura de dados de mudança lê
esse log em vez da tabela.** O log não existe para o analytics de ninguém. O PostgreSQL o chama de
write-ahead log e o MySQL de binary log, e cada um mantém o seu para uso próprio: recuperar-se depois de
uma queda e manter as réplicas atualizadas. Como ele registra mudanças e não estado, guarda exatamente o
que a cópia da seção anterior não conseguia ver. Uma remoção é uma mudança, então o log a tem. Duas
atualizações numa viagem são duas entradas, na ordem em que aconteceram, onde uma tabela só mostra a
segunda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 264\" role=\"img\" aria-label=\"O aplicativo escreve no banco. Dentro dele, o log guarda três mudanças numeradas: uma atualização de R000103, uma inserção de R000105 e uma remoção de R000104; a tabela de viagens guarda o resultado, quatro viagens sem R000104. Uma cópia por updated_at lê a tabela e encontra R000103 e R000105, mas não vê a remoção. Um leitor de CDC lê o log e recebe as três mudanças em ordem.\" data-fig=\"cdc\"><defs><marker id=\"cdc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"152\" y=\"14\" width=\"286\" height=\"240\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"295\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">o banco de dados</text><rect x=\"14\" y=\"181\" width=\"116\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"72.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o aplicativo</text><line x1=\"130\" y1=\"204\" x2=\"168\" y2=\"204\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#cdc-ah)\"></line><rect x=\"170\" y=\"44\" width=\"250\" height=\"102\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"295.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">a tabela de viagens</text><text x=\"295.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R000101  finished</text><text x=\"295.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R000102  finished</text><text x=\"295.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R000103  finished</text><text x=\"295.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R000105  open</text><rect x=\"170\" y=\"166\" width=\"250\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"295.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">o log, escrito antes</text><text x=\"295.0\" y=\"196.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1  update  R000103</text><text x=\"295.0\" y=\"211.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2  insert  R000105</text><text x=\"295.0\" y=\"226.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3  delete  R000104</text><line x1=\"295\" y1=\"166\" x2=\"295\" y2=\"148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#cdc-ah)\"></line><line x1=\"420\" y1=\"94\" x2=\"474\" y2=\"94\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#cdc-ah)\"></line><rect x=\"476\" y=\"54\" width=\"230\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"591.0\" y=\"78.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">uma cópia por updated_at</text><text x=\"591.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">acha R000103 e R000105</text><text x=\"591.0\" y=\"109.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">R000104 simplesmente sumiu</text><line x1=\"420\" y1=\"204\" x2=\"474\" y2=\"204\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#cdc-ah)\"></line><rect x=\"476\" y=\"166\" width=\"230\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"591.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">um leitor de CDC</text><text x=\"591.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lê as mudanças 1, 2 e 3</text><text x=\"591.0\" y=\"219.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a remoção inclusive</text></svg>", "caption": "O banco escreve cada mudança no seu log e depois a aplica na tabela. Uma cópia que lê a tabela encontra as linhas que estão lá; um leitor que segue o log encontra também a que foi apagada."}
```

Um programa que acompanha o log transforma o banco num fluxo de mudanças: insira esta viagem, atualize
aquela, apague a outra. Isso é a **captura de dados de mudança**, change data capture em inglês,
abreviada quase sempre como CDC. Cada mudança chega segundos depois de acontecer, e nada lê a tabela de
viagens, então o app não sente.

## Um log que dá para observar

O SQLite também tem o seu log, mas não um feito para outro programa acompanhar. Um trigger pode fazer o
papel dele: algumas linhas de SQL que o banco executa a cada inserção, atualização e remoção, gravando
uma linha numa tabela de mudanças. Este programa instala três, um por tipo de mudança:

```python
# sources/triggers.py
import sqlite3

db = sqlite3.connect("app.db")
db.executescript("""
DROP TABLE IF EXISTS changes;
CREATE TABLE changes (seq INTEGER PRIMARY KEY, op TEXT, ride_id TEXT, status TEXT);
CREATE TRIGGER on_insert AFTER INSERT ON rides BEGIN
    INSERT INTO changes (op, ride_id, status) VALUES ('insert', NEW.ride_id, NEW.status);
END;
CREATE TRIGGER on_update AFTER UPDATE ON rides BEGIN
    INSERT INTO changes (op, ride_id, status) VALUES ('update', NEW.ride_id, NEW.status);
END;
CREATE TRIGGER on_delete AFTER DELETE ON rides BEGIN
    INSERT INTO changes (op, ride_id, status) VALUES ('delete', OLD.ride_id, OLD.status);
END;
""")
print("every change to rides is now written to changes as well")
```

E este lê as mudanças em ordem:

```python
# sources/changes.py
import sqlite3

db = sqlite3.connect("app.db")
for seq, op, ride_id, status in db.execute("SELECT * FROM changes ORDER BY seq"):
    print(seq, op, ride_id, status)
```

Recomece o app das 09:00, instale os triggers, deixe o mesmo quarto de hora acontecer, e leia o que foi
registrado. `app.py` e `later.py` são os programas da seção anterior, sem mudança:

```
ana@lab:~/roda/sources$ python app.py
app.db holds 4 rides
ana@lab:~/roda/sources$ python triggers.py
every change to rides is now written to changes as well
ana@lab:~/roda/sources$ python later.py
one ride finished, one started, one cancelled and deleted
ana@lab:~/roda/sources$ python changes.py
1 update R000103 finished
2 insert R000105 open
3 delete R000104 open
```

A viagem cancelada está lá, como mudança número 3, com o status que tinha quando foi apagada. Um leitor
que aplica essas três entradas à cópia, em ordem, termina com as mesmas quatro viagens do app.

Triggers são um jeito real de fazer CDC, e antigo, mas têm um preço que o log não tem. Cada trigger é
uma escrita a mais dentro da própria transação do app, então o app paga pela cópia do time de dados a
cada viagem que inicia. **Ler o log custa muito menos ao app, porque o banco escreve o log de qualquer
jeito.** É por isso que o CDC baseado em log é a escolha comum onde o banco oferece um.

## O que ele pede aos donos do banco

Na Roda Livre a ferramenta para isso seria algo como o Debezium, um programa de código aberto que lê os
logs do PostgreSQL, do MySQL e de vários outros bancos e publica cada mudança como uma mensagem. Este
curso dá o nome e para aí; ler um log em produção é trabalho de `pipelines-etl`. Três coisas valem ser
sabidas antes de alguém propor isso, porque cada uma é uma conversa com o time do app:

- **Ele precisa de permissão para ler o log**, um privilégio que os donos do banco concedem, parecido
  com o que uma réplica tem.
- **O banco guarda o log até o leitor buscá-lo.** No PostgreSQL, um leitor de CDC que para num fim de
  semana deixa o log crescendo no disco do primário até voltar. Uma cópia que quebra é problema do time
  de dados; esta pode virar problema do app.
- **O log só começa agora.** Ele guarda as mudanças recentes, não a história de cada linha, então um
  pipeline de CDC começa com uma cópia completa e segue o log a partir do momento em que essa cópia foi
  tirada.

O que sai é um fluxo: mudanças chegando uma a uma, enquanto o app estiver rodando. A aula 8 é sobre
processar dados que nunca terminam de chegar.
