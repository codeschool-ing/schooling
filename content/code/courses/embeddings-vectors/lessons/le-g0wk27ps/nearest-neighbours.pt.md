---
title: Vizinhos mais próximos
version: 1
---

A imagem comum de um classificador é um modelo treinado para a tarefa: milhares de exemplos
rotulados, horas de treino, algo novo para colocar em produção. Com embeddings, o classificador
mais simples que funciona **não tem etapa de treino nenhuma**. Você guarda mensagens que alguém já
separou, e uma mensagem nova recebe o rótulo das que estão mais perto dela.

A equipe de atendimento da Marginalia separou 150 mensagens em cinco setores. O arquivo guarda
cada uma como um objeto JSON por linha, e cada uma diz que parte desta aula pode aprender com ela:

```
ana@lab:~/emb$ head -n 3 data/tickets.jsonl
{"id": "t001", "label": "shipping", "split": "train", "text": "My order was supposed to arrive on Tuesday and it's now Friday. Where is it?"}
{"id": "t002", "label": "shipping", "split": "train", "text": "The tracking page has said 'label created' for four days."}
{"id": "t003", "label": "shipping", "split": "train", "text": "Do you deliver to Portugal and how long does it take?"}
ana@lab:~/emb$ jq -r '.split + " " + .label' data/tickets.jsonl | sort | uniq -c
     10 test account
     10 test ebooks
     10 test payments
     10 test returns
     10 test shipping
     20 train account
     20 train ebooks
     20 train payments
     20 train returns
     20 train shipping
```

As 100 marcadas como `train` são o que um método pode olhar. As 50 marcadas como `test` ficam de
fora para medir o método, dez por setor, e nenhum método desta aula vê os rótulos delas antes de a
nota ser contada. Um conjunto de teste com que o método aprendeu mede memória, não classificação; a
seção *Medindo um classificador* volta a essa separação.

## Gerar os vetores uma vez e guardar

Todo programa desta aula precisa dos mesmos 150 vetores, então o primeiro a rodar calcula os
vetores e grava ao lado dos dados:

```schooling-example
{
  "language": "python",
  "file": "tickets.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport numpy as np\nfrom minilm import embed",
      "note": "Um módulo pequeno que os outros programas importam, para que os 150 tickets virem vetores uma vez só e não uma vez por programa."
    },
    {
      "code": "def load(split):\n    rows = [t for t in map(json.loads, open(\"data/tickets.jsonl\"))\n            if t[\"split\"] == split]",
      "note": "`load(\"train\")` ou `load(\"test\")` lê os tickets de uma das partes, na ordem em que estão no arquivo."
    },
    {
      "code": "    path = f\"{split}.npy\"\n    if not os.path.exists(path):\n        np.save(path, embed([t[\"text\"] for t in rows]))",
      "note": "A primeira chamada transforma os tickets em vetores e grava em `train.npy` ou `test.npy`. As chamadas seguintes acham o arquivo e nem chamam o modelo."
    },
    {
      "code": "    labels = np.array([t[\"label\"] for t in rows])\n    return np.load(path), labels, rows",
      "note": "Devolve três coisas na mesma ordem: os vetores, os rótulos como array do NumPy e os próprios tickets, para imprimir."
    }
  ]
}
```

Os rótulos ficam num array separado, na mesma ordem dos vetores. A linha 7 de `train.npy` é o vetor
do ticket cujo rótulo é `ytr[7]`, e nada mais liga uma coisa à outra; por isso a ordem do arquivo
não pode mudar entre as duas.

## Copiar o rótulo do mais próximo

Uma mensagem nova é comparada com as 100 rotuladas, exatamente como a aula 3 comparou uma pergunta
com os artigos de ajuda. Depois os rótulos das `k` mais próximas são contados, e o mais frequente
vence:

```schooling-example
{
  "language": "python",
  "file": "knn.py",
  "parts": [
    {
      "code": "from collections import Counter\nimport numpy as np\nfrom tickets import load\n\nXtr, ytr, train = load(\"train\")\nXte, yte, test = load(\"test\")\nprint(Xtr.shape, Xte.shape)",
      "note": "Carrega as duas partes. A primeira execução deste programa é a que gera os vetores."
    },
    {
      "code": "S = Xte @ Xtr.T\norder = np.argsort(-S, axis=1)",
      "note": "`Xte @ Xtr.T` é uma tabela 50 × 100: cada ticket de teste comparado com cada ticket de treino. `argsort` das notas com sinal trocado lista, para cada ticket de teste, os de treino do mais perto ao mais longe."
    },
    {
      "code": "def vote(row, k):\n    return Counter(ytr[row[:k]]).most_common(1)[0][0]\n\nfor k in (1, 3, 5, 10):\n    pred = np.array([vote(row, k) for row in order])\n    print(f\"k={k:<3} {(pred == yte).sum()} of {len(yte)} right\")",
      "note": "Pega os rótulos dos `k` mais próximos, conta e fica com o mais frequente. Depois conta quantas das 50 previsões batem com o rótulo verdadeiro."
    }
  ]
}
```

```
ana@lab:~/emb$ python knn.py
(100, 384) (50, 384)
k=1   46 of 50 right
k=3   42 of 50 right
k=5   45 of 50 right
k=10  46 of 50 right
```

Isso é **k vizinhos mais próximos**, ou k-NN. Com `k=1` ele copia o rótulo do único ticket mais
próximo, e **46 dos 50 tickets de teste vão para o setor certo**. Nada foi ajustado aos dados: o
único trabalho foi gerar os vetores e fazer um produto de matrizes.

**Um `k` maior não é automaticamente melhor.** Três vizinhos acertaram 42, cinco acertaram 45 e dez
acertaram 46. Uma votação só muda a resposta quando os vizinhos discordam, e aí dois tickets mais
distantes podem derrotar o mais próximo, para um lado ou para o outro. Um empate é resolvido por
`Counter.most_common`, que devolve o rótulo que encontrou primeiro, e o vizinho mais próximo é o
primeiro encontrado. Ler dois dos erros diz mais do que os totais. `neighbours.py` imprime os cinco
tickets de treino mais próximos de um ticket de teste:

```python
import sys
import numpy as np
from tickets import load

Xtr, ytr, train = load("train")
Xte, yte, test = load("test")
i = [t["id"] for t in test].index(sys.argv[1])
print(test[i]["id"], yte[i], test[i]["text"])
s = Xtr @ Xte[i]
for j in np.argsort(-s)[:5]:
    print(f"  {s[j]:.3f}  {train[j]['id']}  {ytr[j]:9} {train[j]['text']}")
```

```
ana@lab:~/emb$ python neighbours.py t021
t021 shipping Still waiting for my books, ordered almost two weeks ago.
  0.583  t031  returns   I'd like to send back a book I bought last week, it's not what I expected.
  0.572  t016  shipping  I'm moving next week. Will the books still reach me if they're late?
  0.535  t042  returns   I ordered one book and got a completely different title.
  0.523  t020  shipping  Box arrived open and one book is missing.
  0.516  t006  shipping  I only got two of the three books I ordered. Is the third one coming separately?
ana@lab:~/emb$ python neighbours.py t054
t054 returns I sent the book back two weeks ago, where is my refund?
  0.778  t135  ebooks    I downloaded the e-book but now I want a refund.
  0.777  t031  returns   I'd like to send back a book I bought last week, it's not what I expected.
  0.777  t124  ebooks    I bought the wrong e-book by mistake, can I get a refund? I haven't opened it.
  0.567  t036  returns   My aunt gave me a book I already have. Can I return it without her finding out?
  0.513  t020  shipping  Box arrived open and one book is missing.
```

**t021** é uma entrega que não chegou. O vizinho mais próximo é uma devolução, por 0,011, porque os
dois falam de livros comprados há pouco tempo. Os quatro seguintes incluem três tickets de entrega,
então uma votação de cinco acerta onde um vizinho só errou.

**t054** é o mais instrutivo. Três tickets ficam a menos de 0,001 um do outro no topo, e dois dos
três são reembolsos de e-books. O modelo tem razão em pôr os três perto: todos pedem dinheiro de
volta por algo já comprado. O que os separa é uma regra da Marginalia, a de que reembolso de e-book
vai para o setor de e-books, e nada no significado das palavras carrega essa regra. Um
classificador construído sobre semelhança herda toda fronteira que segue o significado e nenhuma
que segue uma política.

## Quanto custa

O k-NN guarda todos os vetores rotulados e compara cada mensagem nova com todos eles. Para 100
tickets isso não é nada. Para um milhão é um problema de busca, o mesmo que a aula 11 apresenta e a
aula 15 torna rápido, e qualquer banco de vetores das aulas 12 a 14 serve para guardá-los.

O que se ganha com esse custo é que **aprender é acrescentar**. Um ticket que a equipe separa hoje é
uma linha a mais amanhã, sem treino nenhum no meio, e um ticket rotulado errado pode ser achado e
apagado, porque toda decisão aponta de volta para os exemplos que a produziram.
