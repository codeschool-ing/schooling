---
title: Um cache de verdade na sua própria máquina
version: 1
---

**Não existe emulador do Memorystore, então esta aula traz o motor no lugar dele.** O Ubuntu 24.04
empacota o Redis 7.0, e o Memorystore for Redis oferece o 7.0 entre as suas versões, então o servidor
do seu laptop responde aos mesmos comandos que aquele que o Google rodaria para você. Tudo daqui até o
fim da aula roda contra um servidor de verdade, com chaves de verdade em memória de verdade. O que
ele não mostra é a metade administrada: sem janela de manutenção, sem réplica em outra zona que se
promove sozinha, sem fatura. **Este é um acréscimo desta aula ao laboratório**, e nada depois dela
precisa dele.

## Instale, e impeça que ele ligue sozinho

```sh
sudo apt-get install -y redis-server
sudo systemctl disable --now redis-server
```

O pacote liga um serviço Redis próprio assim que é instalado, e liga de novo a cada boot. A segunda
linha para o serviço e o mantém parado, para que, como os emuladores, nada rode sem você ligar. No
WSL sem systemd essa linha imprime um erro e não há nada para parar, e tudo bem.

## Um terminal só dele

**O Redis roda num terminal só dele, do mesmo jeito que os emuladores.** Abra um e digite:

```sh
redis-server --port 6379 --save '' --appendonly no
```

Ele imprime algumas linhas e fica esperando. `--save ''` e `--appendonly no` desligam as duas formas
que o Redis tem de gravar em disco, então pará-lo com `Ctrl+C` esquece todas as chaves, como parar um
emulador. Sem senha definida ele roda em modo protegido, que recusa conexões de qualquer máquina que
não seja esta. Você continua digitando no terminal em que digitou as linhas de "Toda vez que você
abrir um terminal".

## Chaves que expiram

`redis-cli` é a linha de comando que veio com o servidor. Ele manda um comando e imprime a resposta:

```
ana@laptop:~/gcp$ redis-cli PING
PONG
ana@laptop:~/gcp$ redis-cli INFO server | grep redis_version
redis_version:7.0.15
ana@laptop:~/gcp$ redis-cli SET product:p-101 '{"name":"banana prata 1kg","price_cents":1290}' EX 300
OK
ana@laptop:~/gcp$ redis-cli GET product:p-101
"{\"name\":\"banana prata 1kg\",\"price_cents\":1290}"
ana@laptop:~/gcp$ redis-cli TTL product:p-101
(integer) 300
ana@laptop:~/gcp$ redis-cli EXPIRE product:p-101 5
(integer) 1
ana@laptop:~/gcp$ sleep 6; redis-cli GET product:p-101
(nil)
ana@laptop:~/gcp$ redis-cli TTL product:p-101
(integer) -2
ana@laptop:~/gcp$ redis-cli SET visits 1
OK
ana@laptop:~/gcp$ redis-cli TTL visits
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
programa põe num cache deveria ter um tempo de vida, e as duas próximas seções mostram o que acontece
dos dois lados dessa regra.

## A biblioteca de cliente

Os programas desta aula falam com o Redis a partir do Python, pelo pacote `redis`. Instale-o no
ambiente virtual do curso, aquele que o `source venv/bin/activate` ligou:

```
ana@laptop:~/gcp$ pip install -q redis==8.1.0
ana@laptop:~/gcp$ python3 -c "import redis; print(redis.__version__)"
8.1.0
```

A versão 8.1.0 foi publicada em 30 de julho de 2026. O mesmo pacote fala com o Memorystore for Redis
e, no modo cluster dele, com o Redis Cluster e o Valkey. No Google Cloud o host seria o endereço
privado da instância na sua VPC em vez de `127.0.0.1`: uma instância do Memorystore não tem endereço
público nenhum, então o programa que a lê roda na mesma rede VPC, o assunto da aula 15 de
`gcp-foundations`.
