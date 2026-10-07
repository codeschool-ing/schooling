---
title: Quando não pagá-la
version: 1
---

Nem toda dívida deve ser paga. Tratar o pagamento como sempre bom é o espelho de tratar a dívida como sempre ruim, e os dois levam a gastar esforço onde ele compra pouco. Uma dívida vale ser paga quando os juros dela, ao longo do tempo que o código vai viver, são maiores que o principal. Várias situações comuns não passam nesse teste.

## Código que vai ser apagado

Um módulo com substituição marcada para o próximo trimestre não precisa de refatoração agora. Cada hora gasta melhorando-o se perde quando ele for embora. Os juros ainda precisam ser pagos até lá, mas pagar o principal seria pagar duas vezes.

## Código em que ninguém mexe

Um módulo embaraçado que funciona, não é tocado e não está no caminho de nenhuma mudança planejada não cobra juros. Pode parecer alarmante num relatório de análise estática, e pode ofender quem o lê; não custa nada ao time enquanto fica parado. Deixe-o, e registre-o, para que no dia em que uma mudança for planejada a dívida entre no preço dessa mudança.

## Protótipos e experimentos

Código escrito para aprender algo — um spike, um protótipo mostrado a três recepcionistas, um experimento com uma clínica — é feito para ser barato e descartável. Exigir dele padrão de produção atrasa o aprendizado que era o propósito dele. O risco é o protótipo que vira produção em silêncio, e a defesa é **decidir explicitamente** quando um experimento se forma, e pagar a dívida dele nesse momento.

## Quando os juros são minúsculos

Uma dívida cujos juros medidos são uma hora por mês não vale uma semana de trabalho, por mais feio que seja o código. A quinta seção desta aula existe para achar essas: uma dívida de que todo mundo reclama e que ninguém mediu às vezes se revela, medida, quase de graça.

## Assumir dívida de propósito

Por fim, assumir dívida pode ser a decisão certa. Entregar o agendamento online uma semana antes para cumprir a renovação de contratos das clínicas, com uma integração de pagamento mais simples que vai precisar ser refeita, pode valer muito mais do que custa refazer. Essa é a célula prudente e deliberada do quadrante de Fowler. É boa gestão quando a decisão fica **escrita com os juros e o gatilho de pagamento**, num registro de decisão de arquitetura, para ser paga quando vencer — e má gestão quando não fica escrita em lugar nenhum.
