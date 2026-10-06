---
title: Medindo uma transcrição: a taxa de erro de palavras
version: 1
---

A **taxa de erro de palavras (WER)** conta o menor número de edições de uma palavra que transformam uma transcrição na verdade, e divide pelo número de palavras da verdade. Três tipos de edição:

- uma **substituição** (S), uma palavra ouvida como outra: *Kau* por *Caio*;
- uma **remoção** (D, de *deletion*), uma palavra que foi dita e falta;
- uma **inserção** (I), uma palavra que não foi dita e aparece.

WER = (S + D + I) / N, em que N é o número de palavras realmente ditas. Como as inserções contam, uma transcrição cheia de palavras inventadas pode passar de 100%.

O `jiwer` calcula e consegue mostrar o alinhamento, palavra por palavra. Aqui estão duas falas, da Bia e do Caio, cada uma recortada da ligação pelos tempos do próprio roteiro e transcrita sozinha:

```python
"""Each turn of the call cut out by the script's own times and transcribed alone, aligned with what was said."""
import json
import sys

import jiwer

import mmlab
from measure import words

turns = json.load(open("media/truth/call-1042.json"))["turns"]
samples = mmlab.read_audio("media/call-1042.wav")
whisper = mmlab.whisper(sys.argv[1], language="en")
pick = [int(n) for n in sys.argv[2:]]
said, heard = [], []
for i in pick:
    t = turns[i]
    text, _ = mmlab.transcribe(whisper, samples[int(t["start"] * mmlab.RATE):int(t["end"] * mmlab.RATE)])
    said.append(words(t["text"]))
    heard.append(words(text))
print(jiwer.visualize_alignment(jiwer.process_words(said, heard), show_measures=False))
```

```
ana@lab:~/mm$ python turns.py base 1 2
=== SENTENCE 1 ===

REF: hi caio im calling about order m1042 its a copy of dom casmurro by machado     de assis and it arrived on the twentyfourth of september
HYP: hi  kau im calling about order m1042 its a copy of dom  kazmuro by machado desiss ***** and it arrived on  24 ************ ** september
           S                                                       S                 S     D                     S            D  D          

=== SENTENCE 2 ===

REF: let me pull that up yes i can see it here one copy of dom  casmurro delivered on the twentyfourth what seems to be the problem
HYP: let me pull that up yes i can see it here one copy of dom casmorrow delivered on the         24th what seems to be the problem
                                                                       S                             S                             
```

As marcas sob cada linha são o veredito do alinhamento. *kau* por *caio* é um **S**. *machado desiss* por *machado de assis* são duas substituições e uma remoção, porque o modelo escreveu duas palavras onde foram ditas três. E três dos erros da primeira linha não são erros: *24* por *twentyfourth*, e o *the* e o *of* que vêm junto. **O modelo escreveu a data como número, e a verdade a escreve por extenso.**

## Meça o que você quer medir

Esse último ponto decide mais do que qualquer escolha de modelo. A mesma transcrição do base da ligação inteira, pontuada de três jeitos:

```python
"""The same transcript scored three ways: as written, without case and punctuation, and with numbers as words."""
import re
import sys

import jiwer
from num2words import num2words

import mmlab
from measure import transcript, words

truth = open("media/truth/call-1042.txt").read()
heard, _ = transcript(mmlab.read_audio("media/call-1042.wav"), mmlab.whisper(sys.argv[1], language="en"))


def spelled(text):
    """24th -> twenty-fourth, 10 -> ten: numbers written as the words they were spoken as."""
    text = re.sub(r"\b(\d+)(st|nd|rd|th)\b", lambda m: num2words(int(m[1]), to="ordinal"), text)
    return re.sub(r"(?<![\w-])\d+(?![\w-])", lambda m: num2words(int(m[0])), text)


print(f"as written:                  WER {jiwer.wer(truth, heard):6.1%}")
print(f"no case, no punctuation:     WER {jiwer.wer(words(truth), words(heard)):6.1%}")
print(f"and numbers spelled out:     WER {jiwer.wer(words(spelled(truth)), words(spelled(heard))):6.1%}")
```

```
ana@lab:~/mm$ python fairly.py base
as written:                  WER  18.5%
no case, no punctuation:     WER  12.6%
and numbers spelled out:     WER  13.2%
```

Pontuada **como escrita**, 18,5%: toda letra maiúscula e toda vírgula que diferem contam como palavra errada. **Sem maiúsculas e pontuação**, a medida que toda transcrição deste curso usa, 12,6%. **Com os números por extenso dos dois lados**, 13,2%: melhor para *24th*, pior para *3480*, que o `num2words` escreve como *three thousand, four hundred and eighty* onde o Caio disse *thirty-four eighty*. Nenhum dos dois jeitos de escrever esse número está errado; são duas formas de escrever um mesmo som.

Então **um WER só se compara com outro WER normalizado do mesmo jeito**. O número de um fornecedor medido com a normalização dele e o seu medido com os padrões do jiwer são dois números diferentes com o mesmo nome. Quando comparar modelos, rode os dois no mesmo áudio, pela mesma função `words()`, contra a mesma verdade, e a comparação passa a significar algo.
