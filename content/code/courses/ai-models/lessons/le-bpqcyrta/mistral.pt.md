---
title: A linha da Mistral
version: 1
---

A Mistral é a única empresa deste diretório que vende modelos fechados por API e também publica
pesos abertos de muitos dos modelos dela, e fica na França, o que importa para alguns compradores
pelo motivo da aula 2 seção 07. As entradas atuais dela na tabela, mais ou menos em ordem de
tamanho:

```
ana@desk:~/desk$ python sheet.py compare mistral/ministral-3b-latest mistral/ministral-8b-latest mistral/mistral-small-latest mistral/mistral-medium-latest mistral/mistral-large-latest mistral/magistral-medium-latest mistral/devstral-latest
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
mistral/ministral-3b-latest                     131,072   131072      0.1      0.1  VFS...
mistral/ministral-8b-latest                     262,144   262144     0.15     0.15  VFS...
mistral/mistral-small-latest                    262,144   262144     0.15      0.6  VFS.R.
mistral/mistral-medium-latest                   262,144   262144      1.5      7.5  VFS.R.
mistral/mistral-large-latest                    262,144   262144      0.5      1.5  VFS...
mistral/magistral-medium-latest                 262,144   262144      1.5      7.5  VFS.R.
mistral/devstral-latest                         256,000   256000      0.4        2  .FS...
```

Leia a tabela pelo nome, porque a Mistral dá nome pela finalidade mais do que pelo tamanho:

- **Ministral 3B e 8B**: modelos pequenos, com o mesmo preço na entrada e na saída, US$ 0,10 e US$
  0,15. Pequenos o bastante para rodar em hardware modesto nas versões de pesos abertos (aula 3).
- **Mistral Small, Medium e Large**: a linha geral. O Small, a US$ 0,15 e US$ 0,60, é o mais barato
  dos candidatos da ana na aula 4, US$ 2,45 por mês para rascunhar com cache.
- **Magistral**: os modelos de raciocínio, com um `R` na última coluna.
- **Devstral** (e Codestral na lista completa): modelos para código.

Uma coisa na tabela parece errada e é um bom teste da leitura da aula 2: **o Large custa menos que o
Medium**, US$ 0,50 contra US$ 1,50. As entradas numeradas da tabela concordam (`mistral-large-3` a
US$ 0,50, `mistral-medium-3.5` a US$ 1,50), então não é um apelido apontando para um lugar
inesperado. É um lembrete de que **a palavra de tamanho num nome é um lugar numa linha, não uma
ordem de preço nem de qualidade**: os dois saíram em momentos diferentes e têm preços definidos pela
Mistral por motivos que a tabela não registra. Qual é melhor para os e-mails da ana é a pergunta da
aula 5, e o mais barato não a vence por se chamar Large.

## Pesos abertos, um modelo de cada vez

A aula 2 seção 04 usou o repositório de inferência da Mistral como exemplo de licença que cobre o
código e não os pesos. A consequência prática está aqui: **se um modelo da Mistral pode ser baixado
e rodado é uma propriedade daquele modelo**, declarada na página dele. Alguns saem sob Apache 2.0,
alguns sob licenças com condições, e os comerciais nem saem. Para a ana, a opção que a aula 3 pediu
para ela manter, preferir um modelo cujos pesos existam, tem de ser conferida modelo a modelo, não
empresa a empresa.
