---
title: Pull, push, e com que frequência a verdade é conferida
version: 2
---

A aula 18 configura máquinas a partir do laptop da Ana: o Ansible se conecta por SSH, faz o trabalho
e vai embora, e nada acontece de novo até ela rodar de novo. As três ferramentas desta aula foram
construídas, na maior parte, ao contrário. **Um agente mora em cada máquina, pergunta a um servidor
como aquela máquina deve estar e aplica a resposta, num horário fixo, com ou sem alguém olhando.**

Isso parece um detalhe de transporte, SSH num caso e a conexão de um agente no outro. Decide mais
do que o transporte: quem começa a conversa decide com que frequência a descrição é comparada com a
máquina, e isso decide quanto tempo uma edição feita à mão sobrevive.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois arranjos lado a lado. À esquerda, pull: um servidor guarda a descrição, e um agente em cada uma de três máquinas se conecta a ele no próprio horário, a cada 30 minutos, pergunta como deve estar e aplica a resposta. À direita, push: uma máquina guarda a descrição e se conecta a cada uma das três por SSH, só quando alguém a executa.\"><defs><marker id=\"pp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"pp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"175.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Pull: um agente em cada máquina</text><text x=\"545.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">Push: uma máquina se conecta</text><path d=\"M360 10 L360 290\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"85\" y=\"40\" width=\"180\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o servidor</text><text x=\"175.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">guarda a descrição</text><rect x=\"20\" y=\"190\" width=\"90\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma máquina</text><text x=\"65.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">agente</text><path d=\"M65 188 L120.0 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pp-ah-phosphor)\"></path><rect x=\"130\" y=\"190\" width=\"90\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma máquina</text><text x=\"175.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">agente</text><path d=\"M175 188 L175.0 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pp-ah-phosphor)\"></path><rect x=\"240\" y=\"190\" width=\"90\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma máquina</text><text x=\"285.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">agente</text><path d=\"M285 188 L230.0 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pp-ah-phosphor)\"></path><text x=\"175.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada agente pergunta no próprio horário,</text><text x=\"175.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a cada 30 minutos por padrão</text><rect x=\"455\" y=\"40\" width=\"180\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma máquina</text><text x=\"545.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">guarda a descrição</text><rect x=\"390\" y=\"190\" width=\"90\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma máquina</text><text x=\"435.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem agente</text><path d=\"M490.0 96 L435 188\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pp-ah-amber)\"></path><rect x=\"500\" y=\"190\" width=\"90\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma máquina</text><text x=\"545.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem agente</text><path d=\"M545.0 96 L545 188\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pp-ah-amber)\"></path><rect x=\"610\" y=\"190\" width=\"90\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma máquina</text><text x=\"655.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem agente</text><path d=\"M600.0 96 L655 188\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pp-ah-amber)\"></path><text x=\"545.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por SSH, só quando</text><text x=\"545.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">alguém executa</text></svg>", "caption": "Pull e push. A diferença é qual lado começa a conversa, e com que frequência."}
```

## Pull: o agente pergunta

O Puppet é o caso mais claro. O agente dele, `puppet agent`, roda em cada máquina, se conecta a um
servidor Puppet, envia os fatos que levantou sobre a máquina e recebe de volta a lista completa de
recursos que aquela máquina deve ter.

**Instalando o Puppet.** Esta aula roda o Puppet no seu próprio computador, e o pacote do próprio
Ubuntu é aquele com que as transcrições foram gravadas, a versão 8.4.0:

```sh
sudo apt-get install -y puppet
```

Rodado como usuário comum, como em toda esta aula, o Puppet lê as configurações dele de
`~/.puppet/etc/puppet.conf`. O da Ana tem uma linha sob o cabeçalho, e a transcrição abaixo a
imprime, então crie o diretório com `mkdir -p ~/.puppet/etc` e escreva o arquivo:

```ini
[main]
certname = laptop
```

Os valores padrão dizem como essa conversa é montada:

```
ana@laptop:~$ puppet config print --section agent runinterval server certname
certname = laptop
runinterval = 1800
server = puppet
```

`runinterval` está em segundos: **1800 é uma execução a cada trinta minutos**, em cada máquina,
enquanto o agente estiver rodando. `server = puppet` é onde o agente procura se ninguém disser outra
coisa, um host chamado literalmente `puppet`. `certname` é o nome pelo qual a máquina é conhecida; a
Ana o definiu como `laptop` no `puppet.conf` dela para bater com o prompt, e sem ele o Puppet usa o
nome completo do computador na rede. O nome importa
porque o agente prova quem é com um certificado assinado por uma autoridade
certificadora que, por padrão, o próprio servidor Puppet mantém, então incluir uma máquina num
arranjo de pull significa um certificado novo, além de um agente novo.

O Chef tem o mesmo formato: `chef-client` em cada máquina, um Chef Infra Server guardando os
cookbooks, uma execução num horário fixo. **O Salt fica no meio.** O agente dele, o minion, abre uma
conexão com o master e a mantém aberta, e o master publica comandos por ela; um minion executa na hora
o que recebe. Isso dá ao Salt a rapidez de um push, por uma conexão que a própria máquina abriu. O
Salt também tem o `salt-ssh` para máquinas sem minion nenhum, e o Ansible tem o `ansible-pull` no
sentido contrário, então a linha entre os dois modelos é um padrão, não um muro.

## O que o horário fixo compra, e o que custa

Um agente que roda a cada meia hora é uma máquina que **se põe de volta no lugar**. Alguém edita à mão
o arquivo do nginx às 10:12; na execução seguinte o agente encontra a diferença e escreve o arquivo
como está descrito. Com push, a mesma edição fica até alguém rodar o playbook de novo, o que pode ser
amanhã e pode ser nunca.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas linhas do tempo da mesma manhã. Nas duas, a ferramenta roda às 10:00 e alguém edita um arquivo à mão às 10:12. Na linha de cima, um agente roda de novo às 10:30 e devolve o arquivo, então o drift dura 18 minutos. Na de baixo nada roda de novo, e o drift dura até alguém lembrar de rodar a ferramenta.\"><text x=\"20.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Pull: o agente roda a cada 30 minutos</text><rect x=\"78\" y=\"68\" width=\"44\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">roda</text><rect x=\"328\" y=\"68\" width=\"44\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">roda</text><rect x=\"578\" y=\"68\" width=\"44\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">roda</text><path d=\"M122 80 L200 80\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M200 80 L330 80\" stroke=\"var(--amber)\" stroke-width=\"3\" fill=\"none\"></path><path d=\"M372 80 L578 80\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M622 80 L700 80\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M200 70 L200 90\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"200.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">editado à mão</text><text x=\"265.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">drift até a próxima execução</text><text x=\"20.0\" y=\"136.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Push: roda quando alguém executa</text><rect x=\"78\" y=\"158\" width=\"44\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">roda</text><path d=\"M122 170 L200 170\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M200 170 L700 170\" stroke=\"var(--amber)\" stroke-width=\"3\" fill=\"none\"></path><path d=\"M200 160 L200 180\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"200.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">editado à mão</text><text x=\"510.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">drift até alguém se lembrar</text><text x=\"100.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10:00</text><text x=\"200.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10:12</text><text x=\"350.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10:30</text><text x=\"600.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11:00</text></svg>", "caption": "A mesma edição à mão nos dois arranjos. Um agente a desfaz na próxima execução; uma ferramenta de push, só quando alguém a executa."}
```

Esse é o argumento mais forte a favor de um agente, e ele corta para os dois lados. A edição das
10:12 pode ter sido a correção de uma queda, feita de madrugada por quem estava de plantão. O agente a
desfaz com a mesma confiança com que desfaz um erro, porque não tem como distinguir um do outro. **Um
arranjo de pull só funciona se todo mundo souber que a descrição é o único lugar onde uma mudança
dura**, que é a cura que a aula 1 deu para o drift, imposta duas vezes por hora.

Os custos são os que se espera de um software em cada máquina. O agente precisa ser instalado,
atualizado e mantido rodando; o servidor precisa ser operado, ter backup e ser alcançável por todas
as máquinas; os certificados precisam ser emitidos e revogados. O push não precisa de nada disso, e
paga na hora da execução: a máquina de controle precisa alcançar todos os alvos naquele momento, por
SSH, com uma chave que funcione.

## Sem servidor

As três ferramentas também rodam numa máquina só, sem servidor, lendo a descrição do próprio disco:
`puppet apply`, `salt-call --local` e o modo local do Chef. É assim que esta aula as roda, porque o
seu laboratório é um computador só. Os recursos, a linguagem e a execução são os mesmos; só a pergunta "de onde
vem a descrição" tem outra resposta.
