---
title: Quando uma execução dá errado, e quem percebe
version: 1
---

Um registro que termina em `done` parece sucesso, e o laço não tem outra palavra para isso. **O laço
consegue conferir a forma de cada turno e os limites de cada chamada; não consegue conferir se o
raciocínio está certo.** Cinco execuções, cada uma quebrada num lugar diferente, mostram que falhas
caem de cada lado dessa linha. Todos os turnos foram escritos pelo curso; as respostas das
ferramentas e os veredictos do laço são o que o `agent` imprimiu.

## Uma observação que o modelo ignora

As ferramentas devolvem os fatos certos, e a resposta contradiz esses fatos:

```
ana@lab:~/pe$ agent runs/ignored.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Thought: I need the rule about approval first.
  model> Action: search[refund approval manager]
  tool>  refunds.md     A refund above R$ 100 needs the shift manager's approval.
step 2
  model> Thought: Now the total for four soups.
  model> Action: calculator[4 * 27.90]
  tool>  111.6
step 3
  model> Thought: That is a normal refund.
  model> Answer: R$ 111.60 back to the card. No approval is needed.
done: an answer after 3 steps
```

Os dois fatos necessários para a resposta certa estão na tela, a duas linhas um do outro, e a
resposta diz o contrário do primeiro: acima de R$ 100 precisa de aprovação, e ela diz que não
precisa. O laço imprime `done`, porque um turno com `Answer:` é tudo o que ele procura. Esta é a
falha que o ReAct torna visível sem impedir: **a prova está no registro, então uma pessoa, ou uma
segunda conferência, consegue pegá-la**. Repare também no último Thought. "That is a normal refund"
("é um reembolso comum") não cita fato nenhum, e um pensamento que não cita nada é o lugar de
costume onde uma execução deixa a prova para trás.

## Uma Action que o laço não consegue ler

O laço encontra a chamada de ferramenta com um padrão: `Action:`, um nome, e o argumento entre
colchetes. Um modelo que escreve parênteses escreveu algo que uma pessoa lê sem dificuldade. Para o laço,
não é chamada nenhuma:

```
ana@lab:~/pe$ agent runs/paren.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Thought: Four soups at R$ 27.90.
  model> Action: calculator(4 * 27.90)
stopped: the reply has neither an Action nor an Answer
```

**Parar é a resposta certa**: adivinhar o que uma linha malformada quis dizer é como um laço acaba
executando uma chamada que ninguém escreveu. Um sistema de verdade mandaria ao modelo uma mensagem
curta dizendo qual é o formato e tentaria mais uma vez, do jeito que a lição 19 conserta uma
resposta que não bate com o esquema.

Uma chamada que o laço CONSEGUE ler ainda pode ser uma que a ferramenta não consegue, e esse é outro
tipo de falha. `27,90` é como se escreve um preço no Brasil, e para a calculadora a vírgula
transforma isso em dois números:

```
ana@lab:~/pe$ agent runs/comma.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Thought: Four soups at R$ 27,90.
  model> Action: calculator[4 * 27,90]
  tool>  error: only numbers and + - * / are allowed
step 2
  model> Thought: The calculator wants a decimal point.
  model> Action: calculator[4 * 27.90]
  tool>  111.6
step 3
  model> Answer: R$ 111.60.
done: an answer after 3 steps
```

O erro voltou como Observation, então o turno seguinte pôde lê-lo e corrigir a chamada. **Uma
ferramenta que responde com uma mensagem de erro clara dá ao modelo algo de onde raciocinar**, ao
passo que uma ferramenta que falha calada, ou devolve `0`, entrega a ele um fato errado.

## Uma execução que esgota os passos

`--max-steps` é o número de turnos que o laço reproduz antes de desistir. Aqui está a execução boa da
seção anterior, com limite de dois:

```
ana@lab:~/pe$ agent runs/refund.txt --max-steps 2
tools allowed: calculator, reviews, search, today
step 1
  model> Thought: The handbook has the rules for refunds. I need the one about approval.
  model> Action: search[refund approval manager]
  tool>  refunds.md     A refund above R$ 100 needs the shift manager's approval.
step 2
  model> Thought: Above R$ 100 needs the shift manager. Now the total for four soups.
  model> Action: calculator[4 * 27.90]
  tool>  111.6
stopped: 2 steps and no answer
```

A execução ia a caminho da resposta certa e foi cortada mesmo assim. Esse é o preço de um limite, e
vale pagar. Um modelo que continua buscando com palavras um pouco diferentes, ou chama de novo a
mesma ferramenta porque não confiou na primeira resposta, ficaria em laço até alguém notar a conta
(lição 15). **Uma execução parada no limite é relatada como parada, nunca como respondida**, e quem
chamou pode aumentar o limite, perguntar a uma pessoa, ou desistir com honestidade.

## Uma ferramenta recusada

A lista de permissões padrão do `agent` tem as quatro ferramentas que só leem. O `send_email` muda
algo fora da conversa, então não está na lista a menos que alguém o coloque lá:

```
ana@lab:~/pe$ agent runs/email.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Thought: Above R$ 100 needs the manager. I will ask for approval by e-mail.
  model> Action: send_email[manager@example.com | Please approve a refund of R$ 111.60 for table 4.]
  tool>  refused: send_email is not allowed in this task
step 2
  model> Thought: I may not send e-mail in this task. A person has to ask the manager.
  model> Answer: R$ 111.60 to the card. Ask the shift manager to approve it before refunding.
done: an answer after 2 steps
```

A ideia era razoável e a recusa estava certa mesmo assim. A tarefa era responder a uma pergunta, e
um e-mail ao gerente é uma ação que alguém deveria decidir tomar. Mesmo com o `send_email` na lista,
o `agent` só segura a chamada e não envia nada até uma pessoa confirmar.

## Por que os limites ficam no laço, e não no prompt

Todos os limites acima moram no programa: o padrão que lê uma Action, a lista de ferramentas
permitidas, a contagem de passos, a retenção de tudo o que muda o mundo. Nenhum deles é uma frase
no prompt como "nunca envie e-mail" ou "pare depois de cinco passos".

O motivo é a lição 7. **Uma frase no prompt é um pedido ao modelo, e o comportamento do modelo
depende de tudo o que está no contexto dele**, inclusive o texto que as ferramentas trazem de
volta. Um resultado de busca, uma avaliação ou uma página da web podem conter instruções próprias, e
um modelo que as lê pode segui-las. Um limite imposto pelo laço não se importa com o que o modelo
foi convencido a fazer: a chamada não está na lista, então não roda. Escreva as instruções no prompt
para o modelo se comportar bem, e ponha os limites no código para que não faça diferença quando ele
não se comportar.

::: track ai
O curso `agents-mcp` constrói este laço contra um modelo de verdade, com as ferramentas descritas
num formato padrão, e mantém cada um destes limites no código.
:::

::: track *
Você não precisa construir o laço para usar o que esta lição mostrou. Quando um produto diz que usa
um agente, estas são as perguntas a fazer a ele: o que ele pode chamar, quantos passos pode dar, e
quem confirma uma ação que muda alguma coisa.
:::
