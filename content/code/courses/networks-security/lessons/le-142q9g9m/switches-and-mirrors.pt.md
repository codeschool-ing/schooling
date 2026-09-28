---
title: Switches, portas espelho e por que o laboratório inunda
version: 1
---

O sensor viu tráfego entre `remote` e `www`, duas outras máquinas. Numa rede moderna isso não deveria
acontecer sozinho: um **switch** aprende qual endereço MAC fica atrás de qual porta e manda cada
quadro só para a porta a que ele se destina. Uma máquina ligada a um switch normalmente ouve o
próprio tráfego, os broadcasts e mais nada.

Quem defende e quer que um sensor veja um segmento pede uma cópia ao switch. Uma **porta espelho**
(mirror port), chamada de SPAN nos equipamentos Cisco, recebe uma cópia de cada quadro que atravessa
as portas ou VLANs escolhidas. A outra opção é um **tap de rede** (network tap), um pequeno
dispositivo em linha num cabo que copia os dois sentidos para uma porta de monitoramento e não pode
ser reconfigurado pela rede.

O laboratório não tem nenhum dos dois, então trapaceia de um jeito que vale dizer em voz alta: a
ponte que faz o papel do switch da DMZ é instruída a esquecer onde está cada endereço, e inunda cada
quadro para todas as portas, como os hubs que os switches substituíram. É por isso que o sensor
consegue ouvir. **Numa rede real, uma máquina ouvindo tráfego que não é endereçado a ela significa
uma de três coisas**:

| causa | quem arranjou |
|---|---|
| uma porta espelho ou um tap | os administradores da rede, para um sensor |
| um switch cuja tabela de endereços foi estourada, e por isso inunda como um hub | um atacante, ou uma falha |
| uma máquina que convenceu as outras a mandar o tráfego para ela, mentindo no ARP | um atacante, próxima seção |

A segunda tem uma defesa direta no switch. O **port security** limita quantos endereços MAC uma porta
pode aprender, e desliga a porta ou descarta o excedente quando uma máquina atrás dela apresenta
mais. Uma porta de mesa tem um computador, às vezes um telefone também; uma porta que de repente
apresenta centenas de endereços não é uma mesa.
