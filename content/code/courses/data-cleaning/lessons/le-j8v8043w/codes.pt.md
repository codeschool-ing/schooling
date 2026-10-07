---
title: Códigos: texto com cara de número
version: 1
---

**Um código é um identificador escrito com dígitos, e dígitos convidam o leitor a tratá-lo como
número.** Um CEP, um código de produto, um CPF, uma agência bancária: nenhum deles é somado, tirado
média ou comparado por tamanho, e todos podem começar com zero. Lidos como números, perdem os zeros à
esquerda; a aula 2 viu `00833` virar `833`.

O reparo é completar até a largura fixa do código, o que o código da seção anterior fez com
`.str.zfill(5)`. Se funcionou é uma pergunta que o catálogo responde:

```
ana@lab:~/clean$ python -c "import pandas as pd; from lines import lines as l; p = pd.read_csv('raw/products.csv', dtype=str); print(l['product_code'].isin(p['product_code']).mean().round(3), l['code'].isin(p['product_code']).mean().round(4)); print(sorted(set(l['code']) - set(p['product_code'])))"
0.546 0.9883
['00123', '00584']
```

Como chegaram, só 54,6% dos códigos de produto dos itens existem no catálogo: todo item do aplicativo
falha, por falta dos zeros. Completados, 98,83% existem. **O 1,2% restante são dois códigos que não
estão no catálogo**, `00123` e `00584`: produtos vendidos em 2025 e retirados do catálogo antes da
exportação. Esse é o problema de órfãos da aula 11, e completar os zeros foi o que o tornou visível —
sem isso, 45% dos itens pareceriam órfãos e os dois reais se perderiam no meio deles.

As regras para qualquer coluna de código:

- **leia como texto**, sempre — a regra da aula 2, aqui pelo seu motivo mais importante;
- **complete até a largura fixa** quando ela é conhecida: oito dígitos para um CEP, cinco para um
  código de produto aqui;
- **escreva na forma canônica para exibir**, `01310-100` com hífen, mas **junte pelos dígitos
  puros**, para que dois formatos de um código nunca deixem de se encontrar;
- **valide contra a lista de onde ele vem**, e conte o que falha. Um código que ninguém consegue
  consultar é um achado, não ruído.
