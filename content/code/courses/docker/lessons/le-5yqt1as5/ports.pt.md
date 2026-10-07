---
title: Publicando portas
version: 1
---

**Um container tem uma rede própria, então um programa escutando dentro dele escuta nessa rede, e não
na da máquina.** O `shelf` escuta na porta 8080, e do shell da Ana não há nada lá:

```
ana@vm:~$ docker run -d --name web shelf:1.0.0
c68c142ea23857936cfd9a03caef47b213c7f133ed577deeea2be5d589bf8b75
ana@vm:~$ curl -sS localhost:8080/version
curl: (7) Failed to connect to localhost port 8080 after 0 ms: Couldn't connect to server
ana@vm:~$ docker port web
```

O `docker port` não imprimiu nada porque nada foi publicado. A aula 4 mostrou o namespace de rede que
faz isso acontecer; a aula 23 abre esse assunto de verdade. Aqui a pergunta é mais estreita: como uma
requisição de fora entra.

## `-p host:container`

**`-p 8080:8080` pede ao Docker que escute na porta 8080 do host e repasse cada conexão à porta 8080
do container.** O primeiro número é a porta na máquina, o segundo é a porta do próprio programa, e
eles não precisam ser iguais:

```
ana@vm:~$ docker run -d --name web -p 8080:8080 shelf:1.0.0
1dc693414105911a109d2d5113a9833d075161b231b05cd387367bd533df5772
ana@vm:~$ docker port web
8080/tcp -> 0.0.0.0:8080
ana@vm:~$ ss -ltn | grep -E "State|:8080"
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
LISTEN 0      4096         0.0.0.0:8080       0.0.0.0:*          
ana@vm:~$ curl -s localhost:8080/version
1.0.0
```

**Leia o endereço no `ss`: `0.0.0.0:8080`, todos os endereços que a máquina tem.** Isso inclui a placa
de rede, então qualquer um que alcance a máquina da Ana alcança o `shelf`. Num notebook no Wi-Fi do
café, ou num servidor com endereço público, raramente é isso o que se queria.

Há uma armadilha no Ubuntu em particular. **O Docker escreve as próprias regras de firewall para as
portas publicadas, e elas valem antes das do `ufw`**, então uma porta que o `ufw status` lista como
fechada pode estar aberta para o mundo se um container a publicou. A documentação do Docker tem uma
página exatamente sobre isso. Não foi reproduzido no laboratório, que não tem `ufw`; a defesa não
depende disso de um jeito ou de outro.

## Publicando num só endereço

**Ponha um endereço na frente: `-p 127.0.0.1:8080:8080` escuta só no endereço de loopback**, que só
programas da mesma máquina alcançam:

```
ana@vm:~$ docker run -d --name web -p 127.0.0.1:8080:8080 shelf:1.0.0
b9876626746a84d3fbf7f2aee8bd2cb62cd2ece1551adc133bfb588600dd880d
ana@vm:~$ ss -ltn | grep -E "State|:8080"
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
LISTEN 0      4096       127.0.0.1:8080       0.0.0.0:*          
ana@vm:~$ docker run -d --name web2 -p 127.0.0.1:8080:8080 shelf:1.0.0
447da7dba2602833cff15533977f60769db4e7cf6f4b1ac61f026fca0f48a44d
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint web2 (14b39bd52054d41abdb9378217c7b985fd57aed370ad6f420c3cbc132bb2c74e): Bind for 127.0.0.1:8080 failed: port is already allocated

Run 'docker run --help' for more information
ana@vm:~$ docker run -d --name web3 -p 127.0.0.1:8081:8080 shelf:1.0.0
724e0656b59de95735161141b7cacad0df6915cf353cc1208960555282c667b0
ana@vm:~$ curl -s localhost:8081/version
1.0.0
```

O `ss` agora mostra `127.0.0.1:8080`. **Faça disso o padrão para tudo o que não deve ser público**: um
banco de dados, uma página de administração, um serviço para o qual um proxy na mesma máquina
encaminha.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A máquina da Ana com duas entradas: o endereço de loopback 127.0.0.1, alcançável só da própria máquina, e a placa de rede, alcançável de outras máquinas. Dentro, o container web roda o shelf na própria porta 8080, no próprio namespace de rede. Com -p 8080:8080 o Docker escuta em 0.0.0.0:8080, todos os endereços, então tanto o curl da Ana quanto outra máquina da rede chegam ao shelf. Com -p 127.0.0.1:8080:8080 ele escuta só no loopback, então o curl da Ana chega ao shelf e a outra máquina não. Sem -p nenhum, nada no host leva à porta do container.\"><defs><marker id=\"l17publish-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17publish-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"170\" y=\"20\" width=\"530\" height=\"240\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"186\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a máquina da Ana</text><rect x=\"186\" y=\"70\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"261\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">127.0.0.1</text><text x=\"261\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">loopback: esta máquina</text><rect x=\"186\" y=\"170\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"261\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">placa de rede</text><text x=\"261\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">alcançável de fora</text><rect x=\"500\" y=\"100\" width=\"180\" height=\"96\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"590\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">container web</text><text x=\"590\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">shelf :8080</text><text x=\"590\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rede própria</text><rect x=\"20\" y=\"90\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">curl (Ana)</text><rect x=\"20\" y=\"178\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">outra</text><text x=\"80\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">máquina</text><path d=\"M140 110 L186 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17publish-ah-phosphor)\"></path><path d=\"M140 198 L186 198\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17publish-ah-amber)\"></path><path d=\"M336 98 L500 136\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l17publish-ah-phosphor)\"></path><path d=\"M336 198 L500 168\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l17publish-ah-amber)\"></path><text x=\"350\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">com qualquer forma de -p</text><text x=\"350\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">só com -p 8080:8080</text></svg>", "caption": "Publicar com -p abre uma porta no host. O endereço antes das portas diz de que lado da máquina essa porta fica.", "same": ["container web"]}
```

O comando do meio é a outra coisa a saber: **uma porta do host, um container.** O `web2` pediu a porta
que o `web` já tinha e foi recusado, embora o Docker já tivesse criado o container, e é por isso que
ele imprimiu um id antes do erro; o `docker ps -a` o listaria como `Created`. Duas cópias do `shelf`
precisam de duas portas no host, e o `web3` na 8081 funciona, com o `shelf` lá dentro ainda na própria
8080.
