---
title: Um banco de dados em segundos
version: 2
---

**Um `docker run` lhe dá um PostgreSQL configurado, com o seu esquema e os seus dados de exemplo,
acessível a partir da sua própria máquina.** Quatro opções fazem isso, e um detalhe da partida da
imagem decide se a primeira coisa que se conecta a ela funciona.

A Ana quer a tabela do catálogo, com dois livros, toda vez que iniciar um banco novo. Ela escreve a
preparação como um arquivo SQL, `initdb/01-schema.sql`, num diretório só dele:

```sql
CREATE TABLE books (
    id     serial PRIMARY KEY,
    title  text NOT NULL,
    author text NOT NULL
);
INSERT INTO books (title, author) VALUES
    ('The Left Hand of Darkness', 'Ursula K. Le Guin'),
    ('Dom Casmurro', 'Machado de Assis');
```

Depois inicia o banco:

```
ana@vm:~$ docker run -d --name db -e POSTGRES_PASSWORD=lab-only -e POSTGRES_DB=shelf -v "$PWD/initdb":/docker-entrypoint-initdb.d:ro -v pgdata:/var/lib/postgresql/data -p 127.0.0.1:5432:5432 postgres:17
56f7a063833db11ab3c0ee2aef5277c1740218706ff97754fc614959c38c0022
```

Cada opção tem um trabalho:

- **`POSTGRES_PASSWORD`** define a senha do usuário `postgres`. A imagem se recusa a iniciar sem uma.
- **`POSTGRES_DB=shelf`** cria um banco chamado `shelf` além do padrão.
- **`-v "$PWD/initdb":/docker-entrypoint-initdb.d:ro`** monta por bind o diretório de preparação
  onde o entrypoint procura scripts. No primeiro início ele roda cada arquivo `.sql` e `.sh` dali, em
  ordem de nome, e é por isso que o arquivo se chama `01-…`.
- **`-v pgdata:…`** guarda os dados num volume nomeado, o hábito da aula 8.
- **`-p 127.0.0.1:5432:5432`** torna a porta 5432 do container acessível na porta 5432 da máquina da
  Ana, e só a partir da própria máquina. A aula 17 trata dessa opção.

## Pronto, e não pronto

A Ana espera o PostgreSQL responder dentro do container e então se conecta a partir da própria
máquina com o `psql`, o cliente do PostgreSQL que a aula 5 instalou no host:

```
ana@vm:~$ time until docker exec db pg_isready -U postgres -q; do sleep 0.2; done

real	0m1.063s
user	0m0.083s
sys	0m0.049s
ana@vm:~$ PGPASSWORD=lab-only psql -h 127.0.0.1 -U postgres -d shelf -c "SELECT title, author FROM books"
psql: error: connection to server at "127.0.0.1", port 5432 failed: server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
```

**O `pg_isready` disse sim depois de cerca de um segundo, e a conexão falhou mesmo assim.** O motivo
é o entrypoint. No primeiro início, ele roda um servidor temporário para executar os scripts de
preparação, e esse servidor só escuta num socket Unix dentro do container, para que nada de fora
alcance um banco montado pela metade. O `pg_isready` sem host confere esse socket, encontrou o
servidor temporário e o deu como pronto. Depois o entrypoint o parou para iniciar o real, e o `psql`
da Ana, chegando pela porta publicada, não encontrou nada.

Fazer a pergunta por TCP, do jeito que o mundo de fora vai se conectar, dá a resposta honesta:

```
ana@vm:~$ time until docker exec db pg_isready -h 127.0.0.1 -U postgres -q; do sleep 0.2; done

real	0m0.423s
user	0m0.044s
sys	0m0.037s
ana@vm:~$ PGPASSWORD=lab-only psql -h 127.0.0.1 -U postgres -d shelf -c "SELECT title, author FROM books"
           title           |      author       
---------------------------+-------------------
 The Left Hand of Darkness | Ursula K. Le Guin
 Dom Casmurro              | Machado de Assis
(2 rows)
```

O log do container conta a sequência inteira:

```
ana@vm:~$ docker logs db 2>&1 | grep -E "initdb.d/|init process complete|ready to accept connections"
2026-10-06 16:46:43.894 UTC [67] LOG:  database system is ready to accept connections
/usr/local/bin/docker-entrypoint.sh: running /docker-entrypoint-initdb.d/01-schema.sql
PostgreSQL init process complete; ready for start up.
2026-10-06 16:46:44.274 UTC [1] LOG:  database system is ready to accept connections
```

**Duas linhas "ready to accept connections"**, de dois servidores diferentes: o temporário, PID 67,
e o real, PID 1, depois que o script rodou e o processo de inicialização terminou. Uma conferência de
prontidão que testa outra coisa que não aquilo que os clientes vão usar responde a outra pergunta; a
aula 19 monta para o Compose uma verificação de saúde que faz a pergunta certa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo do primeiro início da imagem postgres, da esquerda para a direita. O entrypoint cria os arquivos de dados, inicia um servidor temporário que só escuta num socket Unix dentro do container, roda os scripts de docker-entrypoint-initdb.d, para o servidor temporário e inicia o real, que escuta na porta TCP 5432. Um pg_isready no socket diz pronto durante a fase temporária; um cliente pela porta publicada só conecta na última fase.\"><defs><marker id=\"l9init-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">criar os arquivos</text><rect x=\"150\" y=\"60\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servidor temporário · só socket</text><rect x=\"410\" y=\"60\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pará-lo</text><rect x=\"540\" y=\"60\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servidor real · TCP 5432</text><rect x=\"170\" y=\"114\" width=\"210\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"275\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">roda o 01-schema.sql</text><path d=\"M20 30 L700 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9init-ah-wire)\"></path><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text><text x=\"275\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">pg_isready no socket: pronto</text><text x=\"275\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">psql pelo -p: conexão fechada</text><text x=\"620\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">pg_isready -h 127.0.0.1: pronto</text><text x=\"620\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">psql pelo -p: funciona</text><text x=\"275\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linha de log: ready to accept connections, PID 67</text><text x=\"620\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e de novo, PID 1</text></svg>", "caption": "No primeiro início, a imagem roda o PostgreSQL duas vezes. Uma conferência que pergunta ao socket diz pronto durante a primeira; só uma conferência por TCP espera a segunda."}
```

## Só no primeiro início

Os scripts de preparação e as variáveis de ambiente que criam coisas rodam **uma vez, quando o
diretório de dados está vazio**. A Ana remove o container e inicia um novo contra o mesmo volume,
passando desta vez outra senha:

```
ana@vm:~$ docker rm -f db
db
ana@vm:~$ docker run -d --name db -e POSTGRES_PASSWORD=other -e POSTGRES_DB=shelf -v "$PWD/initdb":/docker-entrypoint-initdb.d:ro -v pgdata:/var/lib/postgresql/data -p 127.0.0.1:5432:5432 postgres:17
c1eff2b88f1f07916377771cbbd7c588bf01d2d9b6cbdde077c0e7072c634c6f
ana@vm:~$ docker logs db 2>&1 | grep -E "Skipping|ready to accept"
PostgreSQL Database directory appears to contain a database; Skipping initialization
2026-10-06 16:46:45.083 UTC [1] LOG:  database system is ready to accept connections
ana@vm:~$ PGPASSWORD=other psql -h 127.0.0.1 -U postgres -d shelf -c "SELECT count(*) FROM books"
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "postgres"
ana@vm:~$ PGPASSWORD=lab-only psql -h 127.0.0.1 -U postgres -d shelf -c "SELECT count(*) FROM books"
 count 
-------
     2
(1 row)
```

O entrypoint encontrou um banco no volume e pulou a inicialização inteira: nenhum script, e nenhuma
senha nova. **A senha que funciona continua sendo a primeira**, guardada dentro do banco, e o
`POSTGRES_PASSWORD=other` foi ignorado. Os livros estão lá porque o volume os guardou, não porque o
script rodou de novo. Para mudar uma senha depois, mude-a no banco com SQL; para recomeçar a partir
dos scripts, remova o volume.
