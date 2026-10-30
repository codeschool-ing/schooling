---
title: Uma rejeição, e o que fazer com ela
version: 1
---

**Uma rejeição é uma mensagem no App Store Connect que cita uma diretriz, diz o que o revisor viu e
deixa o build onde estava.** Ela não é um julgamento sobre você e raramente é final. A página da App
Review da Apple, lida em 30 de outubro de 2026, diz que quando um envio não passa "details are
provided, including any specific App Review Guidelines that your submission didn't follow", e que você
"can correspond with App Review to resolve the issues before resubmitting". Nada aqui foi executado;
nenhum build do planner foi enviado.

## Leia em três partes

1. **O número da diretriz.** Ele diz que parte do documento da seção 06 o revisor aplicou, e é o texto
   dessa diretriz que a sua correção tem de satisfazer, não só a frase do revisor.
2. **O que ele viu.** Uma captura de tela, um passo, um aparelho e uma versão do iOS. Reproduza naquela
   versão antes de mudar qualquer coisa; uma falha num aparelho que você não testou é a rejeição 2.1
   mais comum.
3. **O que ele pede.** Às vezes é informação, uma conta de demonstração ou a explicação de um recurso,
   e a resposta é uma mensagem, não um build novo.

## Quatro que o planner poderia receber, e a resposta a cada uma

| o que a mensagem diz | diretriz | o que fazer |
|---|---|---|
| o app travou ao abrir no iPad do revisor | 2.1 | um app de iPhone pode ser revisado num iPad; teste nele, reproduza a falha e corrija |
| login exigido e nenhuma conta de demonstração | 2.1 | acrescentar uma conta de demonstração em *App Review Information*, ou deixar o planner funcionar sem conta |
| o pedido da câmera não explica o uso | 5.1.1 | reescrever a frase de uso da aula 18, seção 02, e reenviar |
| dá para criar conta mas não apagar | 5.1.1(v) | acrescentar a exclusão de conta dentro do app |

**Responda antes de reenviar quando o revisor entendeu errado.** Se o app faz algo que o revisor não
achou, uma frase dizendo onde está, na conversa, é mais rápida que um build novo e guarda o registro do
porquê. Se você acha que a decisão em si está errada, o recurso da seção 06 é o próximo passo, uma vez.

## Depois

Um build aprovado espera o lançamento: na hora, numa data, ou à mão, como você escolheu ao enviar. Um
**lançamento em fases** espalha uma atualização por vários dias e pode ser pausado, que é o assunto da
aula 8 de `mobile-delivery`. E toda rejeição vale uma linha nas anotações do projeto: a mesma diretriz
costuma pegar o mesmo time duas vezes.
