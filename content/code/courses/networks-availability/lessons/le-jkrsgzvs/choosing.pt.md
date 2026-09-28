---
title: A escolha, e o que vem depois da VPN
version: 1
---

Os dois tipos de VPN se apoiam numa suposição: depois que um pacote passa pelo túnel, ele está na rede,
e o firewall da rede é o que fica entre ele e todo o resto. Uma pessoa com acesso remoto e um login
válido alcança todo endereço que o pool tem permissão de alcançar, e quem estiver com o laptop roubado
dela também.

**O acesso de rede zero trust, ZTNA, abandona essa suposição.** Em vez de pôr o dispositivo na rede, um
intermediário (broker) confere a pessoa e o dispositivo a cada vez que eles abrem uma aplicação, e os
liga só àquela aplicação. Nada mais da rede é alcançável pela sessão, e a aplicação não precisa de porta
aberta para a internet, porque um conector dentro da rede da empresa disca para fora, até o broker. É
outro tipo de produto, e não uma opção de VPN, e nada disso rodou neste laboratório.

**O ZTNA não substitui o site a site.** Um caixa e uma impressora não têm pessoa para conferir. Ele
substitui o acesso remoto a aplicações específicas, e é comum uma empresa manter os dois: túneis entre
os escritórios e acesso por aplicação para as pessoas.

| a situação | a escolha |
|---|---|
| dois escritórios cujos dispositivos todos precisam do outro escritório | site a site |
| uma filial de dispositivos que não rodam cliente: caixas, impressoras, câmeras | site a site |
| funcionários em casa usando muitos sistemas internos, e a empresa precisa ver ou filtrar todo o tráfego deles | acesso remoto, túnel completo, com um resolvedor do lado da empresa |
| os mesmos funcionários, com chamadas de vídeo e um link pequeno na matriz | acesso remoto, túnel dividido, com split DNS |
| um prestador que precisa de uma aplicação web | acesso por aplicação, não um túnel para dentro da rede |
| funcionários cujas redes de casa podem usar os números do escritório | renumerar ou traduzir antes da implantação, não depois do primeiro chamado |

Toda linha deixa uma pergunta em aberto, e é a mesma em cada uma. O túnel tem um roteador em cada ponta,
e neste laboratório há um único link para a internet em cada escritório. O que acontece quando um deles
falha é o assunto das aulas 14 a 16.
