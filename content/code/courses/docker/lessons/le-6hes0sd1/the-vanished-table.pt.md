---
title: A tabela que sumiu
version: 1
---

**Um banco de dados num container perde os dados na primeira vez em que alguém remove o container e
inicia outro, a menos que os dados tenham sido postos de propósito em outro lugar.** É a perda de
dados mais comum do primeiro mês com Docker, e com o PostgreSQL ela tem uma reviravolta que vale
entender, porque também mostra a saída.

A Ana inicia o PostgreSQL, cria uma tabela de empréstimos e acrescenta uma linha:

```
ana@vm:~$ docker run -d --name db -e POSTGRES_PASSWORD=lab-only postgres:17
05d41ecdea4494230e0ff46bc8cda5bcd87a4ccab1d13ea5427258bc8767fc0d
ana@vm:~$ docker exec db psql -U postgres -c "CREATE TABLE loans (book text, reader text)" -c "INSERT INTO loans VALUES ('Dom Casmurro', 'Bruno')" -c "SELECT * FROM loans"
CREATE TABLE
INSERT 0 1
     book     | reader 
--------------+--------
 Dom Casmurro | Bruno
(1 row)
```

Depois faz o que as pessoas fazem quando querem mudar um ajuste: remove o container e o roda de novo
com o mesmo comando.

```
ana@vm:~$ docker rm -f db
db
ana@vm:~$ docker run -d --name db -e POSTGRES_PASSWORD=lab-only postgres:17
eea400da67ecfc95e1f4b20368be6658ef9865fced4ece88af64a21659293fb0
ana@vm:~$ docker exec db psql -U postgres -c "SELECT * FROM loans"
ERROR:  relation "loans" does not exist
LINE 1: SELECT * FROM loans
                      ^
```

**A tabela não existe.** O PostgreSQL iniciou com um banco vazio, criado do zero, como se o primeiro
container nunca tivesse rodado.

## Para onde os dados foram de verdade

Isso parece a camada de escrita da etapa anterior sumindo, e não é bem isso. A Ana lista os volumes da
máquina:

```
ana@vm:~$ docker volume ls
DRIVER    VOLUME NAME
local     961db081cbe2c3b181ec267e08d4f001727faf79c3b616f91df158ae32d4f7ea
local     f61e9fe7c8d22b6c1cd6be17555250cb9b107eb622dafda810e26daf15975148
ana@vm:~$ docker inspect db --format "{{range .Mounts}}{{.Type}} {{.Name}} -> {{.Destination}}{{end}}"
volume f61e9fe7c8d22b6c1cd6be17555250cb9b107eb622dafda810e26daf15975148 -> /var/lib/postgresql/data
```

**Dois volumes que ela nunca pediu**, cada um com um hash aleatório comprido como nome, e o `db` novo
usa um deles para `/var/lib/postgresql/data`, que é onde o PostgreSQL guarda os arquivos. O motivo está
na própria imagem:

```
ana@vm:~$ docker image inspect postgres:17 --format "{{json .Config.Volumes}}"
{"/var/lib/postgresql/data":{}}
```

A imagem `postgres` declara esse diretório como **volume**. Sempre que um container parte dela sem
receber instrução sobre o que pôr ali, o Docker cria um **volume anônimo**, novinho, com um hash como
nome, e o monta ali. Então a tabela do primeiro container nunca esteve na camada de escrita dele:
estava no primeiro volume anônimo. Remover o container deixou esse volume para trás, e o segundo
container ganhou um novo, vazio.

Os dados continuam no disco. A Ana monta o primeiro volume, o que o `db` não está usando, num
container novo:

```
ana@vm:~$ docker rm -f db
db
ana@vm:~$ docker run -d --name rescued -e POSTGRES_PASSWORD=lab-only -v 961db081cbe2c3b181ec267e08d4f001727faf79c3b616f91df158ae32d4f7ea:/var/lib/postgresql/data postgres:17
d931c9253912810fe856a9430eac7a33cea3e71a8ff41f477f30910552469a6c
ana@vm:~$ docker exec rescued psql -U postgres -c "SELECT * FROM loans"
     book     | reader 
--------------+--------
 Dom Casmurro | Bruno
(1 row)
```

**A linha voltou.** Nada foi destruído; foi desconectado, sem nada dizendo onde estava.

## Por que isso não é boa notícia

Seria fácil ler isso como "o Docker guarda os dados do banco em segurança de qualquer jeito". Não
guarda, por três motivos:

- **Ninguém sabe qual volume é qual.** Dois hashes, e só um `inspect` do container em execução, ou um
  palpite, diz qual deles guarda os dados de ontem. Com dez reinícios, são dez.
- **A limpeza de costume os apaga.** O `docker volume prune`, o comando que a aula 22 usa para liberar
  espaço, remove volumes anônimos que nenhum container está usando, que é exatamente o que um banco
  órfão é. O `docker run --rm` remove os volumes anônimos de um container quando ele termina.
- **Uma imagem que não declara volume não tem nenhum.** A maioria não declara, e para elas a camada
  de escrita é tudo o que existe, e a regra da etapa anterior vale direto.

**A correção é dar nome ao volume.** O `-v pgdata:/var/lib/postgresql/data` monta um volume chamado
`pgdata`, criado no primeiro uso, e todo container iniciado depois com a mesma opção recebe os mesmos
dados. A aula 8 é inteira sobre essa opção e a alternativa a ela.
