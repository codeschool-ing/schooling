---
title: Defesas que moram no switch e no host
version: 1
---

A detecção diz que algo aconteceu. Várias defesas fazem o ARP spoofing falhar de vez, e a maioria
delas mora no switch, que é o único dispositivo que sabe em qual porta cada máquina está de verdade.

| defesa | onde | o que faz |
|---|---|---|
| **DHCP snooping** | switch | registra qual endereço o servidor DHCP deu a qual MAC em qual porta, e recusa respostas DHCP vindas de portas que não são a do servidor |
| **inspeção dinâmica de ARP** | switch | confere cada resposta ARP contra a tabela do DHCP snooping, e descarta uma resposta que reivindica um endereço que a porta dela nunca recebeu |
| **port security** | switch | limita os endereços MAC que uma porta pode apresentar |
| **802.1X** | switch e host | a porta fica fechada até a máquina se autenticar (aula 22) |
| **entradas de vizinho estáticas** | host | um host crítico mantém um MAC fixo para o seu gateway e ignora ARP sobre ele |

A inspeção dinâmica de ARP (dynamic ARP inspection) é a resposta direta: uma mentira sobre o endereço
do gateway chega por uma porta que nunca recebeu o endereço do gateway, e o switch a descarta antes
que qualquer máquina a ouça.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Um switch com inspeção dinâmica de ARP. A tabela de snooping diz que o endereço do gateway, 192.168.10.1, foi aprendido na porta 1, e que 192.168.10.20 foi dado à porta 3. Uma resposta ARP chegando pela porta 1 alegando 192.168.10.1 casa com a tabela e é encaminhada. Uma resposta ARP chegando pela porta 5 alegando 192.168.10.1 não casa e é descartada, e nenhuma máquina do segmento a ouve.\"><defs><marker id=\"da-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"da-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"230\" y=\"20\" width=\"260\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"245\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">switch: tabela de snooping</text><text x=\"245\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">port 1  192.168.10.1</text><text x=\"245\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">port 3  192.168.10.20</text><text x=\"245\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">port 4  192.168.10.21</text><rect x=\"20\" y=\"40\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw</text><text x=\"30\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">porta 1, o gateway</text><rect x=\"20\" y=\"160\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">uma máquina</text><text x=\"30\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">porta 5</text><rect x=\"550\" y=\"90\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"560\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">porta 3</text><path d=\"M170 63 L230 63\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#da-ah-phosphor)\"></path><text x=\"174\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">is-at .1</text><path d=\"M490 80 L550 105\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#da-ah-phosphor)\"></path><text x=\"496\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">encaminhada</text><path d=\"M170 183 L250 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#da-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"180\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">&quot;192.168.10.1 está na minha MAC&quot;: descartada na porta</text></svg>", "caption": "O switch sabe a que porta cada endereço pertence, então uma alegação vinda da porta errada nunca chega a ninguém.", "same": ["is-at .1"]}
```
Ela precisa
do DHCP snooping para saber a verdade, e precisa de entradas estáticas para tudo o que foi configurado
à mão, como o próprio gateway.

## Uma entrada fixa no host

Quando o switch não pode ajudar, um host pode se recusar a aprender. No `laptop`, o MAC do gateway
escrito à mão como uma entrada permanente:

```
root@laptop:~# ip neigh replace 192.168.10.1 lladdr 52:54:00:a8:0a:01 dev eth0 nud permanent; ip neigh show 192.168.10.1
192.168.10.1 dev eth0 lladdr 52:54:00:a8:0a:01 PERMANENT 
```

Entradas `PERMANENT` não são substituídas por respostas ARP. O `laptop` continua funcionando
normalmente:

```
ana@laptop:~$ curl -s https://www.example.com/
orders service: ok
```

O custo é a manutenção: troque a placa de rede do gateway, ou passe para um segundo firewall com
outro MAC, e todo host com a entrada antiga perde a saída. É razoável para um punhado de servidores
críticos falando com um gateway e impraticável num escritório inteiro, e é por isso que os recursos
do switch existem.

**A defesa que funciona quando todo o resto falha continua sendo a criptografia.** Um host que manda
tudo sobre TLS ou SSH, verificando certificados e chaves de host, entrega a uma máquina no meio só
metadados. Os recursos do switch tornam o ataque difícil; a criptografia o torna inútil.
