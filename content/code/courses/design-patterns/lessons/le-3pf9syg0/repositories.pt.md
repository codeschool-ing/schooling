---
title: "Repositórios: uma coleção de agregados, onde quer que morem"
version: 1
---

**Um repositório dá ao domínio a ilusão de uma coleção de agregados em memória: buscar um pelo id,
salvar um de volta, e não se preocupar com onde ele fica guardado.** O código de domínio pede um
sócio e recebe um `Member` inteiro, empréstimos incluídos. Se isso veio de um dicionário, do SQLite
ou de um servidor do outro lado da rede é assunto do repositório, e só dele.

A ideia errada é o repositório como embrulho de tabela: uma classe por tabela, um `LoanRepository`
com `insert_loan` e `update_loan`. Isso é um objeto de acesso a dados, e ele põe uma segunda porta no
agregado. O código agora consegue acrescentar um empréstimo sem perguntar ao sócio, e a regra dos
cinco empréstimos de duas seções atrás vaza por ali. **Existe um repositório por raiz de agregado, e
ele fala em agregados, nunca em linhas.** Há um `MemberRepository` e nenhum `LoanRepository`, porque
um empréstimo nunca é carregado sem o seu sócio.

Eis dois repositórios atrás de um protocolo, e um caso de uso rodado contra os dois. `member.py` é o
agregado de duas seções atrás:

```schooling-example
{"language": "python", "file": "repositories.py", "parts": [
 {"code": "# repositories.py\nimport copy\nimport sqlite3\nfrom datetime import date\nfrom typing import Protocol\n\nfrom member import Loan, Member, Refused\nfrom money import Money\n\n\nclass MemberRepository(Protocol):\n    def get(self, member_id: str) -> Member: ...\n    def save(self, member: Member) -> None: ...", "note": "O protocolo é tudo o que o resto do código sabe sobre armazenamento: buscar um sócio pelo id, salvar um sócio. Ele fala em agregados, nunca em linhas."},
 {"code": "\n\nclass InMemoryMembers:\n    def __init__(self):\n        self._rows: dict[str, Member] = {}\n\n    def get(self, member_id: str) -> Member:\n        return copy.deepcopy(self._rows[member_id])\n\n    def save(self, member: Member) -> None:\n        self._rows[member.id] = copy.deepcopy(member)", "note": "A versão em memória guarda cópias profundas, então uma mudança só conta depois de salva, como num banco. Sem as cópias, um teste contra ela passaria para um código que esqueceu de chamar `save`."},
 {"code": "\n\nclass SqliteMembers:\n    def __init__(self, db: sqlite3.Connection):\n        self.db = db\n        db.executescript(\"\"\"\n            CREATE TABLE IF NOT EXISTS members (id TEXT PRIMARY KEY, name TEXT, owed INTEGER);\n            CREATE TABLE IF NOT EXISTS loans (member TEXT, copy TEXT, due TEXT);\n        \"\"\")\n\n    def get(self, member_id: str) -> Member:\n        row = self.db.execute(\"SELECT name, owed FROM members WHERE id = ?\", (member_id,)).fetchone()\n        if row is None:\n            raise KeyError(member_id)\n        member = Member(member_id, row[0])\n        member.owed = Money(row[1])\n        member._loans = [Loan(c, date.fromisoformat(d)) for c, d in self.db.execute(\n            \"SELECT copy, due FROM loans WHERE member = ? ORDER BY copy\", (member_id,))]\n        return member", "note": "A versão SQLite mapeia um agregado em duas tabelas. É o único lugar fora de `Member` que mexe em `_loans`: reconstruir um agregado a partir do armazenamento é trabalho do repositório, como um ORM faz por reflexão."},
 {"code": "\n    def save(self, member: Member) -> None:\n        with self.db:\n            self.db.execute(\"INSERT OR REPLACE INTO members VALUES (?, ?, ?)\",\n                            (member.id, member.name, member.owed.cents))\n            self.db.execute(\"DELETE FROM loans WHERE member = ?\", (member.id,))\n            self.db.executemany(\"INSERT INTO loans VALUES (?, ?, ?)\",\n                                [(member.id, l.copy_id, l.due.isoformat()) for l in member.loans])", "note": "`save` grava o agregado inteiro numa transação, a linha do sócio e os empréstimos juntos. Um empréstimo não pode ser salvo sem o seu sócio, porque não existe método que faça isso."},
 {"code": "\n\ndef lend_copy(members: MemberRepository, member_id: str, copy_id: str, today: date) -> str:\n    member = members.get(member_id)\n    try:\n        member.borrow(copy_id, \"book\", today)\n    except Refused as err:\n        return f\"refused: {err}\"\n    members.save(member)\n    return f\"lent {copy_id}\"", "note": "O caso de uso: carregar, pedir ao agregado, salvar. Ele é tipado pelo protocolo e não faz ideia de que classe recebeu."},
 {"code": "\n\nif __name__ == \"__main__\":\n    for members in (InMemoryMembers(), SqliteMembers(sqlite3.connect(\":memory:\"))):\n        members.save(Member(\"m-001\", \"Bia\"))\n        results = [lend_copy(members, \"m-001\", f\"C-{n:04d}\", date(2026, 3, 2)) for n in range(1, 7)]\n        print(type(members).__name__, \"|\", results[0], \"...\", results[-1],\n              \"| loans after reload:\", len(members.get(\"m-001\").loans))\n        unsaved = members.get(\"m-001\")\n        unsaved.name = \"Beatriz\"\n        print(\"  renamed without save, stored name:\", members.get(\"m-001\").name)", "note": "Os mesmos seis pedidos contra os dois repositórios, depois uma renomeação que nunca é salva."}
]}
```

```
ana@laptop:~/patterns/ddd-tactical$ python3 repositories.py
InMemoryMembers | lent C-0001 ... refused: Bia already has 5 loans | loans after reload: 5
  renamed without save, stored name: Bia
SqliteMembers | lent C-0001 ... refused: Bia already has 5 loans | loans after reload: 5
  renamed without save, stored name: Bia
```

As duas linhas são iguais: o primeiro empréstimo sai, o sexto é recusado, e cinco empréstimos voltam
quando o sócio é recarregado. Os dois repositórios mantêm o nome guardado `Bia` depois de uma
renomeação que ninguém salvou. `lend_copy` não mudou entre as duas execuções, e não tinha como
diferenciá-las.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l12-repository\" aria-label=\"Um diagrama de classes de repositories.py. No meio, o protocolo MemberRepository com dois métodos, get e save. A função lend_copy, à esquerda, o usa, desenhada como uma seta simples. Embaixo, duas classes o implementam, desenhadas com pontas de seta vazadas: InMemoryMembers, que guarda cópias profundas num dicionário, e SqliteMembers, que mapeia um Member nas tabelas members e loans. As duas buscam e salvam um Member inteiro; não existe repositório para empréstimos.\"><defs><marker id=\"l12-repository-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"35.0\" y=\"43.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lend_copy()</text><rect x=\"290.0\" y=\"24.0\" width=\"190.0\" height=\"74.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"385.0\" y=\"35.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"385.0\" y=\"49.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">MemberRepository</text><path d=\"M290.0 61.0 L480.0 61.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"298.0\" y=\"72.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">get(member_id) -&gt; Member</text><text x=\"298.0\" y=\"86.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">save(member)</text><path d=\"M185.0 60.0 L287.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-repository-dp-ah-paper-dim)\"></path><text x=\"236.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">usa</text><rect x=\"150.0\" y=\"160.0\" width=\"170.0\" height=\"82.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"171.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">InMemoryMembers</text><path d=\"M150.0 182.5 L320.0 182.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"158.0\" y=\"193.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">_rows: dict</text><path d=\"M150.0 205.0 L320.0 205.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"158.0\" y=\"216.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">get()</text><text x=\"158.0\" y=\"230.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">save()</text><path d=\"M235.0 160.0 L235.0 135.0 L385.0 135.0 L385.0 101.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M385.0 101.0 L392.0 113.0 L378.0 113.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"235.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">cópias profundas num dict</text><rect x=\"430.0\" y=\"160.0\" width=\"170.0\" height=\"82.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"515.0\" y=\"171.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">SqliteMembers</text><path d=\"M430.0 182.5 L600.0 182.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"438.0\" y=\"193.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">db: Connection</text><path d=\"M430.0 205.0 L600.0 205.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"438.0\" y=\"216.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">get()</text><text x=\"438.0\" y=\"230.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">save()</text><path d=\"M515.0 160.0 L515.0 135.0 L385.0 135.0 L385.0 101.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M385.0 101.0 L392.0 113.0 L378.0 113.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"515.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">tabelas members e loans</text><text x=\"620.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nenhum LoanRepository:</text><text x=\"620.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um empréstimo nunca é</text><text x=\"620.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">carregado sem o sócio</text></svg>", "caption": "Um protocolo, dois armazenamentos, um caso de uso que não sabe diferenciá-los."}
```

## O que o protocolo compra

O repositório em memória não é um brinquedo para exibição. É o que os testes usam. Toda regra do
agregado e todo caso de uso podem ser testados contra `InMemoryMembers` em milissegundos, sem banco,
e a versão SQLite só precisa de poucos testes próprios: que o que ela salva, ela devolve. É a
história de testes da lição 2 de `testing-cicd`, um dublê atrás de uma interface, alcançado pelo
caminho que a lição 4 chamou de inversão de dependência: o caso de uso depende do protocolo, e as
duas classes de armazenamento também.

Dois detalhes do código estão ali porque a versão em memória precisa se comportar como
armazenamento. Ela guarda cópias profundas, então uma mudança feita num sócio carregado se perde se
não for salva, como num banco; a linha da renomeação prova isso. Um dublê que entregasse os próprios
objetos deixaria passar um teste de um código que esqueceu de chamar `save`, e o defeito só
apareceria em produção.

## Onde ele encontra a unidade de trabalho

A unidade de trabalho da lição 10 era dona da transação de um caso de uso. Numa aplicação maior os
dois padrões andam juntos: a unidade de trabalho entrega os repositórios, cada `save` registra o
agregado nela, e um único commit no fim grava tudo. Com a regra da seção anterior, um agregado por
transação, esse commit costuma gravar um agregado, o que o mantém curto. `SqliteMembers.save` aqui
faz commit sozinho, com `with self.db:`, porque há um agregado só e nenhuma unidade de trabalho para
esperar.

| linguagem | o que costuma fazer o papel de repositório |
|---|---|
| Python | uma classe como as de cima, muitas vezes sobre a `Session` do SQLAlchemy |
| Java | uma interface do Spring Data como `MemberRepository extends CrudRepository<Member, String>`, implementada em tempo de execução |
| Go | uma interface declarada onde é usada, com uma struct sobre `database/sql` que a satisfaz |
| TypeScript | uma classe sobre o client do TypeORM ou do Prisma, atrás de uma interface que o domínio declara |

O Spring Data deixa o repositório quase de graça, e deixa um repositório por tabela igualmente de
graça. Declarar um só para cada raiz de agregado é uma decisão que o framework não toma por você.
