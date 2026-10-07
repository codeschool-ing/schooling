---
title: Quanto custa um banner, e o que o encarece
version: 2
---

A geração de imagens é cobrada por imagem, por tamanho e qualidade, e os preços por imagem da tabela tornam a comparação simples. Mais um número decide o custo real: **quantas imagens são jogadas fora para cada uma usada**. A aula 3 não mediu nada disso, porque nenhum gerador roda neste curso, então o programa supõe uma em quatro:

```python
"""What one accepted banner costs, from the sheet's per-image prices, when one in four is accepted."""
PRICES = {"gpt-image-1, low": 0.011, "gpt-image-1, medium": 0.042, "gpt-image-1, high": 0.167,
          "gemini-2.5-flash-image": 0.039, "gemini-3.1-flash-image": 0.045}
for name, each in PRICES.items():
    print(f"{name:24} ${each:.3f} each   ${each * 4:.3f} per accepted   ${each * 4 * 52:6.2f} for a year of weekly banners")
```

```
ana@lab:~/mm$ python price.py
gpt-image-1, low         $0.011 each   $0.044 per accepted   $  2.29 for a year of weekly banners
gpt-image-1, medium      $0.042 each   $0.168 per accepted   $  8.74 for a year of weekly banners
gpt-image-1, high        $0.167 each   $0.668 per accepted   $ 34.74 for a year of weekly banners
gemini-2.5-flash-image   $0.039 each   $0.156 per accepted   $  8.11 for a year of weekly banners
gemini-3.1-flash-image   $0.045 each   $0.180 per accepted   $  9.36 for a year of weekly banners
```

A primeira coluna é o preço por imagem da tabela; para o `gpt-image-1` em 1024 por 1024 ele fica num campo que a tabela chama de `input_cost_per_image`, uma esquisitice de nome do arquivo do LiteLLM. **A qualidade mexe no preço em quinze vezes**, de 0,011 dólar em `low` a 0,167 em `high`. Um ano de banners semanais custa entre 2,29 e 34,74 dólares com uma aceita em quatro. Para uma newsletter é troco de qualquer jeito, e a escolha da qualidade deve ser feita olhando as duas, não a conta.

**Deixa de ser troco quando um cliente aperta o botão.** Um recurso "veja seu livro com outra capa" no site da loja não tem uma pessoa escolhendo uma imagem em quatro: cada aperto é uma chamada, e um cliente curioso aperta uma dúzia de vezes. Esse é o alerta da ficha de design sobre este curso, um custo que sobe com o quanto as pessoas usam a coisa, e a aula 13 constrói os limites que o mantêm sob controle.

## Erros que valem tratar

- **400, pedido inválido**: um tamanho que o modelo não aceita, uma máscara que não encaixa. Corrija o pedido; repetir o mesmo vai falhar do mesmo jeito.
- **400 por conteúdo**: o provedor recusou o prompt ou a imagem pela política dele (aula 3). Não repita automaticamente; mostre uma mensagem à pessoa e registre o prompt.
- **429 e 5xx**: limite de taxa ou falha do provedor. Repita com uma espera. O SDK da OpenAI repete esses sozinho, duas vezes por padrão, e o google-genai também repete.

Uma imagem que voltou é um rascunho até alguém aprová-la, e por isso o `banner.json` tem um campo `approved_by` que começa vazio.
