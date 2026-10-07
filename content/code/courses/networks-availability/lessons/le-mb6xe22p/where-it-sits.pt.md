---
title: O que um balanceador lê antes de escolher
version: 1
---

Muita gente imagina um balanceador de carga como um switch que espalha pacotes entre os servidores. **Ele
não espalha pacotes; ele escolhe um servidor uma vez por conexão ou uma vez por requisição**, e tudo o que
envia depois segue essa escolha. Os dois tipos diferem no que leem antes de escolher, e cada um leva o
nome da camada em que para.

**Um balanceador de camada 4 lê endereços e portas e mais nada.** Uma conexão TCP chega para o endereço
do serviço na porta 80 ou 443. O balanceador escolhe um servidor e encaminha os pacotes dessa conexão para
ele, reescrevendo um endereço no caminho, mais ou menos como o NAT faz. Ele nunca olha dentro do fluxo,
então não distingue `GET /` de `GET /slow.txt`, e pode repassar TLS sem ter certificado nenhum. É barato e
rápido, e só tem a conexão para decidir.

**Um balanceador de camada 7 é um proxy que fala o protocolo da aplicação.** Ele mesmo aceita a conexão do
cliente, lê a requisição HTTP e abre uma segunda conexão, dele, até o servidor que escolher. Como lê cada
requisição, pode escolher pelo caminho, pelo cabeçalho `Host` ou por um cookie, e pode acrescentar um
cookie próprio à resposta, do que depende a última seção desta aula. O preço é trabalho: ele interpreta
cada requisição e, para HTTPS, precisa ter o certificado e decifrar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 296\" role=\"img\" aria-label=\"Dois jeitos de um balanceador ficar entre o laptop, visto como 203.0.113.2, e web2. Na camada 4 há uma conexão TCP só, do laptop por lb1 em 192.0.2.80 porta 80 até web2, e lb1 lê só endereços e portas. Na camada 7 há duas conexões, do laptop até lb1 e de lb1 até web2, e lb1 lê a requisição inteira no meio: GET /slow.txt, o cabeçalho Host www.example.com e o cookie SERVERID=w3.\"><defs><marker id=\"l19-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">camada 4: uma conexão, repassada</text><rect x=\"20\" y=\"34\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"80.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"300\" y=\"34\" width=\"160\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lb1</text><text x=\"380.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.80:80</text><rect x=\"620\" y=\"34\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"680.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web2</text><text x=\"680.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.22:80</text><path d=\"M140 57 L298 57\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l19-ah)\"></path><path d=\"M460 57 L618 57\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l19-ah)\"></path><text x=\"380\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lê: endereços e portas</text><text x=\"220\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">uma conexão TCP</text><text x=\"540\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">a mesma conexão</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">camada 7: duas conexões, com a requisição lida no meio</text><rect x=\"20\" y=\"154\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"80.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"300\" y=\"154\" width=\"160\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lb1</text><text x=\"380.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.80:80</text><rect x=\"620\" y=\"154\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"680.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web2</text><text x=\"680.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.22:80</text><path d=\"M140 177 L298 177\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l19-ah)\"></path><path d=\"M460 177 L618 177\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l19-ah)\"></path><text x=\"220\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">conexão 1</text><text x=\"540\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">conexão 2</text><text x=\"380\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lê: a requisição inteira</text><rect x=\"250\" y=\"230\" width=\"260\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"262\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET /slow.txt HTTP/1.1</text><text x=\"262\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Host: www.example.com</text><text x=\"262\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Cookie: SERVERID=w3</text></svg>", "caption": "Com o que cada tipo de balanceador conta para decidir. Tudo nesta aula depois do round robin, o arquivo lento, o cookie, precisa do tipo de camada 7."}
```

O servidor atrás de um balanceador de camada 7 vê uma conexão vinda do balanceador, não do cliente. O
endereço do próprio cliente, se o servidor precisar dele, viaja num cabeçalho que o proxy acrescenta, por
convenção `X-Forwarded-For`; nada no laboratório desta aula o lê, então ele fica só citado aqui, não
mostrado.

## O balanceador

No datacenter, `www.example.com` resolve para `192.0.2.80`, e esse endereço fica em `lb1`, posto lá à mão
para esta aula, `sudo ip addr add 192.0.2.80/24 dev eth0` em `lb1`; a aula 16 é onde dois balanceadores o dividem. `lb1` roda o **HAProxy**, o balanceador de
código aberto que a maioria das equipes Linux conhece primeiro, como proxy de camada 7 em `mode http`, a
configuração da aula 16. Atrás dele há três servidores `nginx`, `web1`, `web2` e `web3`, cada um
respondendo a uma requisição de `/` com uma linha com o próprio nome, então cada escolha do balanceador
aparece impressa na tela do laptop.

O que muda de uma seção para a outra é um bloco da configuração do HAProxy, o `backend`: a lista de
servidores e a regra para escolher entre eles. O resto do `/etc/haproxy/haproxy.cfg` de `lb1` fica como
está aqui:

```schooling-example
{"language": "conf", "file": "haproxy.cfg", "parts": [{"code": "global\n    log stdout format raw local0\n    stats socket /run/haproxy.sock mode 600 level admin", "note": "Como na aula 16: o log vai para a saída padrão, que o comando de início abaixo manda para `/run/haproxy.log`, e o socket de controle é onde a seção sobre menos conexões lê as estatísticas."}, {"code": "defaults\n    mode http\n    log global\n    option httplog\n    timeout connect 2s\n    timeout client 30s\n    timeout server 30s", "note": "Um proxy de camada 7. Os tempos limite de cliente e de servidor são de 30 segundos aqui, mais longos que os dez da aula 16, o que dá folga para os downloads lentos desta aula."}, {"code": "frontend www\n    bind 192.0.2.80:80\n    default_backend web", "note": "Um endereço público, e toda requisição a ele vai para o backend chamado `web`, o bloco que cada seção troca."}]}
```

Cada seção imprime o seu `backend` com `sed` antes de usá-lo: escreva esse bloco no fim do arquivo, no
lugar do bloco da seção anterior. O HAProxy só lê o arquivo quando começa, então depois de cada mudança
pare-o, na máquina virtual, com `sudo bash netlab.sh kill lb1 haproxy`, e inicie-o de novo em `lb1`. Na
primeira vez, só o segundo comando:

```sh
sudo sh -c 'setsid haproxy -db -f /etc/haproxy/haproxy.cfg >> /run/haproxy.log 2>&1 &'
```
