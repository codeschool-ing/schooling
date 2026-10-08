---
title: Pedaços de tamanho fixo
version: 2
---

O jeito mais simples de cortar é por contagem: a cada tantas palavras, caracteres ou tokens, comece um
pedaço novo. Não precisa saber nada do documento, e é por isso que é o padrão da maioria das
bibliotecas e também por isso que faz estrago.

```schooling-example
{
  "language": "python",
  "file": "chunking.py",
  "parts": [
    {
      "code": "def fixed(text, size, overlap=0):\n    \"\"\"Every SIZE words, starting again OVERLAP words before the last cut.\"\"\"\n    words = text.split()\n    step = size - overlap\n    return [\" \".join(words[i:i + size]) for i in range(0, max(len(words) - overlap, 1), step)]",
      "note": "A segunda função do `chunking.py`: acrescente depois de `load`."
    }
  ]
}
```


O `fixed` conta palavras, o que é fácil de ler e bem próximo para prosa em inglês. As bibliotecas
costumam contar caracteres, e as cuidadosas contam os tokens do próprio modelo de embeddings, que é a
unidade do limite da seção anterior. O comportamento é o mesmo em qualquer unidade: um corte cai onde a
conta mandar, seja o que for que estiver ali.

## Onde os cortes caem

O `boundaries.py` corta o regulamento de devoluções em pedaços de 60 palavras e imprime as bordas de
três deles, contando a partir de 0:

```schooling-example
{
  "language": "python",
  "file": "boundaries.py",
  "parts": [
    {
      "code": "import sys\n\nfrom chunking import fixed, load\n\nsize, overlap = int(sys.argv[1]), int(sys.argv[2])\nmeta, body = load()[\"returns-policy\"]\nchunks = fixed(body, size, overlap)\nprint(f\"{len(chunks)} chunks of {size} words, {overlap} overlapping\")",
      "note": "O tamanho e a sobreposição vêm da linha de comando, para que a próxima seção possa rodá-lo de novo com sobreposição."
    },
    {
      "code": "for i in (3, 4, 5):\n    words = chunks[i].split()\n    print(f\"chunk {i} starts: {' '.join(words[:9])} ...\")\n    print(f\"chunk {i} ends:   ... {' '.join(words[-9:])}\")",
      "note": "As primeiras e as últimas nove palavras dos pedaços 3, 4 e 5, que é onde ficam os cortes."
    }
  ]
}
```

```
ana@vm:~/rag$ python boundaries.py 60 0
15 chunks of 60 words, 0 overlapping
chunk 3 starts: to you at our cost with an email explaining ...
chunk 3 ends:   ... choose Return items. 2. Select the books you are
chunk 4 starts: sending back and a reason. The reason helps us; ...
chunk 4 ends:   ... in the box, and drop the parcel at any
chunk 5 starts: post office. Returns are free. You do not pay ...
chunk 5 ends:   ... reaching our warehouse. The money goes back to the
```

**Todas as fronteiras caem no meio de uma frase.** O pedaço 3 começa com *to you at our cost*, o fim de
uma frase cujo sujeito está no pedaço 2. O pedaço 3 termina com *Select the books you are*, e o resto
dessa instrução está no pedaço 4. O pedaço 4 termina em *drop the parcel at any* e o pedaço 5 começa em
*post office*. Cada pedaço é uma janela de texto com pontas esfiapadas, e é pelas pontas que o
significado escapa.

O estrago aparece melhor na frase de que o cliente mais precisa. *Returns are free* fica no começo do
pedaço 5, num pedaço que de resto fala de reembolsos e bancos. Uma pergunta sobre o frete de devolução
agora é comparada com um vetor que é quase todo sobre reembolsos.

## O que ele acerta

O corte de tamanho fixo tem virtudes reais, e é por elas que sobrevive:

- **Todo pedaço fica abaixo do limite**, por construção. Ponha o tamanho abaixo do limite do modelo de
  embeddings, nas unidades do próprio modelo, e nada nunca é truncado.
- **Funciona com qualquer texto**: uma transcrição sem parágrafos, um PDF cuja estrutura se perdeu na
  extração, um arquivo de log.
- **Os pedaços têm tamanho parelho**, então cada pedaço recuperado custa mais ou menos o mesmo no
  prompt.

Essas virtudes importam quando o texto não tem estrutura para seguir. Quando tem, como quase todo
documento que uma empresa escreve, ignorá-la é escolher cortar frases ao meio. A próxima seção atenua o
estrago sem olhar para a estrutura; a seguinte usa a estrutura.
