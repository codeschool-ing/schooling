---
title: O que fica entre uma conta e o primeiro release
version: 1
---

**Abrir a conta é o começo de uma lista, e a lista é mais longa do que as pessoas planejam.** Cada
item é rápido sozinho; juntos, eles decidem se o primeiro release é nesta semana ou no mês que vem.
*Lido na documentação da Apple, outubro de 2026, e na Central de Ajuda do Play Console como
publicada em 2025; não rodado.*

## Do lado da Apple

- **Os acordos.** O acordo de apps gratuitos é aceito na inscrição. Um app pago ou uma compra
  dentro do app precisa do **Paid Applications Agreement**, aceito pelo Account Holder, e depois da
  conta bancária e dos formulários fiscais. Até os três estarem completos, nada com preço pode ser
  vendido.
- **O registro no App Store Connect.** Um app é criado no App Store Connect com o bundle
  identifier, o nome e o idioma principal antes que o primeiro build possa ser enviado a ele. **O
  nome precisa ser único em toda a App Store**, então um nome que outra pessoa já tem é descoberto
  aqui, e não na revisão.
- **O ano da assinatura.** Ele conta a partir do dia da inscrição, e a contagem de 100 aparelhos da
  lição 2 também.

## Do lado do Google

- **Verificação de identidade.** O Google verifica o dono da conta, ou a organização pelo número
  D-U-N-S, antes que a conta possa publicar. Ele pede documentos e pode levar dias.
- **Uma exigência de teste para contas pessoais novas.** A ajuda do Google em 2025 exigia que uma
  conta pessoal criada depois de novembro de 2023 rodasse um **teste fechado com pelo menos 12
  testadores, inscritos por pelo menos 14 dias**, antes de poder pedir acesso à produção. Contas de
  organização estão isentas. A lição 7 trata de teste fechado; essa regra é o motivo de o primeiro
  release numa conta pessoal nova levar duas semanas no mínimo.
- **O perfil de pagamentos.** Um app pago ou produtos dentro do app precisam de uma conta de
  comerciante ligada à conta de desenvolvedor, com os dados fiscais dela.

## Planejando de trás para a frente

**Conte o calendário a partir do passo mais lento, e não do código.** Um pedido de D-U-N-S, uma
verificação e um teste fechado de catorze dias podem levar, cada um, mais tempo do que terminar o
app, e nenhum deles consegue começar tarde e terminar a tempo. A primeira coisa que uma equipe faz
depois de decidir publicar é abrir as contas; o código pode ser terminado enquanto a papelada
espera.

| passo | quem faz | a espera |
|---|---|---|
| número D-U-N-S, para uma organização | a empresa | dias |
| verificação de identidade | o dono da conta | dias |
| acordos, banco e impostos | o Account Holder, o dono | uma tarde, quando todos os dados estão à mão |
| teste fechado numa conta pessoal nova do Play | você e doze testadores | 14 dias ou mais |
| a primeira revisão | as lojas | lição 6 |
