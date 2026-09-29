---
title: O ARP acredita em quem responder
version: 1
---

Para mandar um pacote a um endereço do seu próprio segmento, uma máquina precisa do **MAC** desse
endereço. O ARP pergunta ao segmento inteiro *quem tem 192.168.10.1?*, o dono responde *eu, neste
MAC*, e quem perguntou guarda a resposta na sua **tabela de vizinhos** (neighbour table) por um tempo.
A tabela do `laptop`, e a pergunta feita à mão:

```
ana@laptop:~$ ip neigh show dev eth0
192.168.10.1 lladdr 52:54:00:a8:0a:01 REACHABLE 
ana@laptop:~$ arping -c 2 -I eth0 192.168.10.1
ARPING 192.168.10.1 from 192.168.10.20 eth0
Unicast reply from 192.168.10.1 [52:54:00:A8:0A:01]  0.541ms
Unicast reply from 192.168.10.1 [52:54:00:A8:0A:01]  0.550ms
Sent 2 probes (1 broadcast(s))
Received 2 response(s)
```

O gateway, a interface de LAN do `fw`, responde de `52:54:00:a8:0a:01`, e é isso que o `laptop`
guardou.

**O ARP não tem autenticação nenhuma.** Qualquer máquina do segmento pode responder a uma pergunta, ou
anunciar uma resposta que ninguém pediu, e as outras em geral acreditam e atualizam suas tabelas. Isso
é tudo o que existe no **ARP spoofing**, também chamado de envenenamento de ARP (ARP poisoning): uma
máquina do segmento diz às outras que o endereço do gateway está no MAC *dela*. A partir daí, o
tráfego delas para o mundo de fora passa primeiro por ela. Se ela repassar o tráfego, nada quebra de
forma visível, e ela lê tudo o que a primeira seção desta aula mostrou ser legível.

Três consequências para quem defende:

- **Um atacante precisa estar no segmento.** O ARP não atravessa um roteador, então o spoofing é uma
  ameaça vinda de uma máquina que já está dentro da LAN: um laptop comprometido, ou algo ligado a uma
  tomada de rede livre. A aula 22 trata de quem pode se conectar, para começo de conversa.
- **O sintoma é um endereço com dois MACs**, ou um endereço cujo MAC muda. Isso dá para ver, e a
  próxima seção vê.
- **A criptografia tira o sentido do ataque.** O tráfego que passa pela máquina errada sobre TLS, com o
  certificado verificado, não entrega a ela nada além de metadados. É o fio que a aula 13 retoma.
