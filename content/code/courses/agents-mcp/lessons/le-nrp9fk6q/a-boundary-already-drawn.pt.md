---
title: Uma fronteira que este repositório já traça
version: 1
---

A plataforma em que este curso é publicado é operada por duas pessoas, e as regras dela para essas pessoas, no `CLAUDE.md`, são um exemplo resolvido das três perguntas. Três delas, nas palavras daquele arquivo (que está em inglês):

> **Staff is a role on an account, not a second account.** [...] Three roles, totally ordered — `owner` > `operator` > `read-only` — because a permission matrix is a screen nobody can hold in their head.

> **Mandatory MFA is enforced on the SESSION, not on the account.** [...] **Revoking a role ends every session that held it**, because otherwise removing access is only scheduling it.

> **Every administrative write records the actor.** Two people operate this.

Cada uma responde a uma das perguntas. Os papéis ordenados (dono, operador, só leitura) respondem *o que esta pessoa pode fazer*, numa forma pequena o bastante para raciocinar sobre ela. Conferir o segundo fator em todo pedido, na porta, responde *e se tudo o que um atacante tem é uma senha*. E a auditoria responde *o que acontece quando alguém erra*: há um registro de quem fez.

A auditoria é a parte de que um agente mais precisa, e o pacote que a implementa, `internal/audit`, torna o ator impossível de esquecer. O ator de um registro só pode ser montado por um de dois construtores:

```go
// Actor is who took the action. Unexported fields, and two constructors: an
// entry cannot be assembled with the actor left out, because there is no way to
// write one down that does not name somebody.
type Actor struct {
	id    uuid.UUID
	kind  string
	label string
}

// Staff is a person. The label is their name AT THE TIME, copied in rather than
// joined later: people are renamed and people leave, and an entry that reads
// "changed a plan, actor 9f2c…" a year afterwards is not an answer.
func Staff(id uuid.UUID, label string) Actor {
	return Actor{id: id, kind: KindStaff, label: label}
}

// System is the platform acting on its own — a scheduled job, a webhook, a
// retry. It is a real actor and not an absent one, which is precisely why it
// has a name of its own rather than an empty column.
func System(label string) Actor {
	return Actor{id: systemActor, kind: KindSystem, label: label}
}
```

Um agente que age por uma empresa é um terceiro tipo de ator: nem uma pessoa nem uma tarefa agendada, e deve ser nomeado como ele mesmo em todo registro do que fez. O resto desta aula constrói um hospedeiro que faz isso, e traça a fronteira do agente do jeito que este arquivo traça a da equipe.
