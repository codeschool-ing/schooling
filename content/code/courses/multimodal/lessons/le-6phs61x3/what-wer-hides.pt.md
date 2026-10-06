---
title: O que a taxa de erro de palavras não diz
version: 1
---

Um WER trata toda palavra igual. *The* e *Casmurro* contam o mesmo, e também um *a* perdido e um dígito errado num número de pedido. Para uma loja, as palavras que importam são um conjunto pequeno, e o acerto delas merece um número próprio:

```python
"""How many of the shop's own words came out exactly right, which a word error rate does not say."""
import mmlab
from lexicon import correct
from measure import transcript, words

TERMS = ["Marginalia", "Caio", "M-1042", "Dom Casmurro", "Machado de Assis"]
truth = words(open("media/truth/call-1042.txt").read())
samples = mmlab.read_audio("media/call-1042.wav")
for size in ("tiny", "base"):
    heard, _ = transcript(samples, mmlab.whisper(size, language="en"))
    for label, text in (("as heard", heard), ("corrected", correct(heard)[0])):
        got = sum(min(words(text).count(words(t)), truth.count(words(t))) for t in TERMS)
        want = sum(truth.count(words(t)) for t in TERMS)
        print(f"{size:4} {label:9} {got} of {want} mentions of the shop's terms right")
```

```
ana@lab:~/mm$ python names.py
tiny as heard  1 of 8 mentions of the shop's terms right
tiny corrected 4 of 8 mentions of the shop's terms right
base as heard  3 of 8 mentions of the shop's terms right
base corrected 6 of 8 mentions of the shop's terms right
```

A ligação cita os termos da loja oito vezes: Marginalia duas, Caio duas, M-1042 uma, Dom Casmurro duas e Machado de Assis uma. **O tiny acertou 1 dos 8**, e o base 3. Depois do léxico, o tiny acertou 4 e o base 6. É uma mudança muito maior que a do WER, de 12,6% para 9,9%, e é a mudança que importa à loja: uma transcrição que diz Dom Casmurro é encontrada por quem busca Dom Casmurro.

Então meça as duas coisas: o **WER** para a transcrição inteira, e o **acerto de termos** para as palavras de que o negócio vive. Um modelo que melhora a primeira e piora a segunda é pior para você, e só o segundo número diria isso.

## Montando um conjunto de teste confiável

Todo número desta aula veio de uma ligação, de 151 palavras, com a verdade conhecida porque o laboratório a fez. Uma decisão real precisa de mais, e montá-lo é um trabalho sem glamour:

1. **Amostre gravações reais**, nas condições que você vai encontrar: telefone e aplicativo, silêncio e ruído, cada sotaque dos seus clientes, cada idioma.
2. **Peça a uma pessoa que as transcreva**, com regras escritas para números, nomes e pontuação, para que dois transcritores concordem entre si. As regras são a normalização da seção 02.
3. **Marque os termos que importam** em cada verdade, para o acerto de termos poder ser contado.
4. **Mantenha o conjunto fixo**, e rode todo modelo candidato e toda mudança (um filtro, um léxico, um prompt) contra ele inteiro.

Algumas dezenas de gravações bastam para distinguir o tiny do base, e não bastam para distinguir dois bons modelos hospedados; uma diferença de um ou dois pontos de WER precisa de horas de áudio para ser real. O conjunto de teste é o bem que sobrevive a todo modelo que você testar nele.
