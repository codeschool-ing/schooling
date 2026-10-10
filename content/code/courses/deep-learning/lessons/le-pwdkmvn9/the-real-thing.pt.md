---
title: O de verdade, com os pesos do ImageNet
version: 1
---

Tudo o que veio acima pegou emprestado de uma rede que este curso mesmo treinou, com 528 imagens
pequenas. **Na prática o corpo vem de outra pessoa, treinado com milhões de fotografias, e você o
baixa.** O torchvision traz as arquiteturas e, para cada uma, o endereço de pesos treinados no
ImageNet: 1,28 milhão de fotografias em 1.000 classes.

Esta máquina não alcança o servidor onde esses pesos ficam, então o download aparece abaixo e **não
foi executado neste curso**. O que o torchvision sabe sobre os pesos sem baixá-los é real, e
imprimir isso já diz quase tudo o que importa. Salve como `~/dl/weights.py`:

```schooling-example
{
  "language": "python",
  "file": "weights.py",
  "parts": [
    {
      "code": "\"\"\"weights: what torchvision knows about a pretrained model, without downloading it.\"\"\"\nfrom torchvision.models import ResNet18_Weights, resnet18\n\nw = ResNet18_Weights.DEFAULT\nprint(w, \"from\", w.url)",
      "note": "Todo modelo pré-treinado do torchvision tem ao lado um enum de pesos. `DEFAULT` aponta o melhor conjunto disponível, e o enum guarda o endereço do arquivo sem baixá-lo."
    },
    {
      "code": "print(f\"{w.meta['num_params']:,} parameters, {w.meta['_file_size']} MB,\",\n      \"ImageNet top-1\", w.meta[\"_metrics\"][\"ImageNet-1K\"][\"acc@1\"])\nprint(len(w.meta[\"categories\"]), \"classes, the first three:\", w.meta[\"categories\"][:3])",
      "note": "Os metadados que vêm dentro do torchvision: o tamanho, a acurácia que os pesos alcançaram na validação do ImageNet e os nomes das classes que a cabeça original aprendeu a distinguir."
    },
    {
      "code": "print(\"the head:\", resnet18(weights=None).fc)\nprint(w.transforms())",
      "note": "`weights=None` monta a arquitetura com pesos aleatórios, então nada é baixado. A última camada é a cabeça que uma transferência troca. `transforms()` é o pré-processamento com que os pesos foram treinados."
    }
  ]
}
```

```
PENDING weights
```

Três coisas nessa saída decidem como você usa o arquivo.

**A cabeça fala ImageNet.** `Linear(in_features=512, out_features=1000)` leva as 512 características
do corpo às 1.000 classes, que começam com um peixe, outro peixe e um tubarão. Para o seu problema
ela sai, exatamente como o `transfer.py` trocou a cabeça do `base.pt`.

**A entrada tem de parecer com a do ImageNet.** `ImageClassification` redimensiona o lado menor para
256 pixels, recorta os 224 por 224 do centro e normaliza cada canal de cor com a média e o desvio
padrão do próprio ImageNet: `mean=[0.485, 0.456, 0.406]` e `std=[0.229, 0.224, 0.225]`, um número
para o vermelho, o verde e o azul. O corpo aprendeu os filtros com entradas nessa escala, e uma imagem
em qualquer outra escala chega a eles deslocada. **Monte sempre o pré-processamento a partir de
`weights.transforms()`**, em vez de escrever os números à mão.

**Os números em `meta` são o ponto de partida**, não o seu resultado: 69,758% de top-1 é o que este
arquivo marcou na validação do ImageNet, e um modelo nas suas imagens vai marcar o que as suas
imagens permitirem.

## Como fica a transferência, sem executar

A mesma extração de características do `transfer.py`, numa ResNet-18 pré-treinada. **Não executado
neste curso**: a primeira linha baixa o arquivo de 44,661 MB de `download.pytorch.org`, que este
laboratório não alcança.

```python
import torch.nn as nn
from torchvision.models import ResNet18_Weights, resnet18

weights = ResNet18_Weights.DEFAULT
model = resnet18(weights=weights)            # downloads the file once, then reads it from a cache
for p in model.parameters():
    p.requires_grad = False
model.fc = nn.Linear(model.fc.in_features, 5)   # a new head for five classes of your own

preprocess = weights.transforms()            # resize, crop, scale to [0, 1], normalise
```

O laço de treino que vem depois é o que você já tem, com as fotografias passando por `preprocess`, e
por alguma augmentation, antes de chegar ao modelo. Treinar só `model.fc` num processador é viável;
a passada para a frente pelo corpo congelado é a parte lenta, e dá para fazê-la uma vez por imagem e
guardar as 512 características.

**Os dígitos 8 por 8 combinariam mal com este corpo.** Ele espera três canais de cor a 224 pixels; um
dígito precisaria ser copiado em três canais e ampliado 28 vezes, e os filtros aprendidos em pelo,
grama e janelas estariam procurando coisas que o dígito não tem. Emprestar ajuda quando as imagens
antigas e as novas compartilham as peças pequenas, e é por isso que esta aula pré-treinou em dígitos.
A aula 17 parte de novo do `base.pt` e pergunta o que muda quando o corpo também pode aprender.
