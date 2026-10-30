---
title: O custo de uma flag
version: 1
---

**Toda flag dobra o número de jeitos que o app pode estar, e uma flag que ninguém remove fica para
sempre.** Duas flags fazem quatro combinações, dez fazem mil, e ninguém testa mil. Flags são baratas
de acrescentar e caras de manter, e é por isso que as úteis têm data de fim desde o dia em que entram.

## Três tipos, com três vidas

| tipo | exemplo no planner | quanto tempo deveria viver |
|---|---|---|
| **flag de release** | `statistics`, enquanto a tela é liberada | até chegar a 100%; depois a flag e o caminho de código antigo são apagados |
| **chave de desligar** | desligar a sincronização se o servidor estiver sobrecarregado | para sempre, mas existem pouquíssimas, e cada uma é testada |
| **experimento** | dois layouts da primeira tela, lição 17 | até o experimento ter a resposta, a amostra da lição 18 |

Uma flag de release ainda no código seis meses depois de chegar a 100% é dívida: um galho que ninguém
percorre, e que alguém um dia vira sem querer. A regra de costume é um **ticket para remover a flag**,
criado no mesmo pull request que a acrescenta.

## Testando com flags

- **Teste os dois lados de toda flag em uso** nos testes automáticos, com a flag forçada ligada e
  forçada desligada.
- **Teste os padrões**: o app sem servidor e sem cache, que é o que uma instalação nova numa rede ruim
  encontra primeiro.
- **Nunca teste só a combinação que está ligada na produção hoje**; a de amanhã é outra.

## O mesmo nas três plataformas

Toda plataforma tem os mesmos produtos para isso: o **Firebase Remote Config** para Android, iOS e
React Native; o **LaunchDarkly**, o **ConfigCat**, o **Unleash** e outros, alguns dos quais rodam nos
seus próprios servidores. Eles acrescentam segmentação, painéis e registros de auditoria. O que eles
não mudam é a lógica desta lição: uma cópia em cache, padrões seguros, baldes estáveis, e uma flag que é
removida quando o trabalho dela acaba. *Nenhum desses produtos foi configurado para este curso.*
