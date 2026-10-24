---
title: As lojas, e o que elas revisam
version: 1
---

**Uma loja é um distribuidor com regras, e as regras são a parte que muda.** Tudo nesta seção vale para quando
este curso foi escrito e vem das páginas das próprias lojas; cada loja muda as taxas, os formulários e as
políticas no próprio ritmo, então leia a página da loja no dia em que for publicar. *Nenhuma conta foi aberta e
nada foi enviado para este curso: as duas coisas precisam de uma pessoa aceitando os termos e, no caso da Apple,
de uma assinatura paga.*

## Google Play

Uma conta no **Play Console** custa uma taxa de registro única que o Google define, e pede que a sua identidade
seja verificada. Depois, para cada app:

- **uma página na loja**: o nome, uma descrição curta e uma completa, o ícone com 512 pixels, capturas de tela de
  celulares e tablets, e uma imagem de destaque;
- **os formulários**: classificação de conteúdo, o público-alvo, se há anúncios, e o formulário de **Segurança dos
  dados**, que diz que dados o app coleta e por quê. O planner não manda nada para fora do celular, a localização
  que ele lê incluída, e o formulário diz exatamente isso;
- **uma política de privacidade**, num endereço público, mesmo para um app que não coleta nada;
- **um teste antes da produção**: contas pessoais novas precisam rodar um teste fechado, com um número de
  testadores durante um período que o Google define, antes de o app poder ir para todo mundo.

Depois o AAB da aula 13 vai para uma faixa, interna, fechada, aberta ou de produção, e uma revisão, normalmente
coisa de dias, vem antes do primeiro release de cada faixa.

## A App Store

O **Apple Developer Program** é uma assinatura anual, a um preço que a Apple define. Cada app ganha um registro no
**App Store Connect** com a página dele, capturas de tela para os tamanhos de tela que a Apple pede, o endereço de
uma política de privacidade, e os **detalhes de privacidade**, o formulário da Apple sobre o que o app coleta. Os
builds chegam pelo Xcode, passam primeiro pelo TestFlight, e então vão para a **App Review**, conforme as App
Review Guidelines que a Apple publica.

## A revisão em que apps empacotados reprovam

**Uma diretriz importa mais para este curso que qualquer outra.** A diretriz da Apple sobre funcionalidade mínima
diz que um app deve ser mais que um site reembalado, e um app web empacotado que é só o site dele numa WebView é o
caso clássico de recusa por ela. As políticas do Google têm uma ideia parecida sobre apps que oferecem pouco mais
que um site.

O que um revisor procura é o que faz de um app um app: funcionar offline, usar o aparelho, parecer em casa na
plataforma. **O planner passa pelas partes que as aulas 4 a 6 construíram**: os dados ficam no celular e funcionam
sem rede, ele manda notificações locais, usa a câmera, e as telas foram medidas no orçamento de um celular. Um app
Capacitor cujo único conteúdo é um `server.url` remoto, aquilo que o checklist da aula 13 recusa, é o que reprova.
Um app React Native, cujas telas são views nativas, já começa do lado certo dessa diretriz; é o app empacotado que
precisa conquistá-lo.
