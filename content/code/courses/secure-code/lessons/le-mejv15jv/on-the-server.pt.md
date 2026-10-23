---
title: A única verificação que conta é a do servidor
version: 1
---

O **controle de acesso** responde a uma pergunta a cada requisição: *esta pessoa pode fazer isto,
com isto?* É a falha grave mais comum em aplicações web. O Top 10 da OWASP pôs o **controle de
acesso quebrado** em primeiro lugar em 2021, à frente da injeção, e ele continuou lá na edição de
2025. Raramente falta a ideia: quase toda aplicação tem alguma noção de papéis. Falta uma linha, numa
rota, que ninguém notou.

A ideia errada por trás da maioria dos casos é que **o que a tela não mostra não pode ser alcançado.**
O console do recepcionista não tem link para as notas clínicas, então recepcionistas não leem notas
clínicas. Mas um link é uma conveniência para um navegador honesto. O endereço para o qual ele
apontava continua existindo, e o servidor responde a quem perguntar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l12-where\" aria-label=\"Três lugares onde uma verificação pode ficar, e as requisições que passam por cada um. À esquerda, o navegador: a página, que esconde o link das notas de um recepcionista, e o formulário, que leva um campo oculto role=physio. Abaixo, um terminal mandando uma requisição com curl, que nunca mostra a página. O navegador e o terminal mandam suas requisições ao servidor à direita, onde a verificação lê o nome na sessão e o papel na tabela do próprio servidor. Toda requisição passa pelo servidor; só o navegador honesto passa pela página.\"><defs><marker id=\"l12-where-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o navegador</text><rect x=\"20\" y=\"34\" width=\"260\" height=\"126\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"40\" y=\"50\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a página: link oculto</text><rect x=\"40\" y=\"104\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o formulário: role=physio</text><rect x=\"40\" y=\"196\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um terminal, um script</text><text x=\"150\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">pula a página por completo</text><text x=\"570\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o servidor</text><rect x=\"450\" y=\"60\" width=\"240\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"115.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nome vindo da sessão</text><text x=\"570.0\" y=\"128.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">papel vindo do STAFF</text><text x=\"570.0\" y=\"141.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\"></text><text x=\"570.0\" y=\"154.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">toda requisição passa aqui</text><path d=\"M280 97 L450 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-where-ah-paper-dim)\"></path><path d=\"M260 216 L450 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-where-ah-paper-dim)\"></path></svg>", "caption": "A página e o formulário só veem o navegador honesto. O servidor vê toda requisição, e é por isso que a verificação mora lá."}
```

Três lugares onde uma verificação pode ficar, e o que cada um impede:

- **Na página**, escondendo um link ou um botão. Não impede ninguém que digite o endereço, siga um
  favorito ou mande a requisição de um terminal. Esconder ainda vale a pena: uma tela que oferece só
  o que a pessoa pode fazer é uma tela melhor. **É desenho, não controle.**
- **Na requisição**, confiando em algo que o cliente mandou: um campo oculto `role=physio`, um cookie
  `is_admin=1`, um cabeçalho, um parâmetro no endereço. Tudo numa requisição é escolhido por quem a
  envia. As ferramentas de desenvolvedor de um navegador editam um campo oculto em dois cliques.
- **No servidor, a partir do que o servidor sabe.** A sessão diz quem pergunta; a tabela do próprio
  servidor diz qual é o papel dessa pessoa; a rota diz de que papel precisa. **É a única verificação
  que toda requisição precisa atravessar**, seja o que for que a mandou.

### Três regras

O resto desta aula são estas três, em código e em testes.

1. **Verifique no servidor, a cada requisição.** Não uma vez no login, não na página, não em
   JavaScript. O servidor decide toda vez.
2. **Tire o papel do servidor.** A sessão leva uma identidade, e o servidor consulta o que essa
   identidade pode fazer. Um papel escrito na requisição, ou num cookie que o cliente pode editar, é
   uma alegação, não um fato.
3. **Negue por padrão.** Uma rota que não diz nada sobre quem pode usá-la é recusada, não aberta. A
   falha de controle de acesso é quase sempre uma rota esquecida, e a única defesa contra o
   esquecimento é uma regra que falha fechada e um teste que percebe.

O portal do paciente da aula 1 já encontrou uma quarta pergunta, *com isto?*: a lucia pode cancelar
agendamentos, mas só os dela. Essa é a aula 13. Esta aula trata de papéis.
