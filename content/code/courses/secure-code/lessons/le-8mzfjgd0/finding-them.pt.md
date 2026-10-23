---
title: Achar IDOR em código que você não escreveu
version: 1
---

Uma IDOR é invisível na tela e óbvia no código, quando você conhece os dois formatos. Revisar um
código atrás delas, ou o seu próprio pull request antes de qualquer outra pessoa, é uma busca em três
passos.

### 1. Ache toda consulta por identificador

Liste todo lugar onde um registro é buscado, alterado ou apagado por um id que veio da requisição:
parâmetros de rota como `<int:exam_id>`, query strings, campos JSON, campos de formulário. Numa
aplicação Flask, são os argumentos de toda view e todo `request.args`, `request.form` e `request.json`.
Numa aplicação com ORM, são `get(id)`, `filter_by(id=…)` e parentes.

### 2. Para cada uma, pergunte onde está o dono

Leia a consulta, ou o código logo depois dela, e ache a condição que liga o registro à pessoa logada.
Há três respostas aceitáveis e uma inaceitável:

| o que você acha | veredito |
|---|---|
| o dono faz parte da consulta: `WHERE id = ? AND patient = ?` | seguro |
| a linha é buscada, depois o dono é comparado com a sessão, antes de qualquer coisa ser devolvida ou alterada | seguro, e a uma linha esquecida do inseguro |
| o registro é alcançado pela pessoa: `current_user.exams.get(id)` num ORM | seguro |
| nada liga o registro à pessoa | IDOR |

Olhe as que **alteram** dados com o mesmo cuidado que as que leem. Um delete ou um update só por id faz
o estrago sem devolver nada, então nunca aparece numa resposta que alguém lê.

### 3. Procure donos que chegam na requisição

Procure os nomes de campos de dono no que a requisição traz: `patient`, `user_id`, `account`,
`owner`, `tenant`. Cada um que o servidor **usa para escolher de quem são os dados que lê ou altera** é
um achado, como o `?patient=` era. Um valor que o servidor só grava depois de defini-lo a partir da
sessão está bem; um valor em que ele acredita, não.

### E teste a grade

Para todo recurso que uma pessoa possui, um teste com o formato do último desta aula: cada pessoa pede
cada registro, e só o dono recebe resposta. Ele pega uma rota nova que esqueceu a regra, uma
refatoração que mudou a consulta de lugar, e uma chamada de ORM que perdeu um filtro sem avisar. **É
barato porque não precisa saber onde a falha pode estar.**

### Nos logs

Uma paciente que pede os exames de 1 a 400 em um minuto, e recebe 399 `404`, é um bug num aplicativo
ou alguém contando. A aula 15 pôs as recusas de acesso entre os eventos de segurança que merecem uma
linha; os `404` do `own_exam` são exatamente essas recusas, e cinquenta delas de uma sessão só merecem
um alerta.
