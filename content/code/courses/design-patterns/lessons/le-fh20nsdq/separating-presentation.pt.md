---
title: Três tarefas que mudam em ritmos diferentes
version: 1
---

**O MVC costuma ser descrito como três pastas, `models/`, `views/` e `controllers/`, e diz-se que
um projeto que as tem segue o padrão.** As pastas são uma consequência. A ideia por baixo de todos
os padrões desta lição é mais antiga e mais simples: um programa com tela faz três tarefas
diferentes, e cada uma muda por um motivo diferente. Mantê-las separadas permite que cada uma mude
sem arrastar as outras duas junto.

As três tarefas são estas. As **regras**: um membro pode ter tantos empréstimos, uma devolução
atrasada custa 50 centavos por dia. A **apresentação**: o que a tela mostra e como está organizado.
A **entrada**: transformar uma tecla, um clique ou uma requisição HTTP em algo que o programa deve
fazer. A biblioteca muda as regras quando o conselho se reúne, a tela quando alguém a redesenha, e a
entrada quando o balcão passa do teclado para o navegador e do navegador para o celular. Três
calendários.

Crie `~/patterns/presentation` e trabalhe nele durante a lição inteira:

```sh
mkdir -p ~/patterns/presentation
cd ~/patterns/presentation
```

## Um balcão de empréstimos com as três tarefas num laço só

Aqui está o balcão escrito do jeito que a maioria das primeiras versões é escrita. Ele lê comandos
do teclado, um por linha, e responde a cada um:

```python
# tangled.py
import sys

LIMIT = 2
shelf = ["B1", "B2", "B3"]
loans = {}

for line in sys.stdin:
    cmd, *args = line.split()
    if cmd == "lend":
        code, member = args
        held = [c for c, m in loans.items() if m == member]
        if code not in shelf:
            print(f"*** {code} is not on the shelf ***")
        elif len(held) >= LIMIT:
            print(f"*** {member} already has {LIMIT} loans ***")
        else:
            shelf.remove(code)
            loans[code] = member
            print(f"{code} lent to {member}. On the shelf: {', '.join(shelf)}")
    elif cmd == "return":
        shelf.append(args[0])
        del loans[args[0]]
        print(f"{args[0]} is back. On the shelf: {', '.join(shelf)}")
```

O limite é de dois empréstimos para a transcrição ficar curta; a regra de verdade da biblioteca é
cinco, e a lição 12 transforma esse número numa invariante. O `printf` digita os quatro comandos
por você, então toda execução da transcrição é igual:

```
ana@laptop:~/patterns/presentation$ printf 'lend B1 bia\nlend B2 bia\nlend B3 bia\nreturn B1\n' | python3 tangled.py
B1 lent to bia. On the shelf: B2, B3
B2 lent to bia. On the shelf: B3
*** bia already has 2 loans ***
B1 is back. On the shelf: B3, B1
```

Funciona. Agora leia procurando onde mora cada tarefa. A regra "no máximo dois empréstimos" é o
`elif` do meio, espremido entre duas chamadas a `print`. O formato da linha da estante está escrito
duas vezes, uma depois de um empréstimo e outra depois de uma devolução, e nada obriga as duas a
concordarem. O formato da entrada, `lend B1 bia`, é desmontado na mesma linha de onde a regra lê os
argumentos.

## O que o emaranhado custa

Três pedidos mostram o preço, e cada um é corriqueiro.

**Para testar a regra, você precisa dirigir o teclado e ler a tela.** Não existe função a chamar
que responda "a Bia pode levar o B3?". Um teste precisa mandar texto pela entrada padrão e procurar
asteriscos na saída, e ele quebra no dia em que alguém troca `***` por `!!`, sem que regra nenhuma
tenha mudado.

**Para acrescentar uma página web, você copia a regra.** Um navegador manda uma requisição, não uma
linha na entrada padrão, então o laço não pode ser reaproveitado. Quem escreve a página escreve a
verificação do limite de novo, e dali em diante o balcão e a web têm duas cópias dela. O conselho
sobe o limite para cinco; uma das cópias é atualizada.

**Para mudar o layout, você edita o arquivo das regras.** Pôr a lista da estante numa linha própria
significa editar o mesmo bloco que tira um livro da estante, e quem está redesenhando agora precisa
entender de empréstimos para não quebrar um.

Nada disso importa num script que nunca vai ganhar uma segunda tela, e a lição 19 é honesta sobre
isso. Importa na primeira vez que chega uma segunda tela, um teste ou um redesenho.

## O primeiro movimento de todos os padrões daqui

**Todo padrão desta lição começa tirando as regras para um modelo que não sabe nada de telas nem de
teclados.** Martin Fowler chama isso de *separated presentation*, apresentação separada, e é a parte
em que todos concordam. Onde eles divergem é em como dividem as outras duas tarefas, e numa pergunta
que acaba decidindo quase todo o resto: quando o estado muda, quem avisa a tela?

- No MVC, a view observa o modelo e se redesenha sozinha.
- No MVP, um presenter diz a uma view passiva exatamente o que mostrar.
- No MVVM, a view se liga a propriedades de um view-model e se atualiza quando elas mudam.

As próximas seções constroem cada um sobre o mesmo arquivo de modelo, de modo que o que muda entre
eles é só o lado da apresentação. O modelo é o primeiro programa da próxima seção.
