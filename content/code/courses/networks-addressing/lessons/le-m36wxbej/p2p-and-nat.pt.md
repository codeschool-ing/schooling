---
title: Por que um par em casa é difícil de alcançar
version: 1
---

Os pares da seção anterior estavam no mesmo switch, com endereços que um alcançava no outro. Na
internet, a maioria das máquinas que seriam pares fica atrás de um roteador fazendo NAT, e **o NAT
deixa conversas saírem e não deixa conversas novas entrarem**. A aula 11 desmonta o NAT; esta seção
só mostra o que ele faz com o ponto a ponto.

No laboratório do escritório, o r1 liga o escritório, `10.20.10.0/24`, ao provedor, e toda máquina do
escritório sai com o único endereço público do r1, `203.0.113.2`. Sair funciona. O pc1 é cliente de um
servidor web fora do escritório:

```
ana@pc1:~$ curl -s -m 3 http://192.0.2.80/
served by web1
```

(O `web1` é um dos dois servidores atrás do balanceador de carga da aula 1.) Agora a outra direção.
Do roteador do provedor, o isp, tenta-se uma conexão na porta 8000 do endereço público do escritório,
do jeito que um par na internet tentaria alcançar um socket escutando no pc1:

```
root@isp:~# nc -z -v -w 3 203.0.113.2 8000
nc: connect to 203.0.113.2 port 8000 (tcp) failed: Connection refused
```

`Connection refused` é uma resposta, e veio do próprio r1. A tentativa chegou a `203.0.113.2`, que é o
endereço do r1. O r1 não tem programa na porta 8000 nem regra dizendo que essa porta pertence a uma
máquina de dentro, então o kernel dele respondeu com uma recusa, e o pc1 nem ficou sabendo. **De fora,
o escritório é um endereço sem nada atrás** até alguém configurar uma entrada, que é o
redirecionamento de portas da aula 11.

A saída funciona porque o r1 se lembra dela. A tabela de rastreamento de conexões dele guarda o pedido
web do pc1:

```
root@r1:~# conntrack -L -p tcp 2>/dev/null | head -3
tcp      6 118 TIME_WAIT src=10.20.10.21 dst=192.0.2.80 sport=59190 dport=80 src=192.0.2.80 dst=203.0.113.2 sport=80 dport=59190 [ASSURED] mark=0 use=1
```

Leia a linha em duas metades. `src=10.20.10.21 dst=192.0.2.80 sport=59190 dport=80` é a conexão como o
pc1 a mandou. A segunda metade é a resposta que o r1 espera: de `192.0.2.80` porta 80, para
`203.0.113.2` porta `59190`. Um pacote que chega batendo com a segunda metade é traduzido de volta e
entregue ao pc1. Um pacote que não bate com nada na tabela, como a tentativa do isp na porta 8000, não
tem para onde ir lá dentro. (`TIME_WAIT` e `118` dizem que a conexão já fechou e que a entrada tem 118
segundos de vida.)

Agora ponha os dois pares atrás de roteadores como o r1. Cada um consegue começar uma conversa para
fora, e nenhum consegue receber uma. Os programas que precisam de ponto a ponto através de NAT
combinam três técnicas publicadas, e vale reconhecer os nomes, porque eles aparecem em logs de
firewall e em telas de configuração:

- **um relay**: os dois pares conectam para fora num servidor que repassa os dados entre eles.
  Funciona sempre que os dois alcançam o servidor, e transforma a conversa em cliente-servidor de
  novo (o padrão é o TURN);
- **perguntar a um servidor o que se vê de fora**: um par descobre, por um servidor, o endereço e a
  porta públicos que o roteador lhe deu (STUN), e assim tem o que informar ao outro par;
- **conectar dos dois lados ao mesmo tempo**, para que cada roteador já tenha uma entrada para a
  conversa quando o pacote do outro par chegar. Isso passa por muitos NATs e não por todos, e é por
  isso que o ICE, o procedimento que coordena os três, deixa o relay como último recurso.

Uma chamada de vídeo entre duas casas é o exemplo comum: ela é combinada pelos servidores do
provedor, e o som e a imagem vão direto entre as duas casas quando os roteadores permitem, por um
relay quando não permitem.
