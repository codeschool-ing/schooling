---
title: Qual para qual trabalho
version: 1
---

Os dois não são rivais, e a maioria dos sistemas de verdade usa os dois. O que decide é o que o trabalho
precisa:

| o trabalho precisa de | use |
|---|---|
| outro sistema operacional, ou Windows num host Linux | uma máquina virtual |
| praticar instalação, boot, discos, kernels | uma máquina virtual |
| rodar algo em que você não confia | uma máquina virtual |
| uma máquina inteira para administrar, como nesta trilha | uma máquina virtual |
| empacotar uma aplicação com tudo de que ela precisa | um contêiner |
| muitas cópias de um serviço que ligam e desligam rápido | um contêiner |
| as mesmas ferramentas no computador de todo desenvolvedor | um contêiner |

E as camadas se empilham. Nuvens alugam máquinas virtuais, e a maior parte do que roda nelas roda em
contêineres. O computador em que este curso foi gravado é um exemplo das duas coisas ao mesmo tempo:

```
ana@host:~$ systemd-detect-virt --container; systemd-detect-virt --vm
systemd-nspawn
kvm
```

O host do curso é **um contêiner**, feito com `systemd-nspawn`, **dentro de uma máquina virtual** rodando
sob KVM num data center, e as máquinas virtuais deste curso rodam dentro disso. Cada camada responde a uma
pergunta diferente: a máquina virtual do data center dá um computador inteiro para alugar, o contêiner
mantém o laboratório separado das ferramentas que o gravam, e os convidados do laboratório são os
computadores de que este curso trata.
