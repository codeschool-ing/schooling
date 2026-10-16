---
title: Um cache de verdade na sua própria máquina
version: 1
---

**O moto cria um cluster de cache e não roda cache nenhum, então esta lição traz o dela.** O Ubuntu
empacota o servidor Redis, e o Redis OSS fala o protocolo que o Valkey e o ElastiCache falam. Tudo
daqui até o fim da lição roda contra um servidor de verdade, com chaves de verdade em memória de
verdade. O que ele não mostra é a metade administrada: sem failover, sem réplica em outra zona, sem
fatura. **Este é um acréscimo desta lição ao laboratório**, e nada depois dela precisa dele.

## Instale, e impeça que ele ligue sozinho

```sh
sudo apt-get install -y redis-server
sudo systemctl disable --now redis-server
```

O pacote liga um serviço Redis próprio assim que é instalado, e o liga de novo a cada boot. A segunda
linha para o serviço e o mantém parado, para que, como o moto, nada rode sem você ligar. No WSL sem
systemd essa linha imprime um erro e não há nada para parar, e tudo bem.

## Um terceiro terminal

**O Redis roda num terminal só dele, do mesmo jeito que o moto.** Abra um e digite:

```sh
redis-server --port 6379 --save '' --appendonly no
```

Ele imprime algumas linhas e fica esperando. `--save ''` e `--appendonly no` desligam as duas formas
que o Redis tem de gravar em disco, então pará-lo com `Ctrl+C` esquece todas as chaves, como parar o
moto. Sem senha definida ele roda em modo protegido, que recusa conexões de qualquer máquina que não
seja esta. O terminal do moto fica como está, e você continua digitando naquele em que digitou as
quatro linhas do laboratório.

## Chaves que expiram

O `redis-cli` é a linha de comando que veio com o servidor. Ele manda um comando e imprime a
resposta:

```
ana@laptop:~/aws$ redis-cli PING
PONG
ana@laptop:~/aws$ redis-cli INFO server | grep redis_version
redis_version:7.0.15
ana@laptop:~/aws$ redis-cli SET product:p-101 '{"name":"banana prata 1kg","price_cents":1290}' EX 300
OK
ana@laptop:~/aws$ redis-cli GET product:p-101
"{\"name\":\"banana prata 1kg\",\"price_cents\":1290}"
ana@laptop:~/aws$ redis-cli TTL product:p-101
(integer) 300
ana@laptop:~/aws$ redis-cli EXPIRE product:p-101 5
(integer) 1
ana@laptop:~/aws$ sleep 6; redis-cli GET product:p-101
(nil)
ana@laptop:~/aws$ redis-cli TTL product:p-101
(integer) -2
ana@laptop:~/aws$ redis-cli SET visits 1
OK
ana@laptop:~/aws$ redis-cli TTL visits
(integer) -1
```

**`EX 300` deu à chave um tempo de vida de cinco minutos**, e o `TTL` faz a contagem regressiva. O
`EXPIRE` trocou esse tempo por 5 segundos, e depois do `sleep 6` a chave tinha sumido: o `GET`
respondeu `(nil)` e o `TTL` respondeu `-2`, que quer dizer que a chave não existe. A chave sem
validade respondeu `-1`. Vale guardar esses dois números negativos, porque é com eles que você
distingue "expirou" de "nunca teve validade" quando olha um cache que está se comportando mal. O
Redis remove uma chave expirada no momento em que alguém pede por ela, e uma varredura em segundo
plano remove as que ninguém pede.

**Uma chave que nunca expira é como um cache se enche de coisas que ninguém lê.** Toda chave que um
programa põe num cache deveria ter um tempo de vida, e as duas próximas seções mostram o que
acontece dos dois lados dessa regra.

## A biblioteca de cliente

Os programas desta lição falam com o Redis em Python, pelo pacote `redis`. Instale-o no ambiente
virtual do curso, aquele que o `source venv/bin/activate` ligou:

```
ana@laptop:~/aws$ pip install -q redis==8.1.0
ana@laptop:~/aws$ python3 -c "import redis; print(redis.__version__)"
8.1.0
```

A versão 8.1.0 foi publicada em 30 de julho de 2026. O mesmo pacote fala com o Valkey e com o
ElastiCache sem mudança; na AWS, o host seria o endpoint do cache em vez de `127.0.0.1`.
