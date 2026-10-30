---
title: As fases de cena do iOS, a suspensão, e o AppState do React Native
version: 1
---

**O iOS descreve o mesmo ciclo de vida com três fases e um estado silencioso.** Um app SwiftUI lê a
fase da sua cena, uma janela da interface, em `scenePhase`, que tem três valores, e os métodos de
delegate mais antigos do UIKit informam os mesmos movimentos com mais detalhe:

| fase da cena | a descrição da Apple | o estado neste curso |
|---|---|---|
| `.active` | em primeiro plano e recebendo eventos | **ativo** |
| `.inactive` | em primeiro plano, mas deve pausar o trabalho | **inativo** |
| `.background` | não está visível na interface | **em segundo plano** |
| nenhuma | suspenso: na memória, sem executar | **suspenso** |

**Não existe fase para suspenso, porque um app suspenso não roda código para perceber isso.** O guia
da Apple sobre segundo plano diz que, quando o usuário sai de um app, ele vai para segundo plano por
um instante antes de o UIKit suspendê-lo, e que o UIKit pode desconectar uma cena em segundo plano ou
suspensa a qualquer momento para recuperar os recursos dela. A documentação de `.background` é mais
direta: espere que um app que entra em segundo plano seja encerrado.

## Inativo é a interrupção

**`.inactive` é o que uma ligação, a central de notificações ou o seletor de apps fazem com um app
que continua na tela.** O guia da Apple diz que o sistema desativa um app quando precisa
interrompê-lo temporariamente, por exemplo para mostrar alertas do sistema, e o reativa quando o
painel é fechado. Sair para a tela inicial também passa por ele: a sequência documentada é
`applicationWillResignActive`, depois `applicationDidEnterBackground`, depois uma captura da tela para
o seletor de apps, e então o app pode ser suspenso.

**A Apple pede para salvar antes do que o Android.** O guia dela sobre rodar em segundo plano manda
usar a desativação, a passagem para `.inactive`, para salvar os dados do usuário em disco e fechar os
arquivos abertos, e a passagem para segundo plano para liberar memória e esconder informação
sensível. E `applicationWillTerminate`, o método cujo nome parece uma despedida, é descrito como
geralmente não chamado, para apps que suportam execução em segundo plano, quando o usuário sai,
porque o app simplesmente vai para segundo plano. Um app suspenso que o sistema encerra não fica
sabendo de nada.

## React Native: um listener para os dois

**O React Native informa o ciclo de vida pelo `AppState`, com três valores.** A documentação lista
os três:

| AppState | a descrição do React Native | em que plataforma |
|---|---|---|
| `active` | rodando em primeiro plano | as duas |
| `background` | em outro app, na tela inicial, ou no Android atrás de outra Activity | as duas |
| `inactive` | em transição entre primeiro e segundo plano, ou interrompido, por exemplo por uma ligação | só iOS |

**`inactive` só existe no iOS**, porque o Android não tem um equivalente único que o React Native
informe. Um app React Native escuta o evento `change` e recebe o valor novo; o código da tela é o
mesmo nos dois celulares, e a única linha que difere é se `inactive` chega algum dia. Não há nada
para suspenso nem para morto, pelo mesmo motivo do iOS: nenhum código roda para ouvir.

## Três vocabulários, um modelo

| este curso | Android | iOS | React Native |
|---|---|---|---|
| ativo | resumed | `.active` | `active` |
| inativo | paused | `.inactive` | `inactive`, só iOS |
| em segundo plano | stopped | `.background` | `background` |
| suspenso | processo em cache | suspended | nada |
| não rodando | nenhum processo | not running | nada |

A próxima etapa põe essa tabela num programa, para você alimentá-lo com uma tarde e ler o que cada
plataforma teria dito.
