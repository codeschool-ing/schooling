---
title: Conflito entre times costuma ser sobre uma fronteira
version: 1
---

**Quando dois times vivem brigando, procure algo que eles compartilham e de que ninguém é dono.**
Discordâncias entre pessoas vêm e vão. Discordâncias entre times se repetem, com pessoas diferentes,
porque a causa é estrutural: uma tabela em que os dois escrevem, um serviço de que os dois dependem,
um release que os dois precisam coordenar. Mediar cada discussão quando ela aparece é necessário;
consertar a fronteira é o que impede a próxima.

## As três fronteiras da Marola

Todos os conflitos deste curso até aqui giraram em torno de uma de três coisas compartilhadas:

1. **As conexões do banco de pedidos**, divididas entre checkout e logística até a cota.
2. **A tabela** que o planejador de rotas e o serviço de zonas leem e escrevem, que a aula 7
   encontrou por trás de cinco de sete incidentes.
3. **O momento dos releases**: os jobs em lote da logística e o pico do checkout, que ninguém tinha
   registrado como restrição até 6 de março.

Cada uma produziu um conflito que parecia pessoal ("o checkout culpa todo mundo", "a logística
quebra os nossos releases") e não era. **A coisa compartilhada não tinha dono, então cada decisão
sobre ela era uma negociação, e cada negociação era uma chance de os times se desentenderem.**

## Dê a cada coisa compartilhada um dono e um contrato

O conserto estrutural tem duas partes:

- **Um dono**: um time que decide as mudanças na coisa compartilhada e que os outros precisam
  consultar. Não o time que grita mais alto; aquele cujo serviço mais sofreria com uma mudança
  ruim. As conexões do banco de pedidos agora pertencem ao time de plataforma.
- **Um contrato**: o que o dono promete aos outros, por escrito. A tabela de cotas é um contrato. O
  formato dos eventos do outbox, com número de versão, é um contrato. Um contrato transforma "vocês
  quebraram a gente" em "o contrato diz X; a mudança manteve isso?", que é uma pergunta com
  resposta.

Matthew Skelton e Manuel Pais, em *Team Topologies*, defendem que os times interajam em poucos modos
deliberados (colaborar de perto por um tempo, prestar um serviço um ao outro, ou um time ajudar outro
a aprender) e que a maior parte do atrito vem de interações que ninguém escolheu. **Registrar em que
modo dois times estão, e por quanto tempo**, é um jeito barato de tornar explícita uma fronteira
implícita.

## Quem media não é o dono

Lívia mediou a conversa sobre a cota. Ela não assumiu as cotas e tomou cuidado para não decidi-las
ela mesma, ainda que os dois leads fossem aceitar. **Quem media e decide vira o próximo dono da coisa
compartilhada**, e aí toda discussão futura sobre ela cai na mesa dessa pessoa, o que não escala
além de um punhado de fronteiras.

O trabalho dela era levar os dois donos a uma decisão com que ambos conseguissem conviver, e garantir
que a decisão tivesse um lugar: o time de plataforma para as cotas, um registro de decisão para o
outbox.
