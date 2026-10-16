---
title: Quando o Metabase não funciona
version: 1
---

O Metabase falha de menos jeitos que o PostgreSQL, e a maioria aparece como uma frase vermelha no
formulário **Add your data**, ou como uma página que não carrega. Cada um tem uma verificação pelo
shell que diz qual.

## A página não carrega nada

O Metabase pode ainda estar subindo: dê um minuto a ele, e pergunte direto da máquina com `curl -s
-w '\n' http://localhost:3000/api/health`. `{"status":"ok"}` quer dizer que ele está de pé e o
problema é o caminho do seu navegador até ele — o encaminhamento de porta da aula 1, ou o endereço
no UTM. Sem resposta, o próprio Metabase não está rodando, e `sudo docker ps -a` diz se o contêiner
existe e como ele terminou.

Um contêiner que parou segundos depois de subir costuma dizer por quê no log. Um jeito de provocar
isso é subir um segundo Metabase enquanto o primeiro segura a porta 3000:

```
ana@vm:~$ sudo docker run -d --name metabase2 --network host metabase/metabase:v0.64.1.5
b691785eeb17c3a3dcc59e1be3fcc1c8d71b01767ad8fc7bc443dcbac708b29e
ana@vm:~$ sudo docker ps -a --format "table {{.Names}}\t{{.Status}}"
NAMES       STATUS
metabase2   Exited (1) 23 seconds ago
metabase    Up About a minute
ana@vm:~$ sudo docker logs metabase2 2>&1 | grep FAILED
2026-10-10 05:17:26,268 ERROR core.core :: Metabase Initialization FAILED: Failed to bind to /0.0.0.0:3000 
```

`Exited (1)` e `Failed to bind to /0.0.0.0:3000`: outra coisa estava com a porta. `sudo docker logs
metabase` mostra o log inteiro do seu, e a linha com `FAILED` é a que deve ser lida.

Um contêiner que fica reiniciando, ou uma máquina que trava enquanto o Metabase sobe, está com pouca
memória: a máquina virtual tem menos do que a aula 1 pediu, ou o `-Xmx1g` ficou de fora.

## `password authentication failed`

```
ana@vm:~$ PGPASSWORD=wrong-password psql -h localhost -U metabase lantern -c 'SELECT 1'
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  password authentication failed for user "metabase"
connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  password authentication failed for user "metabase"
```

A senha do formulário não é a do papel. Esse é o único significado dessa mensagem, e a verificação
acima a reproduz pelo shell, então você testa uma senha sem o formulário. `ALTER ROLE metabase
PASSWORD '…'` no `psql lantern` define uma nova.

## A conexão é recusada

Se você subiu o Metabase sem `--network host`, `localhost` dentro do contêiner é o próprio contêiner,
onde não roda PostgreSQL nenhum, e o formulário diz que a conexão foi recusada. Remova o contêiner
com `sudo docker rm -f metabase` e suba de novo com o comando completo desta aula. (Essa falha não
foi reproduzida para o curso; a explicação segue do que a opção faz.)

## O Metabase não mostra tabela nenhuma, ou mostra as antigas

Depois de rodar o `semantic.sql` de novo, as views são novas e o papel não tem grants nelas:

```
ana@vm:~$ psql -q lantern -f semantic.sql 2>/dev/null
ana@vm:~$ PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -c 'SELECT count(*) FROM semantic.orders'
ERROR:  permission denied for schema semantic
LINE 1: SELECT count(*) FROM semantic.orders
                             ^
```

Rode o bloco de `GRANT` desta aula de novo. O Metabase também lembra o que viu na última
sincronização, então uma view renomeada ou nova só aparece depois da próxima; nas configurações de
admin, em *Databases*, o banco Lantern tem um botão para sincronizar o schema agora.
