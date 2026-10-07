---
title: Cinco tarefas na Marginalia
version: 1
---

A loja para a qual este curso trabalha é a Marginalia, a livraria online cuja central de ajuda foi buscada por significado em `embeddings-vectors`, usada para responder em `rag` e entregue a um agente em `agents-mcp`. Ela não existe, e a mídia dela é feita por um programa desta aula. Ela tem cinco tarefas que uma pessoa faz hoje e que um modelo multimodal poderia assumir, e elas são o fio do curso.

| a tarefa | hoje | as aulas |
|---|---|---|
| lançar as notas fiscais dos fornecedores no estoque | alguém digita | 2 e 8 |
| manter um registro pesquisável das ligações de suporte | ninguém faz; as ligações se perdem | 5, 7 e 10 |
| legendar e descrever o vídeo "como devolver um livro" | não é feito, o que exclui clientes surdos e cegos | 4 e 14 |
| fazer banners para a newsletter semanal | um freelancer, quando há verba | 3 e 9 |
| atender o telefone com o status do pedido | a mesma pessoa que responde os e-mails | 6 |

Aqui vai uma primeira prova de três delas, cada uma com um modelo real rodando na sua máquina. Os primeiros oito segundos de uma ligação de suporte, pelo Whisper; a nota fiscal, pelo Tesseract; e uma fotografia e a nota fiscal, pelo detector de objetos do MediaPipe. São dois programas curtos, e o terceiro leitor é o próprio comando `tesseract`.

`listen.py`, o Whisper:

```python
"""The first eight seconds of the support call, through Whisper base."""
import mmlab

samples = mmlab.read_audio("media/call-1042.wav")
text, lang = mmlab.transcribe(mmlab.whisper("base"), samples[: 8 * mmlab.RATE])
print(lang, "|", text)
```

`look.py`, o detector:

```python
"""What MediaPipe's object detector finds in each picture named on the command line."""
import sys

import mediapipe as mp

import mmlab

with mmlab.detector() as det:
    for path in sys.argv[1:]:
        found = det.detect(mp.Image.create_from_file(path)).detections
        print(path, [(d.categories[0].category_name, round(d.categories[0].score, 2)) for d in found] or "nothing")
```

```
ana@lab:~/mm$ python listen.py
en | Good morning, you're through to Marginalia support. My name is Kau. How can it help? Hi Kau, I'm calling about Order M.
ana@lab:~/mm$ tesseract media/invoice-0931.png - 2>/dev/null | head -4
Lantern & Quill Distributors

Rua das Palmeiras 210, Campinas SP
billing@lanternquill.example.com
ana@lab:~/mm$ python look.py media/cat_and_dog.jpg media/invoice-0931.png
INFO: Created TensorFlow Lite XNNPACK delegate for CPU.
media/cat_and_dog.jpg [('cat', 0.78), ('dog', 0.76)]
media/invoice-0931.png [('book', 0.51)]
```

Cada uma das três respostas parece boa à primeira vista, e cada uma está errada em algum ponto.

**A transcrição** acerta o nome da loja e erra o nome do atendente: Caio vira *Kau*, duas vezes. Ela também para no meio do número do pedido, porque os oito segundos acabaram ali. A aula 7 mede com que frequência isso acontece e o que fazer com nomes.

**O Tesseract** leu as primeiras linhas da nota fiscal perfeitamente. Essa é a cópia limpa. A escaneada, na aula 2, é outra história.

**O detector** achou um gato e um cachorro na fotografia, que é aquilo para o que foi treinado. Ele também olhou uma nota fiscal e disse `book`, com 51% de confiança. Não está exatamente errado: a página traz os títulos de quatro livros. Mas o detector só conhece 80 tipos de coisa, e quando vê algo novo escolhe o mais próximo deles. Esse hábito ganha um nome na aula 2, e todo modelo deste curso o tem de alguma forma.

Nada disso é motivo para não usar os modelos. É o motivo de toda tarefa da tabela ser medida antes que alguém confie nela.
