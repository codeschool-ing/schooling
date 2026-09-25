---
title: Para onde foi o tempo
version: 1
---

Quando uma página está lenta, a primeira pergunta é qual camada está lenta, e o `curl -w` responde.
Ele imprime temporizadores no fim de cada etapa:

```
ana@laptop:~$ curl -so /dev/null -w 'dns        %{time_namelookup}\ntcp        %{time_connect}\ntls        %{time_appconnect}\nfirst byte %{time_starttransfer}\ntotal      %{time_total}\n' https://www.example.com/prices.txt
dns        0.000920
tcp        0.001154
tls        0.018201
first byte 0.018616
total      0.019066
```

**Cada número é o tempo desde o começo, não a duração da etapa**, então as etapas são as diferenças:

| etapa | de | até | levou |
|---|---|---|---|
| DNS | 0 | 0.000920 | menos de um milissegundo |
| handshake do TCP | 0.000920 | 0.001154 | uma fração de milissegundo |
| handshake do TLS | 0.001154 | 0.018201 | uns 17 milissegundos |
| primeiro byte do servidor | 0.018201 | 0.018616 | menos de um milissegundo |
| o resto do arquivo | 0.018616 | 0.019066 | menos de um milissegundo |

No laboratório, onde a rede não leva tempo, o handshake do TLS domina: é a própria criptografia,
rodando num computador só para as duas pontas. Numa conexão de verdade, cada etapa tem o seu suspeito.
**Um `dns` lento é o resolver. Um `tcp` lento é distância ou perda. Um `tls` lento é distância de
novo**, já que o handshake precisa de uma ida e volta, ou um servidor sobrecarregado. **Um primeiro
byte lento, depois de todo o resto ter sido rápido, é a aplicação** pensando, e nenhum trabalho de
rede vai mudar isso.
