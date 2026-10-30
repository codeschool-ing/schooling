---
title: O que uma atualização pode mudar, pelas regras das lojas
version: 1
---

**Atualizar um app sem a loja é permitido, dentro de limites que as duas lojas escrevem**, e os limites
são sobre confiança e não sobre tecnologia: o revisor aprovou um app, e uma atualização não pode
transformá-lo em outro.

A **Apple** permite que um app baixe código que roda no próprio interpretador, que é o que um bundle
JavaScript é, desde que a mudança não altere o propósito principal do app, não acrescente recursos que o
revisor nunca viu e não contorne a revisão da App Store nem as regras de pagamento dela. O **Google Play**
proíbe que um app se atualize, ou baixe código executável, por qualquer caminho que não seja o Google
Play, e abre uma exceção para código que roda numa máquina virtual ou num interpretador, como JavaScript
numa WebView ou no motor JavaScript do app. *Isso é um resumo do Apple Developer Program License Agreement
e da política do Google Play sobre abuso de dispositivo e rede como estavam quando este curso foi escrito;
leia o texto atual antes de contar com ele.*

| mudança | remota | um build de loja |
|---|---|---|
| uma correção numa tela | sim | não precisa |
| uma tela nova feita de componentes que já estão no app | sim, se não mudar o que o app é | mais seguro, se for grande |
| um texto, uma cor, uma imagem | sim | não precisa |
| uma biblioteca nativa nova, uma permissão nova | **não**: o app instalado não a tem | sim |
| um propósito novo: o planner vira uma loja | **não**, seja qual for o código | sim, e uma revisão do app novo |

## Soltando uma

Uma atualização chega a todo app instalado na runtime version dela na próxima vez que cada um abre, o
que é mais rápido que um build de loja e também mais rápido para causar estrago. O serviço do Expo manda
uma atualização para um **canal**, `preview` ou `production`, para quem testa a ver primeiro; ele pode
mandá-la para uma parte dos usuários e desfazê-la. **Uma atualização quebrada é o único lançamento que uma
pessoa não consegue evitar deixando de atualizar**, e é por isso que o planner só mandaria uma depois das
mesmas conferências de um build de loja, e a aula 15 volta à ordem em que as mudanças saem.

Apps Capacitor têm a mesma opção por serviços de terceiros que trocam os arquivos web dentro do app, sob
as mesmas regras das lojas, e a aula 15 os nomeia.
