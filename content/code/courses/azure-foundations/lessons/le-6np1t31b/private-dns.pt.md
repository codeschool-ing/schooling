---
title: O nome continua o mesmo, e a resposta muda
version: 1
---

**A aplicação não muda uma linha quando chega um private endpoint.** Ela continua abrindo
`stshopprod.blob.core.windows.net`, porque esse é o nome que o certificado da conta carrega e o nome
que todo SDK monta a partir do nome da conta. O que muda é a resposta que o nome recebe, e se ela é a
privada depende de **onde a pergunta é feita**. Esse é o truque inteiro, e a maioria das falhas de
private endpoints são falhas dele.

## Um CNAME no meio

Quando um private endpoint é criado para uma conta, o Azure muda o DNS público dela: o nome deixa de
apontar direto para o endpoint público e passa a apontar para um nome intermediário numa zona chamada
`privatelink.blob.core.windows.net`, e esse aponta para o endpoint público. Dois resolvedores então
percorrem a mesma cadeia e param em lugares diferentes:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l19-dns-split\" aria-label=\"O mesmo nome resolvido de dois lugares. A cadeia começa em stshopprod.blob.core.windows.net, um CNAME para stshopprod.privatelink.blob.core.windows.net. Perguntado da internet, o DNS público responde o nome intermediário com mais um CNAME que termina no endereço público do serviço de storage. Perguntado de dentro da vnet-shop-prod, o resolvedor do Azure em 168.63.129.16 encontra a zona privada ligada privatelink.blob.core.windows.net e responde o nome intermediário com o registro A 10.20.4.4.\"><defs><marker id=\"l19-dns-split-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-dns-split-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l19-dns-split-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"210.0\" y=\"20.0\" width=\"300.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stshopprod.blob.core.windows.net</text><path d=\"M360.0 55.0 L360.0 86.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-dns-split-af-ah-paper-dim)\"></path><text x=\"372.0\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CNAME</text><rect x=\"160.0\" y=\"88.0\" width=\"400.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stshopprod.privatelink.blob.core.windows.net</text><path d=\"M250.0 123.0 L160.0 180.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-dns-split-af-ah-amber)\"></path><rect x=\"20.0\" y=\"182.0\" width=\"280.0\" height=\"96.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">perguntado da internet</text><text x=\"160.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o DNS público responde o elo do meio</text><text x=\"160.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CNAME adiante até o endpoint público</text><text x=\"160.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um endereço público</text><path d=\"M470.0 123.0 L560.0 180.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-dns-split-af-ah-phosphor)\"></path><rect x=\"420.0\" y=\"182.0\" width=\"280.0\" height=\"96.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">perguntado da vnet-shop-prod</text><text x=\"560.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">168.63.129.16 tem uma zona privada ligada</text><text x=\"560.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A  10.20.4.4</text><text x=\"560.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o private endpoint</text></svg>", "caption": "A zona privada assume o elo do meio, não o nome da conta."}
```

- **Da internet**, ninguém tem uma zona chamada `privatelink.blob.core.windows.net`, então o DNS
  público a responde, e a cadeia termina no endereço público. Com o `publicNetworkAccess` desligado, uma
  conexão ali é recusada: o nome resolve e a conta não responde.
- **De dentro da `vnet-shop-prod`**, o resolvedor da rede, o do próprio Azure em `168.63.129.16`,
  descobre que tem uma zona privada exatamente com esse nome ligada à rede. Ele responde o nome
  intermediário a partir da zona, com o registro A que o zone group escreveu: `10.20.4.4`.

Então **a zona privada não assume o nome da conta; ela assume o elo do meio da cadeia**, e é por isso
que a zona do `pe.bicep` se chama `privatelink.blob...` e não `blob...`. Uma zona privada chamada
`blob.core.windows.net` responderia por toda storage account do Azure, e toda conta a que a loja não
deu endpoint pararia de resolver.

## O mesmo padrão, num nome que dá para perguntar

A máquina onde este curso foi gravado resolve nomes por um resolvedor que só responde pelos hosts que
ela tem permissão de alcançar, então a cadeia de uma storage account não pôde ser mostrada aqui; uma
conta inventada não existe, e uma existente não está nessa lista. O serviço de login da Microsoft
está, e a cadeia pública dele tem o mesmo formato:

```
ana@laptop:~/azure/private-link$ dig login.microsoftonline.com +noall +answer +nottlid | grep CNAME
login.microsoftonline.com. IN	CNAME	login.mso.msidentity.com.
login.mso.msidentity.com. IN	CNAME	ak.privatelink.msidentity.com.
ak.privatelink.msidentity.com. IN CNAME	www.tm.a.prd.aadg.akadns.net.
```

O `dig` faz uma pergunta ao DNS e imprime a resposta; `+noall +answer` deixa só a resposta, e
`+nottlid` omite o tempo de vida que resta a cada registro, que muda a cada segundo. Três elos, e o
segundo está numa zona chamada `privatelink.msidentity.com`: **o próprio nome de login da Microsoft
passa por uma zona `privatelink` na internet pública**, para que uma rede com uma zona privada desse
nome possa responder o elo do meio de outro jeito, exatamente como com a storage account. O último elo
entrega o nome a um serviço que espalha os logins por muitos lugares, e não é estável: em duas
execuções feitas enquanto esta lição era escrita ele apontou uma vez para o `trafficmanager.net` do
Azure Traffic Manager e outra para a zona de outro provedor. A lição 22 explica nomes que respondem
diferente de propósito. Espere que o fim da sua cadeia seja diferente deste; o elo `privatelink` no
meio é a parte que importa.

## Quando a resposta privada não chega

Três erros explicam quase todo endpoint que "não funciona", e cada um aparece como o endereço público
voltando para uma máquina que deveria ter recebido `10.20.4.4`:

- **A zona não está ligada à rede que pergunta.** Uma zona só responde às redes com que tem um link de
  rede virtual. Os endpoints da loja são alcançados pela spoke de produção e pelo hub, então a zona
  precisa de um link para cada uma, ou de uma zona no hub pela qual passa o DNS de toda spoke; a lição
  20 desenha esse hub.
- **A rede não usa o resolvedor do Azure.** Uma rede virtual configurada com um servidor de DNS
  próprio, como um controlador de domínio, pergunta a esse servidor em vez de ao `168.63.129.16`, e
  esse servidor não sabe nada de zonas privadas a não ser que encaminhe as zonas `privatelink` para o
  Azure. A lição 21 cobre o Private Resolver que faz isso para redes e escritórios.
- **A pergunta vem do escritório.** Um notebook na VPN da lição 23 pergunta ao DNS do escritório, que
  pergunta à internet, que dá a resposta pública. O DNS do escritório precisa de um **encaminhador
  condicional** para `privatelink.blob.core.windows.net` apontando para um resolvedor dentro do Azure.

Para ver em qual caso você está, pergunte da máquina que falha: um `nslookup` ou um `dig` do nome da
conta ali devolve `10.20.4.4` ou não, e a cadeia que ele imprime diz em qual elo ela saiu do caminho
privado.
