---
title: Escolher, partindo da tela
version: 1
---

**Escolha perguntando que tipo de tela você tem e o que a sua plataforma já oferece, e não qual
padrão é o mais novo.** O MVVM não é uma melhoria do MVP, que não é uma melhoria do MVC. Cada um
serve a uma situação, e na maioria das plataformas o framework já escolheu por você; ir contra ele
custa mais do que qualquer padrão economiza.

Cinco situações cobrem quase tudo o que você vai escrever.

## Um servidor que renderiza HTML

Use o MVC do framework e mantenha os controllers finos. O framework já decidiu as setas: rotas,
handlers, templates. O que sobra para você é a disciplina de `web.py`, em que o controller lê a
requisição, chama o modelo e escolhe uma view, e as regras ficam num modelo que funcionaria sem
HTTP. **O teste de um controller fino é se você conseguiria chamar o modelo de um script de linha
de comando sem copiar uma linha.** Se a verificação do limite mora no handler, não conseguiria.

## Uma API que devolve JSON

Quase não é uma questão de apresentação. A view é o serializador, e os controllers são os handlers
das rotas. A tela existe em outro lugar, numa aplicação no navegador ou num app de celular, e é
nesse cliente que as duas próximas escolhas são feitas. O que importa no servidor é o mesmo
controller fino, e uma escolha honesta de códigos de status, como o `409 Conflict` de `web.py`.

## Uma tela numa plataforma com data binding

Use MVVM. WPF, JavaFX, Android, SwiftUI, Vue e Angular trazem binding, e os tutoriais, as
bibliotecas e as ferramentas deles pressupõem um view-model. Escrever um presenter que empurra
valores para os widgets numa plataforma dessas joga fora a parte que você já tem. Mantenha o
view-model livre de tipos de widget, para ele poder ser testado como um objeto comum.

## Uma tela numa plataforma sem binding

Use MVP. Um programa de terminal, uma janela Tkinter, o menu de um jogo, um toolkit antigo: nenhum
oferece binding, e construí-lo, como `mvvm.py` fez com `Observable`, é um framework que você passa a
manter. Um presenter e uma interface de view são duas classes comuns, e a lógica de tela fica
testável com uma view falsa. **O MVP também é o jeito mais barato de pôr testes em volta de uma
lógica de tela que já está emaranhada**: extraia as decisões para um presenter uma de cada vez,
deixando para trás o `print` ou as chamadas aos widgets.

## Um script que vai ter uma tela só para sempre

Não use nenhum. `tangled.py` tem vinte e quatro linhas e faz o seu trabalho. Os três custos da
primeira seção chegam com uma segunda tela, um teste ou um redesenho; enquanto nenhum deles é real,
a separação é especulação, e a lição 19 conta quanto a especulação custa. O único hábito que vale a
pena manter mesmo aqui é o primeiro movimento: quando aparecer uma regra, ponha-a numa função que
devolve um valor, e não numa que imprime.

## Sinais de que é hora de separar

O emaranhado se anuncia, e os sinais são concretos:

| você nota | quer dizer | o movimento |
|---|---|---|
| uma regra escrita duas vezes, uma por tela | apresentação e regras dividem um arquivo | extrair o modelo |
| um teste que captura a saída padrão para conferir um número | a lógica está dentro da view | um presenter ou um view-model |
| `if`s decidindo o que fica habilitado, espalhados pelos handlers de evento | lógica de tela sem casa | um view-model, se a plataforma tem binding |
| um handler de oitenta linhas | o controller está fazendo o trabalho do modelo | levar as regras para o modelo |

As lições 3 e 4 deram a versão geral desse argumento: uma classe com um só motivo para mudar, e
detalhes que dependem de políticas e não o contrário. Uma view é um detalhe, e o limite de
empréstimos é uma política. Os padrões desta lição são esse princípio aplicado à única parte de um
programa para a qual uma pessoa olha.
