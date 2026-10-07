---
title: Pondo colunas na mesma escala
version: 1
---

**Normalização** é uma palavra com três sentidos neste curso. A aula 6 normalizou Unicode, e bancos
de dados têm formas normais, que é uma terceira coisa. Aqui ela quer dizer **reescalar um número**
para que colunas medidas em unidades diferentes possam ser comparadas ou combinadas: receita em
reais e número de pedidos, por exemplo, que diferem por um fator de cem.

As duas reescalas comuns, e uma terceira que se comporta diferente:

```schooling-example
{
  "language": "python",
  "file": "scale.py",
  "parts": [
    {
      "code": "from per_customer import per\n\n"
    },
    {
      "code": "r = per[\"revenue\"]\n",
      "note": "A receita de cada cliente no ano."
    },
    {
      "code": "per[\"minmax\"] = (r - r.min()) / (r.max() - r.min())\n",
      "note": "**Min-max**: 0 para o menor, 1 para o maior."
    },
    {
      "code": "per[\"z\"] = (r - r.mean()) / r.std()\n",
      "note": "**Escore z**: distância da média em desvios padrão."
    },
    {
      "code": "per[\"pct\"] = r.rank(pct=True)\n\n",
      "note": "**Posto percentil**: a fração de clientes neste valor ou abaixo."
    },
    {
      "code": "if __name__ == \"__main__\":\n    print(per[[\"revenue\", \"minmax\", \"z\", \"pct\"]].describe().round(3).to_string())\n    print(per.nlargest(2, \"revenue\")[[\"revenue\", \"minmax\", \"z\", \"pct\"]].round(3).to_string())\n",
      "note": "O resumo das quatro colunas, e os dois maiores clientes."
    }
  ]
}
```

```
ana@lab:~/clean$ python scale.py
         revenue    minmax         z       pct
count   2273.000  2273.000  2273.000  2273.000
mean    1178.038     0.033    -0.000     0.500
std     1408.926     0.040     1.000     0.289
min        0.000     0.000    -0.836     0.000
25%      424.750     0.012    -0.535     0.250
50%      892.100     0.025    -0.203     0.500
75%     1568.800     0.044     0.277     0.750
max    35522.500     1.000    24.376     1.000
             revenue  minmax       z  pct
customer_id                              
C01115       35522.5   1.000  24.376  1.0
C01114       28682.5   0.807  19.522  1.0
```

- **Min-max** leva o menor valor para 0 e o maior para 1. O maior é a Clínica Bem Viver, R$
  35.522,50 em dois pedidos de dezembro. Toda família é medida contra uma clínica, e **três
  clientes em cada quatro ficam abaixo de 0,05**: a escala existe, e quase ninguém a usa.
- **O escore z** subtrai a média e divide pelo desvio padrão. O cliente mediano fica em −0,20, e a
  clínica em 24,4. A aula 9 mostrou por quê: os extremos inflam o desvio padrão que deveria
  medi-los.
- **O posto percentil** troca cada valor pela fração de clientes que estão nele ou abaixo. Não pode
  ser arrastado por um extremo, porque só conhece a ordem, e a clínica e o escritório de
  contabilidade aparecem os dois como 1,0. **O que ele joga fora é a distância**: R$ 1.000 e R$ 35.000
  podem ser vizinhos.

Nenhuma das três é certa em geral. Uma escala se escolhe pelo que ela alimenta. Quando um extremo é
real e pertence aos dados, como estas empresas, uma reescala que ele não consiga dominar serve
melhor às famílias: o posto, ou o logaritmo da próxima seção. A marca de pedido corporativo da
primeira seção também pode deixá-las fora do ajuste.

::: track data-science
A reescala é um modelo dos dados, e como todo modelo tem parâmetros: o mínimo e o máximo, ou a
média e o desvio padrão. **Calcule-os só nos dados de treino**, e depois aplique-os sem mudança aos
dados de teste e a tudo que chegar depois. Calculá-los sobre o conjunto inteiro deixa as linhas de
teste moldarem a escala em que serão medidas, uma forma silenciosa de vazamento que faz um modelo
parecer melhor no papel do que vai ser no uso. Os escaladores do scikit-learn, com `fit` num
conjunto e `transform` em outro, existem para essa separação ser difícil de esquecer.
:::

::: track bi
Num painel, valores reescalados raramente são o que as pessoas devem ler: ninguém age sobre uma
receita de 0,025. A reescala ganha o seu lugar nos bastidores, num ranking, numa pontuação
combinada ou numa escala de cor, e o número na tela continua em reais. Quando uma pontuação
combinada aparece, mostre a fórmula dela ao lado.
:::

::: track *
Onde quer que uma coluna reescalada vá parar, os valores de que ela foi calculada ficam na mesma
tabela, e a fórmula, com os números que usou, fica no código que a fez.
:::
