---
title: Um modelo, e dados que cabem nele
version: 1
---

As aulas 3 e 4 viviam encontrando nomes que vinham de algum lugar: `ietf-interfaces`, `ietf-ip`,
`openconfig-interfaces`. Cada um é um **módulo YANG**, um arquivo que descreve como é uma parte da
configuração e do estado: quais itens existem, como se aninham, que tipo tem cada valor e quais
valores são permitidos. **O módulo é o schema; a configuração de um equipamento são dados que
cabem nele.** Um modelo YANG diz que existe uma lista de interfaces com chave pelo nome e que cada
uma tem uma descrição; a configuração do `nc1` diz que existe uma interface chamada `eth1` cuja
descrição é `uplink to core1`.

O YANG, RFC 7950, foi escrito para o NETCONF, e ficou maior que ele. O mesmo modelo descreve os
dados qualquer que seja o protocolo que os transporta, e é por isso que a aula 3 pôde escrever a
descrição da `eth2` por RESTCONF e lê-la de volta por NETCONF sem que um soubesse do outro:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Um modelo YANG, ietf-interfaces, e a mesma folha, a descrição do eth1, como três protocolos a carregam. O NETCONF a escreve como elementos XML no namespace do modelo. O RESTCONF a escreve como JSON com o nome do módulo como prefixo, e põe o caminho na URL. O gNMI a nomeia com um caminho de elementos e chaves.\"><defs><marker id=\"om-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"250\" y=\"16\" width=\"220\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o modelo</text><text x=\"360.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">module ietf-interfaces</text><text x=\"360.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">container interfaces</text><text x=\"360.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">list interface [name]</text><text x=\"360.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">leaf description</text><rect x=\"6\" y=\"180\" width=\"228\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NETCONF</text><text x=\"120.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;interfaces xmlns=&quot;…ietf-interfaces&quot;&gt;</text><text x=\"120.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;interface&gt;&lt;name&gt;eth1&lt;/name&gt;</text><text x=\"120.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;description&gt;uplink…&lt;/description&gt;</text><path d=\"M360 114 L120 176\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#om-ah)\"></path><rect x=\"246\" y=\"180\" width=\"228\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">RESTCONF</text><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">…/ietf-interfaces:interfaces/</text><text x=\"360.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">interface=eth1/description</text><text x=\"360.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">{&quot;ietf-interfaces:description&quot;: …}</text><path d=\"M360 114 L360 176\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#om-ah)\"></path><rect x=\"486\" y=\"180\" width=\"228\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">gNMI</text><text x=\"600.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/interfaces/</text><text x=\"600.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">interface[name=eth1]/</text><text x=\"600.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">description</text><path d=\"M360 114 L600 176\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#om-ah)\"></path><text x=\"360\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o protocolo muda a grafia, não o dado</text></svg>", "caption": "O modelo é escrito uma vez. Cada protocolo tira dele os seus nomes.", "same": ["NETCONF", "RESTCONF", "gNMI"]}
```

Esse é o valor prático para a automação. **Tudo o que um programa precisa saber sobre os dados de
um equipamento está no modelo**: os nomes que ele pode usar num caminho, o tipo de cada valor, os
valores que o equipamento vai recusar. Um script que lê o modelo pode conferir os próprios dados
antes de enviá-los, e uma ferramenta pode gerar a partir dele o cliente, a documentação ou o CLI.
O Clixon, o software por trás do `nc1`, consegue gerar um CLI a partir dos seus modelos, e o modo
interativo do `gnmic` completa caminhos a partir deles.

Os próprios modelos vêm de três tipos de publicador, e um engenheiro de redes encontra os três:

| publicador | exemplos | escrito para |
|---|---|---|
| órgãos de padronização | `ietf-interfaces`, `ietf-ip`, `ietf-routing` | todo fabricante, acordado devagar |
| grupos de operadores | `openconfig-interfaces`, `openconfig-bgp` | o que grandes operadoras precisam, versionado rápido |
| cada fabricante | o `frr-interface` do FRR, e os próprios de cada fabricante | tudo o que aquele equipamento sabe fazer |

Os módulos do IETF usados nesta aula são os que o `pyang` instala junto de si, 69 deles:

```
ana@ctl:~$ ls ietf | head -8; ls ietf | wc -l
ietf-access-control-list.yang
ietf-acldns.yang
ietf-alarms-x733.yang
ietf-alarms.yang
ietf-datastores.yang
ietf-dslite.yang
ietf-ethertypes.yang
ietf-hardware-state.yang
69
```
