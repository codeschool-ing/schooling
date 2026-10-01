---
title: "O escopo: o que o servidor pode emprestar"
version: 1
---

O lado do servidor no DHCP é um arquivo. **Um escopo é o conjunto de endereços que um servidor pode
emprestar numa sub-rede, junto com as opções que vão com eles.** A palavra é da Microsoft; o servidor
da ISC, o deste laboratório, escreve um escopo como um bloco `subnet` com um `range` dentro. Esta é a
configuração inteira do srv:

```
root@srv:~# cat /run/lab/srv/dhcpd.conf
# the office's DHCP server
authoritative;
default-lease-time 600;
max-lease-time 7200;
option domain-name-servers 10.20.10.10;

subnet 10.20.10.0 netmask 255.255.255.0 {
  range 10.20.10.100 10.20.10.199;
  option routers 10.20.10.1;
}

subnet 10.20.20.0 netmask 255.255.255.0 {
  range 10.20.20.100 10.20.20.199;
  option routers 10.20.20.1;
}

host prn {
  hardware ethernet 02:32:ed:ce:04:12;
  fixed-address 10.20.10.50;
}
```

Leia de cima para baixo. `authoritative` declara este servidor o oficial das suas sub-redes, e por
isso ele responde com uma recusa, um DHCPNAK, quando um cliente pede para manter um endereço que não
pertence a esta rede: um laptop que chega de outra rede ainda com o empréstimo antigo na memória.
`default-lease-time 600` empresta endereços por 600 segundos, dez minutos, quando o cliente não pede
um prazo, e `max-lease-time 7200` limita o que um cliente pode pedir a duas horas. `option
domain-name-servers` fica fora de qualquer bloco, então todo escopo a envia, e foi assim que o pc1
recebeu o servidor de nomes.

Depois vêm os escopos. No primeiro, `range 10.20.10.100 10.20.10.199` é o **pool**, e `option
routers 10.20.10.1` é o gateway padrão informado a todo cliente daquele pool. **Quantos endereços
são? Conte as duas pontas: 199 − 100 + 1 = 100.** A sub-rede tem 254 endereços utilizáveis, então o
pool deixa do .1 ao .99 e do .200 ao .254 para uso estático. É ali que moram o r1 (.1), o srv (.10)
e a reserva da impressora (.50).

O segundo escopo, `subnet 10.20.20.0`, é o andar atrás do r1, uma rede na qual o srv nem está. Ele
só faz sentido quando um relay leva os pedidos daquele andar através do roteador, que é o assunto da
seção sobre relay.

Aqui o pool empresta a partir de baixo: o pc1 levou o .100, e o pc2, pedindo em seguida, recebeu o
seguinte. O segundo comando só imprime o resultado, porque o `dhclient` sem `-v` não diz nada:

```
ana@pc2:~$ sudo dhclient eth0 && ip -br addr show eth0
eth0@if125       UP             10.20.10.101/24 fe80::fd:f2ff:fed2:63ba/64 
```

Dimensionar um pool é aritmética mais uma margem. Conte os dispositivos que vão ter endereço ao mesmo
tempo, celulares incluídos, e lembre que **um endereço continua emprestado até o empréstimo vencer**,
mesmo depois de o dono ter saído pela porta. Uma sala de reunião onde quarenta visitantes entram e
saem a cada hora, com empréstimos de um dia, precisa de bem mais do que quarenta endereços no fim da
semana; com empréstimos de uma hora, precisa de uns quarenta. Empréstimos curtos numa rede de
visitantes movimentada e longos num andar onde as mesmas mesas são usadas todo dia é a troca de
costume.

**Esgotar o pool é silencioso.** Um cliente que não recebe oferta continua mandando DISCOVERs. O
Windows, e muitos outros sistemas, então se dão um endereço de 169.254.0.0/16, a faixa link-local do
IPv4, que não alcança nada além do cabo. Esse endereço na tela de um usuário é o sintoma a reconhecer:
nenhum servidor DHCP respondeu. O laboratório nunca esgota o pool, então não há captura disso aqui; a
seção sobre relay mostra um cliente que não recebe resposta nenhuma.
