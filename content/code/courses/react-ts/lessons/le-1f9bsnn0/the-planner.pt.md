---
title: O app que este curso constrói
version: 1
---

**O curso constrói um app só, um planejador de estudos, e o faz crescer aula a aula.** Um estudante
mantém a lista dos cursos que está fazendo, abre um deles, acrescenta sessões de estudo com uma data
e uma duração, marca cada uma quando termina, e vê quanto do plano da semana está feito. Ele é
pequeno o bastante para que cada linha apareça numa aula, e precisa de tudo de que um app de verdade
precisa: uma lista, um formulário, dados de um servidor, uma segunda tela com endereço próprio, e um
número calculado a partir de tudo isso.

**O `angular`, o `vue` e o `svelte` constroem o mesmo app**, com as mesmas telas e os mesmos dados, e
a aula 24 abre as versões deles ao lado da sua. É por isso que as telas abaixo ficam fixadas agora,
antes de qualquer linha ser escrita: o que muda entre os quatro cursos é o código, e nada que um
usuário veria.

## Duas telas

```schooling-figure
{"svg": "<svg data-fig=\"screens\" viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"As duas telas do planejador. À esquerda, a lista de cursos: o título Study planner, a semana de 19 de outubro de 2026 com 80 de 195 minutos feitos, e três cursos com suas sessões e minutos naquela semana. Escolher Statistics abre a tela da direita: um link de volta aos cursos, o título Statistics, as duas sessões com uma caixa para marcar cada uma, e um formulário com data, minutos e um botão Add session.\"><rect x=\"10\" y=\"40\" width=\"330\" height=\"250\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 · os cursos</text><text x=\"26\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Study planner</text><text x=\"26\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Week of 19 Oct 2026</text><text x=\"26\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">80 of 195 minutes done</text><rect x=\"22\" y=\"128\" width=\"306\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">Statistics</text><text x=\"34\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2 sessions · 90 min</text><rect x=\"22\" y=\"176\" width=\"306\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">Spanish</text><text x=\"34\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2 sessions · 60 min</text><rect x=\"22\" y=\"224\" width=\"306\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">Organic chemistry</text><text x=\"34\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 session · 45 min</text><rect x=\"380\" y=\"40\" width=\"330\" height=\"250\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2 · um curso</text><text x=\"396\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Back to courses</text><text x=\"396\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Statistics</text><text x=\"396\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">[x]</text><text x=\"424\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Mon 19 Oct · 50 min</text><text x=\"396\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">[ ]</text><text x=\"424\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Wed 21 Oct · 40 min</text><line x1=\"392\" y1=\"170\" x2=\"698\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"396\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Add a session</text><text x=\"396\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Date</text><rect x=\"450\" y=\"203\" width=\"110\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"505.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026-10-24</text><text x=\"396\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Minutes</text><rect x=\"450\" y=\"231\" width=\"60\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">30</text><rect x=\"396\" y=\"260\" width=\"104\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"448.0\" y=\"271.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Add session</text><line x1=\"330\" y1=\"147\" x2=\"380\" y2=\"147\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"380.0,147.0 372.5,150.2 372.5,143.8\" fill=\"var(--phosphor)\"></polygon></svg>", "caption": "O que o planejador mostra, em todos os cursos da bifurcação. As palavras do próprio app são em inglês nas duas línguas.", "same": ["Study planner", "Week of 19 Oct 2026", "80 of 195 minutes done", "Statistics", "2 sessions · 90 min", "Spanish", "2 sessions · 60 min", "Organic chemistry", "1 session · 45 min", "Back to courses", "Mon 19 Oct · 50 min", "Wed 21 Oct · 40 min", "Add a session", "Date", "Minutes", "Add session"]}
```

A primeira tela lista os cursos. No topo fica a semana: os minutos planejados de segunda a domingo, e
quantos desses minutos estão feitos. Cada curso mostra as sessões dele naquela semana e os minutos
delas. Escolher um curso abre a segunda tela, que lista as sessões daquele curso com uma caixa para
marcar cada uma, e um formulário para acrescentar outra. Um link volta.

A semana precisa vir de algum lugar. No seu navegador ela é a semana de hoje. Nas transcrições ela é
a semana de **segunda-feira, 19 de outubro de 2026**, porque uma transcrição gravada num dia e lida em
outro precisa mostrar os mesmos números, então `look --today 2026-10-21` diz à página que é aquela
quarta-feira. Os dados abaixo caem nessa semana de propósito; a aula 3 acrescenta botões para andar
entre semanas, e com eles você chega a ela de qualquer data.

## Os dados

Os dados do planejador são um arquivo JSON, e o servidor de desenvolvimento o serve como está, a
partir de `public/`. Salve como `public/courses.json`:

```json
{
  "courses": [
    { "id": "statistics", "name": "Statistics" },
    { "id": "spanish", "name": "Spanish" },
    { "id": "chemistry", "name": "Organic chemistry" }
  ],
  "sessions": [
    { "id": "s1", "course": "statistics", "date": "2026-10-19", "minutes": 50, "done": true },
    { "id": "s2", "course": "statistics", "date": "2026-10-21", "minutes": 40, "done": false },
    { "id": "s3", "course": "spanish", "date": "2026-10-20", "minutes": 30, "done": true },
    { "id": "s4", "course": "spanish", "date": "2026-10-23", "minutes": 30, "done": false },
    { "id": "s5", "course": "chemistry", "date": "2026-10-14", "minutes": 60, "done": true },
    { "id": "s6", "course": "chemistry", "date": "2026-10-22", "minutes": 45, "done": false }
  ]
}
```

```
ana@dev:~/planner$ curl -s http://localhost:5173/courses.json | head -n 5
{
  "courses": [
    { "id": "statistics", "name": "Statistics" },
    { "id": "spanish", "name": "Spanish" },
    { "id": "chemistry", "name": "Organic chemistry" }
```

Três cursos e seis sessões. **Uma sessão cita o curso pelo `id` dele**, nunca pelo nome: renomeie
"Organic chemistry" para "Chemistry II" e cada sessão continua pertencendo a ele, porque nada
apontava para as palavras. Uma data é escrita `YYYY-MM-DD`, o único formato que fica em ordem certa
quando ordenado como texto, e uma duração é um número inteiro de minutos.

## Os números a esperar

Cinco das seis sessões caem entre segunda, 19, e domingo, 25 de outubro; a `s5`, no dia 14, é da
semana anterior. Então a semana que as transcrições mostram planeja **195 minutos**, 50 + 40 + 30 +
30 + 45, e **80** deles estão feitos, os 50 e os 30 já marcados. Statistics tem 90 minutos naquela
semana, Spanish 60 e Organic chemistry 45. Cada aula que desenha a primeira tela precisa chegar a
esses números, e a aula 22 os transforma num teste.
