---
title: As palavras da própria loja
version: 2
---

Um modelo de fala é treinado com fala em geral, e todo negócio tem palavras que a fala em geral não tem: nomes de produtos, nomes de pessoas, códigos, jargão. São também as palavras que mais importam nas transcrições dele. Na ligação, as palavras que o Whisper errou são quase todas desse tipo: *Kau* e *Kyo* por Caio, *Dom Kazmuro* e *Dom Casmorrow* por Dom Casmurro, *Machado Desiss* por Machado de Assis, *M1042* por M-1042.

Há três lugares para corrigi-las, e só o último roda neste laboratório.

**Antes de decodificar, inclinando o modelo.** Algumas APIs hospedadas recebem uma lista de palavras a favorecer. O endpoint de transcrição da OpenAI recebe um `prompt`: um texto que o Whisper trata como o que veio antes do áudio, de modo que as grafias dele ficam mais prováveis. Os serviços do Google e da Amazon recebem listas de frases. A aula 10 mostra onde o prompt entra, e por que o `audio_server.py` do curso o aceita e não consegue usá-lo: a exportação ONNX do Whisper que ele roda não tem como recebê-lo.

**Treinando**, com gravações dos seus próprios falantes dizendo as suas próprias palavras. É a correção mais forte e a mais cara, e está fora do alcance deste curso.

**Depois de decodificar, corrigindo o texto contra o que a loja sabe.** A loja tem um catálogo, então sabe como se escreve todo título e todo autor. Um programa pode procurar sequências de palavras escritas quase como uma delas, e trocá-las.

Primeiro o catálogo. O de uma loja de verdade tem milhares de linhas; este tem doze, o bastante para a ligação. Salve-o como `data/books.jsonl` no `~/mm`, um livro por linha:

```json
{"title": "Dom Casmurro", "author": "Machado de Assis"}
{"title": "The Posthumous Memoirs of Brás Cubas", "author": "Machado de Assis"}
{"title": "Bleak House", "author": "Charles Dickens"}
{"title": "Great Expectations", "author": "Charles Dickens"}
{"title": "The Secret Garden", "author": "Frances Hodgson Burnett"}
{"title": "Pride and Prejudice", "author": "Jane Austen"}
{"title": "Emma", "author": "Jane Austen"}
{"title": "Jane Eyre", "author": "Charlotte Brontë"}
{"title": "Middlemarch", "author": "George Eliot"}
{"title": "Madame Bovary", "author": "Gustave Flaubert"}
{"title": "Anna Karenina", "author": "Leo Tolstoy"}
{"title": "Crime and Punishment", "author": "Fyodor Dostoevsky"}
```

Depois o programa que o usa:

```schooling-example
{
  "language": "python",
  "file": "lexicon.py",
  "parts": [
    {
      "code": "\"\"\"Correct a transcript against the words this shop knows: its name, its staff, its books and their authors.\"\"\"\nimport difflib\nimport json\nimport re\n\n"
    },
    {
      "code": "books = [json.loads(line) for line in open(\"data/books.jsonl\")]\nKNOWN = sorted({\"Marginalia\", \"Caio\"} | {b[\"title\"] for b in books} | {b[\"author\"] for b in books}, key=len, reverse=True)\n\n\n",
      "note": "**As palavras que esta loja conhece**: o nome dela, o nome de quem atende, e todo título e autor do catálogo. Os mais longos primeiro, para *Machado de Assis* ser tentado antes de qualquer nome de uma palavra dentro dele."
    },
    {
      "code": "def correct(text, cutoff=0.75):\n    \"\"\"Replace any run of words that is spelt like a known name, but is not it, with the name.\"\"\"\n    fixes = []\n    tokens = text.split()\n    for name in KNOWN:\n        n, i = len(name.split()), 0\n        while i < len(tokens):\n            best = None\n            for size in {max(1, n - 1), n, n + 1}:\n                window = \" \".join(tokens[i:i + size])\n                bare = re.sub(r\"[^\\w ]\", \"\", window).lower()\n",
      "note": "**Para cada nome conhecido, toda janela de palavras com mais ou menos o tamanho dele.** Uma janela uma palavra menor ou maior também é testada, porque o Whisper separa e junta palavras: *Desiss* é uma palavra onde o nome tem duas."
    },
    {
      "code": "                if name.lower() in bare:                 # the name is already there, spelt right\n                    best = None\n                    break\n                first = bare.split()[0] if bare else \"\"\n                if difflib.SequenceMatcher(None, first, name.lower().split()[0]).ratio() < 0.5:\n                    continue                             # a window must start where the name starts\n",
      "note": "**Duas recusas antes de qualquer nota.** Uma janela que já contém o nome fica como está, e uma janela precisa começar com algo parecido com a primeira palavra do nome, para que *by Machado Desiss* nunca seja tomado pelo nome e o *by* se perca."
    },
    {
      "code": "                score = difflib.SequenceMatcher(None, bare, name.lower()).ratio()\n                if score >= cutoff and (best is None or score > best[0]):\n                    best = (score, size, window)\n",
      "note": "**Semelhança de grafia**, de 0 a 1, e a melhor janela acima de 0,75 vence. Isto compara letras, não sons, e é exatamente por isso que vai deixar passar alguns erros (seção 05)."
    },
    {
      "code": "            if best:\n                score, size, window = best\n                tail = window[len(window.rstrip(\",.?!\")):]\n                tokens[i:i + size] = (name + tail).split()\n                fixes.append(f\"{window!r} -> {name!r} ({score:.2f})\")\n                i += n                                   # carry on after the name just written\n            else:\n                i += 1\n",
      "note": "**Trocar, registrar o que foi feito e seguir depois do nome recém-escrito.** Toda mudança é listada, para que uma pessoa veja o que o programa decidiu e possa discordar."
    },
    {
      "code": "    text = \" \".join(tokens)\n    text, n = re.subn(r\"\\bM ?(\\d{4})\\b\", r\"M-\\1\", text)             # an order number has a hyphen\n    fixes += [\"M nnnn -> M-nnnn\"] * n\n    return text, fixes",
      "note": "**Um número de pedido é um padrão, não um nome**, então ganha uma regra: uma letra e quatro dígitos viram `M-1042`, com o hífen que a loja escreve."
    }
  ]
}
```

```python
"""The base transcript, before and after the shop's lexicon, scored against the script."""
import mmlab
from lexicon import correct
from measure import transcript, wer

truth = open("media/truth/call-1042.txt").read()
heard, _ = transcript(mmlab.read_audio("media/call-1042.wav"), mmlab.whisper("base", language="en"))
fixed, fixes = correct(heard)
for f in fixes:
    print("  ", f)
print(f"WER before {wer(truth, heard):6.1%}   after {wer(truth, fixed):6.1%}")
```

```
ana@lab:~/mm$ python fix.py
   'Machado Desiss' -> 'Machado de Assis' (0.87)
   'Dom Kazmuro' -> 'Dom Casmurro' (0.78)
   'Dom Casmorrow' -> 'Dom Casmurro' (0.88)
   M nnnn -> M-nnnn
WER before  12.6%   after   9.9%
```

Três correções e um número de pedido reformatado, e o WER caiu de **12,6% para 9,9%**. Toda correção é impressa com a nota dela, e é assim que se percebe quando o limite está frouxo demais: uma versão anterior deste programa, sem a regra "precisa começar como o nome", transformou *by Machado Desiss* em *Machado de Assis* e apagou o *by*.

## O que ele não consegue corrigir

**Caio continua *Kau* e *Kyo*.** A semelhança de grafia compara letras, e *kau* e *caio* quase não têm nenhuma em comum (0,29). Soam parecido e se escrevem diferente, e uma comparação de grafia é a ferramenta errada para palavras que soam igual. Uma comparação fonética (Soundex, Metaphone, ou os fonemas que a aula 6 imprimiu) pegaria algumas; para o nome do próprio atendente, a correção mais barata é o sistema de telefonia saber quem atendeu.

**Um número errado não é um nome mal escrito.** O tiny ouviu *M-1042* como *M 142*, um dígito perdido. Nenhuma lista de palavras recupera um dígito perdido, e "corrigi-lo" para o número de pedido válido mais próximo seria inventar dados. O que a loja pode fazer é conferir: o pedido M-142 existe? Não existe, então a transcrição é marcada para uma pessoa, o mesmo movimento da nota da aula 2 conferindo a si mesma.
