---
title: Cada um com a própria identidade
version: 1
---

No primeiro boot, os dois clones construíram uma identidade própria:

```
ana@web1:~$ hostname; cat /etc/machine-id; ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub | cut -d" " -f2; ip -br addr show enp1s0
web1
497efb056e9e47e2ad5e043f60c0197e
SHA256:QwyMWfkx9XuCuYM4gL0kEXcsVfng91WTDJJcvv81wok
enp1s0           UP             192.168.122.94/24 metric 100 fe80::5054:ff:fede:d811/64 
ana@web2:~$ hostname; cat /etc/machine-id; ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub | cut -d" " -f2; ip -br addr show enp1s0
web2
cad521dab6f54a3c8e19814358bd185d
SHA256:rToOEEK6436+h6osMISaGDGNlNgkHVT5FkX2Q+BIcvE
enp1s0           UP             192.168.122.87/24 metric 100 fe80::5054:ff:fec6:50d0/64 
```

Cada um tem **o próprio nome**, `web1` e `web2`, do próprio disco do cloud-init. Cada um tem **o
próprio machine-id**, `497efb056e9e47e2ad5e043f60c0197e` e `cad521dab6f54a3c8e19814358bd185d`, e nenhum é o antigo `f2b0a97d568b4cd0bb0179512eaab5f9` do modelo. Cada um tem **a
própria chave de host**, e **o próprio endereço**, `192.168.122.94` e `192.168.122.87`, porque a configuração de rede
foi escrita de novo para cada placa. Dois convidados de um modelo, e nada que deveria ser único é
dividido.

É assim que todo laboratório do resto deste curso é feito, e como a maioria das nuvens faz máquinas: uma
imagem selada, uma camada fina por máquina, e um disco pequeno de configurações lido no primeiro boot. O
`lab.sh vm` faz exatamente isso desde a aula 1, com a própria imagem de nuvem do Ubuntu como modelo.
