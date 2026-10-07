---
title: Um conjunto de teste decide, não uma impressão
version: 2
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

O `label.py` roda um modelo de prompt sobre o conjunto de teste: põe cada mensagem onde está
`{message}`, pergunta ao modelo na temperatura 0 e escreve cada resposta numa linha, na mesma ordem
dos testes:

```
ana@lab:~/pe$ cat label.py
import subprocess, sys

template = open(sys.argv[1], encoding="utf-8").read()
for line in open(sys.argv[2], encoding="utf-8"):
    tid, want, text = line.rstrip("\n").split("\t")
    prompt = template.replace("{message}", text)
    reply = subprocess.run(["ask", prompt, "--temperature", "0", "--plain"],
                           capture_output=True, text=True).stdout
    print(" ".join(reply.split()))
ana@lab:~/pe$ python3 label.py prompts/weak.txt tests.tsv > replies-weak.txt
ana@lab:~/pe$ cat replies-weak.txt
This review is positive. The reviewer mentions that the cinnamon bun and oat flat white were "perfect", which suggests a high level of satisfaction with their experience. They also express a desire to return, indicating that they will likely be a repeat customer.
This review is mixed, but leaning towards being slightly negative. The reviewer waited a long time for their tea, which is a inconvenience, but they mention that the staff were "kind about it", which suggests that the staff's attitude made up for the wait. However, the wait itself is still a negative experience.
This review is negative. The reviewer mentions that the soup was cold, which is a significant flaw in the food, and that no one came to take it back, implying poor customer service.
This review is positive. The reviewer is expressing their satisfaction with the bread, stating that it is the "best" in the neighborhood and that it is still warm at 8, implying that it is freshly baked and of high quality.
This review is positive. The reviewer mentions "Great" and "Wonderful service", which indicate a high level of satisfaction with their experience.
This review is neutral. It's a question being asked, rather than a statement or opinion, so it doesn't convey a positive or negative sentiment.
This review is mixed, but leaning towards being slightly negative. The reviewer mentions that the cake was "dry", which is a negative characteristic. However, they also mention that the coffee was a redeeming factor, which suggests that the reviewer was able to find some positive aspect of their experience. Overall, the tone is somewhat lukewarm and disappointed, but not entirely negative.
Essa review é positiva. Embora o texto seja em português e não contenha muitas palavras, a presença de "estava ótimo" e "também" indica que o reviewer gostou do pão de queijo e do café.
ana@lab:~/pe$ python3 score.py tests.tsv replies-weak.txt
r1  wanted positive      got This review is positive. The reviewer mentions that the cinnamon bun and oat flat white were "perfect", which suggests a high level of satisfaction with their experience. They also express a desire to return, indicating that they will likely be a repeat customer.
r2  wanted mixed         got This review is mixed, but leaning towards being slightly negative. The reviewer waited a long time for their tea, which is a inconvenience, but they mention that the staff were "kind about it", which suggests that the staff's attitude made up for the wait. However, the wait itself is still a negative experience.
r3  wanted negative      got This review is negative. The reviewer mentions that the soup was cold, which is a significant flaw in the food, and that no one came to take it back, implying poor customer service.
r4  wanted positive      got This review is positive. The reviewer is expressing their satisfaction with the bread, stating that it is the "best" in the neighborhood and that it is still warm at 8, implying that it is freshly baked and of high quality.
r5  wanted negative      got This review is positive. The reviewer mentions "Great" and "Wonderful service", which indicate a high level of satisfaction with their experience.
r6  wanted not_a_review  got This review is neutral. It's a question being asked, rather than a statement or opinion, so it doesn't convey a positive or negative sentiment.
r7  wanted mixed         got This review is mixed, but leaning towards being slightly negative. The reviewer mentions that the cake was "dry", which is a negative characteristic. However, they also mention that the coffee was a redeeming factor, which suggests that the reviewer was able to find some positive aspect of their experience. Overall, the tone is somewhat lukewarm and disappointed, but not entirely negative.
r8  wanted positive      got Essa review é positiva. Embora o texto seja em português e não contenha muitas palavras, a presença de "estava ótimo" e "também" indica que o reviewer gostou do pão de queijo e do café.
0 of 8 right
```

**Nenhuma de oito.** Cada resposta é um parágrafo, e o `score.py` compara um parágrafo com uma
palavra. Olhe além da forma, e as falhas ainda não são todas o mesmo problema:

- `r1` a `r4` e `r7` trazem o rótulo certo, dentro de uma frase. **A resposta certa na forma
  errada** é uma resposta errada para um programa. O prompt nunca disse qual forma a resposta tem.
- `r6` é a pergunta, e desta vez o modelo não a respondeu: inventou um rótulo, `neutral`, que o café
  não usa. O prompt nunca disse que uma mensagem podia ser outra coisa além de uma avaliação, nem
  como chamá-la.
- `r8` é um rótulo na língua errada. A mensagem estava em português, e a resposta também; o prompt
  nunca disse em que língua vêm os rótulos.
- `r5` é o sarcasmo, lido ao pé da letra: "Great" e "Wonderful service" são palavras positivas.

O prompt forte diz as quatro coisas em voz alta: a forma, as perguntas, a língua e o sarcasmo:

```
ana@lab:~/pe$ python3 label.py prompts/strong.txt tests.tsv > replies-strong.txt
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

Sete de oito, e a que sobra é `r5`, **o sarcasmo, mesmo com o prompt forte citando o sarcasmo como
caso de borda**. Esse é o resultado útil. A contagem diz que a forma, a língua e as perguntas foram
resolvidas, e diz exatamente o que não foi.

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
