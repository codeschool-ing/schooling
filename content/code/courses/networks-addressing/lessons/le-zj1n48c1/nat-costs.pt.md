---
title: O que o NAT custa
version: 1
---

O NAT resolveu a falta de endereços IPv4 e cobrou por isso de jeitos que aparecem anos depois. O
primeiro aparece dentro do próprio escritório.

O pc2 tenta o serviço redirecionado pelo endereço público, do jeito que faria um notebook cujo favorito
guarda o nome público:

```
ana@pc2:~$ curl -s -m 4 http://203.0.113.2:8080/; echo "exit status $?"
exit status 7
```

Conexão recusada, de dentro, enquanto o mesmo endereço e porta funcionavam a partir do isp um momento
antes. A regra explica: `iifname "eth1" tcp dport 8080 dnat to 10.20.10.10:80`. O pedido do pc2 chegou ao
r1 pela **eth0**, então o redirecionamento não casou, e o pacote era simplesmente para o r1, que não tem
nada na porta 8080. Esse é o problema do **hairpin**: um serviço publicado através de NAT não é
alcançável pelo endereço público a partir da rede em que ele mora, a não ser que o roteador esteja
preparado para isso. Há duas correções comuns: dar ao lado de dentro a sua própria resposta para o nome
(DNS dividido, o split DNS, para que o escritório resolva o nome do servidor para `10.20.10.10`), ou
acrescentar hairpin NAT no roteador, que casa também com a interface de dentro e reescreve a origem para
que a resposta volte pelo r1 e não direto do srv.

O resto dos custos vem do que o NAT faz com a ideia de que qualquer máquina alcança qualquer outra:

- **o fim a fim acabou.** Uma máquina de dentro não é alcançável a não ser que alguém redirecione uma
  porta para ela, um serviço por porta pública. A aula 5 mostrou o que isso faz com os programas ponto a
  ponto: relays e a maquinaria de STUN, TURN e ICE existem por causa disso;
- **os logs veem um endereço para todo mundo.** Todo servidor que o escritório usou registrou
  203.0.113.2 para os três PCs. Uma reclamação de fora que cita esse endereço cita o escritório inteiro,
  e achar a máquina exige cruzar a porta e a hora exata com registros que o r1 teria de guardar — o r1
  do laboratório não guarda nenhum;
- **o meio guarda estado.** O r1 tem uma entrada para cada conexão. Se o r1 reinicia, a tabela some e
  toda conexão aberta através dele cai; se a tabela enche, conexões novas falham;
- **NAT duas vezes.** Provedores com falta de endereços usam NAT de operadora (CGNAT): o roteador do
  cliente recebe um endereço externo de `100.64.0.0/10`, um bloco reservado exatamente para isso, e o
  provedor traduz de novo. Um redirecionamento de porta no roteador do cliente passa então a redirecionar
  a partir de um endereço que a internet não alcança.

**O IPv6 não precisa de nada disso.** Com endereços de 128 bits há o bastante para cada dispositivo ter
um público, e a aula 9 numera um escritório assim. O que sobra é o firewall: um roteador IPv6 continua
descartando, por regra, as conexões que ninguém pediu, que é o trabalho que se atribuía ao NAT por
engano desde o começo.
