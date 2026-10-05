---
title: O caso de uso, lido contra uma política
version: 1
---

A mesma chamada ao modelo pode ser uma resposta de suporte para uma confeitaria ou mil avaliações falsas
dos bolos dela. **O que um cliente vai fazer com o modelo decide a maior parte do risco**, e a Tarefa só
descobre perguntando, antes da chave, e conferindo depois. A metade de perguntar é um caso de uso
declarado a partir de uma lista, mais uma frase nas palavras do próprio cliente, lidos contra uma
política:

```
ana@lab:~/guard$ cat data/use-cases.json
{
 "allowed": [
  "customer-support",
  "translation",
  "proposal-drafting"
 ],
 "review": [
  "hiring-screening",
  "health-information",
  "legal-drafting",
  "marketing-copy"
 ],
 "prohibited": [
  "mass-messaging",
  "fake-reviews",
  "impersonation",
  "tracking-individuals"
 ],
 "prohibited_phrases": [
  "5-star reviews?",
  "fake",
  "impersonat",
  "without (their )?consent",
  "track (a|one) person"
 ]
}
```

Três listas, e cada uma significa algo diferente:

- usos em **allowed** passam quando a empresa está em ordem: responder clientes, traduzir, redigir
  propostas. O estrago que uma resposta ruim faz é limitado, e alguém lê a saída.
- usos em **review** vão a uma pessoa antes de qualquer chave além do sandbox. Não são proibidos. Cada
  um está na lista porque uma falha cai sobre alguém que não escolheu o modelo.
- usos em **prohibited** são recusados, peça quem pedir: mensagens enviadas em massa a quem nunca
  pediu, avaliações falsas, se passar por uma pessoa, rastrear um indivíduo.

A lista de revisão é onde as aulas anteriores deste curso voltam:

| caso de uso | por que uma pessoa olha antes |
|---|---|
| `hiring-screening` | uma decisão sobre o trabalho das pessoas, com o viés da aula 9 e o direito de revisão do art. 20 da LGPD |
| `health-information` | dado sensível pelo art. 11, e um paciente que age sobre uma resposta errada |
| `legal-drafting` | um contrato que ninguém qualificado lê antes de ser assinado |
| `marketing-copy` | em geral tranquilo, e o passo mais curto até avaliações falsas |

## A categoria e a frase

A empresa escolhe a própria categoria, então a categoria é a coisa mais barata de errar de propósito.
É por isso que a frase declarada também é lida. A Avalia+ Marketing escolheu `marketing-copy`, que
sozinha só a mandaria para revisão:

```
ana@lab:~/guard$ guard onboard data/applications.jsonl --now 2026-09-30 --id ap-03
ap-03  Avalia+ Marketing      REVIEW  sandbox  company opened 41 days ago
                                               use case marketing-copy needs a person to approve it
                                               description says "5-star reviews", a prohibited use
```

A lista de frases pegou *5-star reviews* na descrição da própria empresa. Como toda lista de palavras
deste curso, é uma rede com buracos, e um candidato que escreve *"product testimonials"* passa por
ela. O que a lista compra é que o caso óbvio chega a uma pessoa com o motivo já escrito. A pessoa
então decide, e a decisão e o motivo são registrados com o nome de quem revisou, como todo ato
administrativo.

## O que quem revisa pergunta

Quem revisa um `REVIEW` pergunta o que o formulário não comportou. A Contrata Já RH escreveu isto:

```
ana@lab:~/guard$ grep ap-02 data/applications.jsonl
{"id": "ap-02", "company": "Contrata Já RH", "cnpj": "23.045.678/0001-96", "contact": "talentos@contrataja.example", "website": "contrataja.example", "use_case": "hiring-screening", "description": "Rank CVs for our clients' job openings and reject the weakest automatically."}
```

*"Reject the weakest automatically"* é a frase que importa. Ordenar currículos para ajudar um
recrutador é um caso de uso; rejeitar pessoas sem ninguém ler o currículo delas é outro, e é uma
decisão tomada só com base em tratamento automatizado, que o art. 20 da LGPD deixa o candidato
contestar. Quatro perguntas resolvem a maioria das revisões:

1. **Quem são os usuários finais**, e eles sabem que há um modelo envolvido?
2. **Uma pessoa age sobre a saída**, ou a saída age sozinha?
3. **Quanto custa uma saída ruim**, e a quem?
4. **O que vai ser medido**, e a Tarefa vai ver a medição?

Para a Contrata Já RH, um resultado razoável é uma aprovação com condições: nenhuma rejeição
automática, todo ranking revisado por um recrutador, e as taxas por grupo da aula 9 relatadas à Tarefa
a cada trimestre. Uma alternativa razoável é a recusa. O que não é razoável é aprovar a frase como
está porque a categoria estava numa lista.
