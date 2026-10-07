---
title: Quantos bytes um modelo precisa
version: 2
---

É tentador ler o tamanho de um modelo como uma impressão: 70B soa grande, 7B soa pequeno, e se um
deles roda na sua máquina parece algo que só se descobre tentando. **É aritmética, e cabe numa
linha: o número de pesos vezes os bytes que cada peso ocupa.** Todo o resto desta seção é de onde
vem o segundo número.

O `toylm` precisou de 7478 bytes para as suas 436 contagens, uns 17 bytes cada, porque as guarda como
texto, com as palavras ao lado. Um modelo grande guarda os pesos como números binários de largura
fixa, e a largura é uma escolha:

| largura | bytes por peso | o que é |
|---|---|---|
| 32 bits | 4 | precisão total |
| 16 bits | 2 | a largura usual em que os pesos de um modelo são publicados |
| 8 bits | 1 | quantizado: cada peso arredondado para um de no máximo 256 valores |
| 4 bits | ½ | quantizado com mais força: cada peso arredondado para um de no máximo 16 valores |

## O exemplo resolvido

O `size.py` é a multiplicação, escrita uma vez para rodar com qualquer tamanho:

```python
import sys

weights = float(sys.argv[1])
for bits in (32, 16, 8, 4):
    print("%2d bits: %6.1f GB" % (bits, weights * bits / 8 / 1e9))
```

Bits divididos por 8 dão bytes, e dividir por 10⁹ dá gigabytes. Para um modelo de 7B e um de 70B:

```
ana@lab:~/pe$ python3 size.py 7e9
32 bits:   28.0 GB
16 bits:   14.0 GB
 8 bits:    7.0 GB
 4 bits:    3.5 GB
ana@lab:~/pe$ python3 size.py 70e9
32 bits:  280.0 GB
16 bits:  140.0 GB
 8 bits:   70.0 GB
 4 bits:   35.0 GB
```

**Um modelo de 7B a 16 bits precisa de 14 GB só para os pesos**, e a 4 bits precisa de 3,5. São os
mesmos sete bilhões de pesos, guardados com um quarto da largura.

Os pesos são o piso, não o total. Um modelo rodando também precisa de memória de trabalho para o
texto que está processando, e essa parte cresce com o tamanho do contexto (lição 4). Um modelo
cujos pesos mal cabem não tem espaço sobrando para ler um documento longo.

## Quantização, e o que ela custa

Guardar um peso em menos bits é arredondá-lo para um conjunto de valores mais grosso. O `quant.py`
faz isso com quatro números inventados para fazer as vezes de pesos. Ele acha o maior, divide a
faixa nos degraus que a largura permite e arredonda cada peso para o degrau mais próximo:

```python
w = [0.0173, -0.4121, 0.2958, -0.0846]
print("original:", " ".join("%+.4f" % x for x in w))
for bits in (8, 4):
    levels = 2 ** (bits - 1) - 1
    step = max(abs(x) for x in w) / levels
    back = [round(x / step) * step for x in w]
    err = max(abs(a - b) for a, b in zip(w, back))
    print("%d bits:  " % bits, " ".join("%+.4f" % x for x in back), " largest error %.4f" % err)
```

```
ana@lab:~/pe$ python3 quant.py
original: +0.0173 -0.4121 +0.2958 -0.0846
8 bits:   +0.0162 -0.4121 +0.2953 -0.0844  largest error 0.0011
4 bits:   +0.0000 -0.4121 +0.2944 -0.0589  largest error 0.0257
```

A 8 bits, cada peso mudou no máximo 0,0011. A 4 bits o erro fica mais de vinte vezes maior, e **o
menor peso, `0.0173`, virou exatamente zero**: o que ele contribuía sumiu. Os métodos de quantização
de verdade são mais espertos que este, arredondam em grupos pequenos e protegem os pesos que mais
importam, mas a troca é a mesma. **Menos bits compram memória e custam um pouco de qualidade**, e a
perda cresce conforme a largura encolhe. Quanta qualidade um modelo perde numa largura é medido, não
suposto: procure essa medição onde a versão quantizada é publicada.

## O modelo na sua própria máquina

Você já tem um destes no disco. O Ollama diz o que ele é:

```
ana@lab:~/pe$ ollama show llama3.2:3b | head -7
  Model
    architecture        llama     
    parameters          3.2B      
    context length      131072    
    embedding length    3072      
    quantization        Q4_K_M    

```

**3,2 bilhões de pesos, quantizados com um método chamado `Q4_K_M`.** A mesma multiplicação, para
essa contagem:

```
ana@lab:~/pe$ python3 size.py 3.2e9
32 bits:   12.8 GB
16 bits:    6.4 GB
 8 bits:    3.2 GB
 4 bits:    1.6 GB
```

A 4 bits os pesos ocupariam 1,6 GB, e o `ollama list` da lição 1 disse que o arquivo tem 2,0 GB. O
`Q4_K_M` guarda a maioria dos pesos com uns quatro bits e alguns dos mais sensíveis com mais, então
a média real fica um pouco acima de quatro, e o arquivo, um pouco acima da conta. Depois, o
`ollama ps` da lição 1 disse 2,9 GB enquanto ele respondia: os 2,0 GB de pesos, mais a memória de
trabalho para uma janela de contexto de 4096 tokens, a coluna `CONTEXT` da mesma linha. **A conta dá
o piso, e a medição dá o total**, e vale ter os dois antes de escolher um modelo para uma máquina.

## Por que isso decide onde um modelo roda

Pense num notebook com 16 GB de memória, em que também precisam caber o sistema operacional e tudo
o que estiver aberto nele. O modelo de 7B a 16 bits, 14 GB, não cabe com folga. A 4 bits, 3,5 GB,
cabe. O modelo de 70B precisa de 35 GB mesmo a 4 bits, o que é uma estação de trabalho ou um
servidor.

Esse é o sentido prático dos parâmetros. **A contagem, vezes a largura, diz de que hardware um
modelo precisa**, e a largura é uma escolha que você faz com a qualidade no outro prato da balança.
Quando você chama um modelo por uma API, nada disso é problema seu: o provedor guarda os pesos e você
paga por token, que é a lição 3. Quando você baixa os pesos e roda por conta própria, é a primeira
conta a fazer, e a lição 12 trata de quais provedores permitem isso.
