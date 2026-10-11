---
title: Papéis e permissões
version: 1
---

**Um papel é um nome para um conjunto de permissões, e uma pessoa recebe um papel em vez de receber
cada permissão uma por uma.** Isso é controle de acesso baseado em papéis, RBAC (*role-based access
control*), e é por onde a maioria das APIs começa: a loja tem clientes, funcionários e um
administrador, e o que cada um pode fazer é escrito uma vez. O `orders.py` tem quatro papéis, seis
permissões e cinco pessoas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Cinco pessoas, quatro papéis e seis permissões no orders.py. Ana e Bruno são clientes, Carla é staff, Dora é admin e Eva é auditor. O papel customer concede orders:read, orders:create e orders:cancel. Staff concede orders:read, orders:read_all e orders:refund. Admin concede as mesmas três e mais people:read. Auditor não está na tabela e não concede nada.\"><defs><marker id=\"l11-rbac-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"70\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">pessoas</text><text x=\"300\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">papéis</text><text x=\"570\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">permissões</text><rect x=\"20\" y=\"40\" width=\"100\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Ana</text><line x1=\"120\" y1=\"56\" x2=\"248\" y2=\"68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-rbac-ah)\"></line><rect x=\"20\" y=\"90\" width=\"100\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Bruno</text><line x1=\"120\" y1=\"106\" x2=\"248\" y2=\"68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-rbac-ah)\"></line><rect x=\"20\" y=\"140\" width=\"100\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Carla</text><line x1=\"120\" y1=\"156\" x2=\"248\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-rbac-ah)\"></line><rect x=\"20\" y=\"190\" width=\"100\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Dora</text><line x1=\"120\" y1=\"206\" x2=\"248\" y2=\"192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-rbac-ah)\"></line><rect x=\"20\" y=\"240\" width=\"100\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Eva</text><line x1=\"120\" y1=\"256\" x2=\"248\" y2=\"254\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-rbac-ah)\"></line><rect x=\"250\" y=\"52\" width=\"110\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"305.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">customer</text><line x1=\"360\" y1=\"68\" x2=\"500\" y2=\"54\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"360\" y1=\"68\" x2=\"500\" y2=\"96\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"360\" y1=\"68\" x2=\"500\" y2=\"138\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><rect x=\"250\" y=\"114\" width=\"110\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"305.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">staff</text><line x1=\"360\" y1=\"130\" x2=\"500\" y2=\"54\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"360\" y1=\"130\" x2=\"500\" y2=\"180\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"360\" y1=\"130\" x2=\"500\" y2=\"222\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><rect x=\"250\" y=\"176\" width=\"110\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"305.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">admin</text><line x1=\"360\" y1=\"192\" x2=\"500\" y2=\"54\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"360\" y1=\"192\" x2=\"500\" y2=\"180\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"360\" y1=\"192\" x2=\"500\" y2=\"222\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"360\" y1=\"192\" x2=\"500\" y2=\"264\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><rect x=\"250\" y=\"238\" width=\"110\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"305.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">auditor</text><rect x=\"500\" y=\"40\" width=\"140\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders:read</text><rect x=\"500\" y=\"82\" width=\"140\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders:create</text><rect x=\"500\" y=\"124\" width=\"140\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders:cancel</text><rect x=\"500\" y=\"166\" width=\"140\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders:read_all</text><rect x=\"500\" y=\"208\" width=\"140\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders:refund</text><rect x=\"500\" y=\"250\" width=\"140\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">people:read</text><text x=\"305\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">fora de ROLES: nenhuma permissão</text></svg>", "caption": "Uma pessoa tem um papel; o código só pergunta pelas permissões da direita.", "same": ["Ana", "Bruno", "Carla", "Dora", "Eva"]}
```

Uma permissão nomeia uma coisa e uma ação, `orders:refund`. Os dois-pontos são só uma convenção, e
outras APIs escrevem `refund_orders` ou `orders.refund`; o que importa é que o nome diga o que é
permitido, e não quem costuma ter permissão. `orders:read_all` é a que se lê errado com facilidade:
`orders:read` deixa ler pedidos, e o `find` decide quais, enquanto `orders:read_all` é a permissão
que faz "quais" significar todos.

## Cheque a permissão, não o papel

A ideia errada é escrever o papel no código:

```python
if role == "admin" or role == "staff":
    refund(order)
```

Funciona no dia em que é escrito. Aí a loja contrata alguém no atendimento que deve estornar pedidos
e não ver a lista de pessoas, e todo `if` que menciona `staff` precisa ser achado e relido, em todo
handler. O que ninguém achou é um bug. Código que pergunta pela permissão não muda nada:

```python
if "orders:refund" in perms:
    refund(order)
```

Um papel `support` vira então uma linha em `ROLES`, com `orders:read`, `orders:read_all` e
`orders:refund`, e nenhum handler fica sabendo que ele existe. **O código pergunta por permissões;
só a tabela conhece papéis.** No `orders.py` a palavra `admin` nunca aparece numa checagem. A
tabela de rotas nomeia `people:read`, e a Dora tem essa permissão porque a linha `admin` de `ROLES`
diz que tem.

De onde o papel é lido também importa. O `orders.py` lê da tabela `people` a cada requisição, então
uma troca de papel vale a partir da requisição seguinte. Um papel copiado para dentro de um token
quando ele foi emitido, coisa que um JWT da aula 8 pode carregar, vale até o token expirar: é o
preço de não perguntar ao banco.

O RBAC é simples enquanto os papéis são poucos e as regras são sobre tipos de pessoa. Ele aperta
quando a regra é sobre um objeto em particular ou um momento em particular. "Funcionários podem
estornar, mas só até 30 dias" não é um papel, e "Atributos e políticas" trata do que fazer nesse
caso.
