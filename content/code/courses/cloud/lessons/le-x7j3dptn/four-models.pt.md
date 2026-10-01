---
title: Quatro modelos de implantação, uma pergunta cada
version: 1
---

A aula 1 definiu nuvem pelo que ela faz: autosserviço, acesso pela rede, recursos agrupados,
elasticidade e medição. Nenhuma dessas cinco diz **onde o hardware fica nem quem mais o usa**. O
mesmo documento da NIST, a SP 800-145, responde isso à parte, com quatro *modelos de implantação*:
pública, privada, comunitária e híbrida.

A imagem comum é que as palavras descrevem um lugar. Pública fica lá fora na internet, privada fica
no seu prédio. Não é assim que as definições estão escritas. O local pode variar em três das quatro;
o que cada modelo fixa primeiro é **para quem a infraestrutura é provisionada**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Os quatro modelos de implantação da NIST SP 800-145, dispostos por quem pode rodar cargas no mesmo hardware, de uma organização a qualquer um. Privada: para uma organização, nas instalações dela ou fora delas, operada por ela ou por um contratado. Comunitária: para um grupo de organizações com interesses comuns, como uma missão ou uma lei, dentro ou fora das instalações. Pública: para qualquer um que se cadastre, nas instalações do provedor, operada pelo provedor. Abaixo das três, a híbrida: duas ou mais delas, ainda separadas, ligadas de modo que dados e aplicações possam passar de uma para a outra.\"><defs><marker id=\"dm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">quem pode rodar cargas no mesmo hardware</text><text x=\"20\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">menos</text><text x=\"700\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais</text><path d=\"M70 38 L650 38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dm-ah)\"></path><rect x=\"20\" y=\"56\" width=\"200\" height=\"116\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\" font-weight=\"600\">Privada</text><text x=\"34\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">para uma organização</text><text x=\"34\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dentro ou fora do prédio dela</text><text x=\"34\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">operada por ela ou contratado</text><rect x=\"260\" y=\"56\" width=\"200\" height=\"116\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"274\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\" font-weight=\"600\">Comunitária</text><text x=\"274\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">para um grupo com interesses</text><text x=\"274\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">comuns: uma missão, uma lei</text><text x=\"274\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dentro ou fora das instalações</text><rect x=\"500\" y=\"56\" width=\"200\" height=\"116\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"514\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\" font-weight=\"600\">Pública</text><text x=\"514\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">para quem se cadastrar</text><text x=\"514\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nas instalações do provedor</text><text x=\"514\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">operada pelo provedor</text><path d=\"M120 174 L120 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#dm-ah)\"></path><path d=\"M360 174 L360 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#dm-ah)\"></path><path d=\"M600 174 L600 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#dm-ah)\"></path><rect x=\"20\" y=\"200\" width=\"680\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"34\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">Híbrida</text><text x=\"34\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">duas ou mais das três, cada uma ainda uma nuvem própria, ligadas de modo</text><text x=\"34\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">que dados e aplicações possam passar de uma para outra ou usar as duas</text></svg>", "caption": "Os quatro modelos da NIST respondem primeiro a uma pergunta: quem mais pode rodar naquele hardware. Onde ele fica e quem o opera vêm depois, com folga nas duas primeiras e fixos na pública. Híbrida não é um quarto tipo de hardware; é uma ligação entre os outros."}
```

Lado a lado, nos termos da NIST e em palavras simples:

| modelo | provisionada para | onde pode ficar | quem pode operar |
|---|---|---|---|
| privada | uma organização, que pode ter muitos consumidores, como suas unidades de negócio | dentro ou fora das instalações dela | a organização, um terceiro, ou os dois |
| comunitária | um grupo de organizações com interesses comuns: uma missão, exigências de segurança, uma política, conformidade | dentro ou fora das instalações | um ou mais membros, um terceiro, ou uma combinação |
| pública | uso aberto pelo público em geral | nas instalações do provedor | uma empresa, uma universidade, um órgão de governo, ou uma combinação |
| híbrida | duas ou mais das anteriores, ainda distintas, ligadas por tecnologia que deixa dados e aplicações passarem de uma para outra | onde ficarem suas partes | quem opera cada parte |

Leia a tabela por coluna e duas coisas ficam claras.

Primeiro, **uma nuvem privada pode ficar no prédio de outra empresa**. Uma empresa que aluga uma
sala de servidores dedicados num datacenter de colocation e roda uma pilha de nuvem neles tem uma
nuvem privada fora das suas instalações: o prédio é compartilhado, o hardware não. "Privada" fala de
quem usa, não do endereço no portão.

Segundo, **híbrida não é um quarto tipo de hardware**. Não existe servidor híbrido para comprar. A
palavra nomeia uma composição: duas nuvens que continuam separadas e são ligadas de modo que uma carga
possa passar de uma para a outra, ou rodar nas duas. O exemplo da própria NIST é o *cloud bursting*:
o lado privado atende a carga até lotar, e o excedente vai para o lado público.

A rigor, a híbrida da NIST liga duas nuvens. Na prática a palavra é usada de forma mais solta, e um
datacenter comum ligado a uma região pública é chamado de híbrido por quase todo mundo, os
provedores inclusive. Esta aula segue o uso comum. A diferença importa num lugar só, e é por isso
que a seção sobre nuvem privada pergunta o que falta a um datacenter para ele contar como nuvem.

## Dois eixos, não uma lista

O modelo de implantação e o modelo de serviço da aula 1 são **perguntas independentes**. IaaS,
PaaS e SaaS dizem quanto da pilha o provedor opera por você; pública, privada e comunitária dizem
quem divide o hardware por baixo. OpenStack rodando dentro de um banco dá às equipes do banco IaaS
numa nuvem privada. Um webmail vendido a qualquer um com cartão é SaaS numa nuvem pública. Qualquer
combinação é possível, e uma frase que usa só uma das duas palavras deixou metade da descrição de
fora.

## A pergunta por trás de cada nome

Reduzido a uma pergunta, cada modelo responde **quem mais roda no mesmo hardware**:

- ninguém de fora da organização: privada;
- organizações que dividem suas regras e interesses: comunitária;
- qualquer um que se cadastre e pague: pública.

A híbrida muda a pergunta do hardware para a ligação. O que precisa passar entre os dois lados,
quanto custa passar, e o que quebra quando o link cai. A maior parte do resto desta aula é sobre
essa ligação, porque é nela que estão as surpresas.
