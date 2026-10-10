---
title: Quem tem algo em jogo, e do que cada um precisa
version: 1
---

Duas imagens de stakeholders são comuns e as duas estão erradas. Numa, o stakeholder é "o negócio": a
diretora de produto e o CTO, e todo o resto executa. Na outra, todo mundo que é afetado é stakeholder
do mesmo jeito, e todos recebem o mesmo e-mail semanal. **Stakeholder é qualquer pessoa que pode
afetar uma decisão ou é afetada por ela, e eles diferem em quanto podem mudá-la e em quanto se
importam.** Essas duas diferenças decidem do que cada um precisa do arquiteto, e com que frequência.

## Uma iniciativa, onze stakeholders

Em 2026 a Carreto decidiu tirar do monólito a emissão do CT-e, o conhecimento de transporte eletrônico
que todo frete precisa antes de o caminhão sair, e pô-la num serviço próprio. O código no monólito
tinha crescido em volta das regras de um estado e era difícil de mudar; um novo leiaute do CT-e estava
chegando; e quando o monólito ficava lento, caminhões esperavam um documento na doca.

O primeiro passo da Renata foi uma lista, feita com uma pergunta em cada conversa: **quem recebe o
telefonema quando isto falha?** As respostas foram bem além das pessoas na reunião de planejamento:

- Tomás Viana, o CTO, que aprovou a iniciativa e responde por ela ao conselho;
- Sílvio Matos, o diretor financeiro, porque o CT-e é um documento fiscal e um errado vira multa;
- Helena Prado, a diretora de produto, porque os embarcadores veem a etapa do CT-e no seu fluxo;
- Bruno Farias e Payments, porque toda fatura a um embarcador se refere ao seu CT-e;
- Diego Araújo e o time Driver, porque o app mostra o documento ao motorista antes da partida;
- Paula Reis e Platform, que vão operar o serviço e cuidar do certificado digital que assina cada CT-e;
- o escritório de contabilidade de fora que entrega as obrigações fiscais da Carreto;
- o time de suporte, que atende quando o caminhão de um embarcador fica parado na doca;
- os motoristas, que não podem sair sem o documento e recebem por viagem;
- os times de Matching e Tracking, cujos serviços leem a carga que o CT-e descreve;
- a SEFAZ, a autoridade tributária estadual que autoriza cada CT-e.

O último item é um stakeholder de outro tipo. A SEFAZ não pode ser convencida e não vai a reunião. Ela
é uma **restrição com interface**: suas regras, sua disponibilidade e suas mudanças de leiaute moldam o
desenho, e o trabalho com esse stakeholder é ler suas notas técnicas e planejar para suas quedas. Pô-la
na lista ao lado das pessoas continua útil, porque alguém precisa ser dono de acompanhá-la.

## A grade de poder e interesse

Uma lista de onze não diz onde gastar tempo. A ferramenta de costume é uma grade com dois eixos:
**poder**, quanto uma pessoa pode mudar ou parar a decisão, e **interesse**, quanto a decisão a afeta
ou quão de perto ela acompanha. A grade costuma ser creditada ao trabalho de Aubrey Mendelow no começo
dos anos 1990, e cada um dos quatro quadrantes vem com uma instrução padrão.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 390\" role=\"img\" aria-label=\"Uma grade com poder no eixo vertical e interesse no eixo horizontal. Muito poder e muito interesse, gerenciar de perto: Sílvio Matos, financeiro; Helena Prado, produto; Bruno Farias, Payments. Muito poder e pouco interesse, manter satisfeito: Tomás Viana, CTO; o escritório de contabilidade. Pouco poder e muito interesse, manter informado: suporte; Diego e o time Driver; Paula e Platform; os motoristas. Pouco poder e pouco interesse, monitorar: Matching; Tracking. Uma nota abaixo diz que a SEFAZ fica fora da grade: uma restrição com interface, não alguém a convencer.\"><defs><marker id=\"grid-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"90\" y=\"30\" width=\"270\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">manter satisfeito</text><text x=\"225\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Tomás Viana, CTO</text><text x=\"225\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o escritório de contabilidade</text><rect x=\"360\" y=\"30\" width=\"270\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">gerenciar de perto</text><text x=\"495\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Sílvio Matos, financeiro</text><text x=\"495\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Helena Prado, produto</text><text x=\"495\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Bruno Farias, Payments</text><rect x=\"90\" y=\"180\" width=\"270\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">monitorar</text><text x=\"225\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Matching</text><text x=\"225\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Tracking</text><rect x=\"360\" y=\"180\" width=\"270\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">manter informado</text><text x=\"495\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">suporte</text><text x=\"495\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Diego e o time Driver</text><text x=\"495\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Paula e Platform</text><text x=\"495\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">os motoristas</text><path d=\"M70 330 L70 34\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#grid-ah)\"></path><text x=\"40\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">poder</text><path d=\"M90 350 L626 350\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#grid-ah)\"></path><text x=\"636\" y=\"350\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">interesse</text><text x=\"360\" y=\"376\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A SEFAZ fica fora da grade: uma restrição com interface, não alguém a convencer</text></svg>", "caption": "Os stakeholders do serviço de CT-e na grade de Mendelow, como Renata a desenhou no começo. O quadrante diz quanta atenção cada um recebe; a grade é redesenhada a cada fase.", "same": ["Tomás Viana, CTO", "Bruno Farias, Payments", "Matching", "Tracking"]}
```

- Muito poder, muito interesse: **gerenciar de perto.** Sílvio, Helena e Bruno podem, cada um, parar o
  trabalho, e cada um vai notar toda mudança. Renata se reunia com eles a cada duas semanas por trinta
  minutos, com as decisões que vinham pela frente e suas consequências.
- Muito poder, pouco interesse: **manter satisfeito.** Tomás patrocina o trabalho e não quer o
  detalhe; o escritório de contabilidade poderia se recusar a fechar uma entrega e não tem interesse
  em como o serviço é construído. Cada um recebia uma página por mês: avanço, riscos em reais e qualquer
  decisão que precisasse deles.
- Pouco poder, muito interesse: **manter informado.** Suporte, o time do Diego e Platform convivem com
  o resultado todo dia e não decidem o escopo. Recebiam um post no canal do projeto a cada marco e um
  convite aberto para o fórum de arquitetura (a terceira seção desta aula).
- Pouco poder, pouco interesse: **monitorar.** Matching e Tracking são afetados só nas bordas. Os ADRs
  bastavam, e Renata conversava com eles antes de qualquer mudança nos dados da carga.

**Os quadrantes são instruções sobre esforço, não sobre respeito.** Os motoristas ficam no canto de
manter informado porque nenhum deles se senta nas reuniões de planejamento da Carreto, e eles são as
pessoas para quem a iniciativa inteira existe. O interesse deles chega pelo Diego, que sabe que um
motorista numa doca em Paranaguá sem sinal não pode esperar um documento carregar, e pelo suporte, que
fica sabendo quando dá errado.

## A grade se mexe

Uma grade desenhada uma vez está errada em um mês. Em julho a SEFAZ publicou a data do novo leiaute, e
Sílvio passou de atento a ansioso: perder a data significava caminhões que não podiam sair legalmente.
Renata passou a reunião quinzenal com ele para semanal até o novo leiaute estar em produção. O
escritório de contabilidade também se mexeu, de uma página mensal para uma revisão dos documentos de
teste.

O movimento contrário importa tanto quanto. Com o serviço no ar e estável, o interesse de Helena voltou
para a etapa no fluxo do embarcador, e uma reunião quinzenal seria um custo para ela sem nada dentro.
**Redesenhe a grade a cada fase do trabalho**, e avise quando mudar a frequência com que encontra
alguém; senão a mudança soa como abandono.

## Do que cada um precisa do arquiteto

A grade diz quanta atenção cada stakeholder recebe. O que vai nessa atenção depende do que cada um está
tentando proteger, e Renata escreveu uma linha por stakeholder antes da primeira reunião:

| stakeholder | o que protege | do que precisa da Renata |
|---|---|---|
| Sílvio | nenhuma multa, nenhum conhecimento rejeitado | o risco de rejeição em reais, e a data em que o novo leiaute fica pronto |
| Helena | o fluxo do embarcador | quais telas mudam, e quando |
| Bruno | faturas que batem com seu CT-e | a interface entre o novo serviço e o faturamento, antes de ser construída |
| Tomás | o compromisso com o conselho | uma página por mês e nenhuma surpresa |
| suporte | não ser o último a saber | o que muda para o embarcador no dia em que muda |

Nenhuma dessas pessoas pediu um diagrama de arquitetura, e só o Bruno leria um. **Dizer a mesma coisa a
cinco pessoas de cinco formas não é incoerência**: a decisão é a mesma e as consequências mudam com o
leitor. O ofício de adaptar uma mensagem ao conselho, ao produto, a um time e a um cliente é a aula 3 de
`architect-communication`; esta aula trata de saber a quem você deve uma mensagem, antes de tudo.

## Os stakeholders que ninguém listou

A pergunta do telefonema achou três stakeholders que a primeira reunião de planejamento não tinha
mencionado: o suporte, o escritório de contabilidade e o certificado de Platform. O certificado não é
uma pessoa, mas vence todo ano, e um CT-e assinado com certificado vencido é rejeitado. Alguém precisa
ser dono dessa data, e antes da lista da Renata ninguém era.

O padrão é geral. **Os stakeholders mais esquecidos são os que encontram o sistema quando ele falha**:
suporte, plantão, operação, alguém de fora que entrega ou audita. Eles têm pouco poder sobre o desenho e
o conhecimento mais direto do que dá errado nele, e uma hora com eles cedo custa menos que um incidente
depois.
