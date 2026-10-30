---
title: VoiceOver, testado usando
version: 1
---

**O único jeito de saber o que o VoiceOver diz é ligá-lo e escutar.** Cada regra desta aula ajuda, e
nenhuma substitui dez minutos com a tela lida em voz alta e os olhos fechados. Esta seção não foi
executada para o curso: ela precisa de um simulador ou de um iPhone, e foi escrita a partir do guia
do usuário do VoiceOver da Apple e da documentação do Accessibility Inspector do Xcode, lidos em 30
de outubro de 2026.

## O mínimo que a pessoa precisa saber

Num iPhone, o VoiceOver fica em *Ajustes*, *Acessibilidade*, *VoiceOver*, e o atalho de
acessibilidade, um clique triplo no botão lateral, o liga e desliga depois de configurado.
**Configure o atalho antes de ligar o VoiceOver**, porque os gestos mudam por completo enquanto ele
está ligado:

| gesto | o que faz |
|---|---|
| tocar, ou arrastar um dedo | lê o que está sob o dedo |
| deslizar um dedo para a direita ou para a esquerda | vai para o próximo elemento ou para o anterior |
| toque duplo | ativa o último elemento lido |
| deslizar para cima ou para baixo | a opção atual do rotor, como as ações personalizadas da seção 03 |
| deslizar dois dedos para cima | lê a tela inteira desde o topo |

## O que escutar no planner

Percorra as quatro telas, `CourseListView`, `CourseDetailView`, `SessionForm` e `WeekView`, com a tela
coberta, e anote cada lugar onde você precisou olhar:

- **um elemento lido como algo que não é uma frase**, como o nome de arquivo de uma imagem ou `50 min`;
- **um controle que você não achou ou não percebeu que era controle**, o `onTapGesture` da seção 03;
- **paradas demais** numa linha que é uma coisa só, ou **uma parada** onde deveria haver duas;
- **uma mudança que ninguém anunciou**: marcar uma sessão como feita deve mudar o valor que o
  VoiceOver lê, e um erro embaixo de um campo do `SessionForm` deve ser lido quando aparece;
- **a ordem**: o total da semana deve vir antes da lista que ele soma, e não depois.

## Sem telefone: o Accessibility Inspector

O Xcode traz o **Accessibility Inspector**, em *Xcode*, *Open Developer Tool*. Apontado para o
simulador, ele mostra o rótulo, o valor, os traits e a dica do elemento sob o ponteiro, percorre os
elementos na ordem do VoiceOver e roda uma **auditoria** que acusa elementos sem rótulo, texto que
não escala e contraste abaixo dos limites. Ele pega a metade mecânica. Se um rótulo faz sentido
continua sendo uma pergunta que só escutar responde.
