---
title: Logs que um programa consegue ler
version: 1
---

Métricas dizem quantos e quão rápido. Quando um número parece errado, a próxima pergunta é sobre
pedidos específicos: quais falharam, com que erro, em qual cópia. Essa é a tarefa de um log, e um
log só é útil se puder ser **procurado pelos seus campos**, o que quer dizer escrevê-lo para um
programa ler e não uma pessoa.

A bilheteria escreve um objeto JSON por linha, na saída padrão. O Docker guarda o que cada contêiner
escreve ali, e o `docker compose logs` lê; `--no-log-prefix` tira o nome do contêiner do começo de
cada linha, para que a linha seja JSON puro:

```
ana@lab:~/tickets$ docker compose logs app --no-log-prefix | tail -3
{"time": "2026-10-10T06:10:17.822+00:00", "level": "info", "message": "request", "host": "9c46e3d34a31", "method": "POST", "route": "/events/{id}/tickets", "status": 201, "ms": 29.6}
{"time": "2026-10-10T06:10:17.823+00:00", "level": "info", "message": "request", "host": "9c46e3d34a31", "method": "POST", "route": "/events/{id}/tickets", "status": 201, "ms": 43.2}
{"time": "2026-10-10T06:10:17.823+00:00", "level": "info", "message": "request", "host": "9c46e3d34a31", "method": "POST", "route": "/events/{id}/tickets", "status": 201, "ms": 26.0}
```

Toda linha tem as mesmas chaves no mesmo formato: a hora em UTC ao milissegundo, um nível, uma
mensagem, a cópia que a escreveu e os campos do próprio pedido. Uma linha como
`POST /events/7/tickets took 43 ms` lê bem e precisa ser desmontada com um padrão para ser contada;
uma linha JSON já está desmontada, e todo sistema de logs indexa os campos de JSON diretamente.

## Quando algo quebra

A réplica é parada, como se tivesse caído, e a página de um show é pedida:

```
ana@lab:~/tickets$ docker compose stop replica
 Container tickets-replica-1 Stopping 
 Container tickets-replica-1 Stopped 
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"error": "internal error"}
ana@lab:~/tickets$ docker compose logs app --no-log-prefix | grep '"level": "error"' | tail -1
{"time": "2026-10-10T06:10:28.856+00:00", "level": "error", "message": "request failed", "host": "e8f493cffbb3", "method": "GET", "route": "/events/{id}", "error": "AdminShutdown: terminating connection due to administrator command"}
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'sum by (route, status) (tickets_requests_total{status="500"})'
{route="/events/{id}", status="500"} => 1 @[1791612635.399]
ana@lab:~/tickets$ docker compose start replica
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Starting 
 Container tickets-replica-1 Started 
```

Três vistas de uma falha. O **cliente** recebeu um 500 com uma mensagem curta, e nada sobre o lado de
dentro: uma mensagem de erro para usuários não deve descrever o banco. O **log** diz exatamente o que
aconteceu: um `GET` de `/events/{id}` falhou com `AdminShutdown`, o jeito do PostgreSQL de dizer que o
servidor do outro lado da conexão foi desligado. A **métrica** contou: um pedido com status 500
naquela rota, que é o que um alerta sobre a taxa de erros dispararia.

Sem o `try` do `observe`, a exceção teria fechado a conexão sem resposta, o nginx teria respondido
502, e nada na bilheteria teria registrado coisa alguma. **Um erro que o programa não captura é um
erro que as próprias métricas dele não conseguem ver.**

## O que vai num log, e o que não vai

- **Uma linha por evento que valha achar depois**, com os campos que o identificam: rota, status,
  duração, e na aula 8 o rastro a que ele pertence.
- **Níveis usados para o que querem dizer.** `error` é algo que precisa de uma pessoa; `info` é o
  registro do trabalho normal. Um sistema que registra erros para eventos normais ensina as pessoas
  a ignorá-los.
- **Nada de segredos nem de dados pessoais.** Senhas, tokens, números de cartão, o e-mail de um
  comprador. Logs são copiados para mais lugares e guardados por mais tempo que qualquer outra coisa
  que um sistema escreve, e um campo registrado por acidente é um vazamento que dura tanto quanto os
  logs.
- **Não como substituto de uma métrica.** Contar linhas de log para saber a taxa de pedidos funciona,
  e custa armazenamento em proporção ao tráfego; um contador custa o mesmo em qualquer tráfego. A 800
  pedidos por segundo, o log de pedidos da bilheteria tem uns 70 milhões de linhas por dia.
