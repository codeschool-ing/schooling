---
title: A parte que prova algo
version: 1
---

O esqueleto funciona. Aqui está ele rodando, com um item e duas professoras que querem o mesmo:

```
ana@laptop:~/loanbook$ python3 app.py add "Projector 2"
added Projector 2
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/loan -d '{"borrower": "Beatriz Nunes"}'
{"borrower": "Beatriz Nunes", "due_on": "2026-10-04"}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/loan -d '{"borrower": "Carlos Mendes"}'
{"borrower": "Carlos Mendes", "due_on": "2026-10-04"}
ana@laptop:~/loanbook$ curl -s localhost:8000/api/items | python3 -m json.tool
[
    {
        "id": 1,
        "name": "Projector 2",
        "loan": {
            "borrower": "Beatriz Nunes",
            "lent_on": "2026-09-27",
            "due_on": "2026-10-04"
        }
    },
    {
        "id": 1,
        "name": "Projector 2",
        "loan": {
            "borrower": "Carlos Mendes",
            "lent_on": "2026-09-27",
            "due_on": "2026-10-04"
        }
    }
]
```

Os dois empréstimos foram aceitos, e a lista agora mostra o **Projector 2 duas vezes**, uma para cada
professora. É exatamente a primeira história da Marta na aula 4, reproduzida em quatro comandos, e é a
linha de não deve do briefing quebrada do jeito mais direto possível.

Este é o momento de que a aula trata. O esqueleto prova que uma página, uma API e um banco podem ser
ligados, que é o que toda lista de tarefas prova. **A parte do loanbook que prova algo é esta recusa**, e
ela não está no esqueleto. Se o projeto parasse aqui, seria o tutorial da aula 2 com outro substantivo.

Então a regra de escopo não é *a menor versão que roda*. É: **a menor versão que contém a única coisa que
só este projeto tem**. No loanbook isso quis dizer que a recusa entrou no marco logo depois do esqueleto, `v0.2.0`, antes
de estilo, páginas de erro e deploy. A aula 2 já mostrou o commit que fez isso, e a aula 12 mostra o
teste que a garante.

Todo projeto tem a sua coisa única, e o briefing costuma nomeá-la na linha de não deve. Encontre-a antes
de cortar qualquer coisa, porque ela é o único item da lista que não pode ser cortado.
