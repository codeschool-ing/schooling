---
title: Dois lugares para pô-lo
version: 1
---

**O WAF do Azure é uma política que você prende a algo que já recebe HTTP**, e há duas coisas assim:

| | **Front Door** | **Application Gateway** |
|---|---|---|
| onde roda | na borda global da Microsoft, perto do cliente | numa região, dentro da sua rede virtual |
| o que ele protege | qualquer coisa com endereço público: App Service, um site estático, outra região | backends na rede virtual, inclusive privados |
| o que acrescenta | cache, balanceamento global, TLS na borda | roteamento de camada 7 dentro de uma região, backends privados |
| tipo de política do WAF | `FrontDoorWebApplicationFirewallPolicies` | `ApplicationGatewayWebApplicationFirewallPolicies` |

Os clientes da loja chegam a ela pelo **Front Door Premium**, que manda o tráfego ao App Service em `brazilsouth`; o WAF roda
ali, na borda, e um ataque é parado antes de entrar na região. O Application Gateway é a resposta onde os backends precisam
ficar privados e a borda não é do Azure, e algumas arquiteturas rodam os dois: Front Door na borda para o tráfego global,
Application Gateway na região para o roteamento interno.

Os dois tipos de política dividem as partes importantes: **conjuntos de regras gerenciados**, mantidos pela Microsoft, que
casam padrões de ataque conhecidos como injeção de SQL e cross-site scripting; **regras personalizadas**, escritas por você,
avaliadas primeiro; e um **modo**, *Detection* ou *Prevention*. Nenhuma foi implantada para este curso: não há Front Door nem
gateway. As políticas foram escritas e compiladas, que é o assunto das duas próximas seções.

Uma coisa o WAF não faz: **ele não conserta a aplicação.** Uma regra que bloqueia um padrão de injeção de SQL ganha tempo; a
consulta parametrizada no código é a correção. Um WAF na frente de código vulnerável é um guarda numa porta de fechadura
quebrada.
