---
title: Quem registrou o domínio, e quando
version: 1
---

**Todo nome de domínio tem um registro**: quando foi criado, por qual registrador e, cada vez menos, por
quem. Para um link numa mensagem suspeita, a linha mais útil desse registro é a **data de criação**. Um
domínio registrado semana passada e já mandando boletos aos clientes da Jatobá é a forma dos domínios
parecidos que a aula 14 bloqueou.

## WHOIS e RDAP

O protocolo antigo para perguntar é o **WHOIS**, texto simples na porta 43, com um formato diferente
para cada registro. O substituto é o **RDAP**, o Registration Data Access Protocol, que responde às
mesmas perguntas por HTTPS em JSON estruturado, para que um script leia as datas sem adivinhar um
layout. A ICANN passou a exigir RDAP dos registros e registradores que credencia, e a maioria dos
clientes hoje o prefere.

Nenhum dos dois foi acessado neste curso: o laboratório não tem internet, e o cliente `whois` não está
entre os pacotes do laboratório. Estas são as formas documentadas, mostradas para você rodar num
computador que tenha as duas coisas. Elas não foram executadas aqui, e nenhuma saída é mostrada:

```sh
whois example.com
curl -s https://rdap.org/domain/example.com
```

O `rdap.org` é um serviço público que manda cada consulta ao registro responsável pelo domínio. No JSON
que volta, a lista `events` traz as datas de `registration` e `expiration`, e `entities` traz o
registrador.

## Lendo o registro

| o que você vê | o que sugere |
|---|---|
| criado nas últimas semanas | domínios novos são baratos e descartáveis, e é por isso que o phishing os usa; muitos feeds de reputação da aula 14 os listam por isso |
| um nome a uma letra de distância do próprio escritório, ou de um cliente | um domínio parecido, seja qual for a idade |
| o titular escondido | comum desde as leis de proteção de dados, o GDPR e a LGPD entre elas; não é sinal sozinho |
| expiração em menos de um ano | comum para um domínio que ninguém pretende manter |

**Nenhuma linha sozinha condena um domínio.** Um domínio novo pode ser de uma empresa nova e honesta, e
um antigo pode ser tomado. A idade, a semelhança com um nome em que você confia e o que o urlscan viu a
página fazer, lidos juntos, são a evidência, e a decisão que eles sustentam é a da aula 14: se o nome
entra na lista.

## O que esta aula acrescenta às outras

Cada ferramenta desta aula transforma uma coisa suspeita em **indicadores**: um hash, um domínio, um
endereço, uma técnica. São eles que os controles das aulas anteriores consomem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l19-indicators\" aria-label=\"Um arquivo suspeito à esquerda vira quatro tipos de indicador no meio: um hash, um domínio, um endereço e uma técnica. Cada um vai para um controle de uma aula anterior à direita: o hash para as assinaturas de antivírus da aula 7 e a caça da aula 8, o domínio para a lista de bloqueio do resolvedor da aula 14, o endereço para as regras de firewall da aula 10, a técnica para as regras de detecção da aula 8.\"><defs><marker id=\"l19-indicators-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l19-indicators-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"100.0\" width=\"140.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um arquivo</text><text x=\"90.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fatura-outubro.pdf</text><rect x=\"260.0\" y=\"30.0\" width=\"120.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"320.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">hash</text><path d=\"M160.0 125.0 L260.0 48.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-paper-dim)\"></path><path d=\"M380.0 48.0 L440.0 48.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-phosphor)\"></path><text x=\"448.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">assinaturas, aula 7; caça, aula 8</text><rect x=\"260.0\" y=\"85.0\" width=\"120.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"320.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">domínio</text><path d=\"M160.0 125.0 L260.0 103.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-paper-dim)\"></path><path d=\"M380.0 103.0 L440.0 103.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-phosphor)\"></path><text x=\"448.0\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lista do resolvedor, aula 14</text><rect x=\"260.0\" y=\"140.0\" width=\"120.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"320.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">endereço</text><path d=\"M160.0 125.0 L260.0 158.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-paper-dim)\"></path><path d=\"M380.0 158.0 L440.0 158.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-phosphor)\"></path><text x=\"448.0\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">regras de saída, aula 10</text><rect x=\"260.0\" y=\"195.0\" width=\"120.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"320.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">técnica</text><path d=\"M160.0 125.0 L260.0 213.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-paper-dim)\"></path><path d=\"M380.0 213.0 L440.0 213.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-phosphor)\"></path><text x=\"448.0\" y=\"213.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">regras de detecção, aula 8</text></svg>", "caption": "A análise vale o que ela alimenta nos controles.", "same": ["fatura-outubro.pdf", "hash"]}
```

A habilidade está menos em usar os serviços do que em usá-los na ordem certa, manter os dados do
escritório fora deles e anotar o que disseram e quando.
