---
title: Encolhendo a superfície
version: 1
---

Só existem três jeitos de diminuir uma superfície de ataque, e vale tentá-los em ordem, porque cada
um é mais barato e mais confiável que o seguinte.

| | o que significa | no portal |
|---|---|---|
| **remover** | o ponto de entrada deixa de existir | a página de perfil precisa de um campo livre de "recado para a recepção" que a equipe nunca lê? |
| **restringir** | menos gente chega até ele, ou só com credencial | o console só na rede da clínica; o webhook só com a assinatura do gateway |
| **reduzir o que ele alcança** | ele continua existindo, e consegue fazer menos | o worker com uma conta que lê agendamentos e nada mais |

**Remover** é o mais forte: um campo que não existe não pode ser abusado, e não precisa de teste,
patch nem revisão. É também o que as equipes esquecem de considerar, porque uma funcionalidade tem
dono e a ausência dela não tem.

**Restringir** muda quem está do outro lado da fronteira. O console na rede da clínica significa que
um desconhecido precisa estar dentro de uma clínica, ou dentro da rede dela, antes que a página de
login sequer responda. O webhook com assinatura verificada significa que só quem tem a chave do
gateway consegue mandá-lo.

**Reduzir o que ele alcança** é o que sobra quando um ponto de entrada precisa continuar aberto. O
formulário de login do paciente precisa responder a qualquer um, por definição. O que ele consegue
fazer depois ainda pode ficar menor: uma sessão de paciente que não chega ao exame de outro paciente
(T07) é uma superfície menor atrás da mesma porta.

### Medindo a mudança

Contar pontos de entrada é a primeira medida, e ela quase não se mexe. O que se mexe é **o número de
entradas que um desconhecido consegue usar sem credencial**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l06-shrinking\" aria-label=\"Pontos de entrada por quem consegue usá-los sem credencial, em três estados. Como desenhado na aula 2: quatro pontos de entrada, dois abertos a qualquer um, o formulário de login e o webhook, e dois que pedem credencial. Como está, com o console respondendo à internet: cinco, três abertos a qualquer um. Depois de duas mudanças, a assinatura do webhook e o console só na rede da clínica: quatro, um aberto a qualquer um, o formulário de login do paciente.\"><text x=\"200.0\" y=\"46.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">como desenhado na aula 2</text><rect x=\"212.0\" y=\"30.0\" width=\"110.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"322.0\" y=\"30.0\" width=\"110.0\" height=\"32.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M267.0 30.0 L267.0 62.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M322.0 30.0 L322.0 62.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M377.0 30.0 L377.0 62.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"442.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4 entradas, 2 abertas a qualquer um</text><text x=\"200.0\" y=\"102.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">como está</text><rect x=\"212.0\" y=\"86.0\" width=\"165.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"377.0\" y=\"86.0\" width=\"110.0\" height=\"32.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M267.0 86.0 L267.0 118.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M322.0 86.0 L322.0 118.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M377.0 86.0 L377.0 118.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M432.0 86.0 L432.0 118.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"497.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5 entradas, 3 abertas a qualquer um</text><text x=\"200.0\" y=\"158.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">depois de duas mudanças</text><rect x=\"212.0\" y=\"142.0\" width=\"55.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"267.0\" y=\"142.0\" width=\"165.0\" height=\"32.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M267.0 142.0 L267.0 174.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M322.0 142.0 L322.0 174.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M377.0 142.0 L377.0 174.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"442.0\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4 entradas, 1 abertas a qualquer um</text><rect x=\"212.0\" y=\"214.0\" width=\"14.0\" height=\"10.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"232.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">qualquer um consegue mandar</text><rect x=\"420.0\" y=\"214.0\" width=\"14.0\" height=\"10.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">exige credencial</text></svg>", "caption": "Contar pontos de entrada é um começo. Contar os que um desconhecido consegue usar é o número que se mexe quando a superfície encolhe de verdade."}
```

Como desenhado na aula 2, o portal parecia ter duas portas abertas: o formulário de login e o
webhook. Desenhado como está, tem três. Depois de duas mudanças, a assinatura do webhook e o console
na rede da clínica, tem uma, e essa não dá para fechar porque os pacientes precisam dela. O total
foi de cinco para quatro; as portas abertas foram de três para uma. Esse segundo número é o que se
reporta.

### O que isso faz com a lista de ameaças

Restringir o console fecha a T12 como ela está escrita: a página de login não responde mais à
internet. Não fecha a T03, a recepcionista vítima de phishing, que agora exige o atacante também
numa rede de clínica; isso torna a T03 menos provável, e as aulas de risco vão pôr um número em
quanto menos. A verificação de assinatura fecha a T01. E nenhuma das duas mudanças tira uma linha
do `threats.csv`. Uma ameaça que foi tratada fica na lista com a decisão ao lado, que é o assunto da
aula 12: um modelo que apaga as ameaças mitigadas esquece por que a mitigação está ali.
