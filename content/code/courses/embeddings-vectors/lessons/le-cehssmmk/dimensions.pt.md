---
title: O que é uma dimensão
version: 1
---

Um vetor do all-MiniLM-L6-v2 tem 384 números, e é tentador lê-los como 384 características: uma
coordenada para *fala de dinheiro*, uma para *urgente*, uma para *fala de livros*. A aula 1 disse
que os números não significam nada um a um. Esta seção mostra que isso é verdade ao pé da letra, e
por que tem de ser.

## Um ponto, ou uma seta a partir da origem

Uma **coordenada** é um número que situa algo ao longo de um eixo. Dois números situam um ponto
num mapa: tanto para leste, tanto para norte. Três situam um ponto numa sala. Cada número a mais é
mais um eixo, em ângulo reto com todos os outros, e nada na aritmética muda quando são 384. Só o
desenho fica impossível.

Então um vetor é um ponto num espaço com tantos eixos quantas dimensões o modelo tem. Fica mais
fácil pensar nele como uma **seta** que vai da origem, o ponto em que toda coordenada é zero, até
esse ponto. Uma seta tem **direção** e **comprimento**, e o resto desta aula é sobre qual dos dois
carrega o significado.

## Gire o espaço inteiro e nada muda

Se uma coordenada medisse *fala de dinheiro*, os eixos seriam especiais: girá-los levaria esse
significado para outro número. Gire e veja. `rotate.py` transforma os 40 artigos de ajuda em
vetores e depois multiplica todos pela mesma **rotação** aleatória, uma matriz que gira o espaço
inteiro em torno da origem sem esticar nada:

```schooling-example
{
  "language": "python",
  "file": "rotate.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nD = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])",
      "note": "Transforme os 40 artigos de ajuda em vetores, cada um como título e corpo juntos, como na aula 1."
    },
    {
      "code": "rng = np.random.default_rng(2)\nQ, _ = np.linalg.qr(rng.standard_normal((384, 384)))\nR = D @ Q",
      "note": "Monte uma rotação aleatória: a decomposição QR de uma matriz de números aleatórios dá uma matriz ortogonal `Q`, que gira o espaço sem esticá-lo. A semente faz dela a mesma rotação em toda execução. `D @ Q` gira os 40 vetores de uma vez."
    },
    {
      "code": "print(\"before:\", D[0, :4].round(4))\nprint(\"after: \", R[0, :4].round(4))",
      "note": "As quatro primeiras coordenadas do primeiro artigo, antes e depois."
    },
    {
      "code": "change = np.abs(D @ D.T - R @ R.T).max()\nprint(f\"largest change in any of {len(D) * len(D)} scores: {change:.1e}\")",
      "note": "Todas as notas entre todos os pares de artigos, antes e depois, e a maior diferença em qualquer ponto das duas tabelas de 40 × 40."
    }
  ]
}
```

```
ana@lab:~/emb$ python rotate.py
before: [-0.0291  0.0291  0.047   0.024 ]
after:  [ 0.0086 -0.0308  0.0113  0.0972]
largest change in any of 1600 scores: 7.0e-07
```

**Todas as coordenadas mudaram, e nenhuma nota mudou.** Os quatro primeiros números do primeiro
artigo são completamente outros depois do giro, mas os 1.600 produtos escalares entre os 40 artigos
se mexeram no máximo `7.0e-07`, que é o arredondamento de números de 32 bits. Uma busca, um
classificador ou uma figura construídos sobre essas notas dariam exatamente as mesmas respostas no
espaço girado.

É por isso que nenhuma coordenada significa nada sozinha. Uma cópia girada do all-MiniLM-L6-v2
seria um modelo tão bom quanto ele, e o treino não tinha motivo para preferir uma orientação a
outra, então os eixos que saíram são um acaso. Só o arranjo das setas umas em relação às outras é
real: os **ângulos** entre elas e, quando importa, os comprimentos. Isso também explica o aviso da
aula 1 sobre misturar modelos. Dois modelos com a mesma dimensão são, no melhor caso, dois arranjos
girados de jeitos diferentes, e ninguém sabe qual é o giro.

## 384, 256, 1536

A dimensão é uma escolha de quem fez o modelo. O all-MiniLM-L6-v2 devolve 384, o WordLlama devolve
256 e o `text-embedding-3-small` da OpenAI devolve 1536 por padrão (a aula 7 o chama). Mais
dimensões dão ao modelo mais espaço para manter significados diferentes separados, e custam na
mesma proporção: 1536 números float32 são 6.144 bytes por vetor contra 1.536 para 384, e cada
comparação faz quatro vezes mais multiplicações. Se o espaço extra compensa depende dos seus
textos, e é por isso que a aula 9 mede dois modelos nas perguntas do próprio curso em vez de
confiar no número maior.
