---
title: Três lugares onde uma falha nasce
version: 1
---

A imagem comum de uma falha de segurança é um forasteiro esperto achando uma rachadura num sistema
pronto. Essa imagem põe o problema no fim, nas mãos de quem ataca. **A maior parte das falhas é
escrita no começo, por quem constrói o sistema, e chega por um de três lugares**: o requisito, o
projeto ou a implementação. Onde uma falha nasceu decide quem consegue pegá-la e quanto custa
corrigir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l01-births\" aria-label=\"Três lugares onde uma falha nasce, da esquerda para a direita na ordem em que uma funcionalidade é feita. No requisito: ninguém escreveu que um paciente só pode cancelar o próprio agendamento. No projeto: o console da equipe foi projetado para responder pela internet. Na implementação: a busca junta o texto do paciente ao SQL. Embaixo de cada uma, o lugar mais barato para pegá-la: lendo o requisito, num modelo de ameaças, numa revisão de código ou num teste. Uma seta embaixo diz que o custo da correção cresce quanto mais tarde a falha é encontrada.\"><defs><marker id=\"l01-births-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-births-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">requisito</text><rect x=\"30\" y=\"86\" width=\"200\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"106.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">“o paciente pode cancelar</text><text x=\"130.0\" y=\"119.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um agendamento” — de quem?</text><text x=\"130\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">pega mais barato por</text><rect x=\"30\" y=\"182\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ler o requisito</text><path d=\"M230 48 L260 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-births-ah-paper-dim)\"></path><rect x=\"260\" y=\"30\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">projeto</text><rect x=\"260\" y=\"86\" width=\"200\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"106.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o console da equipe</text><text x=\"360.0\" y=\"119.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">responde pela internet</text><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">pega mais barato por</text><rect x=\"260\" y=\"182\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um modelo de ameaças</text><path d=\"M460 48 L490 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-births-ah-paper-dim)\"></path><rect x=\"490\" y=\"30\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">implementação</text><rect x=\"490\" y=\"86\" width=\"200\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"106.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a busca junta o</text><text x=\"590.0\" y=\"119.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">texto ao SQL</text><text x=\"590\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">pega mais barato por</text><rect x=\"490\" y=\"182\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma revisão, um teste</text><path d=\"M30 256 L690 256\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l01-births-ah-amber)\"></path><text x=\"360\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">quanto mais tarde for encontrada, mais cara a correção</text></svg>", "caption": "O mesmo portal, três falhas, nascidas em três lugares diferentes. Cada uma sai mais barata de pegar onde nasceu."}
```

### No requisito

Um requisito é uma frase com que alguém concordou. O portal da Vereda tem esta: *o paciente pode
cancelar um agendamento pela internet até 24 horas antes da sessão.* Cada palavra está correta, e
mesmo assim falta algo. Ela nunca diz **de quem** é o agendamento. Quem constrói exatamente o que a
frase diz constrói um botão de cancelar que funciona em qualquer agendamento, e nenhum teste escrito
a partir da frase vai reclamar.

Uma falha de requisito é uma frase que falta, então não se acha lendo o código. O código faz o que
pediram. Ela se acha lendo o requisito e perguntando quem **não** pode fazer aquilo, que é a
pergunta que um revisor atento à segurança faz a toda história de usuário.

### No projeto

Uma falha de projeto é uma decisão sobre a forma do sistema. O console da equipe, onde as
recepcionistas cuidam da agenda e os fisioterapeutas escrevem as notas clínicas, foi projetado para
responder pela internet, como o portal dos pacientes. Cada linha do código pode estar perfeita e o
console continua a uma senha roubada de todas as notas clínicas da Vereda.

Nenhuma revisão de um arquivo isolado acha isso, porque nenhum arquivo isolado está errado. Isso se
acha desenhando o sistema e perguntando o que pode dar errado em cada parte, que é a modelagem de
ameaças.

::: track devsecops
O curso `threat-modeling`, logo depois deste na sua trilha, trata só disso, e trabalha sobre este
mesmo portal.
:::

::: track *
O curso `threat-modeling` trata só disso, trabalha sobre este mesmo portal e indica este curso como
o que se faz antes.
:::

### Na implementação

O terceiro lugar é o assunto deste curso. O projeto diz que a busca de pacientes usa consultas
parametrizadas. O desenvolvedor, com pressa, monta a consulta juntando o texto do paciente à string
SQL. O requisito estava certo e o projeto estava certo, e **o código diz algo diferente dos dois**.

Falhas de implementação são de longe as mais comuns das três, porque há muito mais código do que
requisitos ou projetos. São também as mais baratas de pegar, porque quem as escreveu pode pegá-las
antes de qualquer outra pessoa ver o código: sabendo como é a chamada segura, e escrevendo um teste
que falharia se a insegura voltasse.

### Por que o lugar importa

A tabela é o motivo de esta aula vir primeiro. Cada lugar tem seu tipo de evidência e seu tipo de
revisor.

| nasce no | parece | pego por | corrigido por |
|---|---|---|---|
| requisito | uma frase que nunca diz quem não pode | ler a história e perguntar pelo abuso | uma frase nova, e um teste para ela |
| projeto | um componente no lugar errado, uma confiança que ninguém verificou | um modelo de ameaças do desenho | mudar a forma do sistema |
| implementação | uma chamada insegura onde existe uma segura | revisão de código, teste, scanner | mudar a linha, e um teste para ela continuar corrigida |

**Quanto mais tarde a falha é encontrada, mais cara fica a correção**, e o custo cresce mais rápido
nas duas primeiras. Uma frase que falta, achada numa reunião de planejamento, custa uma frase. Achada
em produção, custa um incidente, uma comunicação de proteção de dados e uma mudança em código de que
outro código agora depende.

Este curso trabalha sobretudo na terceira linha, porque é onde estão as mãos de quem desenvolve. O
exemplo desta aula, duas seções adiante, é a primeira linha: o botão de cancelar cujo requisito
esqueceu de dizer *de quem*.
