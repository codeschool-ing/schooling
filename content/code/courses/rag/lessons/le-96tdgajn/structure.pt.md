---
title: Seguindo a estrutura do documento
version: 1
---

Um documento escrito por uma pessoa já diz onde os assuntos começam e terminam. Títulos marcam seções,
linhas em branco marcam parágrafos, uma lista marca itens que andam juntos. Cortar por essas marcas
mantém cada pedaço sobre uma coisa só, e não custa nada além de ler as marcas.

## Seções, depois parágrafos

O `structured` do `chunking.py` corta em dois níveis. Primeiro, cada seção `## ` é separada, para que
nenhum pedaço atravesse de um assunto para o seguinte. Depois, dentro de uma seção, parágrafos inteiros
são juntados num pedaço até que o próximo parágrafo o levaria além do limite de tamanho:

```schooling-example
{
  "language": "python",
  "file": "chunking.py",
  "parts": [
    {
      "code": "def sections(text):\n    \"\"\"(heading path, body) for every '## ' section, the document's title first.\"\"\"\n    title = re.search(r\"^# (.+)$\", text, re.M).group(1)\n    out = []\n    for part in re.split(r\"\\n(?=## )\", text)[1:]:\n        heading, _, body = part.partition(\"\\n\")\n        out.append((f\"{title} > {heading[3:]}\", body.strip()))\n    return out",
      "note": "Uma seção é tudo de um título `## ` até o próximo. O nome dela é um caminho, o título do documento e depois o título da seção, para que um pedaço diga de onde veio depois de cortado."
    },
    {
      "code": "def structured(text, size):\n    \"\"\"Inside each section, whole paragraphs packed together up to SIZE words.\"\"\"\n    chunks = []\n    for path, body in sections(text):\n        pack = []\n        for para in re.split(r\"\\n\\s*\\n\", body):\n            if pack and len(\" \".join(pack + [para]).split()) > size:\n                chunks.append((path, \"\\n\\n\".join(pack)))\n                pack = []\n            pack.append(para)\n        if pack:\n            chunks.append((path, \"\\n\\n\".join(pack)))\n    return chunks",
      "note": "Dentro de uma seção, os parágrafos são juntados até que o próximo levaria o pedaço além de `size` palavras. Um parágrafo nunca é partido, e um pedaço nunca atravessa para a próxima seção."
    }
  ]
}
```

```
ana@lab:~/rag$ python structure.py
12 chunks
 120 words  Returns and refunds policy > The return window
  27 words  Returns and refunds policy > The return window
 117 words  Returns and refunds policy > How to start a return
  94 words  Returns and refunds policy > Refunds
  29 words  Returns and refunds policy > Refunds
  90 words  Returns and refunds policy > Damaged, faulty and wrong items

If a book arrives with a torn cover, bent corners or water damage, photograph it next to the
packaging and send the pictures within 14 days of delivery. We replace damaged books at no cost and
you do not need to send the damaged copy back.

If we sent a different title from the one you ordered, tell us within 14 days. Keep the parcel
closed if you can. We send the right book at once with a prepaid label for the wrong one, and you
are not charged twice.
```

**Doze pedaços para o regulamento, e cada um começa e termina num parágrafo.** São desiguais, 27
palavras aqui e 120 ali, porque parágrafos são desiguais; é o preço de não cortá-los ao meio. A seção
*How to start a return* é um pedaço de 117 palavras, os passos numerados e *Returns are free* juntos,
que é exatamente o trecho de que a pergunta sobre o frete precisa.

## O caminho de títulos viaja com o pedaço

Cada pedaço leva um caminho: *Returns and refunds policy > Damaged, faulty and wrong items*. O pedaço
impresso acima nunca diz que trata do regulamento de devoluções da Marginalia; ele diz *a book*, *we*,
*14 days*. Sem o caminho, quem lê o pedaço recuperado, pessoa ou modelo, não consegue dizer se aqueles
14 dias são de devoluções, de e-books ou do contrato de vendedores, que usam todos a expressão. Com ele,
o pedaço se descreve sozinho.

O caminho é também o que conserta os números de cláusula perdidos e o título *Rate limits* perdido da
aula 2. A aula 5 o guarda ao lado de cada pedaço, o imprime em cada citação, e mede o que acontece
quando ele também entra no embedding junto com o texto do pedaço.

## Divisão recursiva

As bibliotecas implementam essa ideia como **divisão recursiva**: tentar cortar no separador mais
grosso, uma quebra de seção; se um pedaço ainda estiver grande demais, cortá-lo no seguinte, uma linha
em branco; depois numa quebra de linha, depois num fim de frase, e só em último caso numa palavra. O
`RecursiveCharacterTextSplitter` do LangChain é o mais conhecido, e a aula 10 o roda neste corpus. O
`structured` é a mesma ideia com dois níveis, e tem uma fraqueza que a versão recursiva não tem: um
único parágrafo mais longo que o limite fica inteiro, então um documento com um parágrafo enorme o
derrota. O parágrafo mais longo do regulamento fica bem abaixo do limite, e por isso era seguro aqui.

## Estrutura que precisa ser lida antes

O Markdown torna as marcas fáceis de achar. Outros formatos as escondem: um PDF guarda texto
posicionado, não títulos; uma página HTML embrulha a estrutura em marcação; uma planilha é uma grade. O
passo de extração que transforma isso em texto decide se alguma estrutura sobrevive, e um pipeline que
passa PDFs por um extrator de texto simples e depois corta por contagem jogou a estrutura fora duas
vezes. A aula 11 olha o RAGFlow, uma ferramenta construída sobretudo em torno desse problema de
extração.
