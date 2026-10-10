---
title: Um modelo, puxado para dois lados
version: 1
---

**Um único modelo que serve às regras e às telas acaba com a forma errada para as duas.** As regras
querem uma estrutura pequena com exatamente o que elas verificam: quem está com qual exemplar, quem
está esperando. As telas querem respostas já juntadas e contadas: um título com o autor e o número
de exemplares na estante. Ponha os dois numa classe e cada tela nova acrescenta uma consulta que
percorre estruturas feitas para as regras, e cada regra nova tem de desviar de campos que só estão
ali para exibição.

A ideia errada a largar primeiro é que essa tensão é questão de desempenho e só importa em escala.
O custo aparece primeiro no projeto, com três títulos, e o problema de velocidade chega depois.

Crie `~/patterns/cqrs` e trabalhe nele durante a lição inteira:

```sh
mkdir -p ~/patterns/cqrs
cd ~/patterns/cqrs
```

## Uma biblioteca com exemplares e fila

O balcão da lição 7 emprestava itens por código. Uma biblioteca de verdade tem vários exemplares de
um título, e um membro pode reservar um título que está emprestado, o que o põe numa fila para o
próximo exemplar que voltar. Aqui está tudo isso numa classe só, do jeito que costuma começar:

```schooling-example
{"language": "python", "file": "strained.py", "parts": [
 {"code": "# strained.py\nfrom datetime import date, timedelta\n\n\nclass Library:\n    LIMIT = 5\n\n    def __init__(self):\n        self.titles = {}       # title_id -> (title, author)\n        self.copies = {}       # copy_id -> title_id\n        self.holder = {}       # copy_id -> (member, due)\n        self.waiting = {}      # title_id -> [member, ...]", "note": "Uma classe para a biblioteca inteira. Um título tem vários exemplares, um exemplar está na estante ou com um membro até uma data, e um título pode ter uma fila de membros esperando por ele."},
 {"code": "\n    # ---- commands: they change the library and enforce the rules\n    def lend(self, copy_id: str, member: str, on: date) -> None:\n        title_id = self.copies[copy_id]\n        queue = self.waiting.get(title_id, [])\n        if copy_id in self.holder:\n            raise ValueError(f\"{copy_id} is already out\")\n        if queue and queue[0] != member:\n            raise ValueError(f\"reserved for {queue[0]}\")\n        if sum(1 for m, _ in self.holder.values() if m == member) >= self.LIMIT:\n            raise ValueError(f\"{member} is at the limit\")\n        if queue:\n            queue.pop(0)\n        self.holder[copy_id] = (member, on + timedelta(days=14))\n\n    def give_back(self, copy_id: str) -> None:\n        del self.holder[copy_id]\n\n    def reserve(self, title_id: str, member: str) -> None:\n        self.waiting.setdefault(title_id, []).append(member)", "note": "Os três comandos, com as regras da lição 7 mais uma: um título reservado vai para o primeiro membro da fila. Cada método precisa de `holder` e `waiting`, e nenhum lê o nome ou o autor de um título."},
 {"code": "\n    # ---- queries: added one screen at a time\n    def availability(self) -> list[str]:\n        rows, visited = [], 0\n        for title_id, (title, author) in sorted(self.titles.items()):\n            on_shelf = 0\n            for copy_id, of_title in self.copies.items():\n                visited += 1\n                if of_title == title_id and copy_id not in self.holder:\n                    on_shelf += 1\n            queue = len(self.waiting.get(title_id, []))\n            rows.append(f\"{title:<20} {author:<20} on shelf {on_shelf}  waiting {queue}\")\n        rows.append(f\"(visited {visited} copy records for {len(self.titles)} titles)\")\n        return rows", "note": "A tela que o balcão mais olha. Para cada título ela percorre todos os exemplares, contando os que estão na estante, e conta quantos registros visitou para o custo também aparecer na tela."},
 {"code": "\n    def loans_of(self, member: str) -> list[str]:\n        return [f\"{self.titles[self.copies[c]][0]}, due {due}\"\n                for c, (m, due) in sorted(self.holder.items()) if m == member]", "note": "Uma segunda tela, os empréstimos de um membro com títulos e vencimentos. Ela junta três dicionários para montar uma linha."},
 {"code": "\n\nif __name__ == \"__main__\":\n    lib = Library()\n    lib.titles = {\"T1\": (\"Dom Casmurro\", \"Machado de Assis\"),\n                  \"T2\": (\"Vidas Secas\", \"Graciliano Ramos\"),\n                  \"T3\": (\"A Hora da Estrela\", \"Clarice Lispector\")}\n    lib.copies = {\"C1\": \"T1\", \"C2\": \"T1\", \"C3\": \"T2\", \"C4\": \"T3\"}\n    lib.lend(\"C1\", \"bia\", date(2026, 3, 2))\n    lib.lend(\"C3\", \"caio\", date(2026, 3, 2))\n    lib.reserve(\"T2\", \"bia\")\n    for row in lib.availability():\n        print(row)\n    print(lib.loans_of(\"bia\"))", "note": "Dois empréstimos e uma reserva, depois as duas telas."}
]}
```

```
ana@laptop:~/patterns/cqrs$ python3 strained.py
Dom Casmurro         Machado de Assis     on shelf 1  waiting 0
Vidas Secas          Graciliano Ramos     on shelf 0  waiting 1
A Hora da Estrela    Clarice Lispector    on shelf 1  waiting 0
(visited 12 copy records for 3 titles)
['Dom Casmurro, due 2026-03-16']
```

A tela está certa: um *Dom Casmurro* está na estante, o único *Vidas Secas* está com o Caio e a Bia
espera por ele. E para dizer isso a classe visitou doze registros de exemplar para três títulos.

## Onde a tensão aparece

**As duas metades da classe leem dados diferentes.** `lend`, `give_back` e `reserve` leem `copies`,
`holder` e `waiting`. Nunca tocam em `titles`, os nomes e autores. As consultas leem tudo, e passam
a maior parte do tempo juntando. Dois grupos de métodos dividem uma classe porque dividem um
assunto, não porque dividem uma necessidade.

**Toda consulta paga por uma estrutura feita para escrita.** `holder` é indexado por exemplar porque
é isso que um empréstimo muda. A tela de disponibilidade quer uma contagem por título, então percorre
todos os exemplares para cada título: 3 títulos vezes 4 exemplares são os 12 que o programa
imprimiu. Uma biblioteca de bairro com 2.000 títulos e 5.000 exemplares visitaria dez milhões de
registros para desenhar uma página. Um índice ajudaria, e seria um índice acrescentado à estrutura
das regras por causa da tela.

**Toda tela nova alarga o modelo.** O balcão pede "exemplares que voltam esta semana"; a classe ganha
um método que ordena `holder` por data. O site pede "mais emprestados do ano"; a classe ganha um
contador que `lend` agora precisa atualizar, e o método de regra passa a carregar um campo que
nenhuma regra lê. Cada acréscimo é pequeno. Depois de um ano, a classe que guarda o limite de
empréstimos é quase toda código de tela, e uma mudança numa delas exige alguém conferindo que
nenhuma regra se mexeu.

Num banco de dados a mesma tensão aparece como um esquema normalizado servindo aos dois: escritas
querem tabelas estreitas e poucos índices, para cada mudança tocar pouco, e telas querem linhas
largas e muitos índices, para cada página ler pouco. Um esquema só é um meio-termo entre elas,
ajustado para o lado que reclamou por último.

## Duas tarefas, dois modelos

O resto da lição separa a classe ao longo da linha que já se vê nela, o comentário que diz
`# ---- queries`. Essa linha tem nome e história. A próxima seção começa pela regra por trás dela,
na escala de um método, e a seguinte a leva para a escala de modelos inteiros, onde ela se chama
CQRS.
