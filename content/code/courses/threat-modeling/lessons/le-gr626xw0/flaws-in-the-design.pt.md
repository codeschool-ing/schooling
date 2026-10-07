---
title: As falhas moram no projeto
version: 1
---

Defeitos de segurança vêm em dois tipos, e as ferramentas que acham um são cegas para o outro.
**Um bug é código que não faz o que o projeto diz.** Uma consulta montada concatenando strings
quando o projeto dizia parametrizada, um cookie de sessão sem `HttpOnly`: o projeto estava certo e
a implementação escorregou. **Uma falha de projeto é um projeto que está errado**, implementado
fielmente. Cada linha faz o que lhe pediram, e o que lhe pediram é inseguro.

| | um bug | uma falha de projeto |
|---|---|---|
| onde nasceu | na implementação | no requisito ou no projeto |
| exemplo no portal | a busca de agendamentos concatena o texto do paciente no SQL | o webhook de pagamento marca um agendamento como pago para qualquer pedido que diga isso, venha de quem vier |
| o que acha | revisão de código, análise estática, testes, um scanner | ler o projeto e perguntar o que pode dar errado |
| o que corrigir significa | mudar algumas linhas | mudar o projeto, e depois as linhas |

O curso `secure-code` (aula 1) traça a mesma linha pelo lado de quem programa. Este curso vive na
coluna da direita.

### Por que os scanners passam reto por uma falha

Vale seguir o exemplo do webhook até o fim. O handler recebe um pedido, lê do corpo um id de
agendamento e um status, e atualiza a linha. Usa uma consulta parametrizada. Valida que o id é um
número. Um analisador estático não tem nada a relatar, porque não existe chamada perigosa. Um
scanner dinâmico manda entrada malformada e recebe erros limpos de volta. O código está correto.
O que falta é um passo que ninguém projetou: **verificar que o pedido veio do gateway de
pagamento**, conferindo a assinatura que o gateway põe em cada chamada. Sem isso, qualquer um que
descubra o endereço do webhook consegue marcar o próprio agendamento como pago.

Nada no código aponta para o passo que falta, porque um passo ausente não deixa linha para ser
apontada. Ele é achado por alguém olhando o desenho, vendo uma seta de fora para dentro do portal
que mexe com dinheiro e perguntando: *quem tem permissão para mandar isto?*

### Quanto custa achar tarde

O argumento costumeiro para fazer isso cedo cita um multiplicador: um defeito custa dez, ou cem,
vezes mais para corrigir em produção do que no projeto. **Cuidado com esse número.** Ele é
repetido em toda parte e remonta a estudos das décadas de 1970 e 1980 cujos dados são difíceis de
achar, e os números específicos não sobrevivem a uma leitura atenta das fontes. O argumento não
precisa deles, porque o mecanismo é visível por si só:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l01-where-found\" aria-label=\"Uma falha de projeto, encontrada em cinco momentos. No requisito ou no projeto, corrigir é mudar um desenho numa reunião. No código, é reescrever o módulo construído em cima dela. No teste, a reescrita mais os testes feitos para a forma antiga. Em produção, a reescrita, a migração dos dados já guardados do jeito errado e, talvez, um incidente para responder.\"><defs><marker id=\"l01-where-found-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"128.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"84.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">requisito</text><rect x=\"34.0\" y=\"175.0\" width=\"100.0\" height=\"30.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"84.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">mudar uma frase</text><path d=\"M148.0 58.0 L158.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-where-found-tm-ah-paper-dim)\"></path><rect x=\"158.0\" y=\"40.0\" width=\"128.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"222.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">projeto</text><rect x=\"172.0\" y=\"153.0\" width=\"100.0\" height=\"52.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"222.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">mudar um desenho</text><text x=\"222.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">numa reunião</text><path d=\"M286.0 58.0 L296.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-where-found-tm-ah-paper-dim)\"></path><rect x=\"296.0\" y=\"40.0\" width=\"128.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">código</text><rect x=\"310.0\" y=\"131.0\" width=\"100.0\" height=\"74.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reescrever o módulo</text><text x=\"360.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">construído em cima</text><path d=\"M424.0 58.0 L434.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-where-found-tm-ah-paper-dim)\"></path><rect x=\"434.0\" y=\"40.0\" width=\"128.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"498.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">teste</text><rect x=\"448.0\" y=\"109.0\" width=\"100.0\" height=\"96.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"498.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a reescrita, e</text><text x=\"498.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">os testes em volta</text><path d=\"M562.0 58.0 L572.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-where-found-tm-ah-paper-dim)\"></path><rect x=\"572.0\" y=\"40.0\" width=\"128.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"636.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">produção</text><rect x=\"586.0\" y=\"87.0\" width=\"100.0\" height=\"118.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"636.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a reescrita, migrar</text><text x=\"636.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">dados, um incidente</text><text x=\"20.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o que corrigir envolve</text></svg>", "caption": "Nenhuma porcentagem, porque o número honesto depende da falha. O que cresce é a lista de coisas que precisam mudar."}
```

Achada no projeto, a falha do webhook é uma frase num requisito e uma seta redesenhada num quadro
branco. Achada em produção, é a mudança no handler, mais descobrir quais agendamentos foram
marcados como pagos por alguém que não o gateway, mais decidir o que dizer a esses pacientes e ao
contador da clínica. A correção em si são as mesmas poucas linhas em qualquer etapa. Tudo em volta
dela cresce.

### O que modelagem de ameaças não é

Três coisas são chamadas de modelagem de ameaças e são outra coisa:

- **Um teste de intrusão.** Um pentest ataca o sistema construído para achar o que é explorável
  agora. É evidência sobre a implementação, depois do fato. Um modelo de ameaças é raciocínio sobre
  o projeto, e diz ao pentester onde olhar.
- **Uma checklist.** Uma lista de controles pergunta "fizemos X?". Não consegue perguntar o que
  este sistema em particular precisa e não está na lista de ninguém, que é onde as falhas moram.
- **Um documento de conformidade.** Um auditor pode pedir para ver um modelo de ameaças (aula 14).
  Escrever um *para* o auditor produz o documento e pula o raciocínio, e a primeira declaração do
  manifesto existe porque isso acontece com muita frequência.
