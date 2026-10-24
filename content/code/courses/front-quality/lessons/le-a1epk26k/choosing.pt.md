---
title: Sessão ou token, para um app como este
version: 1
---

**Para um app de navegador que conversa com o próprio servidor, uma sessão num cookie `HttpOnly` é o
padrão mais simples e mais seguro.** Isso vai contra muitos tutoriais, que pegam primeiro um JWT no
`localStorage`, então eis a comparação em que a escolha se apoia:

| | id de sessão num cookie | JWT carregado pela página |
|---|---|---|
| o que o navegador guarda | um id aleatório que sozinho não quer dizer nada | as próprias afirmações, legíveis por quem o tiver |
| um script da página consegue ler | não com `HttpOnly`, que é o objetivo | sim, onde quer que a página o guarde |
| sair, ou bloquear uma conta | apagar uma entrada; para de funcionar na hora | funciona até o `exp`, a menos que cada servidor tenha uma lista de bloqueio |
| mandado com as requisições | sozinho, pelo navegador, ao site que o definiu | pelo seu código, num cabeçalho `Authorization` |
| muitos servidores conferindo | precisam de um armazenamento compartilhado | cada um confere a assinatura sozinho |
| o ataque contra o qual defender | outro site fazendo o navegador mandá-lo (CSRF, aula 9) | um script na página lendo-o (XSS, aula 9) |

**A última linha decide a maioria dos casos.** Um cookie que o navegador manda sozinho convida
requisições que outro site começa, e o `SameSite` e as checagens da aula 9 fecham essa porta. Um token
que a página guarda é exatamente tão seguro quanto a página está livre de scripts injetados, e a aula 9
mostra como um `innerHTML` perdido deixa um texto virar script. Um cookie marcado `HttpOnly` não pode ser
lido por script nenhum, venha ele de onde vier.

## Onde os tokens acertam

Os tokens valem a pena onde o servidor não pode ser um processo só com uma memória só: vários serviços,
cada um conferindo requisições sozinho, ou uma API chamada por apps que não são navegadores. Eles também
são o que o OAuth devolve, que é a próxima seção. Nesses casos, mantenha o access token de vida curta e
fora de um armazenamento que um script consiga ler, e a aula 6 mostra o arranjo que faz as duas coisas,
um servidor pequeno do próprio app guardando os tokens enquanto o navegador guarda só um cookie.
