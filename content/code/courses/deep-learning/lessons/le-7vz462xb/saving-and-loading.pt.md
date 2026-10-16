---
title: Salvar e carregar um state dict
version: 1
---

O `train.py` terminou com `torch.save(model.state_dict(), "mlp.pt")`. **Um state dict são os números
do modelo, pelo nome, e nada mais**: nem a classe, nem a ordem das camadas, nem as ativações. Lê-los
de volta exige, então, o código que constrói a rede primeiro. Salve como `~/dl/load.py`:

```schooling-example
{
  "language": "python",
  "file": "load.py",
  "parts": [
    {
      "code": "\"\"\"load: the trained weights read back into a fresh network, and checked.\"\"\"\nimport torch\n\nimport loop\nimport tdigits\nfrom mlp import make_mlp\n\n_, val, _ = tdigits.load()\nstate = torch.load(\"mlp.pt\")\nfor name, tensor in state.items():\n    print(f\"{name:9s} {tuple(tensor.shape)}\")",
      "note": "Um state dict é um dicionário comum de nomes de parâmetros para tensores. Guarda os números e não o código: nada nele diz que `0` é um `Linear` ou que há um ReLU entre as camadas."
    },
    {
      "code": "torch.manual_seed(1)\nmodel = make_mlp()\nprint(\"fresh:   val loss %.4f  val acc %.3f\" % loop.evaluate(model, *val))\nmodel.load_state_dict(state)\nprint(\"loaded:  val loss %.4f  val acc %.3f\" % loop.evaluate(model, *val))",
      "note": "O código constrói a rede, com pesos aleatórios, e o `load_state_dict` copia nela os números salvos, pelo nome. Os números de validação devem ser os que a última época do `train.py` imprimiu."
    },
    {
      "code": "try:\n    make_mlp(hidden=64).load_state_dict(state)\nexcept RuntimeError as e:\n    print(str(e).split(\"\\n\")[0])\n    print(str(e).split(\"\\n\")[1].strip())",
      "note": "Um código que constrói uma rede diferente recusa o arquivo, e diz qual tensor não coube."
    }
  ]
}
```

```
ana@vm:~/dl$ wc -c mlp.pt
11829 mlp.pt
ana@vm:~/dl$ python load.py
0.weight  (32, 64)
0.bias    (32,)
2.weight  (10, 32)
2.bias    (10,)
fresh:   val loss 2.3180  val acc 0.097
loaded:  val loss 0.1461  val acc 0.950
Error(s) in loading state_dict for Sequential:
size mismatch for 0.weight: copying a param with shape torch.Size([32, 64]) from checkpoint, the shape in current model is torch.Size([64, 64]).
```

O arquivo tem 11.829 bytes, os 2.410 números a quatro bytes cada mais os nomes e a contabilidade do
próprio formato. A rede nova, com pesos aleatórios, marca 0.097, cerca de um em dez, que é chutar
entre dez dígitos. Depois do `load_state_dict` ela marca 0.950 com perda 0.1461, os mesmos dois
números da última linha do `train.py`. **Conferir que um modelo carregado reproduz um número que
tinha antes de ser salvo é o teste de que os pesos certos entraram no código certo.**

As duas últimas linhas são o que acontece quando não entraram. Uma rede construída com 64 unidades
ocultas tem um `0.weight` de `[64, 64]`, o arquivo tem `[32, 64]`, e o `load_state_dict` recusa em vez
de carregar a metade. Esse rigor é o motivo de o state dict, e não o modelo inteiro, ser o que se
salva.

## Por que não salvar o modelo inteiro

`torch.save(model)` também funciona, e guarda o modelo com pickle, que registra uma referência à
classe pelo módulo e pelo nome, e não o código da classe. Renomear ou mover esse código quebra todo
arquivo salvo assim. Carregar um pickle também roda código escolhido por quem escreveu o arquivo, e é
por isso que o `torch.load` agora usa `weights_only=True` por padrão e só aceita tensores e
contêineres simples, um state dict entre eles.

## Retomar o treino

Os pesos bastam para prever. Para continuar treinando de onde uma execução parou, o otimizador também
tem um `state_dict()`, e isso importa para o Adam, cujas duas médias móveis por parâmetro (aula 5)
recomeçariam do zero. Um checkpoint é então um dicionário com os dois state dicts e o número da
época, salvo com o mesmo `torch.save`.
