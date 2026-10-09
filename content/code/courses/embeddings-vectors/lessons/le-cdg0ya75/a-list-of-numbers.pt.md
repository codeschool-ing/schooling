---
title: Uma lista de números
version: 1
---

Um modelo de embedding recebe um texto e devolve uma quantidade fixa de números. O modelo que este
curso usa na maior parte do tempo é o **all-MiniLM-L6-v2**, um modelo aberto e pequeno publicado
pelo projeto sentence-transformers. Ele roda no seu próprio computador e não precisa de conta. A aula 9 abre o
modelo por dentro; por enquanto ele é uma função chamada `embed` em `minilm.py`, o arquivo que você
salvou em *Preparando o ambiente*.

Aqui está o título do artigo de reembolso passando por ele:

```schooling-example
{
  "language": "python",
  "file": "first.py",
  "parts": [
    {
      "code": "from minilm import embed",
      "note": "`embed` vem de `minilm.py`, que roda o all-MiniLM-L6-v2 nesta máquina."
    },
    {
      "code": "v = embed(\"When your refund arrives\")[0]",
      "note": "Entra um texto, sai uma lista de vetores, um por texto. `[0]` pega o primeiro e único."
    },
    {
      "code": "print(v.shape, v.dtype)\nprint(v[:8].round(4))",
      "note": "O vetor é um array do NumPy. Imprima o formato, o tipo de número e os oito primeiros números, arredondados."
    },
    {
      "code": "print(\"length:\", round(float((v * v).sum()) ** 0.5, 6))\nprint(\"bytes: \", v.nbytes)",
      "note": "O comprimento é a raiz quadrada da soma dos quadrados, e `nbytes` é o espaço que ele ocupa na memória."
    }
  ]
}
```

```
ana@lab:~/emb$ python first.py
(384,) float32
[-0.0865 -0.0142 -0.0045  0.0386  0.0407  0.0211  0.0703  0.0093]
length: 1.0
bytes:  1536
```

Três coisas nessa saída merecem leitura lenta.

**O formato é `(384,)`.** Seja qual for o texto, três palavras ou três parágrafos, saem 384
números. Esse número é uma propriedade do modelo, chamada **dimensão**, e todo vetor que esse modelo
produz tem essa dimensão. Outros modelos produzem 256, 768, 1536 ou 3072; a aula 2 diz o que é uma
dimensão e o que ela não é.

**Os números não significam nada um a um.** `-0.0865` é a primeira coordenada do vetor deste texto,
e ela não mede nada que se possa nomear, como *o quanto isto fala de dinheiro*. A informação está
espalhada pelas 384 coordenadas ao mesmo tempo. O que carrega significado é a **posição do vetor
inteiro** em relação a outros vetores do mesmo modelo.

**O comprimento é 1,0.** O modelo divide cada vetor pelo próprio comprimento antes de entregá-lo,
então todos ficam na superfície de uma esfera de raio 1. Essa escolha não é universal: alguns
modelos devolvem vetores de qualquer comprimento, e a aula 2 mostra o que muda quando isso acontece.

## Quanto custa guardar um

Cada número é um `float32`, quatro bytes, então um vetor ocupa 384 × 4 = **1.536 bytes**, a linha
`bytes` acima. O texto de onde ele veio, *When your refund arrives*, tem 24 bytes. O vetor é 64
vezes maior que o título que ele descreve.

Essa proporção surpreende quem espera que um embedding seja uma versão comprimida do texto. Ele não
é. É uma descrição do significado do texto numa forma fácil de comparar, e nada nele está arrumado
para ser lido de volta como palavras. Para uma central de ajuda de 40 artigos o tamanho não importa. Para
quarenta milhões de documentos com um modelo de 1536 dimensões são cerca de 246 GB antes de
qualquer índice, e a aula 18 trata exatamente dessa conta.

## Mesmo texto, mesmo vetor

Rode `first.py` duas vezes e os números saem idênticos, até o último dígito. O modelo não tem
aleatoriedade na inferência: o mesmo texto no mesmo modelo dá o mesmo vetor. É isso que permite
calcular o vetor de um documento uma vez, guardá-lo e comparar perguntas novas com ele no ano que
vem — **desde que o modelo não tenha mudado**. Outro modelo, ou até outra versão do mesmo, produz
vetores que não podem ser comparados com os guardados. A seção *O que um embedding não é* volta a
isso.
