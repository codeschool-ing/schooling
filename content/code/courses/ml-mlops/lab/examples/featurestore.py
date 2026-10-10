FILE = __file__.replace('/examples/', '/programs/')
LANGUAGE = "python"
NAME = "featurestore.py"
PARTS = [
 ('"""featurestore.py', "The four commands are the whole interface. Two write the offline store, one builds the online store from it, and one reads a member the way a service would.",
  "Os quatro comandos são a interface inteira. Dois gravam o armazenamento offline, um monta o online a partir dele, e um lê um membro do jeito que um serviço leria."),
 ("import datetime", "The store is a file of its own, `features.db`, beside the shop. `MAX_AGE` is how old a value may be and still be used, the store's **time to live**.",
  "O armazenamento é um arquivo próprio, `features.db`, ao lado da loja. `MAX_AGE` é a idade máxima de um valor que ainda pode ser usado, o **tempo de vida** do armazenamento."),
 ("def snapshot", "A snapshot is `features.py` run for one day and appended, with the day beside every row as `as_of`. **The label is dropped before anything is stored**: a feature store holds what was known on a day, and the label is what was learned after it. Running a day twice replaces it rather than doubling it.",
  "Uma fotografia é o `features.py` rodado para um dia e anexado, com o dia ao lado de cada linha como `as_of`. **O rótulo é descartado antes de qualquer coisa ser guardada**: uma feature store guarda o que se sabia num dia, e o rótulo é o que se descobriu depois dele. Rodar um dia duas vezes o substitui em vez de duplicá-lo."),
 ("def historical", "The **point-in-time join**. For each row asked about, `merge_asof` takes that member's newest snapshot on or before the moment, never after, and gives nothing if the newest is older than `MAX_AGE`. The `row` column puts the answers back in the order they were asked.",
  "A **junção no ponto do tempo**. Para cada linha perguntada, o `merge_asof` pega a fotografia mais nova daquele membro até o momento, nunca depois, e não dá nada se a mais nova for mais velha que `MAX_AGE`. A coluna `row` devolve as respostas na ordem em que foram perguntadas."),
 ("def online", "The online store is rebuilt from the offline one: each member's latest row, **unless that row is older than `MAX_AGE`**, and one index so a lookup by member is a single seek.",
  "O armazenamento online é reconstruído a partir do offline: a linha mais nova de cada membro, **a menos que ela seja mais velha que `MAX_AGE`**, e um índice para que a busca por membro seja um único acesso."),
 ("def get", "What a service calls: one member, one row, or `None` when the store has nothing fresh enough.",
  "O que um serviço chama: um membro, uma linha, ou `None` quando o armazenamento não tem nada novo o bastante."),
 ('if __name__ == "__main__":', "`backfill` takes one snapshot a week between two days; `snapshot` takes one, which is what a nightly job would run after the shop's load.",
  "`backfill` tira uma fotografia por semana entre dois dias; `snapshot` tira uma, que é o que um job noturno rodaria depois da carga da loja."),
]
