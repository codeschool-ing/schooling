---
title: Quando o controle não é um controle
version: 1
---

**Um `button` vem com o teclado incluído.** Ele recebe o foco, Enter e Espaço o apertam, um leitor de tela o
anuncia como botão, e o **Done** do planner funciona pelo teclado sem uma linha escrita para isso. Uma `div`
com um tratador de clique não tem nada disso: o Tab a pula, nenhuma tecla a aperta, e um leitor de tela a lê
como texto.

Eis o que é preciso para uma `div` se comportar como botão, que é o argumento mais claro para não fazer
isso:

```schooling-example
{"language": "html", "parts": [{"code": "<div class=\"tick\" role=\"button\" tabindex=\"0\">Done</div>\n", "note": "Uma `div` com a cara do botão do planner. O `role` diz ao leitor de tela que anuncie um botão, e o `tabindex=\"0\"` a põe na ordem de tabulação, onde uma `div` não está."}, {"code": "<script>\n  const tick = document.querySelector(\".tick\");\n  tick.addEventListener(\"click\", markDone);\n", "note": "O clique é a parte fácil, e a única que a maioria das pessoas escreve."}, {"code": "  tick.addEventListener(\"keydown\", (event) => {\n    if (event.key === \"Enter\" || event.key === \" \") {\n      event.preventDefault();\n      markDone();\n    }\n  });\n</script>", "note": "Enter e Espaço precisam ser ensinados. O `preventDefault` impede o Espaço de rolar a página, que é o que ele faz em tudo que não é botão. E isto ainda dispara o Espaço quando a tecla desce, onde um botão espera ela subir."}]}
```

**Quatro coisas, cada uma das quais um `button` já faz**, e a cópia ainda é diferente: um botão de verdade
dispara no Espaço quando a tecla é solta, e não quando desce, pode ser `disabled`, e envia o formulário em
que está. Cada uma delas é um bug esperando na cópia. A primeira regra do ARIA, que a aula 12 lê por
inteiro, diz a mesma coisa: se existe um elemento para a tarefa, use-o.

## Armadilhas, e o Esc

O 2.1.2 *Sem bloqueio do teclado*, nível A, pede que o foco sempre consiga sair de qualquer coisa em que
entrou pelo teclado. Armadilhas são raras em HTML puro e comuns no que é construído em cima dele: um editor
embutido que guarda o Tab para si, um mapa que captura as setas, uma caixa de diálogo que mantém o foco
dentro e não oferece saída.

Uma caixa de diálogo é o único lugar onde manter o foco dentro é *certo*, porque o que está atrás dela não
pode ser usado enquanto ela está aberta, e o Esc é a saída. O elemento `<dialog>` aberto com `showModal()`
faz tudo isso: move o foco para dentro da caixa, torna o resto da página inerte para que o Tab não o
alcance, fecha com Esc, e devolve o foco a quem a abriu. Como no botão, o elemento que existe para a tarefa
faz a tarefa.
