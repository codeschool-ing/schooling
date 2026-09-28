---
title: HSRP e GLBP, as versões da Cisco
version: 1
---

O VRRP foi padronizado depois que a Cisco já tinha lançado a própria resposta ao mesmo problema, o
**HSRP**, Hot Standby Router Protocol, e muitas redes ainda o usam. Nada disso foi executado aqui: o
laboratório é Linux, e HSRP e GLBP só existem em equipamento Cisco. As ideias são as que esta aula mediu,
e as diferenças estão nos detalhes que pegam quando dois fabricantes se encontram ou quando alguém passa de
um para o outro.

| | VRRP | HSRP | GLBP |
|---|---|---|---|
| de quem | padrão da IETF, RFC 3768 e 5798 | Cisco, descrito na RFC 2281 | Cisco |
| os papéis | master e backups | active e standby | um gateway que responde ARP, até quatro que encaminham |
| heartbeat, por padrão | a cada 1 s | hello a cada 3 s, morto depois de 10 s | hello a cada 3 s, morto depois de 10 s |
| MAC virtual | `00-00-5E-00-01-` e o VRID | `0000.0c07.acXX`, o grupo em hexadecimal (versão 1) | um por roteador que encaminha |
| pegar de volta depois de voltar | ligado por padrão | desligado por padrão | desligado por padrão para o gateway que responde ARP |
| divide a carga | não, um master por grupo | não, um active por grupo | sim, dentro de um grupo |

Três linhas merecem uma frase cada.

**Os timers.** Os padrões do HSRP, um hello a cada três segundos e dez segundos antes de o standby agir,
dão um buraco em torno de dez segundos, onde os padrões do VRRP deram 3,264 nesta aula. Os dois podem ser
baixados, o HSRP até milissegundos, e a aula 14 disse quanto custa baixá-los. Os padrões são o que uma rede
recebe quando ninguém pensou no assunto, e é por isso que vale conhecê-los.

**Preempção.** No HSRP um roteador que volta não assume a menos que esteja configurado com `preempt`. Quem
aprendeu VRRP espera que ele assuma, quem aprendeu HSRP espera que não, e uma equipe misturada descobre
durante uma queda qual suposição a configuração fez. A regra de tracking do fim da seção anterior é onde
isso mais importa.

**O MAC virtual.** O HSRP sempre usa o MAC virtual, então um failover não muda entrada ARP nenhuma, o
comportamento que o padrão do VRRP pede e que o modo padrão do keepalived pula. Também é uma impressão
digital útil: `0000.0c07.ac0a` na tabela ARP de um host quer dizer que o gateway é o grupo HSRP 10.

## Usando os dois roteadores ao mesmo tempo

VRRP e HSRP deixam o backup parado. Ele está aquecido, está pronto, e não encaminha nada, o que é bom para
resiliência e um desperdício para um par de roteadores caros. A resposta clássica são **dois grupos**: o
grupo 1 com `hq` como master do `.1`, o grupo 2 com `hq2` como master do `.4`, e metade dos hosts recebendo
do DHCP o `.1` e metade o `.4`. Cada roteador é backup do endereço do outro. Funciona, e dobra a
configuração e divide os hosts à mão.

O **GLBP**, Gateway Load Balancing Protocol, faz a divisão sozinho. Um roteador, o gateway virtual ativo,
responde a todo pedido ARP para o único endereço virtual, e responde a hosts diferentes com MACs virtuais
diferentes, cada um pertencente a um de até quatro roteadores que encaminham. Todo host tem o mesmo
endereço de gateway e, sem saber, metade manda para um roteador e metade para o outro. Se um dos que
encaminham morre, outro assume o MAC dele.

Dois grupos com um master em cada é o formato que a aula 16 usa para balanceadores, onde se chama
ativo-ativo, e vem com uma regra que vale igualmente para roteadores: **cada um dos dois precisa dar conta
de tudo sozinho**, senão no dia em que um falhar o outro fica sobrecarregado em vez de redundante.
