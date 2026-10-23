---
title: Antes que qualquer coisa saia do escritório
version: 1
---

**Mais cedo ou mais tarde alguém encaminha um arquivo ou um link e pergunta se é seguro.** A "fatura"
de um cliente com uma extensão estranha, um link para uma página de pagamento quase certa, um anexo
que o filtro de e-mail deixou passar. O instinto é jogá-lo no primeiro scanner online que aparece numa
busca. Esta aula trata de responder bem à pergunta, e a primeira parte de responder bem é a ordem em
que se fazem as coisas, porque **enviar um arquivo para um serviço online é publicá-lo**.

## O que um envio entrega

Os serviços online que esta aula descreve guardam o que recebem. A documentação do VirusTotal diz com
todas as letras que arquivos enviados pela interface pública são compartilhados com os clientes
premium e os parceiros de segurança dele, que podem baixá-los. As varreduras públicas do urlscan.io
ficam visíveis para qualquer um que procure. Os planos gratuitos do any.run e do Joe Sandbox tornam
públicas as análises. Tudo isso é útil para a comunidade de segurança e perigoso para você se o arquivo era da Jatobá.
**A planilha de um cliente cheia de CPFs, enviada "para conferir", é um
vazamento de dados** exatamente do tipo que a aula 9 tentou impedir, e pela LGPD o escritório responde
por ele.

O mesmo vale para links. Uma URL pode levar um token que faz alguém entrar, um código de redefinição ou
o nome de um cliente no caminho; enviá-la publicamente entrega isso a estranhos, e varrê-la pode até
consumir o token.

## A ordem

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l19-triage\" aria-label=\"A ordem da triagem. Um: olhar localmente, com file, um hash, strings e uma regra YARA, o que não manda nada a lugar nenhum. Dois: buscar o hash num serviço online, o que não revela nada do conteúdo. Se existe relatório, ler e parar. Se não, três: perguntar se o arquivo é do escritório ou traz dados de cliente. Se sim, analisar em privado, no seu próprio sandbox ou num serviço privado pago. Se não, pode ser enviado. Quatro, em todo caso: anotar o hash, onde olhou, o que disse e quando.\"><defs><marker id=\"l19-triage-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-triage-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"150.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 olhar localmente</text><text x=\"95.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">file, hash, strings, YARA</text><rect x=\"210.0\" y=\"30.0\" width=\"150.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"285.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2 buscar o hash</text><text x=\"285.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não revela nada</text><path d=\"M170.0 55.0 L210.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-triage-dh-ah-paper-dim)\"></path><rect x=\"400.0\" y=\"30.0\" width=\"140.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">relatório achado</text><text x=\"470.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ler, parar</text><path d=\"M360.0 55.0 L400.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-triage-dh-ah-paper-dim)\"></path><rect x=\"210.0\" y=\"130.0\" width=\"150.0\" height=\"56.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"285.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3 é do escritório?</text><text x=\"285.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ou dado de cliente?</text><path d=\"M285.0 80.0 L285.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-triage-dh-ah-paper-dim)\"></path><text x=\"292.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada achado</text><rect x=\"20.0\" y=\"140.0\" width=\"150.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">análise privada</text><text x=\"95.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aula 12, ou paga</text><path d=\"M210.0 160.0 L170.0 162.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-triage-dh-ah-amber)\"></path><text x=\"190.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sim</text><rect x=\"400.0\" y=\"140.0\" width=\"140.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pode ser enviado</text><text x=\"470.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">serviço público</text><path d=\"M360.0 160.0 L400.0 162.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-triage-dh-ah-paper-dim)\"></path><text x=\"380.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não</text><rect x=\"160.0\" y=\"225.0\" width=\"400.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4 anotar: hash, onde, o que disse, quando</text></svg>", "caption": "O envio é o último passo e o opcional, nunca o primeiro.", "same": ["file, hash, strings, YARA"]}
```

1. **Olhe localmente primeiro.** O que o arquivo é de verdade, e o hash dele, não custam nada e não
   deixam rastro. A próxima seção faz isso no `desk`.
2. **Busque pelo hash antes de enviar qualquer coisa.** Um hash não revela nada do conteúdo, e se o
   arquivo é conhecido, a resposta já está lá.
3. **Envie só o que não é do escritório.** Um arquivo de fora, que ninguém do escritório escreveu e que
   não traz dados de cliente, pode ir para um serviço; todo o resto vai para uma análise privada, como o
   sandbox da aula 12 ou um serviço pago com envios privados.
4. **Anote o que você fez**: o hash, onde olhou, o que disse e quando. O veredito de um serviço online
   muda conforme mais motores aprendem um arquivo, e "estava limpo na terça" só serve com a data.

Suba o laboratório desta aula: uma máquina, a estação onde o arquivo chegou.

```sh
sudo bash hostlab.sh up desk
```
