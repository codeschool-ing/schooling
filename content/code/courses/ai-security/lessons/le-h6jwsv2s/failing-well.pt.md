---
title: O que acontece quando uma resposta falha, e os limites em volta
version: 1
---

Um validador que recusa uma resposta fez só metade do trabalho. **O código também precisa decidir o que
acontece em seguida**, e as duas respostas fáceis estão erradas: mostrar a resposta mesmo assim derrota
o validador, e mostrar ao cliente um erro a cada recusa torna o recurso inútil nos dias em que o modelo
está com problemas.

A resposta comum é pedir mais uma vez dizendo ao modelo o que estava errado, e então parar. O laço do
laboratório tem oito linhas:

```schooling-example
{"language": "python", "file": "guardlab/retry.py", "parts": [{"code": "def ask(call, check, attempts=2):\n    feedback = []\n", "note": "`call` pergunta ao modelo e devolve o texto; `check` devolve a lista de problemas, vazia quando a resposta passa. `attempts` é um limite fixo, e dois é a escolha comum."}, {"code": "    for n in range(1, attempts + 1):\n        text = call(feedback)\n        problems = check(text)\n        yield n, problems\n", "note": "Cada tentativa é conferida pelas mesmas regras. Quem chama vê todas as tentativas, para que cada uma possa ir para o log."}, {"code": "        if not problems:\n            return\n        feedback = problems\n", "note": "Uma resposta que passa encerra o laço. Uma que falha entrega os problemas à chamada seguinte, que pode pô-los no prompt: as mensagens do validador são escritas para o modelo ler, além de uma pessoa."}]}
```

No laboratório, o `guard retry` roda este laço com **respostas escritas pelo curso fazendo as vezes das
tentativas do modelo**: o primeiro ID na linha de comando é a primeira tentativa, o segundo é a nova
tentativa. Nenhum modelo é chamado; o que é real é o laço e as verificações. Uma nova tentativa que
funciona, e uma que não:

```
ana@lab:~/guard$ guard retry out-3 out-1; echo "exit $?"
attempt 1  REJECT $.category: 'illustration' is not one of design, development, writing, translation, marketing
           sent back: 1 problem(s) with the previous reply
attempt 2  ok
exit 0
ana@lab:~/guard$ guard retry out-2 out-7; echo "exit $?"
attempt 1  REJECT not JSON: Expecting value at character 0
           sent back: 1 problem(s) with the previous reply
attempt 2  REJECT $.summary: 607 characters, limit 400
                  $.skills: 7 items, limit 5
no valid reply after 2 attempts: the job goes to a person
exit 1
```

Quando as tentativas acabam, o trabalho vai para uma pessoa, e **nada das respostas recusadas chega ao
cliente**. Essa é a regra que mais importa nesta seção: um validador falha fechado. Uma resposta que não
pôde ser conferida é tratada como uma resposta que falhou, porque a alternativa é uma verificação que
só funciona quando nada está errado.

## Os limites que vêm junto

O laço de novas tentativas é um de vários limites, e cada um limita um jeito diferente de uma chamada
ao modelo sair do controle:

| limite | o que ele limita | onde apareceu |
|---|---|---|
| tentativas por requisição | quantas vezes uma requisição é repetida | o laço acima |
| `max_tokens` em cada chamada | o tamanho, e portanto o custo, de uma resposta | a API do fornecedor |
| tamanho de cada campo de entrada | o custo do prompt, e quanto o modelo precisa ler | as regras de entrada |
| tokens por usuário por dia | quanto uma pessoa pode gastar | aula 7 |
| chamadas de ferramenta ou turnos por tarefa | até onde um agente vai antes de parar | aula 10 |

O `max_tokens` merece uma nota porque é fácil defini-lo alto demais, com o argumento de que uma resposta
nunca deve ser cortada. Uma resposta cujo resumo o schema limita a 400 caracteres nunca precisa de
milhares de tokens. Um limite perto do que o schema permite transforma uma resposta prolixa numa que
falha rápido e barato, e o laço de novas tentativas cuida dela a partir dali.

## Conte as recusas

Toda recusa vai para o log com o id da requisição, como a aula 11 recomenda, com o caminho e a regra que
falhou. Contadas por dia, as recusas são um dos números mais úteis que este recurso produz. Uma taxa que
sobe depois de uma mudança de prompt ou de uma atualização do modelo é o primeiro sinal de que algo
mudou, e chega antes de qualquer cliente reclamar. A camada de métricas da aula 11 é o lugar dela: uma
contagem por dia, sem texto nenhum, guardada tanto quanto as outras contagens.
