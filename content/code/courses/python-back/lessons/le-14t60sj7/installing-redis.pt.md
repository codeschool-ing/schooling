---
title: Instalando o Redis
version: 1
---

O Celery põe as tarefas num **broker**, um servidor que guarda mensagens até um worker pegá-las. Ele
pode usar RabbitMQ ou Redis; este curso usa o **Redis**, o armazenamento em memória que o
`servers-cache` instala e estuda, o que dá uma instalação só para os dois usos.

## Três lugares para tê-lo

| caminho | o que você ganha | o que custa ao seu computador |
|---|---|---|
| **na sua máquina virtual** (recomendado) | o Redis 7 do arquivo do Ubuntu, como serviço | alguns megabytes de disco, e um servidor pequeno rodando ao fundo na máquina virtual |
| **instalado no seu próprio computador** | o `redis` do Homebrew no macOS; no Windows não há versão nativa, e a documentação do Redis aponta para o WSL | o mesmo, no computador em que você também trabalha |
| **online** | um Redis que uma empresa de hospedagem roda, muitas vezes com uma cota gratuita | nada no seu computador; uma URL com senha, nos termos de outra pessoa |

**A máquina virtual é a escolha**, pelos mesmos motivos do PostgreSQL na aula 4, e é o mesmo pacote
que o `servers-cache` instala. Um Redis hospedado funciona com o Celery sem mudanças: a URL do broker
mais abaixo ganha uma senha e um nome de host, e a aula 15 diz onde uma URL dessas mora. Ele não foi
usado neste curso.

## Instalando

Na máquina virtual:

```sh
sudo apt update
sudo apt install -y redis-server
```

O pacote instala o servidor e o `redis-cli`, e inicia o serviço. Confira as três coisas:

```
ana@vm:~/agenda$ redis-server --version
Redis server v=7.0.15 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=d064f9f48c901a92
ana@vm:~/agenda$ systemctl is-active redis-server
active
ana@vm:~/agenda$ redis-cli ping
PONG
```

**`PONG`** é o Redis respondendo na porta padrão, 6379, só em `127.0.0.1`: a configuração do Ubuntu
não escuta em outros endereços, que é o que um broker na mesma máquina quer. Depois o Celery, com o
extra que traz o cliente do Redis:

```
ana@vm:~/agenda$ uv add "celery[redis]"
Resolved 35 packages in 280ms
Prepared 16 packages in 2.97s
Installed 16 packages in 7ms
 + amqp==5.4.1
 + billiard==4.3.1
 + celery==5.6.3
 + click-didyoumean==0.3.1
 + click-plugins==1.1.1.2
 + click-repl==0.4.1
 + kombu==5.6.2
 + packaging==26.3
 + prompt-toolkit==3.0.53
 + python-dateutil==3.0.0
 + redis==6.4.0
 + six==1.17.0
 + tzdata==2026.5
 + tzlocal==5.4.5
 + vine==5.1.0
 + wcwidth==0.9.3
```
