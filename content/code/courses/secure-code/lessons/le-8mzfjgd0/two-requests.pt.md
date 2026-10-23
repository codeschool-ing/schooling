---
title: A mesma requisição, duas vezes
version: 1
---

Uma **referência direta insegura a objeto**, IDOR na sigla em inglês, é a falha de controle de acesso
mais simples de descrever. Uma requisição nomeia um registro pelo identificador, `/exams/2`, e o
servidor busca esse registro e o devolve, depois de conferir que *alguém* está logado mas não que o
registro é **dessa pessoa**. A aula 12 chamou isso de a pergunta que os papéis não respondem: *com
isto?*

Não exige habilidade nenhuma para ser achada, e é isso que a torna comum. O identificador está na
barra de endereço, e costuma ser um número que vai subindo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l13-two\" aria-label=\"Uma referência direta insegura a objeto desenhada como duas requisições do navegador da lucia, ambas com o cookie de sessão válido dela. A primeira pede GET /exams/1, a ressonância do joelho dela, e o servidor responde 200 com ela. A segunda difere num caractere, GET /exams/2, que é o raio X da coluna da marta, e o servidor com a falha responde 200 com o exame da marta, porque só conferiu que alguém estava logado. Depois da correção, a segunda requisição recebe 404, a mesma resposta de um exame que não existe.\"><defs><marker id=\"l13-two-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-two-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-two-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o navegador da lucia, logada</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o portal</text><rect x=\"520\" y=\"36\" width=\"160\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"20\" y=\"44\" width=\"200\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"63.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">GET /exams/1</text><text x=\"120.0\" y=\"76.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Cookie: a sessão da lucia</text><path d=\"M220 62 L520 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-two-ah-paper-dim)\"></path><path d=\"M520 84 L220 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-two-ah-phosphor)\"></path><text x=\"370\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">200: Knee MRI (da lucia)</text><rect x=\"20\" y=\"130\" width=\"200\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"149.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">GET /exams/2</text><text x=\"120.0\" y=\"162.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Cookie: a sessão da lucia</text><path d=\"M220 148 L520 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-two-ah-paper-dim)\"></path><path d=\"M520 170 L220 170\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-two-ah-amber)\"></path><text x=\"370\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">200: Lumbar spine X-ray (da marta)</text><text x=\"120\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">um caractere de diferença</text><text x=\"370\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">depois da correção: 404, como um exame que não existe</text></svg>", "caption": "As duas requisições são da lucia e as duas são válidas. Só o servidor consegue saber que a segunda pede o registro de outra pessoa.", "same": ["GET /exams/1", "GET /exams/2"]}
```

As duas requisições diferem em **um caractere**. As duas levam o cookie de sessão válido da lucia. A
primeira pede a ressonância do joelho dela e a recebe. A segunda pede o exame 2, que é da marta, e
num portal com a falha recebe esse também: o servidor leu o número, achou uma linha e a mandou. Nada
na requisição foi forjado. **A sessão prova quem a lucia é; não diz nada sobre o que ela pode ver.**
Num portal de fisioterapia, o que ela vê é dado de saúde de outra pessoa, e pela LGPD isso é um
incidente a comunicar.

### Por que continua acontecendo

A ideia errada é que **um identificador é segredo**, ou pelo menos obscuro: pacientes só veem os links
dos próprios exames, então só pedem os próprios exames. Tudo nessa frase trata da tela. O servidor
recebe requisições, não telas, e a aula 12 já mostrou quanto vale um link escondido.

Dois hábitos do código comum a produzem:

- **Buscar só pelo id.** `SELECT … WHERE id = ?` é a primeira consulta que qualquer um escreve para uma
  página de detalhe, e está certa para os dados e errada para o acesso. A posse precisa fazer parte da
  consulta, ou ser conferida no resultado dela, toda santa vez.
- **Tirar o dono da requisição.** `?patient=marta` numa lista, um campo `patient_id` num corpo JSON, um
  número de conta num formulário. Se o servidor o usa para decidir de quem são os dados que lê, o
  cliente escolheu de quem são os dados que lê.

### A regra

**Toda requisição de um registro é respondida só com os registros da pessoa logada, e o dono vem da
sessão, nunca da requisição.** Um registro que existe mas não é dela recebe a mesma resposta que um
registro que não existe.

O resto da aula é essa regra como um teste que pede todo exame a todo paciente, uma consulta que não
consegue devolver a linha errada, e o motivo de a resposta ser `404` e não `403`.
