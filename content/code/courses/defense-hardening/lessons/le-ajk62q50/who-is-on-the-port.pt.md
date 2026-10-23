---
title: Quem está do outro lado do cabo
version: 1
---

**Uma porta de rede entrega a rede a qualquer coisa que estiver ligada nela.** Num switch comum, no
instante em que um cabo é conectado, o dispositivo do outro lado pode mandar quadros para todas as
máquinas do segmento, pedir um endereço ao servidor DHCP e começar a conversar. As aulas 1 e 2
endureceram o que cada máquina roda. Esta aula trata da pergunta anterior: que dispositivos deveriam
estar na rede, e como a rede consegue saber.

A imagem errada é a de que a rede fica dentro do prédio e o prédio está trancado, então o que está
ligado pertence a ele. A recepção da Jatobá tem uma tomada de rede atrás de uma cadeira. O notebook
de um visitante, a caixa de diagnóstico de um prestador, um pequeno aparelho esquecido atrás de uma
impressora: nenhum deles precisa de senha para usar essa tomada.
Uma vez no segmento, cada um
alcança o SSH do portal, os compartilhamentos de arquivos e tudo o que a aula 1 achou escutando.

O **controle de acesso à rede** (NAC) leva a decisão para a porta do switch. Antes de encaminhar o
tráfego de um dispositivo, o switch pergunta quem ele é, e só abre a porta para uma resposta que
aceita. Há dois jeitos comuns de perguntar, e a aula monta os dois no `sw`, o switch do laboratório:

| | a pergunta | quanto a resposta prova |
|---|---|---|
| **filtro de MAC** | este endereço de hardware está na minha lista? | que o dispositivo afirma ter esse endereço |
| **802.1X** | este dispositivo consegue provar quem é com uma credencial? | que ele tem uma chave ou uma senha que a rede emitiu |

## O switch do laboratório

O `sw` é uma máquina como as outras, e o namespace de rede dele é o próprio switch: uma bridge
chamada `br0` e uma porta por máquina, com o nome da máquina ligada nela. Um filtro preso à
`port-desk` vê cada quadro que o `desk` envia, antes de a bridge encaminhá-lo para qualquer lugar.
Essa é exatamente a posição da segurança de porta de um switch gerenciável, e é por isso que o
laboratório consegue mostrar os dois métodos de verdade.

Suba o laboratório com `sudo bash hostlab.sh up desk web` e abra dois shells: um no `sw` e um no
`desk`, os dois com `sudo bash hostlab.sh sh`. Todo arquivo que a aula escreve fica num diretório
`nac` no seu home em cada máquina.

Duas coisas desta aula não estão no laboratório. Um switch de verdade implementa os dois métodos no
firmware e é configurado pela interface própria, que muda de fabricante para fabricante.
O laboratório os faz com as mesmas ferramentas Linux sobre as quais o firmware de um switch muitas
vezes é construído, o `nftables` para o filtro da porta e o `hostapd` para o 802.1X. E o laboratório
não tem servidor RADIUS: o `hostapd` confere as credenciais ele mesmo, onde uma rede de verdade as
manda para um servidor central. A última seção diz o que muda, e nenhuma das partes de fabricante ou
de RADIUS foi executada para este curso.
