---
title: Quando um template falha
version: 1
---

Templates falham de quatro jeitos, e o Django faz barulho em três deles. Cada um destes foi produzido
com `manage.py shell -c`, que roda uma linha de Python com o projeto carregado; o `tail -1` fica com a
última linha do traceback, que é a que diz a causa.

## O arquivo não está onde o Django procurou

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.template.loader import render_to_string; render_to_string(\"events/event_lsit.html\")" 2>&1 | tail -1
django.template.exceptions.TemplateDoesNotExist: events/event_lsit.html
```

Um erro de digitação no nome passado ao `render`. Numa requisição, com o `DEBUG` ligado, a página de
erro também lista todo diretório em que o Django procurou e por que cada um não tinha o arquivo, o que
resolve a outra causa comum: o template está em `events/templates/` sem o segundo `events/`, ou num
`templates/` do projeto que o `DIRS` não cita.

## Uma tag que nunca é fechada

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.template import Template; Template(\"{% for e in events %}{{ e }}\")" 2>&1 | tail -1
django.template.exceptions.TemplateSyntaxError: Unclosed tag on line 1: 'for'. Looking for one of: empty, endfor.
```

**Este falha quando o template é carregado**, antes de qualquer dado entrar, e diz a linha e as tags
que o fechariam. Toda tag de bloco tem uma tag de fim, e o `{% for %}` também aceita `{% empty %}` no
meio.

## Um filtro que não existe

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.template import Template; Template(\"{{ event.starts_at|dat }}\")" 2>&1 | tail -1
django.template.exceptions.TemplateSyntaxError: Invalid filter: 'dat'
```

Mesmo momento, mesmo tipo de mensagem. Um filtro de biblioteca, como o `naturaltime` do
`django.contrib.humanize`, também precisa da biblioteca no `INSTALLED_APPS` e de um `{% load %}` no
topo do template; sem isso, ele falha exatamente como um erro de digitação.

## Uma variável que não existe, e que não falha

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.template import Template, Context; print(repr(Template(\"[{{ event.titel }}]\").render(Context({\"event\": {\"title\": \"Django Night\"}}))))"
12 objects imported automatically (use -v 2 for details).

'[]'
```

**`event.titel` não imprimiu nada, e nada reclamou.** Uma variável que não pode ser resolvida é
trocada por um texto vazio, de propósito, para que um valor opcional ausente do contexto não derrube a
página. O preço é que um erro de digitação produz uma página com um buraco e nenhum erro.

Dois hábitos pegam isso. Olhe a página, que é a única conferência que vê um título faltando. E durante
o desenvolvimento, ponha `'string_if_invalid': 'MISSING %s'` no `OPTIONS` de `TEMPLATES`, que imprime o
nome de toda variável que não pôde ser resolvida; tire antes de ir para produção, porque alguns
templates do próprio Django contam com o texto vazio.
