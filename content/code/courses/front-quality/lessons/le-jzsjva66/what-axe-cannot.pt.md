---
title: O que nenhuma máquina consegue decidir
version: 1
---

**Uma verificação automática encontra o que dá para decidir a partir do documento, e boa parte da
acessibilidade não dá.** A Deque, que escreve o axe, mediu que suas regras automáticas encontraram cerca de
**57%** dos problemas de acessibilidade que seus auditores encontraram à mão, contados por problema e não
por critério; por critério a fatia é menor, porque muitos critérios só são testáveis em parte. De um jeito
ou de outro, uma página que passa no axe não é por isso acessível, e uma equipe que trata o teste verde como
a resposta parou na metade.

O que o axe consegue decidir: uma razão de contraste, uma imagem sem `alt`, um campo sem rótulo, um botão
sem nome, um id duplicado, um `role` que não existe. O que não consegue, porque a resposta é sobre
significado ou comportamento:

| a pergunta | por que uma máquina não responde | onde este curso responde |
|---|---|---|
| o `alt` diz o que a imagem significa? | `alt="image"` passa em todas as regras | aula 12 |
| o foco anda numa ordem que faz sentido? | a ordem é válida seja qual for | aula 11 |
| todo controle pode ser alcançado e usado pelo teclado? | o axe olha a página, não aperta teclas | aula 11 |
| o elemento com foco está visível? | um estilo que remove o contorno é CSS válido | aula 11 |
| uma mudança na página é anunciada? | uma atualização que ninguém ouve não quebra regra nenhuma | aula 12 |
| a página ainda funciona sem animação, com zoom de 200%, com 320 pixels de largura? | esses são outros estados da página | aula 13 |

**O resto deste curso é a segunda coluna.** Cada uma dessas perguntas ganha um teste onde um teste
consegue fazê-la, com o Testing Library ou o Playwright apertando teclas e lendo a página como a tecnologia
assistiva a lê, e uma verificação manual onde só uma pessoa consegue responder.

## O piso, mantido em todas as páginas

A plataforma em que você está lendo este curso roda o axe do jeito que esta aula faz, com as mesmas cinco
etiquetas, sobre cada uma das suas próprias telas e nos dois temas de cor, a cada mudança no código. Os
dois temas porque contraste é a falha mais comum e um tema escuro é outro conjunto de cores, que é o
assunto da aula 13. E ela diz, no mesmo lugar, o que uma verificação dessas não encontra: se a ordem do foco
faz sentido, se um erro é anunciado, se um nome descreve o que um controle faz. **Uma verificação é o piso,
não o teto.**
