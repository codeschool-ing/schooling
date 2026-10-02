---
title: Um conjunto de teste decide, não uma impressão
version: 1
---

O jeito comum de julgar um prompt é testá-lo em uma ou duas entradas, ler as respostas e concluir
que parece bom. Isso julga as entradas que você por acaso escolheu, e é assim que o prompt fraco da
seção de leitura anterior passaria: teste numa avaliação entusiasmada, receba `positive`, publique.
**Um prompt é julgado por um conjunto de teste**: um punhado de entradas cujas respostas certas uma
pessoa decidiu antes, passadas pelo prompt e contadas.

## Oito mensagens com rótulos conhecidos

Este é um conjunto de teste para o rotulador do café. Cada linha tem um id, o rótulo que uma pessoa
deu e a mensagem, separados por tabulações:

```
ana@lab:~/pe$ cat tests.tsv
r1	positive	Lovely cinnamon bun and the oat flat white was perfect. Will come back on Sunday.
r2	mixed	Waited fifteen minutes for a tea at noon. The staff were kind about it.
r3	negative	The soup was cold and nobody came to take it back.
r4	positive	Best bread in the neighbourhood, still warm at eight.
r5	negative	Great, another forty minutes for a coffee. Wonderful service.
r6	not_a_review	Do you open on public holidays?
r7	mixed	The cake was dry but the coffee made up for it.
r8	positive	O pão de queijo estava ótimo e o café também.
```

Ele é pequeno de propósito, e não é aleatório. **Cada linha está ali por um motivo.** `r1` e `r3`
são os casos fáceis que qualquer prompt deveria acertar. `r2` e `r7` são mistos. `r5` é irônico.
`r6` é uma pergunta. `r8` está em português. Um conjunto de teste só com casos fáceis daria nota
boa a todo prompt e não lhe diria nada.

Pontuar é comparar, então um programa curto faz isso. Ele lê o conjunto de teste e um arquivo de
respostas, uma por linha na mesma ordem, imprime cada divergência e conta os acertos:

```
ana@lab:~/pe$ cat score.py
import sys

tests = [line.rstrip("\n").split("\t") for line in open(sys.argv[1], encoding="utf-8")]
replies = [line.rstrip("\n") for line in open(sys.argv[2], encoding="utf-8")]
right = 0
for (tid, want, text), got in zip(tests, replies):
    if got == want:
        right += 1
    else:
        print("%s  wanted %-13s got %s" % (tid, want, got))
print("%d of %d right" % (right, len(tests)))
```

## Pontuando o prompt fraco e o forte

Nenhum modelo foi chamado nesta lição, então as respostas abaixo foram **escritas pelo curso como
substitutas** do que um modelo poderia devolver a cada prompt. A pontuação delas é real. Primeiro,
as respostas ao prompt fraco:

```
ana@lab:~/pe$ cat replies-weak.txt
Positive!
Mixed: the wait was long, but the staff were kind.
negative
positive
positive
On public holidays the café follows the Sunday hours.
mixed
Positivo
ana@lab:~/pe$ python3 score.py tests.tsv replies-weak.txt
r1  wanted positive      got Positive!
r2  wanted mixed         got Mixed: the wait was long, but the staff were kind.
r5  wanted negative      got positive
r6  wanted not_a_review  got On public holidays the café follows the Sunday hours.
r8  wanted positive      got Positivo
3 of 8 right
```

Três de oito. Leia as cinco falhas por tipo, porque não são o mesmo problema:

- `r1` e `r2` são o rótulo certo na forma errada. `Positive!` não é `positive` para um programa. O
  prompt nunca disse que forma a resposta tem.
- `r6` é o modelo respondendo à pergunta do cliente em vez de rotulá-la. O prompt nunca disse que
  uma mensagem podia ser outra coisa além de uma avaliação.
- `r8` é um rótulo no idioma errado. O prompt nunca disse em que idioma os rótulos estão.
- `r5` é a ironia, lida ao pé da letra.

O prompt forte diz as cinco com todas as letras: a forma, as perguntas, o idioma e a ironia. As
respostas dele:

```
ana@lab:~/pe$ cat replies-strong.txt
positive
mixed
negative
positive
positive
not_a_review
mixed
positive
ana@lab:~/pe$ python3 score.py tests.tsv replies-strong.txt
r5  wanted negative      got positive
7 of 8 right
```

Sete de oito, e a que sobra é a `r5`, **a ironia, mesmo com o prompt forte nomeando a ironia como
caso-limite**. Esse é o resultado útil. A contagem diz que o formato, o idioma e as perguntas estão
resolvidos, e diz exatamente o que não está.

## Quando o zero-shot basta, e quando seguir adiante

A contagem decide, contra uma régua que você define antes de rodar. Se o café precisa que toda
reclamação chegue ao gerente, uma reclamação irônica arquivada como `positive` é o único erro que
ele não pode aceitar, e sete de oito não basta, por melhor que pareça.

O que tentar em seguida depende do tipo de falha:

| a falha | o próximo passo |
|---|---|
| a resposta certa na forma errada | declarar o formato; as lições 18 e 19 o conferem |
| um tipo inteiro de entrada não tratado | nomeá-lo no prompt como caso-limite |
| um caso-limite nomeado e ainda errado | mostrá-lo: exemplos, lição 21 |
| o modelo não sabe os fatos | fornecê-los: contexto, lição 24, ou recuperação, lição 11 |

A terceira linha é onde a `r5` está. Uma descrição de ironia não moveu o modelo; um exemplo de
mensagem irônica com o seu rótulo muitas vezes mostra a fronteira melhor que uma frase que a
descreve. Essa é a lição 21.

**Dois avisos sobre o próprio conjunto de teste.** Oito mensagens bastam para achar os tipos de
falha acima e são poucas demais para medir uma taxa de erro: um erro a mais move a nota em doze
pontos e meio. Um conjunto de teste confiável cresce cada vez que uma mensagem real é rotulada
errado, e essa mensagem entra com o rótulo certo. E o conjunto de teste é para testar. Se as
mensagens dele virarem os exemplos do prompt, o prompt vai pontuar bem nelas pelo motivo errado,
coisa a que a lição 21 volta.
