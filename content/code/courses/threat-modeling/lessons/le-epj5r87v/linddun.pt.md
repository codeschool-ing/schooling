---
title: LINDDUN, ameaças à privacidade
version: 1
---

O STRIDE pergunta se um atacante consegue quebrar uma propriedade. Dano à privacidade muitas vezes
não precisa de atacante nenhum: o sistema faz exatamente o que foi projetado para fazer, e o
problema é esse. A T08, o lembrete por SMS que conta a qualquer um que segure o celular que o dono
está em tratamento, é uma ameaça à privacidade que o STRIDE achou quase por acaso. O **LINDDUN** foi
construído para achar esse tipo de propósito.

Ele vem do grupo de pesquisa DistriNet da KU Leuven, na Bélgica, e funciona como o STRIDE: uma
categoria por letra, aplicada aos elementos e fluxos de um DFD.

| | categoria | a pergunta no portal |
|---|---|---|
| **L** | **linking (vinculação)** | dá para juntar registros de lugares diferentes e saber mais sobre uma pessoa do que qualquer um deles mostra? |
| **I** | **identifying (identificação)** | dá para individualizar uma pessoa a partir de dados que deveriam ser anônimos? |
| **N** | **non-repudiation (não repúdio)** | um paciente pode ficar sem conseguir negar algo que, com razão, gostaria de manter para si? |
| **D** | **detecting (detecção)** | dá para saber que alguém é paciente, sem ler nada? |
| **D** | **data disclosure (divulgação de dados)** | o sistema coleta, guarda ou compartilha mais dado pessoal do que precisa? |
| **U** | **unawareness and unintervenability (desconhecimento e impossibilidade de intervir)** | o paciente sabe o que acontece com os dados dele, e consegue fazer algo a respeito? |
| **N** | **non-compliance (não conformidade)** | o tratamento descumpre a lei ou a política que a Vereda publicou? |

Duas letras se leem ao contrário do STRIDE, e são o sinal mais claro de que privacidade é outra
pergunta. No STRIDE, o não repúdio é uma propriedade que você *quer*: prova de quem fez o quê. No
LINDDUN, é uma ameaça *ao paciente*: um registro que prova que ele foi a um fisioterapeuta,
guardado onde ele não esperava. A detecção é parecida: o simples fato de um lembrete chegar diz
alguma coisa, mesmo com o texto cifrado.

### Aplicado aos fluxos que saem da Vereda

O lugar mais produtivo para começar é cada fluxo que leva dado pessoal para fora do controle da
Vereda, e cada repositório que o guarda:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l05-linddun-flows\" aria-label=\"Os fluxos que levam dado pessoal para fora da Vereda, com as categorias do LINDDUN que cada um levantou. Para o provedor de SMS: telefone, nome, horário e clínica do paciente; detecção, divulgação de dados, desconhecimento. Para o gateway de pagamento: nome, CPF e valor; vinculação, divulgação de dados. Para dentro do banco de prontuários: todo agendamento e anotação, guardados sem data de fim; identificação, não conformidade.\"><defs><marker id=\"l05-linddun-flows-tm-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><circle cx=\"130.0\" cy=\"145.0\" r=\"50\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"130.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Vereda</text><rect x=\"230.0\" y=\"32.0\" width=\"140.0\" height=\"36.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Provedor de SMS</text><path d=\"M160.0 70.0 L228.0 50.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-linddun-flows-tm-ah-paper)\"></path><text x=\"300.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">telefone, nome, horário, clínica</text><rect x=\"390.0\" y=\"37.0\" width=\"106.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"443.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">Detecção</text><rect x=\"500.0\" y=\"37.0\" width=\"106.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"553.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">Divulgação de dados</text><rect x=\"610.0\" y=\"37.0\" width=\"106.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"663.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">Desconhecimento</text><rect x=\"230.0\" y=\"127.0\" width=\"140.0\" height=\"36.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Gateway de pagamento</text><path d=\"M180.0 145.0 L228.0 145.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-linddun-flows-tm-ah-paper)\"></path><text x=\"300.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nome, CPF, valor</text><rect x=\"390.0\" y=\"132.0\" width=\"106.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"443.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">Vinculação</text><rect x=\"500.0\" y=\"132.0\" width=\"106.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"553.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">Divulgação de dados</text><rect x=\"230.0\" y=\"225.0\" width=\"140.0\" height=\"30.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M230.0 225.0 L370.0 225.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M230.0 255.0 L370.0 255.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"300.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Banco de prontuários</text><path d=\"M160.0 220.0 L228.0 240.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-linddun-flows-tm-ah-paper)\"></path><text x=\"300.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">todo agendamento e anotação, sem data de fim</text><rect x=\"390.0\" y=\"227.0\" width=\"106.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"443.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">Identificação</text><rect x=\"500.0\" y=\"227.0\" width=\"106.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"553.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">Não conformidade</text></svg>", "caption": "O STRIDE perguntou se um atacante conseguiria ler estes fluxos. O LINDDUN pergunta se eles deveriam levar o que levam, e se o paciente sabe.", "same": ["Vereda"]}
```

- **Para o provedor de SMS** vão um telefone, um primeiro nome, um horário e o nome da clínica. Isso
  é **detecção** (uma mensagem de uma clínica de fisioterapia diz que a pessoa é paciente) e
  **divulgação de dados** (o provedor recebe mais do que um lembrete precisa). E o aviso de
  privacidade que o paciente aceitou não cita o provedor: **desconhecimento**.
- **Para o gateway de pagamento** vão o nome do paciente, o CPF e o valor. O gateway precisa do
  valor e de uma referência; o CPF deixa o gateway **vincular** este pagamento a tudo o mais que
  ele sabe sobre essa pessoa.
- **Para dentro do banco de prontuários** vão todo agendamento e toda anotação, e nada sai nunca.
  Guardar dado de saúde sem prazo de retenção é uma questão de **não conformidade** na LGPD, que só
  permite o tratamento enquanto durar a finalidade dele. E agendamentos antigos tornam uma pessoa
  **identificável** muito depois de ela ter deixado de ser paciente.

Nenhum desses precisa de atacante. Cada um se corrige com uma decisão de projeto. Um lembrete diz
"você tem sessão amanhã às 10:00, responda C para cancelar"; um pedido de pagamento leva uma
referência do agendamento e nenhum CPF; e uma regra de retenção remove agendamentos depois do prazo
que a lei e o conselho profissional exigem. O curso `security-fundamentals` (aula 17) apresentou a
LGPD; o LINDDUN é como os princípios da lei viram perguntas sobre um DFD específico.

### Para onde ir com ele

A equipe do LINDDUN publica duas formas práticas: o **LINDDUN GO**, um baralho de cartas para uma
sessão leve, e o **LINDDUN PRO**, uma versão sistemática que percorre cada fluxo. Para uma equipe
que já faz STRIDE, uma hora com o LINDDUN GO nos fluxos que saem da empresa é a revisão de
privacidade mais barata que existe.
