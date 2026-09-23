---
title: "\"Depende de\": a única ferramenta por trás das três formas"
version: 2
---

Toda forma normal é enunciada em termos de uma ideia, e ela é mais simples que o nome dela. Se você
entender esta seção, as três seguintes são contabilidade.

> **B depende de A** quando saber A basta para saber B. Me dê A e eu te digo B, toda vez, sem mais
> nenhuma informação.

O livro-texto chama isso de **dependência funcional** e escreve `A → B`. A seta é toda a notação, e
vale ler em voz alta como *"A determina B"*.

## Lendo-as na tabela de matrículas

Pegue a tabela da seção anterior e pergunte, coluna por coluna, *o que preciso saber para saber
isto?*

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 258\" role=\"img\" aria-label=\"Quatro setas de dependência da tabela de matrículas. A primeira, destacada de outro jeito, vai de enrolment_id para tudo e está marcada como a chave determinando toda coluna — a única seta que você quer. As outras três vão de student_email para student_name, de course_code para course_title e teacher, e de teacher para teacher_room, cada uma marcada como uma coluna que não é a chave determinando outra. Uma nota diz que cada uma delas é um fato guardado uma vez por matrícula em vez de uma vez só.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Leia cada seta em voz alta como \"determina\": saber o da esquerda basta para saber o da direita, toda vez.</text><rect x=\"14\" y=\"44\" width=\"150\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"56.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">enrolment_id</text><path d=\"M168 56.0 L214 56.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></path><path d=\"M214 56.0 L207 52.0 L207 60.0 Z\" fill=\"var(--phosphor)\"></path><rect x=\"218\" y=\"46\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">everything</text><text x=\"390\" y=\"56.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a chave determina toda coluna — que é a única seta que você quer</text><rect x=\"14\" y=\"82\" width=\"150\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"94.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">student_email</text><path d=\"M168 94.0 L214 94.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></path><path d=\"M214 94.0 L207 90.0 L207 98.0 Z\" fill=\"var(--amber)\"></path><rect x=\"218\" y=\"84\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">student_name</text><text x=\"390\" y=\"94.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma coluna que não é a chave determinando outra</text><rect x=\"14\" y=\"120\" width=\"150\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"142.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">course_code</text><path d=\"M168 142.0 L214 142.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></path><path d=\"M214 142.0 L207 138.0 L207 146.0 Z\" fill=\"var(--amber)\"></path><rect x=\"218\" y=\"122\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"132\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">course_title</text><rect x=\"218\" y=\"144\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">teacher</text><text x=\"390\" y=\"142.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma coluna que não é a chave determinando outra</text><rect x=\"14\" y=\"178\" width=\"150\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"190.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">teacher</text><path d=\"M168 190.0 L214 190.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></path><path d=\"M214 190.0 L207 186.0 L207 194.0 Z\" fill=\"var(--amber)\"></path><rect x=\"218\" y=\"180\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">teacher_room</text><text x=\"390\" y=\"190.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma coluna que não é a chave determinando outra</text><text x=\"14\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Três das quatro setas começam onde não é a chave. Cada uma é um fato guardado uma vez por matrícula, e não uma vez só.</text><text x=\"14\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Isso é o conteúdo inteiro das três seções seguintes: ache as setas que não começam na chave e dê uma tabela a cada uma.</text></svg>", "caption": "Uma seta que não começa na chave é um fato morando na tabela errada. Achá-las é o trabalho; as três formas são nomes para qual tipo você achou."}
```

Leia a primeira: me diga `ana@ex.com` e eu te digo `Ana Lopes`, sem olhar qual curso nem qual nota.
O nome do aluno depende do aluno e de mais nada.

Leia a terceira: me diga que a professora é `Reis` e eu te digo a sala. A sala depende da
professora, não do curso e não da matrícula.

E `grade` não está em nenhuma dessas listas, que é a parte interessante. Me diga a aluna e eu não
consigo dizer a nota — ela tem várias. Me diga o curso e também não. A nota precisa das **duas**:

```
student_email, course_code  →  grade
```

Isso é uma dependência de um *par*, e é a que sobrevive a toda divisão abaixo, porque a nota é
genuinamente um fato sobre o par. A aula 1 encontrou essa ideia como *fatos que pertencem ao par*,
na tabela de ligação. É a mesma coisa com um nome.

## O teste que te mantém honesto

A armadilha é responder pelo que a tabela por acaso contém hoje em vez de pelo que é verdade.

Hoje, toda linha com `SQL101` também tem `Reis`. Isso significa que `course_code → teacher`? Só se
for verdade de toda linha que possa vir a existir. Faça a pergunta sobre o mundo:

> **O mesmo A poderia alguma vez aparecer com dois B diferentes?**

Se sim, não há dependência. Se não — se isso seria um erro que alguém iria querer impedir — a
dependência é real.

Teste nesta: SQL101 poderia ter dois professores? Numa escola em que um curso tem um professor,
não, e `course_code → teacher` vale. Numa escola em que cursos são co-lecionados, sim, e não vale —
e o modelo certo é então outro. **A dependência é um fato sobre o negócio, não sobre os dados que
você tem por acaso**, que é por que normalização não pode ser feita por um programa olhando linhas.

## Três tipos, e duas das formas têm o nome deles

Uma **dependência total** da chave é o caso saudável: a coluna precisa de toda a chave e de mais
nada. `grade` precisa de `student_email` e `course_code`.

Uma **dependência parcial** é de *parte* de uma chave composta. `student_name` precisa só de
`student_email`, que é metade da chave — então o nome está sendo guardado numa tabela cuja chave é
mais fina que o fato. É isso que a **2FN** remove.

Uma **dependência transitiva** passa por uma coluna comum. A chave determina `teacher`, e `teacher`
determina `teacher_room`, então a chave determina a sala *por meio da* professora. É isso que a
**3FN** remove.

```localised
chave  →  teacher  →  teacher_room
          └────── o passo que a torna transitiva
```

As duas são a mesma doença com encanamento diferente: **um fato está sendo guardado em algum lugar
cuja identidade não é a coisa de que o fato trata.** A sala é um fato sobre uma professora, mantido
numa tabela cujas linhas são matrículas, então é repetido uma vez por matrícula e pode discordar de
si mesmo.

## Por que a chave valeu todo aquele trabalho na aula 1

Note contra o que cada uma dessas definições é enunciada: **a chave**. Parcial significa parte da
chave; transitiva significa não diretamente da chave. Uma tabela sem chave primária não tem forma
normal nenhuma, porque não há de que as colunas dependam.

Essa é a ligação entre as duas aulas. A aula 1 disse "dê uma chave a cada tabela" como regra
prática. Aqui se revela que a chave é o que torna possível dizer qualquer coisa precisa sobre o
projeto.

## As três formas, na linguagem que você já tem

Você consegue lê-las agora, e elas devem soar quase óbvias:

| forma | a regra |
|---|---|
| **1FN** | toda célula guarda um valor único; não há grupos repetidos |
| **2FN** | 1FN, e nenhuma coluna não-chave depende só de *parte* da chave |
| **3FN** | 2FN, e nenhuma coluna não-chave depende de outra coluna não-chave |

Que é a frase da seção anterior, mais uma vez, e agora deve soar diferente:

> Toda coluna não-chave depende da chave, da chave **inteira**, e de **nada além** da chave.
