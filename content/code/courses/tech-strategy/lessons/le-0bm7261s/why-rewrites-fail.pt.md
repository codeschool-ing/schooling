---
title: Por que as reescritas falham
version: 1
---

A proposta chegou ao Davi na semana seguinte à publicação da estratégia. O Mateus Araújo, líder
técnico do Checkout, queria começar de novo com dois engenheiros de Pagamentos: reescrever do zero o
módulo de reservas, com tudo o que nove anos tinham ensinado. O código de todos os times entra nesse
módulo, então a reescrita levaria junto as partes do `coreto-core` ligadas a ele — seis engenheiros,
dezoito meses. O código antigo continuaria rodando até o novo ficar pronto, e então a Coreto faria a
troca. O Davi recusou, e essa é a linha da lista do "que não vamos fazer" da aula 3; esta aula é o
argumento por trás dessa linha.

É a proposta mais atraente do software, e as razões por trás dela são reais. O monólito é difícil de
mudar, o código das reservas de assento é a pior parte, e todo engenheiro que já trabalhou ali sabe
esboçar um desenho melhor. O que a proposta erra são três coisas de uma vez: **o que o código antigo
contém, o tamanho que o novo acaba tendo e o que o sistema antigo faz enquanto espera.**

## O código antigo é a documentação que ninguém escreveu

Em 2000, Joel Spolsky publicou "Things You Should Never Do, Part I", sobre a decisão da Netscape de
reescrever o seu navegador do zero, que deixou a empresa anos sem uma nova versão principal enquanto
os concorrentes continuavam lançando. O argumento dele era sobre código, e não sobre a Netscape.
Código antigo parece feio porque foi consertado. Cada desvio estranho, cada caso especial que parece
inútil, muitas vezes é um bug que alguém encontrou em produção e uma correção que ninguém anotou em
nenhum outro lugar.

O módulo de reservas da Coreto está cheio deles. Uma condição libera reservas mais cedo para uma rede
de casas; uma verificação trata a meia-entrada que a lei brasileira garante aos estudantes; uma nova
tentativa existe porque um provedor de pagamento uma vez respondeu duas vezes ao mesmo pedido. Cada
um parece entulho para quem lê pela primeira vez, e cada um é um requisito. **Uma reescrita parte dos
requisitos de que as pessoas se lembram.** Os que vivem só no código são redescobertos um de cada
vez, em produção, depois da troca.

## O segundo sistema

Fred Brooks deu nome ao perigo seguinte em *The Mythical Man-Month*, em 1975: o efeito do segundo
sistema. Quem projeta um primeiro sistema é cuidadoso, porque ninguém ainda sabe o que vai funcionar.
Na segunda vez, confiante, o projetista põe tudo o que tinha segurado — cada generalização, cada
funcionalidade adiada. O segundo sistema sai maior e mais atrasado que o primeiro, e muitas vezes
mais lento.

A proposta do Mateus já mostra isso. A primeira página promete um modelo de reservas limpo. A segunda
acrescenta um barramento de eventos, um sistema de plugins para as casas e suporte a vendas fora do
Brasil, e ninguém na Coreto pediu nenhuma dessas coisas. Cada acréscimo é razoável sozinho. Juntos,
transformam uma estimativa de dezoito meses em algo que ninguém consegue estimar.

## O alvo móvel

**O sistema antigo não para enquanto o novo é escrito.** Ao longo de dezoito meses, os sete times da
Coreto vão continuar entregando no `coreto-core`; só a estratégia já põe um time de Reservas para
trabalhar no código das reservas de assento a partir de 1º de março. Cada mudança feita no sistema
antigo é uma mudança que o novo também precisa fazer antes de poder substituí-lo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Um gráfico esquemático sem números. O eixo horizontal é o tempo, o vertical é o que cada sistema faz. O sistema antigo começa alto e continua subindo. O sistema novo começa em zero. O plano o faz encontrar o sistema antigo como ele estava no primeiro dia; como a linha antiga continua subindo, a nova a encontra muito depois e bem mais acima.\"><defs><marker id=\"l06t-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 30 L70 280 L690 280\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l06t-ah)\"></path><text x=\"380.0\" y=\"310\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">tempo desde o início da reescrita</text><text x=\"80\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">o que o sistema faz</text><path d=\"M70 170 L690 70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><path d=\"M70 280 L330 170\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></path><path d=\"M70 170 L330 170\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></path><circle cx=\"330\" cy=\"170\" r=\"5\" fill=\"var(--paper-dim)\"></circle><path d=\"M70 280 L490 102\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><circle cx=\"490\" cy=\"102\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"680\" y=\"58\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">o sistema antigo, ainda sendo mudado</text><text x=\"338\" y=\"194\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o plano: alcançar o sistema</text><text x=\"338\" y=\"210\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">antigo como era no primeiro dia</text><text x=\"478\" y=\"78\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">o que acontece: alcançar</text><text x=\"478\" y=\"94\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">um sistema que não parou</text><text x=\"150\" y=\"262\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">o sistema novo</text></svg>", "caption": "O alvo móvel. Uma reescrita é estimada contra o sistema antigo como ele está quando o trabalho começa, e o sistema antigo continua mudando enquanto o novo é escrito."}
```

**Uma reescrita persegue um alvo que não para de se mover**, e quanto mais rápido a empresa entrega,
mais rápido ele se afasta. A escolha é desagradável dos dois lados. Congele o sistema antigo, e o
negócio espera um ano e meio pelas suas funcionalidades. Continue mudando, e a linha de chegada da
reescrita recua. Os seis engenheiros da reescrita são seis de 52 sem entregar nada que um cliente
veja, e os outros 46 estão aumentando o trabalho deles a cada sprint.

## Nada até o fim

O último problema é como o dinheiro é gasto. Uma reescrita não entrega nada até a troca: dezoito
meses de salários sem mudança que alguma casa ou comprador consiga ver, seguidos de uma única virada
em que cada diferença entre os dois sistemas aparece de uma vez. Se o código novo estiver errado
sobre uma reserva de assento, estará errado para todos os eventos na mesma manhã.

**O risco inteiro cai no único dia em que a empresa menos pode bancá-lo**, e na Coreto sempre há uma
abertura de vendas chegando. Compare com as dívidas da aula 5, em que cada pagamento começa a
economizar horas na sprint seguinte.

## O que as quatro têm em comum

| motivo | o que custa |
|---|---|
| o conhecimento vive no código antigo | requisitos redescobertos em produção |
| o efeito do segundo sistema | um escopo que cresce além de qualquer estimativa |
| o alvo móvel | uma linha de chegada que recua, ou um negócio que espera |
| valor só no fim | todo o risco caindo numa única virada |

Nenhum desses motivos tem a ver com a competência de quem propõe a reescrita. São propriedades da
abordagem, e pegam times bons tanto quanto times fracos. Elas também têm condições — tamanho,
mudança, uma troca irreversível — e a próxima seção trata das duas situações em que essas condições
deixam de valer.
