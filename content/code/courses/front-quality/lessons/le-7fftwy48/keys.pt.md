---
title: O que um teclado faz numa página
version: 1
---

**Tudo o que uma página deixa alguém fazer com o mouse, ela tem que deixar fazer com o teclado.** É o
critério 2.1.1 *Teclado*, nível A, e é o primeiro deste curso sem nada que uma máquina consiga verificar:
o axe lê a página, e nunca aperta uma tecla.

Quem precisa disso é mais gente do que quem não consegue segurar um mouse. Um leitor de tela é comandado
pelo teclado, então todo usuário cego do planner é um usuário de teclado. Também é quem tem um tremor, ou
usa um acionador, um único botão que um aparelho transforma em *próximo* e *apertar*, ou fala comandos que
viram teclas. E também é quem desenvolve e não quer tirar as mãos do teclado.

## As teclas, e o que se espera de cada uma

| tecla | o que ela faz |
|---|---|
| **Tab**, **Shift+Tab** | levam o **foco**, o único elemento que recebe as teclas, para o próximo ou o anterior elemento que pode recebê-lo |
| **Enter** | segue um link; aperta um botão; num formulário, o envia |
| **Espaço** | aperta um botão; marca uma caixa de seleção; em qualquer outro lugar, rola a página |
| **setas** | andam *dentro* de um controle: entre botões de opção, por um select, entre as partes de uma data |
| **Esc** | fecha o que foi aberto: um menu, uma caixa de diálogo, um seletor |

**O que recebe o foco sem ajuda nenhuma** é uma lista curta: um link com `href`, um `button`, um
`input`, um `select`, um `textarea`, um `summary`, e qualquer coisa com `tabindex` zero ou mais. Um
controle `disabled` não recebe. Todo o resto, uma `div`, um `span`, um `li`, é pulado pelo Tab seja lá
o que aconteça quando é clicado, e essa é a raiz da maior parte das falhas de teclado.

## Os critérios que esta aula testa

| critério | nível | ele pede |
|---|---|---|
| 2.1.1 Teclado | A | tudo funciona pelo teclado |
| 2.1.2 Sem bloqueio do teclado | A | o foco sempre consegue sair do que entrou |
| 2.4.3 Ordem do foco | A | o foco anda numa ordem que preserva o sentido |
| 2.4.7 Foco visível | AA | o elemento com foco pode ser visto |
| 2.4.11 Foco não encoberto (Mínimo) | AA | o elemento com foco não fica escondido atrás de outra coisa |
| 2.4.13 Aparência do foco | AAA | o indicador é grande o bastante e contrasta o bastante para ser visto |

## Experimente antes

Antes de qualquer teste, use o planner como alguém sem mouse. Suba o servidor de desenvolvimento, abra
`http://localhost:5173/#/course/javascript`, deixe o mouse de lado e aperte Tab algumas vezes, depois Enter
no botão **Done**. Duas coisas dão errado, e a primeira você vê na hora: não dá para saber onde você está.
Anote o que perceber, porque as próximas quatro seções transformam cada achado num teste.
