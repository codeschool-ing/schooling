---
title: Um endereço de origem é uma afirmação
version: 1
---

Todo pacote carrega o endereço de onde veio, e **quem envia escreve esse campo**. Nada no IP o
confere. Uma máquina pode pôr ali o endereço que quiser, e o pacote viaja do mesmo jeito; o que ela
não consegue é receber a resposta, que vai para quem de fato é dono do endereço. Isso é a
**falsificação de endereço** (*address spoofing*), e é a prima, na camada de rede, do ARP spoofing da
aula 7, em que a mentira era sobre qual MAC é dono de um endereço em um segmento.

Origens forjadas importam por três motivos com que um defensor se depara:

| uso de uma origem forjada | por que funciona | aula |
|---|---|---|
| passar por uma regra que confia em um endereço | uma regra de firewall `ip saddr 192.168.20.0/24 accept` acredita no campo | esta aula |
| reflexão e amplificação | as respostas vão para o endereço forjado, a vítima | 6 |
| esconder de onde vem uma inundação | cada pacote diz vir de uma origem diferente, aleatória | 6 |

O laboratório consegue mostrar o primeiro com o próprio equipamento. O `remote`, na internet, foi
configurado com um segundo endereço da **faixa de servidores** da empresa, `192.168.20.99`, e o usa
como origem de um pedido à loja. Uma gravação no `www` mostra o que chegou:

```
ana@remote:~$ curl -s -m2 --interface 192.168.20.99 https://www.example.com/; echo "exit $?"
exit 28
root@www:~# cut -d" " -f2-7 syn.txt
IP 192.168.20.99.37688 > 192.0.2.80.443: Flags [S],
```

O pedido estourou o tempo, como tinha de acontecer: o `www` respondeu a `192.168.20.99`, e esse
endereço não está na internet, então a resposta não foi a lugar útil nenhum. **Mas o `SYN` chegou ao
`www` dizendo vir do segmento de servidores**, através de um firewall cujas regras foram escritas em
termos de zonas. Qualquer regra, em qualquer lugar, que confie em `192.168.20.0/24` como "nossos
servidores" acabou de confiar em um pacote vindo da internet.

A correção não é parar de confiar em endereços de vez, o que deixaria pouco com que escrever regras.
É **conferir que um endereço de origem chega de onde esse endereço mora**, que é exatamente o fato que
a aula 1 disse que as interfaces carregam.
