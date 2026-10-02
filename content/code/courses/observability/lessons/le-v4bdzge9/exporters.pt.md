---
title: Exporters: métricas para coisas que não as têm
version: 1
---

Os serviços da loja publicam as próprias métricas porque o curso os escreveu assim. Uma máquina
Linux, um banco PostgreSQL ou um site que não é seu não publicam nada no formato do Prometheus. **Um
exporter é um pequeno programa que pergunta a uma coisa dessas sobre ela mesma, do jeito que ela
puder ser perguntada, e responde à coleta do Prometheus com o resultado.** O laboratório roda três,
e o RabbitMQ tem um embutido:

| alvo | o que ele traduz | como pergunta |
|---|---|---|
| `node-exporter` | a máquina Linux: processadores, memória, discos, rede | lê `/proc` e `/sys` |
| `postgres-exporter` | o PostgreSQL | roda consultas nas visões de estatística dele |
| o plugin do próprio RabbitMQ | filas, conexões, mensagens | de dentro do broker |
| `blackbox-exporter` | a vitrine, de fora | manda uma requisição e mede o tempo |

Uma métrica de cada:

```
ana@obs:~/shop$ ./promq 'node_load1'
__name__=node_load1 instance=node-exporter:9100 job=node  0.5
ana@obs:~/shop$ ./promq 'pg_up'
__name__=pg_up instance=postgres-exporter:9187 job=postgres  1
ana@obs:~/shop$ ./promq 'rabbitmq_queue_messages_ready'
__name__=rabbitmq_queue_messages_ready instance=rabbitmq:15692 job=rabbitmq  0
ana@obs:~/shop$ ./promq 'probe_success'
__name__=probe_success instance=http://storefront:8080/health job=blackbox  1
```

A carga média da máquina no último minuto, o banco respondendo, uma fila vazia, e a sonda externa
dando certo. **A última é de outra natureza.** As outras três relatam o que um sistema diz de si; o
blackbox exporter age como um cliente e relata o que viveu, dividido por fase:

```
ana@obs:~/shop$ ./promq 'probe_http_duration_seconds'
__name__=probe_http_duration_seconds instance=http://storefront:8080/health job=blackbox phase=connect  0.000294823
__name__=probe_http_duration_seconds instance=http://storefront:8080/health job=blackbox phase=processing  0.001231325
__name__=probe_http_duration_seconds instance=http://storefront:8080/health job=blackbox phase=resolve  0.000709531
__name__=probe_http_duration_seconds instance=http://storefront:8080/health job=blackbox phase=tls  0
__name__=probe_http_duration_seconds instance=http://storefront:8080/health job=blackbox phase=transfer  0.000096116
```

Resolver o nome, conectar, o processamento do servidor e a transferência, cada um alguns décimos de
milissegundo numa máquina só, e sem TLS porque o laboratório fala HTTP puro por dentro. **Uma sonda
de fora pega o que nenhuma métrica interna pega**: um serviço que se declara saudável enquanto o
balanceador na frente dele não manda ninguém para lá. A aula 14 volta a ela.

Para quase tudo o que uma equipe roda já existe um exporter, escrito pelo projeto ou pela
comunidade, e a primeira pergunta sobre um componente novo é qual. Escrever um exporter é o último
recurso, e raramente passa de um laço que pergunta e uma página que responde.
