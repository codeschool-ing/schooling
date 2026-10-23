---
title: O que o admin não é
version: 1
---

O admin é um painel para um punhado de pessoas de confiança. Três coisas decorrem disso, e a primeira
é fácil de perder porque tudo parece em ordem.

## Ele não chama as suas regras

A aula 4 pôs a regra de capacidade em `services.register`, e o formulário do site a chama. O
formulário de inclusão de uma inscrição no admin não chama: ele monta um `ModelForm` a partir do
modelo e o grava. O workshop de async tem 12 lugares, e 12 inscrições:

```
ana@vm:~/agenda$ psql agenda -c "SELECT count(*) FROM events_registration WHERE event_id = 2"
 count 
-------
    12
(1 row)

ana@vm:~/agenda$ TOKEN=$(grep csrftoken ~/admin-cookies.txt | cut -f7); curl -si -b ~/admin-cookies.txt -d "csrfmiddlewaretoken=$TOKEN&event=2&name=Elisa&email=elisa@example.org" http://127.0.0.1:8000/admin/events/registration/add/ | grep -E "^(HTTP|Location)"
HTTP/1.1 302 Found
Location: /admin/events/registration/
ana@vm:~/agenda$ psql agenda -c "SELECT count(*) FROM events_registration WHERE event_id = 2"
 count 
-------
    13
(1 row)
```

**Treze inscrições para doze lugares**, incluídas pela superusuária pelo admin, e nada recusou. A
restrição de unicidade teria barrado uma segunda Elisa, porque o banco a garante seja quem for que
grave; a regra de capacidade mora numa função que o admin nunca chama. O histórico do admin registrou
tudo fielmente:

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.contrib.admin.models import LogEntry; [print(e.action_time.date(), e.user, e) for e in LogEntry.objects.all()]"
14 objects imported automatically (use -v 2 for details).

2026-10-16 ana Added “Elisa for Async Python workshop”.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Dois caminhos até a tabela de inscrições. O formulário do site chama o services.register, que trava o evento, conta e insere. O formulário de inclusão do admin grava um model form direto na tabela, sem a contagem. Os dois param na restrição de unicidade de evento e e-mail; só o primeiro para na regra de capacidade.\"> <defs><marker id=\"dr-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"dr-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <rect x=\"20\" y=\"30\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"55\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o formulário do site</text> <rect x=\"20\" y=\"120\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"145\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a inclusão do admin</text> <rect x=\"240\" y=\"30\" width=\"230\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"355\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">services.register()</text> <text x=\"355\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">trava, conta, insere</text> <rect x=\"540\" y=\"70\" width=\"160\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"620\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">events_registration</text> <text x=\"620\" y=\"109\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">unique (event, email)</text> <path d=\"M170 50 L234 50\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#dr-a)\"></path> <path d=\"M470 50 L534 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#dr-a)\"></path> <path d=\"M170 140 L534 106\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#dr-b)\"></path> <text x=\"352\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">um ModelForm, depois save(): sem contar</text> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">As duas portas chegam à restrição; só uma passa pela regra de capacidade.</text> </svg>", "caption": "Uma regra escrita numa função vale para quem chama essa função. O admin não é um deles, a menos que você o faça ser, ou feche a porta dele."}
```

Há duas correções honestas. Uma é mandar o admin pela mesma porta: um formulário próprio cujo `clean`
chame a regra, ou um `save_model` que chame o `register`. A outra, que o agenda escolhe, é **fechar a
porta**: as inscrições são feitas no site, pelas pessoas que se inscrevem, e quem organiza as vê e pode
cancelá-las. Dois métodos fazem isso, um no inline e outro no `RegistrationAdmin`:

```
ana@vm:~/agenda$ grep -n -B1 -A1 'has_add_permission' events/admin.py
16-
17:    def has_add_permission(self, request, obj=None):
18-        return False
--
53-
54:    def has_add_permission(self, request):
55-        return False
```

O `has_add_permission` devolvendo `False` tira os links *Add* e a linha vazia do inline, e a própria
página de inclusão agora responde:

```
ana@vm:~/agenda$ curl -s -b ~/admin-cookies.txt -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/admin/events/registration/add/
403
```

A décima terceira inscrição, a da Elisa, foi depois apagada pelo shell, o que devolve o workshop aos
seus doze.

## Ele não é o site

As páginas do admin são feitas para quem conhece o modelo de dados. Mostram nomes crus de campos,
aceitam qualquer valor que o modelo aceite, e supõem que a pessoa sabe o que *Delete selected* em
quatrocentas linhas vai fazer. **Visitantes nunca ganham contas de staff**, por mais conveniente que
fosse deixá-los editar a própria inscrição ali; isso é uma página no site, com view e regras próprias.

## Ele é uma porta que vale guardar

O admin consegue mudar toda linha do banco, então o login dele é o mais valioso do site. Ele não tem
segundo fator próprio; bibliotecas como o `django-otp` acrescentam um, e uma conta de staff sem ele
está a uma senha do banco inteiro. Sirva o admin só por HTTPS, o que a aula 16 arranja; mantenha as
contas de staff poucas e os grupos estreitos, como fez a seção anterior; e leia o histórico, que
registra toda mudança feita pelo admin com quem a fez. Mudar o admin de `/admin/` para outro endereço
só detém tentativas automáticas que procuram o padrão; não é uma defesa sozinho.
