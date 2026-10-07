---
title: O laboratório, e três jeitos de montá-lo
version: 1
---

**Ninguém aprende controle de acesso lendo um GRANT.** Aprende quando uma consulta que devia
funcionar responde `permission denied`, ou quando uma que devia falhar devolve seis mil linhas.
Por isso toda aula aqui é executada, numa máquina que você mesmo monta, e a plataforma não dá
nenhuma: o laboratório é seu, no seu computador.

É uma máquina Linux com:

- **PostgreSQL 16**, num cluster próprio chamado `gov` na porta 5433, com o banco da Ipê, `ipe`.
  Três schemas — `sales`, `health` e `support` — e sete tabelas, carregadas com 6.012 clientes e
  sete anos de pedidos.
- **OpenBao**, um servidor de gestão de chaves, instalado mas não iniciado. A aula 4 o inicia.
- **Uma pequena autoridade certificadora** do próprio laboratório, que a aula 3 usa para dar ao
  banco um certificado que o cliente consiga conferir.

O script que o monta é o `lab.sh`, publicado com o código-fonte deste curso, com o gerador de
dados e o schema em `lab/` ao lado. Ele cria um usuário chamado `ana`, instala os pacotes de que
precisa, gera os dados e os carrega. Depois que ele roda, a máquina é esta:

```
ana@lab:~/gov$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@lab:~/gov$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  gov     5433 online postgres /var/lib/postgresql/16/gov  /var/log/postgresql/postgresql-16-gov.log
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

`main` é o cluster que o Ubuntu cria quando o PostgreSQL é instalado. O laboratório não mexe nele
e monta o `gov` ao lado, para que nada do que você fizer neste curso toque um banco que você já
tinha.

## Três jeitos de rodar

**Numa máquina virtual — recomendado.** Uma máquina virtual Ubuntu 24.04 com 2 GB de memória e
10 GB de disco livre basta. O `lab.sh` cria usuários, um servidor de banco, um servidor de
chaves e entradas no `/etc/hosts`, e dá à `ana` o direito de usar `sudo` sem senha. É exatamente
o tipo de mudança que você não quer no computador em que trabalha. A aula 4 de `virtualization`
monta uma máquina virtual no VirtualBox, se você nunca fez uma. Dentro dela:

```sh
sudo bash lab.sh up
```

**Instalado num Linux seu.** Dá, e o script é idempotente, mas leia antes: ele edita o
`/etc/hosts`, escreve o `/etc/postgresql-common/user_clusters` e acrescenta um arquivo de
sudoers. Se algum desses é um arquivo que importa para você, use a máquina virtual.

**Em contêineres, para quase tudo.** A imagem oficial `postgres:16` roda as aulas de banco, e o
OpenBao também publica uma imagem. Você carregaria o `lab/schema.sql` e os arquivos gerados por
conta própria, e os caminhos dos transcritos — `/etc/postgresql/16/gov`, o log em
`/var/log/postgresql` — serão outros num contêiner. O curso não foi gravado assim; o caminho fica
citado para que quem não consegue rodar máquina virtual ainda tenha uma saída.

## Duas linhas que as aulas pressupõem

O `psql` do Ubuntu pergunta a um pequeno wrapper com qual cluster falar. O laboratório responde
`gov` e o banco `ipe`, mas uma conexão por nome de host não consulta o wrapper, então a porta
precisa estar também no ambiente. O `lab.sh` põe isto no `~/.bashrc` da `ana`; se você montar o
laboratório de outro jeito, ponha você:

```sh
export PGPORT=5433 PGDATABASE=ipe
```

O laboratório também aponta dois nomes para a própria máquina, `db.ipe.example` e
`bao.ipe.example`, para que a aula 3 possa conferir um certificado contra um nome e não contra
um endereço.

## Quando a montagem falha

Três falhas respondem pela maior parte, e cada uma se anuncia:

- **O `apt-get` não alcança o repositório.** Os pacotes não chegam e o primeiro `psql` responde
  `command not found`. Proxy ou firewall é a causa comum. Quando
  `sudo apt-get install postgresql-16` funcionar na mão, o script funciona também.
- **O download do OpenBao falha no checksum.** O script para em vez de instalar um binário por
  que não pode responder. Não apague nada; rode de novo, e se falhar duas vezes, o arquivo na
  rede não é o que o script fixa, o que vale saber antes de executá-lo.
- **A porta 5433 está ocupada.** O `pg_createcluster` recusa. Outra coisa na máquina escuta ali;
  numa máquina virtual nova, nada escuta.

Se falhar outra coisa, leia as dez últimas linhas que o script imprimiu. Ele para no primeiro
erro em vez de seguir, então a última linha é a que quebrou. `sudo bash lab.sh reset` joga fora o
banco e o `~/gov` e os monta de novo a partir dos arquivos, que é também como se recomeça uma
aula.
