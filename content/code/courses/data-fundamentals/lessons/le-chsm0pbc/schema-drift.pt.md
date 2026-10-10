---
title: Deriva de esquema, ou a forma que mudou de um dia para o outro
version: 1
---

**Deriva de esquema (schema drift) é a forma do dado que chega mudar sem que ninguém adiante seja
avisado: um campo aparece, some, ou passa a trazer outro tipo.** Com dado estruturado ela não acontece
em silêncio, porque a tabela recusa a primeira linha que não cabe. Com dado semiestruturado ela é o
estado normal das coisas, porque cada registro é livre para ser um pouco diferente e nada na porta
reclama.

Ninguém na Roda Livre fez nada errado em 16 de setembro. O time do aplicativo lançou a versão 4.2. Ela
registra se a pessoa pegou um capacete, e manda o nível da bateria do jeito que a tela do aplicativo
mostra, como `"58%"` em vez de `58`. As duas mudanças faziam sentido de onde o time do aplicativo estava.
Nenhuma chegou aos ouvidos do time de dados.

## Inferindo um esquema, e comparando dois

Como os eventos não declaram o próprio esquema, um programa pode deduzi-lo lendo-os: cada campo, pelo
nome com pontos, com os tipos em que apareceu e quantos registros o tinham. Faça isso para dois lotes e
compare, e a deriva se imprime sozinha. Salve isto como `drift.py`:

```python
# shapes/drift.py
import json
import sys


def paths(obj, prefix=''):
    for key, value in obj.items():
        if isinstance(value, dict):
            yield from paths(value, prefix + key + '.')
        else:
            yield prefix + key, type(value).__name__


def infer(path):
    seen, rows = {}, 0
    for line in open(path):
        rows += 1
        for name, kind in paths(json.loads(line)):
            seen.setdefault(name, {}).setdefault(kind, 0)
            seen[name][kind] += 1
    return seen, rows


old, n_old = infer(sys.argv[1])
new, n_new = infer(sys.argv[2])
print('schema of', sys.argv[1])
for name, kinds in sorted(old.items()):
    present = sum(kinds.values())
    print(f'  {name:14} {"/".join(sorted(kinds)):5} in {present} of {n_old}')
print('changes in', sys.argv[2])
for name in sorted(old.keys() | new.keys()):
    a, b = sorted(old.get(name, {})), sorted(new.get(name, {}))
    if not a:
        print(f'  new field    {name} ({"/".join(b)})')
    elif not b:
        print(f'  gone         {name}')
    elif a != b:
        print(f'  type changed {name}: {"/".join(a)} -> {"/".join(b)}')
```

`paths` percorre um evento e devolve o nome com pontos de cada campo junto com o nome do seu tipo em
Python. `infer` faz isso para cada linha de um arquivo e conta. O último laço compara os dois conjuntos
de nomes e tipos. Rode nos dois dias:

```
ana@lab:~/roda/shapes$ python drift.py rides-2025-09-15.jsonl rides-2025-09-16.jsonl
schema of rides-2025-09-15.jsonl
  app            str   in 6 of 6
  bike.battery   int   in 6 of 6
  bike.id        str   in 6 of 6
  charges        list  in 6 of 6
  coupon         str   in 1 of 6
  end.minutes    int   in 5 of 6
  end.station    str   in 5 of 6
  ride_id        str   in 6 of 6
  start.at       str   in 6 of 6
  start.station  str   in 6 of 6
changes in rides-2025-09-16.jsonl
  type changed bike.battery: int -> str
  new field    helmet (bool)
```

O primeiro bloco é o esquema de 15 de setembro, inferido: dez campos, os tipos que tinham, e com que
frequência apareciam. Ele diz o que a seção anterior mostrou à mão, agora para todos os campos de uma
vez: `coupon` estava em 1 evento de 6, e `end.minutes` e `end.station` em 5 de 6. Ele também mostra
`start.at` como `str`, porque o JSON não tinha outro jeito de enviá-lo.

O segundo bloco é a deriva. **Um campo novo quase não faz mal**: `helmet` só não é lido por nada ainda,
e fica sem uso até alguém pedir por ele. **Um tipo que mudou é o perigoso.** Qualquer coisa que some
`bike.battery` ou tire a média dele agora encontra `"58%"`. Em Python isso hoje é um `TypeError`, que é
o tipo barulhento. Carregado numa coluna que aceita texto, ele entraria sem erro e ordenaria `"100%"`
antes de `"58%"`, porque texto é comparado um caractere por vez, e todo gráfico ordenado por bateria
estaria errado sem um erro em lugar nenhum.

## O que o time de dados faz com isso

A deriva não pode ser evitada do lado do time de dados; o aplicativo é de outra pessoa e vai mudar de
novo. O que dá para decidir é **onde ela é percebida**:

- na porta, por uma conferência como o `drift.py` rodada em cada lote antes de ele ser usado, que para
  ou avisa enquanto o lote ainda é pequeno e a causa tem uma versão de idade;
- no leitor, quando um relatório quebra, e aí três semanas de eventos podem ter as duas formas;
- nunca, quando a forma nova é convertida em silêncio em algo errado, que é o caso contra o qual vale
  projetar.

A outra metade é a conversa. Um **contrato de dados**, que a aula 4 apresentou, é o acordo com o time
do aplicativo sobre o que um evento contém, para que mudar um tipo vire algo que eles avisam antes da
versão sair, em vez de algo que o time de dados descobre depois. A aula 6 mostra como alguns formatos
carregam um esquema dentro do arquivo e deixam que ele mude seguindo regras, e a aula 7 constrói
conferências que rodam na chegada. As duas são respostas à pergunta desta seção.
