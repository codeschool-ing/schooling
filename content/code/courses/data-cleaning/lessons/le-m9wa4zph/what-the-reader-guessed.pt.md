---
title: O que o leitor adivinhou
version: 1
---

**Todo leitor de CSV converte enquanto lê, e toda conversão é um palpite.** O pandas olha uma
coluna, decide que ela guarda números, datas ou texto, e entrega o resultado como se o arquivo
tivesse dito isso. Na maioria das vezes o palpite acerta. Um perfil é onde você acha as vezes em que
não acertou, e por isso um perfil precisa olhar o arquivo antes do palpite.

Lendo o arquivo de clientes sem opção nenhuma:

```
ana@lab:~/clean$ python -c "import pandas as pd; c = pd.read_csv('raw/customers.csv'); print(c.dtypes); print(c['birth_year'].head(3))"
customer_id             str
name                    str
email                   str
cep                     str
city                    str
state                   str
signed_up               str
birth_year          float64
signup_channel          str
marketing_opt_in        str
dtype: object
0    1986.0
1    1982.0
2    1953.0
Name: birth_year, dtype: float64
```

Nove colunas voltaram como texto, `str`. Uma voltou como `float64`, um número de ponto flutuante:
`birth_year`. Um ano é um número inteiro, então por que float? Porque 338 linhas não têm ano de
nascimento, e uma coluna inteira simples do NumPy não guarda valor faltante, então o pandas escolheu
o único tipo numérico que guarda. **Todo ano agora sai impresso com `.0` depois**, e os 106 anos de
dois dígitos do aplicativo agora são os números 87.0, 92.0 e assim por diante, indistinguíveis de um
valor real a não ser por serem impossíveis.

Os itens dos pedidos mostram um palpite pior:

```
ana@lab:~/clean$ python -c "import pandas as pd; i = pd.read_csv('raw/order_items.csv'); print(i['product_code'].head(4))"
0    438
1    739
2    689
3    833
Name: product_code, dtype: int64
ana@lab:~/clean$ python -c "import pandas as pd; i = pd.read_csv('raw/order_items.csv', dtype=str); print(i['product_code'].head(4))"
0      438
1      739
2      689
3    00833
Name: product_code, dtype: str
```

Os códigos de produto são textos de cinco dígitos no catálogo, `00833`, e o site os escreve assim.
**Lido sem opções, `00833` vira o número 833** e os zeros à esquerda somem de vez; nada no resultado
diz que eles existiram. Lida como texto, a coluna mostra a situação real: algumas linhas dizem
`00833` e outras `438`, porque o aplicativo escreve os códigos sem zeros. Isso é um achado — dois
sistemas, dois formatos — e a leitura padrão o apagou antes de alguém vê-lo.

## Leia tudo como texto primeiro

A regra que este curso segue daqui em diante é **ler como texto, olhar, e só então converter de
propósito**:

- `dtype=str` mantém cada valor exatamente como está no arquivo;
- `keep_default_na=False, na_values=[""]` faz só um campo realmente vazio ser faltante. Por padrão o
  pandas também transforma `NA`, `null`, `None`, `n/a` e outros textos em faltantes, o que numa
  coluna de códigos de país apaga a Namíbia, cujo código é `NA`;
- a conversão acontece depois, uma coluna de cada vez, com uma checagem que conta o que não
  converteu. A aula 10 é sobre esse passo.

Em SQL, a mesma regra é o motivo de a aula 1 ter carregado o schema `raw` com toda coluna como
`text`. Um `COPY` para uma tabela tipada é a versão do banco de um palpite, só que ele costuma falhar
alto em vez de em silêncio — o melhor dos dois jeitos de estar errado.
