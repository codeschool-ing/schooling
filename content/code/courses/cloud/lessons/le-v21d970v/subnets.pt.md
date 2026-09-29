---
title: "Sub-redes: fatias da faixa, e os endereços que você não recebe"
version: 1
---

A faixa de uma VPC não é onde as máquinas ficam. **As máquinas ficam em sub-redes**: blocos CIDR
menores recortados da faixa da VPC, como a seção anterior recortou `10.0.0.0/16` em `/20`s. Uma
instância é lançada numa sub-rede e pega o endereço privado do bloco dela. Duas sub-redes da mesma VPC
não podem se sobrepor, e tudo o que o resto desta aula prende — uma tabela de rotas, uma network ACL,
um balanceador de carga — se prende a sub-redes.

Por que dividir, se um bloco grande comportaria tudo? Porque a sub-rede é a unidade sobre a qual os outros
controles agem. Uma tabela de rotas decide para onde vai o tráfego de uma sub-rede inteira, então
máquinas que nunca devem alcançar a internet ficam numa sub-rede cuja tabela não tem saída, e máquinas
voltadas para a internet ficam em outra. A divisão é uma afirmação sobre quem pode falar com quem.

## Uma sub-rede e uma zona

**Na AWS, uma sub-rede vive em exatamente uma zona de disponibilidade.** Você escolhe a zona ao
criá-la, e toda instância lançada nela roda ali. Então uma aplicação que deve sobreviver à perda de uma
zona precisa de pelo menos duas sub-redes para cada papel, uma em cada zona, e é por isso que os
layouts desta aula vêm em pares.

Os outros dois provedores traçam a linha em outro lugar. **No Google Cloud uma
sub-rede é regional**: abrange todas as zonas da região, e você escolhe a zona por instância. No Azure
também, uma virtual network e suas sub-redes abrangem todas as zonas da região, e a zona é escolhida
por recurso. O objetivo do desenho é o mesmo em todo lugar, máquinas de cada papel em mais de uma zona;
o que muda é se quem carrega a zona é a sub-rede ou a instância. A aula 9 explica o que é uma zona,
fisicamente, e quanto custa em tempo cruzar de uma para outra.

## Os endereços que o provedor guarda

Um `/24` tem 256 endereços. Você não pode usar todos, porque **a AWS reserva cinco endereços em toda
sub-rede**: os quatro primeiros e o último. Numa sub-rede `10.0.1.0/24` são estes, e tirá-los deixa o
número que você de fato pode dar a máquinas:

```
ana@laptop:~/cloud$ python3 -c "import ipaddress; s = ipaddress.ip_network('10.0.1.0/24'); print(s[0], s[1], s[2], s[3], s[-1]); print(s.num_addresses - 5)"
10.0.1.0 10.0.1.1 10.0.1.2 10.0.1.3 10.0.1.255
251
ana@laptop:~/cloud$ python3 -c "print(2**(32-28) - 5)"
11
```

A AWS documenta para que serve cada um. `10.0.1.0` é o endereço da rede. `10.0.1.1` é o roteador da
VPC, o gateway para onde toda instância da sub-rede manda. `10.0.1.2` é reservado ao servidor DNS do
provedor. `10.0.1.3` fica guardado para uso futuro. `10.0.1.255` seria o endereço de broadcast, e a
VPC não transporta broadcast, mas o endereço fica retido assim mesmo.

**251 endereços utilizáveis num `/24`**, e na ponta pequena a perda pesa. A AWS aceita sub-redes de
`/16` até `/28`; um `/28` tem 16 endereços, e o segundo comando mostra que sobram 11. O Azure também
guarda cinco em cada sub-rede; o Google Cloud guarda quatro na faixa primária de cada sub-rede. A lista
exata muda, e o hábito é o mesmo: subtraia antes de dimensionar.

## Dimensionar sem se arrepender

Os endereços de uma sub-rede não são consumidos só pelas suas instâncias. Um balanceador de carga
põe um nó em cada sub-rede que atende, e cada nó ocupa um endereço; um banco gerenciado ocupa um; e
também cada interface de cada instância que um grupo de autoscaling (aula 4) sobe numa hora de pico.
Uma sub-rede cheia recusa o próximo lançamento, e na AWS a faixa de uma sub-rede não pode ser mudada
depois que ela existe.

Então o padrão é generoso. Com `10.0.0.0/16` há dezesseis `/20`s para distribuir, cada um com 4.091
endereços utilizáveis na AWS, e mesmo seis deles — pública, aplicação e dados, em duas zonas —
deixam dez sem uso para o que vier depois. Esgotar a VPC é muito mais difícil que esgotar a sub-rede,
e um `/28` não economiza nada que valha a pena.
