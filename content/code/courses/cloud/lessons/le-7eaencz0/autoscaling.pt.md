---
title: "Grupos de autoscaling: um número que o provedor mantém verdadeiro"
version: 1
---

O autoscaling costuma ser apresentado como "a nuvem acrescenta servidores quando o tráfego sobe". Essa
é uma das coisas que ele faz, e não a primeira. **Um grupo de autoscaling é uma promessa sobre um
número**: haverá tantas instâncias saudáveis, lançadas a partir deste template, e quando a realidade
discorda o grupo muda a realidade até ela concordar de novo. Acrescentar máquinas por causa do tráfego
é essa promessa com um número que se move.

## Três números e um template

Um grupo é definido por três contagens e um launch template.

- O mínimo é o menor número de instâncias que o grupo vai rodar, qualquer que seja a carga.
- O máximo é o maior, qualquer que seja a carga. É um teto para a capacidade e para a conta.
- O desejado é o número que o grupo está buscando agora, sempre entre os dois. Você pode defini-lo, e
  as políticas de escala da próxima seção o mudam.

O launch template é a resposta para "como é uma instância", anotada uma vez como a seção de
lançamento descreveu: a imagem, o tipo, os security groups, o user data. Quando o grupo precisa de uma
máquina, ele lança uma a partir do template, e nunca entra numa para consertá-la.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um grupo de Auto Scaling com mínimo 2, desejado 3 e máximo 6, espalhado por duas zonas de disponibilidade. Um launch template o alimenta. Na zona a uma instância está saudável e outra falhou na verificação de saúde e está sendo encerrada; uma substituta é lançada a partir do template. A zona b tem uma instância saudável. Espaços tracejados mostram a folga até o máximo.\"><defs><marker id=\"asg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"108\" width=\"150\" height=\"124\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"91\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">launch template</text><text x=\"30\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">imagem</text><text x=\"30\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tipo de instância</text><text x=\"30\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">security group</text><text x=\"30\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">user data</text><rect x=\"196\" y=\"14\" width=\"508\" height=\"304\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"212\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">grupo de Auto Scaling</text><text x=\"688\" y=\"34\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">mín 2   desejado 3   máx 6</text><rect x=\"212\" y=\"52\" width=\"230\" height=\"254\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"224\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">zona a</text><rect x=\"462\" y=\"52\" width=\"230\" height=\"254\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"474\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">zona b</text><rect x=\"228\" y=\"84\" width=\"96\" height=\"60\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">saudável</text><rect x=\"334\" y=\"84\" width=\"96\" height=\"60\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"382\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">reprovada</text><text x=\"382\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">encerrada</text><rect x=\"228\" y=\"196\" width=\"202\" height=\"56\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"329\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">substituta</text><text x=\"329\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a partir do template</text><path d=\"M382 144 L382 190\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#asg-ah)\"></path><path d=\"M166 224 L222 224\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#asg-ah)\"></path><rect x=\"478\" y=\"84\" width=\"96\" height=\"60\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"526\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">saudável</text><rect x=\"588\" y=\"84\" width=\"96\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"478\" y=\"196\" width=\"96\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"588\" y=\"196\" width=\"96\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"636\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">folga até o máx</text></svg>", "caption": "O grupo guarda um número, não um conjunto de máquinas. Quando uma instância falha na verificação de saúde, o grupo a encerra e lança outra a partir do template, e a contagem volta ao desejado; as zonas são onde ele as espalha, e a aula 9 explica isso.", "same": ["launch template", "security group", "user data"]}
```

## Verificações de saúde e substituição

De tempos em tempos o grupo pergunta se cada instância está saudável, e ele tem dois jeitos de
perguntar.

A verificação do próprio provedor pergunta se a máquina virtual está rodando e alcançável pelo host:
se deu boot, se o hipervisor a enxerga. Ela pega um kernel travado ou um host com defeito. Não pega um
servidor web que parou de responder numa máquina que, no resto, está bem.

A **verificação de um balanceador de carga** pergunta à aplicação. O balanceador na frente do grupo,
que a aula 6 monta, pede um caminho como `/health` a cada instância, e uma instância que deixa de
responder com sucesso é marcada como não saudável. É a verificação que vê o que os usuários veem, e
um grupo que atende tráfego web deve usá-la.

**Uma instância não saudável não é consertada, é substituída.** O grupo a encerra e lança uma nova a
partir do template, e a contagem volta para onde estava. Ninguém é chamado para entrar, porque não há nada na máquina antiga que justifique entrar nela, que é exatamente a propriedade que a última seção desta aula
exige.

Uma configuração impede que isso dê errado do jeito óbvio. Uma instância nova leva um tempo para dar
boot e rodar o user data, e nesse tempo ela falha na verificação porque ainda não está atendendo. O
**período de carência** diz ao grupo para ignorar as verificações por um tempo depois do lançamento;
curto demais, e o grupo mata toda instância nova antes de ela terminar de subir e lança outra, para
sempre.

## Espalhado por zonas

Um grupo pode receber subnets em mais de uma zona de disponibilidade, e ele espalha as instâncias por
elas e as mantém equilibradas. Se uma zona cai, as instâncias dali falham nas verificações, e o grupo
lança as substitutas nas zonas que continuam funcionando. A aula 9 diz o que é uma zona e por que duas
raramente caem juntas; por enquanto o ponto é que o grupo faz o espalhamento, então um `SubnetId`
escolhido à mão deixa de ser o que decide onde as suas máquinas rodam.

**Um grupo de um também serve.** Com mínimo, desejado e máximo todos em 1, o grupo nunca escala, mas
substitui a sua única instância quando ela falha numa verificação. É o jeito mais barato de ter uma
máquina que volta sozinha, desde que, de novo, nada nela precise sobreviver.
