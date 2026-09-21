---
title: O que um editor dá que o prompt não dá
version: 1
---

Dá para escrever Python em qualquer editor de texto, inclusive no que veio com o seu sistema
operacional. Não é para fazer isso, e o motivo não é conforto.

## As quatro coisas que importam

**Ele sabe que o arquivo é Python.** O que significa que as cores querem dizer alguma coisa — uma
string sem fechar fica da cor errada da aspa em diante, e você vê isso antes de rodar qualquer coisa.

**Ele indenta por você, com espaços.** O `TabError` da seção anterior é uma classe de defeito que
simplesmente deixa de existir quando o editor está configurado para inserir quatro espaços na tecla
Tab.

**Ele avisa que o nome não existe**, antes de você rodar. A maioria dos editores roda um verificador
pequeno enquanto você digita; o erro de digitação que produziu o `NameError` da demonstração fica
sublinhado enquanto você ainda está na linha.

**E ele roda o arquivo** sem você trocar de janela, o que soa como comodidade e é, na verdade, o que
deixa o ciclo editar-rodar-ler rápido o bastante para se aprender nele.

## As duas configurações para fazer agora

Seja qual for o editor:

1. **Inserir espaços em vez de tabulação, quatro deles.**
2. **Mostrar espaços em branco**, ao menos sob demanda. A indentação ser a sintaxe faz de um espaço
   perdido uma questão de sintaxe, e é o único tipo de defeito que não dá para enxergar.

## O que usar

**VS Code** com a extensão de Python é o que a maioria usa e o que a maioria dos tutoriais supõe.
**PyCharm** é mais pesado e sabe mais sobre o seu código. **Vim**, **Emacs** ou **Helix** se você já
mora em um — a aula 12 do `linux-terminal` é o curso para isso, e esta não é a semana de começar.

Nada disso é requisito. Um `hello.py` escrito no Bloco de Notas roda exatamente igual. O editor é a
velocidade com que você descobre que errou, o que ao longo de um curso deste tamanho é a maior parte
do aprendizado.
