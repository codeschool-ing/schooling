---
title: Nessus, OpenVAS e Qualys, pela documentação
version: 1
---

Os três nomes que aparecem sempre que alguém diz "scan de vulnerabilidades" são três produtos da
primeira família. Fazem o mesmo trabalho e diferem principalmente em quem opera a maquinaria e em
como ela é paga. **Esta seção os descreve pela documentação dos fornecedores; nenhum deles foi executado para este curso.** Os detalhes que mais mudam, preços e limites das edições gratuitas,
são os que você confere na página do próprio fornecedor antes de planejar em cima deles.

### Nessus

O Nessus é o scanner da Tenable. Ele é instalado numa máquina que você controla, e as checagens, que
a Tenable chama de plugins, chegam por um feed que a Tenable atualiza continuamente. Um scanner roda
scans sem autenticação e com credenciais, e os Nessus Agents coletam dos hosts onde há um agente
instalado.

As edições diferem em escala. O **Nessus Essentials** é gratuito e limitado a um número pequeno de
endereços IP; o limite mudou ao longo dos anos, então leia a página da Tenable para saber o de hoje.
O **Nessus Professional** é uma licença paga por scanner, a escolha comum de um consultor ou de um
time de segurança pequeno. Uma organização com milhares de hosts usa as plataformas de gestão da
Tenable (o Tenable Vulnerability Management, na nuvem da Tenable, ou o Tenable Security Center, nos
próprios servidores), com vários scanners e agentes reportando a um lugar só.

### OpenVAS e Greenbone

O OpenVAS é um scanner de código aberto, desenvolvido pela Greenbone. A **Greenbone Community
Edition** o empacota com o serviço de gestão e uma interface web, o Greenbone Security Assistant, e é
gratuita; a Greenbone documenta como rodá-la como um conjunto de containers. As checagens vêm do
Greenbone Community Feed. A oferta comercial da Greenbone acrescenta um feed enterprise com cobertura
maior, appliances e suporte.

É o único dos três que um aluno consegue rodar em casa sem registrar nada, o que o torna o primeiro
contato habitual com um scanner de rede. É também o mais pesado de operar: o feed precisa ser
sincronizado antes do primeiro scan, e os containers pedem memória e disco que um laptop pequeno, já
rodando um cluster, talvez não tenha sobrando.

### Qualys

A Qualys é uma plataforma em nuvem, vendida por assinatura; o produto de vulnerabilidades se chama
VMDR. A maquinaria de scan vem em três formas: scanners da própria Qualys na internet, para o que fica
exposto à internet; scanner appliances, virtuais ou físicos, colocados dentro da sua rede; e o Qualys
Cloud Agent nos hosts. **Os resultados, a agenda e os relatórios ficam na nuvem da Qualys**, não numa
máquina sua, o que é todo o atrativo para algumas organizações e toda a objeção para outras.

| | Nessus | OpenVAS / Greenbone | Qualys |
|---|---|---|---|
| quem opera o motor | você, na sua máquina | você, na sua máquina | a Qualys, e appliances que você coloca |
| como lê um host | rede, credenciais, Nessus Agents | rede e credenciais | rede, credenciais, Cloud Agent |
| opção gratuita | Nessus Essentials, poucos endereços IP | a Community Edition | confira a página da própria Qualys |
| pago | Professional, e as plataformas da Tenable | feed enterprise, appliances | assinatura |
| onde ficam os resultados | o scanner, ou a plataforma da Tenable | o seu servidor | a nuvem da Qualys |

### Escaneie só o que é seu, ou o que você foi autorizado por escrito a escanear

**Um scan é tráfego que o lado que recebe não consegue distinguir do primeiro passo de um ataque.**
Uma varredura de portas parece igual seja quem for que a envie, e uma checagem com credenciais é um
login. Alguns dispositivos, como impressoras antigas e controladores industriais, caem quando são
sondados. Então a regra não é formalidade:

- **Escaneie o que é seu**: a sua máquina, os seus containers em `127.0.0.1`, uma rede que você
  administra. Tudo o que o linkbox faz neste curso fica na sua própria máquina por esse motivo.
- **Qualquer outra coisa exige autorização por escrito** de quem é dono, com os endereços no escopo, a
  janela de datas e horários, o tipo de scan e uma pessoa que possa ser chamada para pará-lo. "O
  cliente disse que tudo bem" numa reunião não é autorização; um escopo assinado é.
- **Uma conta de nuvem tem um senhorio.** Cada provedor publica uma política sobre o que os clientes
  podem testar nas próprias contas, e o que não podem, como inundar um serviço compartilhado. Leia
  antes de escanear as suas próprias instâncias lá.
- **O sistema de outra pessoa não é seu para escanear**, por mais público que seja e por mais inofensivo
  que o scan pareça. Isso inclui o serviço que você usa todo dia e o endereço que você achou num log.

O mesmo vale para o scan ativo da aula 4: ele envia requisições feitas para provocar erros, e só cabe
contra o seu próprio staging, nunca contra produção e nunca contra o de outra pessoa.
