---
title: O modelo são quatro arquivos
version: 1
---

Um modelo para o Transformers.js é um repositório do Hub com um formato conhecido, e a seção 03 da
aula 12 disse o que há num deles. **O huggingface.co estava fora de alcance na máquina em que este
curso foi gravado**, então o modelo da ana não vem do Hub. O lab treina um no lugar: o
`train-sorter` lê os trinta primeiros dos quarenta casos dela, aprende que palavras apontam para que
rótulo e grava o resultado no formato que o Transformers.js espera. Os dez últimos casos ficam de
fora, intocados, para a seção 04.

```
ana@desk:~/desk$ train-sorter
224 words in the vocabulary, 1125 numbers in the model
trained on 30 cases, 10 kept back
```

É a menor coisa que ainda conta como modelo: um **saco de palavras** e uma camada linear, o que é
regressão logística. Cada palavra dos e-mails de treino ganha cinco números, um por rótulo; a nota
de um e-mail para um rótulo é a soma dos números das palavras dele mais um viés. 224 palavras vezes
cinco, mais cinco vieses, dá os 1.125. Um modelo de verdade do tipo que a seção 02 da aula 12 tinha
em mente tem milhões de números, e nada do que vem a seguir muda com a contagem.

```
ana@desk:~/desk$ find models -type f | sort | xargs wc -c
 326 models/lantern-sorter/config.json
4949 models/lantern-sorter/onnx/model.onnx
4303 models/lantern-sorter/tokenizer.json
  90 models/lantern-sorter/tokenizer_config.json
9668 total
```

Quatro arquivos, menos de dez kilobytes ao todo:

| arquivo | o que a biblioteca lê nele |
|---|---|
| `config.json` | a arquitetura a carregar e os nomes dos rótulos |
| `tokenizer.json` | como texto vira número: o vocabulário e as regras em volta dele |
| `tokenizer_config.json` | ajustes com que o tokenizador começa |
| `onnx/model.onnx` | a computação e os pesos, em precisão de 32 bits |

```
ana@desk:~/desk$ cat models/lantern-sorter/config.json
{
 "model_type": "bert",
 "architectures": [
  "BertForSequenceClassification"
 ],
 "id2label": {
  "0": "order-status",
  "1": "refund",
  "2": "address-change",
  "3": "product-question",
  "4": "other"
 },
 "label2id": {
  "order-status": 0,
  "refund": 1,
  "address-change": 2,
  "product-question": 3,
  "other": 4
 }
}
```

`id2label` é o que transforma o quarto número do modelo em `product-question`. `model_type: bert` é
uma **afirmação**, e não verdadeira: isto não é um BERT. Ela diz ao Transformers.js que código de
carregamento usar, e a biblioteca acredita, porque tudo de que esse código precisa do grafo são duas
entradas e uma saída com os nomes certos:

```
ana@desk:~/desk$ python -c "import onnx; g = onnx.load(\"models/lantern-sorter/onnx/model.onnx\").graph; print(*[n.op_type for n in g.node]); print([i.name for i in g.input], \"->\", [o.name for o in g.output])"
Gather Cast Unsqueeze Mul ReduceSum Add
['input_ids', 'attention_mask'] -> ['logits']
```

Seis operações: buscar a linha de números de cada token, zerar o preenchimento, somar as linhas,
somar o viés. Esse é o modelo inteiro.

## O que o tokenizador faz com um e-mail

O tokenizador roda antes de tudo isso, e decide o que o modelo chega a ver. O `tokens.mjs` pede a
ele, pelo Transformers.js, que codifique uma frase e a decodifique de volta:

```js
import { AutoTokenizer, env } from "@huggingface/transformers";
env.allowRemoteModels = false;
env.localModelPath = process.cwd() + "/models/";

const tokenizer = await AutoTokenizer.from_pretrained("lantern-sorter");
const text = process.argv[2];
const ids = tokenizer.encode(text);
console.log(ids.join(" "));
console.log(tokenizer.decode(ids));
```

```
ana@desk:~/desk$ node tokens.mjs "Where is my order LB-20488? It has not arrived."
2 211 90 109 127 95 1 1 1 91 73 117 13 1 3
[CLS] where is my order lb [UNK] [UNK] [UNK] it has not arrived [UNK] [SEP]
```

Quinze ids. `[CLS]` e `[SEP]` marcam o começo e o fim. O número do pedido `20488`, o hífen e os dois
sinais de pontuação viraram `[UNK]`, o token para qualquer coisa fora do vocabulário, que não carrega
evidência nenhuma. **Uma palavra que o modelo nunca viu no treino é uma palavra que ele não sabe
ler**, e isso vale para todo modelo de todo tamanho. O tokenizador da caixa da seção 02 da aula 1 é
a mesma ideia com um vocabulário muito maior, cortado em pedaços de palavras para que menos coisas
fiquem de fora.
