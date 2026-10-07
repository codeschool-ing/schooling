---
title: Escolhendo uma ferramenta
version: 1
---

Três ferramentas deram a mesma resposta, então a escolha entre elas não é sobre estar certo. É sobre
tudo o que cerca a resposta:

| | Planilha | Power Query | SQL | pandas | dplyr |
|---|---|---|---|---|---|
| Registra o que foi feito | não | sim, como etapas | sim, como consulta | sim, como script | sim, como script |
| Adivinha tipos a menos que se diga | ao abrir | ao importar, editável | não: converte ou falha | sim, a menos que `dtype=str` | sim, a menos que `col_types` |
| Fácil de revisar num diff | não | possível, como código M | sim | sim | sim |
| Bom para | olhar, ajustes pequenos | importações repetíveis | dados onde estão | explorar, comparação aproximada | pipelines legíveis |

Algumas regras saem da tabela, e são as mesmas seja qual for a ferramenta:

- **A ferramenta que registra o trabalho é a ferramenta para limpar.** Uma mudança digitada numa
  célula é uma mudança que ninguém consegue refazer, revisar ou desfazer no mês que vem. A aula 17 é
  exatamente sobre isso.
- **Use a ferramenta que a próxima pessoa sabe ler.** Uma consulta para uma equipe que trabalha em
  SQL, um script para uma equipe que trabalha em Python ou R, Power Query para uma equipe que vive no
  Excel. Uma limpeza que ninguém mais consegue acompanhar é uma limpeza que vai ser refeita do zero.
- **Passe de uma ferramenta para outra em fronteiras limpas**, com tipos declarados dos dois lados:
  um CSV gravado com os códigos como texto e lido com `dtype=str`, ou uma tabela no banco com os seus
  tipos e verificações. A maior parte dos defeitos deste curso nasceu exatamente numa travessia
  assim, por uma ferramenta que adivinhou.
- **Quando duas ferramentas precisam concordar, prove**, como esta aula fez: a mesma especificação,
  duas implementações, os mesmos números.

Nenhuma das quatro é a profissional e as outras amadoras. **O hábito profissional é a tarefa
escrita, os passos registrados e a verificação cruzada**, e toda ferramenta aqui permite os três.
