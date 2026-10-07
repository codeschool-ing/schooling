---
title: pg_hba.conf, o arquivo da porta
version: 1
---

Bruno já tem senha e continua sem entrar. Ana tenta pela própria conta, pelo socket local do
servidor:

```
ana@lab:~/gov$ psql -U bruno
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: FATAL:  Peer authentication failed for user "bruno"
```

**`peer` é um método que não pede senha nenhuma.** Ele pergunta ao sistema operacional qual
usuário está do outro lado do socket e deixa esse usuário entrar como o papel de mesmo nome. O
usuário de sistema da Ana é `ana`, ela pediu para ser `bruno`, e os dois não batem. Para uma
pessoa logada no próprio servidor de banco, `peer` é o método mais forte que existe: não há
segredo para roubar, porque a testemunha é o kernel.

Qual método vale para qual conexão é tarefa de um arquivo, o `pg_hba.conf` — *host-based
authentication*, autenticação baseada no host. O Ubuntu entrega o cluster com este:

```
ana@lab:~/gov$ sudo grep -v -e '^#' -e '^$' /etc/postgresql/16/gov/pg_hba.conf
local   all             postgres                                peer
local   all             all                                     peer
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
```

Cada linha é uma regra com cinco colunas: o **tipo** de conexão (`local` para o socket, `host`
para TCP), o **banco**, o **usuário**, o **endereço** do cliente no caso de TCP, e o **método**.
Lido como política, o padrão do Ubuntu diz: nesta máquina, qualquer um pode ser o papel com o seu
nome; por TCP a partir desta máquina, qualquer um com a senha pode ser qualquer um; e o mesmo para
replicação. É um padrão sensato para o notebook de uma pessoa. Não é política para o dado de uma
empresa.

## A versão da Ana

```conf
# TYPE  DATABASE  USER      ADDRESS        METHOD
local   all       postgres                 peer
local   ipe       ana                      peer
host    ipe       all       127.0.0.1/32   scram-sha-256
host    all       all       all            reject
```

Quatro linhas, e cada uma diz algo deliberado:

- **só `postgres` e `ana` podem usar o socket**, e só como eles mesmos;
- **todos os outros conectam por TCP, só ao `ipe`, com SCRAM** — então todo outro login é uma
  senha conferida pelo servidor, e o endereço na linha o limita a esta máquina;
- **tudo o que não está descrito acima é recusado**, nominalmente, em vez de cair no fim do
  arquivo.

A última linha não é enfeite. Uma conexão que não bate com linha nenhuma é recusada de qualquer
jeito, então `reject` não muda quem entra. O que ele muda é **o motivo no log**: "rejects
connection" diz que uma regra recusou, enquanto "no entry" pode significar que o arquivo foi
editado errado. Um arquivo que termina numa recusa explícita é um arquivo cujo autor pensou no
fim.

## Vale a primeira que bate

O servidor lê o arquivo de cima para baixo e para na primeira linha cujo tipo, banco, usuário e
endereço batem. **Nada abaixo dessa linha é lido.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l1-hba-first-match\" aria-label=\"O pg_hba.conf é lido de cima para baixo, e a primeira linha cujo tipo, banco, usuário e endereço batem decide. Uma conexão do bruno por TCP pula as duas linhas local e para na linha 4, scram-sha-256. Ele nunca chega à linha 5.\"><defs><marker id=\"dg-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"95.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">bruno, por TCP</text><text x=\"95.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">db.ipe.example</text><rect x=\"220.0\" y=\"30.0\" width=\"470.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"238.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"258.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" xml:space=\"preserve\" fill=\"var(--paper)\">local   all  postgres          peer</text><rect x=\"220.0\" y=\"80.0\" width=\"470.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"238.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"258.0\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" xml:space=\"preserve\" fill=\"var(--paper)\">local   ipe  ana               peer</text><rect x=\"220.0\" y=\"130.0\" width=\"470.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"238.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"258.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" xml:space=\"preserve\" fill=\"var(--paper)\">host    ipe  all  127.0.0.1/32 scram-sha-256</text><rect x=\"220.0\" y=\"180.0\" width=\"470.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"238.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"258.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" xml:space=\"preserve\" fill=\"var(--paper-dim)\">host    all  all  all          reject</text><path d=\"M170.0 125.0 L218.0 148.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><text x=\"455.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">linhas 2 e 3 não batem: tipo errado. A linha 4 bate, e decide.</text></svg>", "caption": "Vale a primeira que bate, e nada abaixo dela é lido. Um erro de ordem é um erro de segurança."}
```

Isso faz da ordem uma propriedade de segurança. Troque as linhas 4 e 5 e todo login por TCP é
recusado; ponha uma linha `host all all 0.0.0.0/0 trust` no topo durante uma emergência e toda
regra abaixo dela deixa de existir, para todo mundo, até alguém lembrar. A segunda é a clássica,
porque funciona e ninguém percebe.

O arquivo é lido quando o servidor sobe e quando ele recebe ordem de recarregar, não a cada
edição, então a mudança tem dois passos:

```
ana@lab:~/gov$ sudo install -o postgres -g postgres -m 640 pg_hba.conf /etc/postgresql/16/gov/
ana@lab:~/gov$ sudo -u postgres psql -c "SELECT pg_reload_conf()"
 pg_reload_conf 
----------------
 t
(1 row)

ana@lab:~/gov$ sudo -u postgres psql -c "SELECT line_number, type, database, user_name, address, auth_method FROM pg_hba_file_rules"
 line_number | type  | database | user_name  |  address  |  auth_method  
-------------+-------+----------+------------+-----------+---------------
           2 | local | {all}    | {postgres} |           | peer
           3 | local | {ipe}    | {ana}      |           | peer
           4 | host  | {ipe}    | {all}      | 127.0.0.1 | scram-sha-256
           5 | host  | {all}    | {all}      | all       | reject
(4 rows)
```

`pg_hba_file_rules` é a leitura que o próprio servidor fez do arquivo, e **é o que se olha depois
de toda edição**. Uma linha com erro de digitação aparece ali com a coluna `error` preenchida, e o
servidor continua usando a última versão que conseguiu interpretar — então uma edição quebrada
falha em silêncio, a menos que alguém pergunte. A linha 1, o comentário, não é regra; as quatro
regras são da 2 à 5.

Agora o Bruno pelo socket encontra outra recusa:

```
ana@lab:~/gov$ psql -U bruno
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: FATAL:  no pg_hba.conf entry for host "[local]", user "bruno", database "ipe", no encryption
```

Nenhuma linha descreve `local`, `bruno`, `ipe`: ele deve vir por TCP, com senha.
