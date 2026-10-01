---
title: Máscaras curinga, lidas bit a bit
version: 1
---

As ACLs do IOS escrevem redes com uma **máscara curinga** (wildcard mask) em vez de uma máscara de
sub-rede: `192.168.30.0 0.0.0.255` em vez de `192.168.30.0/24`. A curinga é a máscara de sub-rede
invertida: **um bit 0 quer dizer "tem de casar", um bit 1 quer dizer "qualquer valor"**. Então
`0.0.0.255` diz que os três primeiros bytes têm de casar e o último pode ser qualquer coisa.

O `ipaddress` do Python chama a curinga de **host mask**, e calcula as duas a partir de um prefixo:

```
ana@branch:~$ python3 -c "import ipaddress as i; n=i.ip_network(\"192.168.30.0/24\"); print(n.netmask, n.hostmask); n=i.ip_network(\"10.20.16.0/20\"); print(n.netmask, n.hostmask, n.num_addresses)"
255.255.255.0 0.0.0.255
255.255.240.0 0.0.15.255 4096
```

`/24` é a netmask `255.255.255.0` e a curinga `0.0.0.255`. `/20` é `255.255.240.0` e a curinga
`0.0.15.255`, e cobre 4.096 endereços. O jeito rápido de calcular uma curinga à mão é subtrair de 255
cada byte da netmask: `255 - 240 = 15`.

Três curingas com nome próprio:

| curinga | abreviação no IOS | casa com |
|---|---|---|
| `0.0.0.0` | `host 192.168.30.20` | exatamente um endereço |
| `255.255.255.255` | `any` | todo endereço |
| `0.0.0.255` | nenhuma | um /24 |

**Uma curinga não precisa ser uma sequência de uns no fim**, e essa é a única coisa que ela faz e um
prefixo não. `192.168.0.1 0.0.254.0` casa com `192.168.0.1`, `192.168.2.1`, `192.168.4.1` e assim por
diante: o host `.1` em todo terceiro byte par. Raramente é uma boa ideia, porque a próxima pessoa tem de
decifrá-la bit a bit para saber o que ela permite, e as ACLs que causam quedas são as que ninguém
consegue ler de relance.
