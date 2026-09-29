---
title: Locks
version: 1
---

O candidate é compartilhado, e dois scripts editando ele ao mesmo tempo fariam cada um o commit do
trabalho pela metade do outro. **A resposta do NETCONF é um lock num datastore**, obtido com `lock`
e devolvido com `unlock`. Enquanto uma sessão o detém, a edição de qualquer outra sessão é
recusada:

```schooling-example
{
  "language": "python",
  "file": "locks.py",
  "parts": [
    {
      "code": "from ncclient.operations import RPCError\n\nfrom nc import connect, interface_config\n\nEDIT = interface_config(\"<interface><name>eth2</name><description>from session B</description></interface>\")\n"
    },
    {
      "code": "with connect() as a, connect() as b:\n    print(\"A session\", a.session_id, \"B session\", b.session_id)\n    a.lock(\"candidate\")\n    print(\"A: lock candidate: ok\")",
      "note": "**Duas sessões, como dois scripts ou duas pessoas teriam.** A pega o lock do candidate."
    },
    {
      "code": "    try:\n        b.edit_config(target=\"candidate\", config=EDIT)\n    except RPCError as e:\n        print(\"B: edit-config:\", e.tag, \"-\", e.message)\n    a.unlock(\"candidate\")\n    print(\"A: unlock candidate: ok\")\n    b.edit_config(target=\"candidate\", config=EDIT)\n    print(\"B: edit-config: ok\")\n    b.discard_changes()",
      "note": "**B é recusada, e fica sabendo quem tem o lock.**"
    }
  ]
}
```

```
ana@ctl:~$ python locks.py
A session 9 B session 10
A: lock candidate: ok
B: edit-config: lock-denied - Operation failed, lock is already held
A: unlock candidate: ok
B: edit-config: ok
```

A recusa tem uma tag própria, **`lock-denied`**, que é o que um script deve procurar: ela quer
dizer "outra pessoa está mudando este equipamento, tente de novo mais tarde", não "sua mudança
está errada". O erro também traz o id da sessão que detém o lock; o `nc1` numerou essas duas
sessões como 9 e 10.

Um lock pertence a uma sessão. **Se a sessão que o detém morre, o lock é liberado**, então um
script que travou não consegue bloquear um equipamento para sempre. É também por isso que um lock
não substitui a coordenação entre pessoas: um colega digitando no CLI de um equipamento sem
NETCONF não vai vê-lo, e um equipamento configurado dos dois jeitos ao mesmo tempo fica com a
configuração de quem escreveu por último.

O hábito que isso sugere para todo script de mudança é curto: **lock, descartar o que houver no
candidate, editar, validar, commit, unlock.** Descartar primeiro joga fora uma edição que alguém
abandonou, e o lock garante que ninguém acrescente uma no meio.
