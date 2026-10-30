---
title: Duas telas, duas cópias dos dados
version: 1
---

**Desde a aula 8 o planner carrega de propósito um defeito: a semana e a página do curso guardam
cada uma uma cópia dos dados, e as cópias se afastam.** O `Week` e o `CoursePage` declaram cada um
`resource({ loader: loadPlanner })`, então cada um busca o `courses.json` e guarda o que voltou.
Marcar uma sessão como feita muda a cópia do `CoursePage`, e o `Week` não tem como saber.

O curso de JavaScript tem uma sessão ainda por fazer nesta semana, no sábado, dia 24, de 50 minutos.
Marque-a, e leia o total da semana depois:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week-summary --network --do 'check 2026-10-24, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /courses.json  200
net  GET /courses.json  200
-- check 2026-10-24, 50 minutes
165 minutes planned, 90 done.

75 minutes to go.

Done this week
```

Dois pedidos do mesmo arquivo, um por componente, e depois da marcação a semana ainda diz 90 minutos
feitos, onde deveria dizer 140. Cada número na página está certo sobre a própria cópia. Nada está
quebrado em nenhum dos dois componentes, e é por isso que um defeito assim sobrevive: o erro está em
como os dois estão arranjados, e isso não está em nenhum dos arquivos.

## O arranjo de que ele precisa

As duas telas querem a mesma coisa: **um** conjunto de cursos e sessões, carregado uma vez, mudado
num lugar, e lido por quem precisar. Foi nisso que a seção sobre hierarquia da aula 10 terminou: uma
instância no injetor raiz, pedida pelas duas, é uma cópia só.

Uma classe que guarda essa cópia e as operações sobre ela, sem template próprio, é o que o Angular
chama de **serviço**. Para o framework não é um tipo diferente de coisa. `@Injectable`,
`providedIn: 'root'`, `inject`: tudo nele é a aula 10, aplicado a uma classe cujo trabalho são os
dados da aplicação em vez de uma saudação.
