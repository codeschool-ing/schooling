---
title: Os três serviços, e em torno do que cada um foi construído
version: 1
---

Eles fazem o mesmo serviço e foram desenhados por três empresas com três suposições diferentes
sobre o que uma pessoa está fazendo, e essa suposição é a coisa a conhecer.

| | construído em torno de | a pasta que ele sincroniza |
|---|---|---|
| **iCloud Drive** | *os seus aparelhos*, e mantê-los iguais | opcionalmente a Mesa e os Documentos em si |
| **OneDrive** | *a sua conta de trabalho*, e a máquina ser substituível | Mesa, Documentos e Imagens, redirecionados |
| **Google Drive** | *o navegador*, com o aplicativo de desktop vindo depois | um disco virtual, ou uma pasta espelhada |

## O que cada um faz que os outros não fazem

O **iCloud** é o único que sincroniza coisas que não são arquivos: mensagens, senhas, dados de
saúde, o arranjo de uma tela inicial. A opção *Mesa e Documentos* dele é genuinamente útil e
genuinamente surpreendente, porque ligá-la **move** aquelas pastas para dentro do iCloud — e
desligá-la depois as deixa no iCloud e dá ao Mac pastas vazias, que são os cinco minutos mais
alarmantes que este serviço produz.

O **OneDrive** tem o *Known Folder Move*, que faz o mesmo redirecionamento no Windows, e é o que a
maioria das empresas liga para todo mundo. É a razão de um notebook de trabalho novo poder ser
logado e virar a *sua* máquina vinte minutos depois.

O **Google Drive** oferece dois modos e a diferença importa: o **streaming** põe um disco virtual
na máquina com nada guardado localmente até ser aberto, e o **espelhamento** mantém uma cópia
inteira de uma pasta escolhida. Streaming é o padrão e é o que falha dentro de um avião.

## Quanto custam, honestamente

As franquias gratuitas são `5 GB` no iCloud, `5 GB` no OneDrive e `15 GB` no Drive, e a última é
dividida com o Gmail e o Fotos, que é o assunto da seção sobre espaço.

Os planos pagos custam mais ou menos o mesmo por terabyte, e os três embutem coisas que você pode
já estar pagando — o Office com o OneDrive, recursos extras nos outros. **A comparação que importa
não é preço. É em qual ecossistema as suas máquinas e os seus colegas já estão**, porque o custo
de ser a única pessoa num diferente é pago em cada pasta compartilhada.

## A única coisa para conferir nos três

**Onde a pasta de fato está no disco.** Os três podem ser apontados para outro lugar, e os três
caem por padrão em algum lugar dentro da pasta pessoal — o que significa que o backup da pasta
pessoal da aula oito já está copiando uma versão substituta de tudo que há neles.

Duas consequências:

- **Exclua a pasta sincronizada do backup, ou ajuste-a para manter os arquivos localmente.**
  Copiar substitutos é copiar nada; copiar o conteúdo inteiro duplica o que já está fora de casa.
  Qualquer uma das duas se defende; o acidente é não saber qual você tem.
- **A pasta de uma segunda conta é uma segunda pasta.** Logar num OneDrive de trabalho e num
  pessoal produz duas pastas, duas cotas e dois conjuntos de regras, e arquivos movidos entre elas
  arrastando são *copiados para fora de uma e para dentro da outra*, com o compartilhamento que
  isso implicar.
