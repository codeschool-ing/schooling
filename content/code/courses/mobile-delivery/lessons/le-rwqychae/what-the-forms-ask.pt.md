---
title: O que os dois formulários perguntam
version: 1
---

**As duas lojas fazem a mesma pergunta de fundo, que dados saem do celular e o que acontece com
eles, e as duas publicam a sua resposta na página do app.** A Apple chama o resultado de **privacy
details**, mostrado como um rótulo de três caixas; o Google chama o formulário de **Segurança dos
dados**. Nenhum dos dois é conferido contra o app antes de ele ir ao ar. Os dois são uma declaração
pela qual você responde, e uma falsa é motivo para tirar o app do ar. *Lido na página App Privacy
Details da Apple, outubro de 2026, e na Central de Ajuda do Play Console como publicada em 2025;
não rodado.*

## O que "coletar" quer dizer

A Apple define com precisão: **um dado é coletado quando é transmitido para fora do aparelho de um
jeito que permite a você ou a um terceiro acessá-lo por mais tempo do que o necessário para atender
o pedido em tempo real.** Duas consequências vêm daí, e as duas surpreendem:

- Dado que nunca sai do celular **não é coletado**. As sessões do planner, guardadas só no banco do
  celular, não precisam de declaração.
- Dado enviado uma vez e jogado fora depois da resposta, uma busca respondida e não registrada,
  **também não é coletado**. A mesma busca gravada num log por um mês é.

## As três caixas da Apple

| caixa | o que põe um dado nela |
|---|---|
| **Data Used to Track You** | ele é cruzado com dados de outras empresas para publicidade, ou compartilhado com um corretor de dados |
| **Data Linked to You** | ele está ligado à identidade da pessoa, pela conta, pelo aparelho ou por qualquer outra coisa |
| **Data Not Linked to You** | ele é coletado, e nada o liga de volta a quem o enviou |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l05-label\" aria-label=\"O rótulo de privacidade da Apple como três caixas, com os quatro tipos de dado do planner dentro delas. Data Used to Track You está vazia. Data Linked to You guarda o endereço de e-mail e os cursos e sessões, porque a conta os liga à pessoa. Data Not Linked to You guarda os relatórios de crash e os eventos de produto, que não levam conta nenhuma. Uma nota diz que dado que nunca sai do celular não aparece em caixa nenhuma.\"><rect x=\"20\" y=\"20\" width=\"200\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"120\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Data Used to Track You</text><text x=\"120\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">vazia: nada é compartilhado com anunciante</text><rect x=\"260\" y=\"20\" width=\"200\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Data Linked to You</text><rect x=\"276\" y=\"62\" width=\"168\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">endereço de e-mail</text><rect x=\"276\" y=\"102\" width=\"168\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cursos e sessões</text><text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">a conta os liga à pessoa</text><rect x=\"500\" y=\"20\" width=\"200\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Data Not Linked to You</text><rect x=\"516\" y=\"62\" width=\"168\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">relatórios de crash</text><rect x=\"516\" y=\"102\" width=\"168\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">eventos de produto</text><text x=\"600\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">sem conta, um id de instalação aleatório</text><text x=\"360\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">dado que nunca sai do celular não fica em caixa nenhuma</text></svg>", "caption": "Os quatro tipos de dado do planner nas três caixas da Apple. O que decide a caixa é se algo liga o dado à pessoa, e não quão sensível o dado parece.", "same": ["Data Used to Track You", "Data Linked to You", "Data Not Linked to You"]}
```

Para cada tipo de dado, a Apple também pergunta as **finalidades**: funcionamento do app,
analytics, personalização do produto, a sua própria publicidade, publicidade de terceiros, outras.

## O formulário do Google

O Google pergunta, para cada tipo de dado, se ele é **coletado**, se é **compartilhado** com um
terceiro, para quais finalidades, se coletá-lo é **opcional**, e duas perguntas sobre o app
inteiro: os dados são **criptografados em trânsito**, e as pessoas podem **pedir que os dados delas
sejam apagados**. Ele também pergunta o que a Apple não pergunta: se o dado é processado de forma
**efêmera**, só na memória.

## A mesma resposta nas três plataformas

Nada nos dois formulários depende da linguagem do app. Um app React Native responde às mesmas
perguntas sobre os mesmos dados, uma vez em cada console. O que muda entre as plataformas é onde o
dado é coletado no código, e a seção "Código que você não escreveu" é a parte que as pessoas
esquecem.
