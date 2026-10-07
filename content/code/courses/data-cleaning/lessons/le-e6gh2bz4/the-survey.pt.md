---
title: A pesquisa, e os clientes que não responderam
version: 1
---

**Uma pesquisa é o caso mais puro de dado faltante que existe: a maioria das pessoas não responde, e
ninguém escolhe ao acaso se responde.** No dia seguinte a todo pedido online entregue, a Quitanda
Verde manda uma pesquisa de uma pergunta — de 0 a 10, quanto você nos recomendaria — e informa o Net
Promoter Score: a fração de 9 e 10, os promotores, menos a fração de 0 a 6, os detratores.

Primeiro a taxa de resposta, e depois se ela depende de como foi a entrega:

```schooling-example
{
  "language": "python",
  "file": "survey.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "survey = pd.read_csv(\"raw/survey.csv\", dtype=str, keep_default_na=False, na_values=[\"\"])\norders = pd.read_csv(\"raw/orders.csv\", dtype=str, keep_default_na=False,\n                     na_values=[\"\"]).drop_duplicates()\n",
      "note": "A pesquisa e os pedidos, os dois como texto, os pedidos sem as repetições."
    },
    {
      "code": "both = survey.merge(orders[[\"order_id\", \"courier\", \"delivery_minutes\"]], on=\"order_id\")\nboth[\"answered\"] = both[\"nps\"].notna()\n",
      "note": "Cada convite ligado ao seu pedido, para carregar o entregador e o tempo de entrega. Uma resposta é uma nota que não está vazia."
    },
    {
      "code": "print(f\"invitations: {len(both)}, answered: {both['answered'].sum()} \"\n      f\"({both['answered'].mean() * 100:.1f}%)\")\n",
      "note": "A taxa de resposta geral."
    },
    {
      "code": "own = both[both[\"courier\"] == \"propria\"].copy()\nown[\"band\"] = pd.cut(pd.to_numeric(own[\"delivery_minutes\"]), [0, 40, 60, 80, 120],\n                     right=False)\nprint((own.groupby(\"band\", observed=True)[\"answered\"].mean() * 100).round(1).to_string())\n",
      "note": "Para a frota própria, a taxa de resposta por faixa de tempo de entrega. `right=False` faz cada faixa incluir a borda de baixo: 40 pertence a `[40, 60)`."
    }
  ]
}
```

```
ana@lab:~/clean$ python survey.py
invitations: 26494, answered: 9656 (36.4%)
band
[0, 40)      37.2
[40, 60)     38.2
[60, 80)     34.7
[80, 120)    32.4
```

Cerca de um convite em três é respondido. **E, passados os 40 minutos, a taxa cai à medida que a
entrega fica mais lenta**: 38,2% para entregas de 40 a 60 minutos, 34,7% de 60 a 80, e 32,4% para as
de 80 minutos ou mais. Clientes cuja entrega foi mal respondem menos.

Isso é de novo uma coluna visível prevendo os vazios, o que faz a pesquisa parecer MAR no tempo de
entrega. Em parte, é. Mas pense no que leva alguém a responder: não os minutos em si, mas **como o
cliente se sentiu** — exatamente a nota que falta. Um cliente irritado com uma entrega rápida que
chegou com as mangas machucadas também pula a pesquisa, e nenhuma coluna registra as mangas. A
satisfação move tanto a nota quanto a decisão de dá-la. Isso é MNAR, com uma sombra visível.

## O que isso faz com o número

De novo o laboratório tem o que o trabalho nunca tem: `truth/nps.csv` guarda a nota que todo cliente
convidado teria dado, respondendo ou não.

```python
import pandas as pd


def nps(scores):
    return round(((scores >= 9).mean() - (scores <= 6).mean()) * 100, 1)


survey = pd.read_csv("raw/survey.csv")
truth = pd.read_csv("~/clean-data/truth/nps.csv")
print("NPS from the answers:      ", nps(survey["nps"].dropna()))
print("NPS of everybody invited:  ", nps(truth["nps"]))
```

```
ana@lab:~/clean$ python nps_truth.py
NPS from the answers:       40.6
NPS of everybody invited:   31.3
```

**O NPS das respostas é 40,6. O NPS de todos os convidados é 31,3.** Nove pontos, por causa de uma
taxa de resposta e de uma seleção que ninguém enxerga no arquivo. E o viés corre na direção que
lisonjeia, que é a de sempre: quem está menos contente com um serviço é também quem menos se dispõe
a gastar um minuto contando isso a ele.

## O que dá para fazer só com o dado real

Nenhuma técnica recupera as notas que faltam; elas nunca foram dadas. O que um relatório cuidadoso
faz:

- **informa a taxa de resposta ao lado da nota**, sempre, para o leitor poder pesá-la;
- **compara quem respondeu e quem não respondeu no que se sabe dos dois** — tempo de entrega, canal,
  frequência de compra — e diz onde diferem, como a tabela acima faz para o tempo de entrega;
- **acompanha a tendência mais do que o nível**: se a seleção se mantém parecida de um mês para o
  outro, uma nota em queda ainda quer dizer algo, mesmo com o nível lisonjeado;
- e, quando o número importa o bastante, **pergunta diretamente a uma pequena amostra aleatória de
  quem não respondeu**, por telefone, que é o único jeito de medir as pessoas que a pesquisa não vê.

A aula 4 volta a isso com as opções para os tempos de entrega, em que a origem tinha a resposta e
simplesmente a jogou fora.
