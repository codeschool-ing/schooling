---
title: Os dados do planner, e as suas datas
version: 1
---

**O planner trabalha com um arquivo pequeno de dados e um módulo pequeno de aritmética de datas, e os
dois são JavaScript comum que não sabe nada de Svelte.** Vale manter essa separação desde o primeiro
dia: os dados e as regras sobre semanas podem ser testados sozinhos na aula 19, e os componentes só
precisam mostrá-los.

## Os dados

Três cursos e seis sessões em outubro de 2026. Cada sessão aponta para o seu curso pelo `id` do
curso, tem uma data escrita como `YYYY-MM-DD`, um número de minutos e se está feita. Salve como
`src/lib/planner.json`:

```schooling-example
{"language": "json", "file": "src/lib/planner.json", "parts": [
 {"code": "{\n\t\"courses\": [\n\t\t{ \"id\": \"algebra\", \"name\": \"Linear algebra\" },\n\t\t{ \"id\": \"spanish\", \"name\": \"Spanish\" },\n\t\t{ \"id\": \"guitar\", \"name\": \"Guitar\" }\n\t],", "note": "Três cursos. O `id` é o que uma sessão usa para dizer a que curso pertence; o `name` é só para pessoas."},
 {"code": "\t\"sessions\": [\n\t\t{ \"id\": 1, \"course\": \"algebra\", \"date\": \"2026-10-13\", \"minutes\": 60, \"done\": true },\n\t\t{ \"id\": 2, \"course\": \"spanish\", \"date\": \"2026-10-15\", \"minutes\": 30, \"done\": true },\n\t\t{ \"id\": 3, \"course\": \"algebra\", \"date\": \"2026-10-19\", \"minutes\": 90, \"done\": true },\n\t\t{ \"id\": 4, \"course\": \"guitar\", \"date\": \"2026-10-20\", \"minutes\": 45, \"done\": false },\n\t\t{ \"id\": 5, \"course\": \"spanish\", \"date\": \"2026-10-22\", \"minutes\": 30, \"done\": false },\n\t\t{ \"id\": 6, \"course\": \"algebra\", \"date\": \"2026-10-24\", \"minutes\": 60, \"done\": false }\n\t]\n}", "note": "Seis sessões, em ordem de data. Duas caem na semana de 12 de outubro e quatro na semana de 19 de outubro."}
]}
```

Uma data como string nesse formato tem uma propriedade que deixa tudo o que vem abaixo curto:
**duas delas se comparam corretamente como texto.** `"2026-10-19" < "2026-10-24"` é verdade pelo mesmo
motivo que as datas estão nessa ordem, então não é preciso transformá-las em objetos `Date` para
ordenar ou comparar.

## A semana

Uma semana no planner começa na segunda-feira. Quatro funções bastam para tudo o que o planner vai
fazer com datas: achar a segunda-feira de uma data, mover uma data alguns dias, perguntar se uma data
está numa certa semana, e escrever uma data para pessoas lerem. Salve como `src/lib/week.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/week.js", "parts": [
 {"code": "// week.js: dates as 'YYYY-MM-DD' strings, and the week they fall in.\n// Weeks start on Monday.\nconst DAY = 24 * 60 * 60 * 1000;\nconst toTime = (date) => Date.parse(`${date}T00:00:00Z`);\nconst toDate = (time) => new Date(time).toISOString().slice(0, 10);", "note": "Todo cálculo acontece em UTC, à meia-noite, então a resposta é a mesma em todo computador, seja qual for o fuso horário."},
 {"code": "/** The Monday of the week `date` falls in. */\nexport function mondayOf(date) {\n\tconst day = new Date(toTime(date)).getUTCDay();\n\treturn toDate(toTime(date) - ((day + 6) % 7) * DAY);\n}\n\n/** `date` moved by `days`, which may be negative. */\nexport function addDays(date, days) {\n\treturn toDate(toTime(date) + days * DAY);\n}", "note": "`getUTCDay` diz 0 para domingo e 1 para segunda, então `(day + 6) % 7` é quantos dias se passaram desde a segunda."},
 {"code": "/** Whether `date` falls in the week that starts on `monday`. */\nexport function inWeek(date, monday) {\n\treturn date >= monday && date < addDays(monday, 7);\n}", "note": "Comparação simples de strings, que funciona por causa do formato da data."},
 {"code": "/** `2026-10-19` as `19 Oct 2026`. */\nexport function format(date) {\n\treturn new Date(toTime(date)).toLocaleDateString('en-GB', {\n\t\tday: 'numeric',\n\t\tmonth: 'short',\n\t\tyear: 'numeric',\n\t\ttimeZone: 'UTC'\n\t});\n}", "note": "`en-GB` escreve o dia antes do mês, e `timeZone: 'UTC'` impede que ela vá para o dia anterior nas Américas."}
]}
```

Nada nos dois arquivos é reativo, e nada precisa ser. **Runes vão onde os valores mudam enquanto a
página está aberta**, e o resto desta aula as põe no componente da página, uma de cada vez. Um
cálculo de data que dá a mesma resposta para a mesma entrada pertence a um módulo comum, onde é mais
simples de ler e de testar.

Dá para experimentar o módulo no terminal antes de qualquer componente usá-lo:

```
ana@dev:~/planner$ node -e "import('./src/lib/week.js').then((w) => console.log(w.mondayOf('2026-10-24'), w.format('2026-10-19'), w.inWeek('2026-10-25', '2026-10-19')))"
2026-10-19 19 Oct 2026 true
```

O sábado, dia 24, está na semana que começa na segunda, dia 19, e o domingo, dia 25, também.
