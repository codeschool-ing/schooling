---
title: O padrão estrangulador
version: 1
---

Um sistema que precisa mudar costuma ser discutido como se houvesse duas escolhas: continuar
remendando o código antigo, ou reescrevê-lo. A aula 6 pôs preço na reescrita e a recusou. Só
remendar deixa a dívida das reservas de assento cobrando juros a cada sprint. **Há uma terceira
escolha: substituir o sistema antigo uma peça de cada vez, enquanto ele continua atendendo
tráfego.** A produção roda o tempo todo numa mistura de antigo e novo, e ninguém precisa escolher um
dia para a troca.

## A figueira

Martin Fowler deu o nome em 2004, num artigo curto chamado "StranglerFigApplication", por causa de
uma planta que ele tinha visto nas florestas tropicais de Queensland. Uma figueira estranguladora
começa como semente nos galhos de uma árvore hospedeira. Ela solta raízes até o chão, envolve o
tronco e cresce até se sustentar sozinha; a árvore hospedeira lá dentro acaba morrendo e apodrecendo,
e a figueira mantém a forma.

A versão de software guarda as partes que importam. O sistema novo cresce em volta do antigo, e não
ao lado dele. Ele assume uma função de cada vez. E o sistema antigo continua funcionando o tempo todo,
até não sobrar nada para ele fazer e ele poder ser removido.

## A forma

O padrão tem cinco movimentos, e a ordem é o que importa:

1. Ponha na frente do sistema antigo algo pelo qual passe todo pedido relevante. A palavra de Fowler
   para isso é fachada; pode ser um proxy, um roteador ou um ponto de entrada único dentro do código
   antigo.
2. Construa a peça nova para uma fatia de comportamento.
3. Roteie essa fatia para a peça nova, e mantenha o caminho de volta aberto.
4. Repita com a fatia seguinte, até não sobrar nada no caminho antigo.
5. Apague o código antigo.

**O primeiro movimento é o que mais exige reflexão e não entrega nada que um cliente veja.** Todos os
outros dependem dele, porque a fachada é o que torna uma fatia movível — e movível de volta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Três etapas da esquerda para a direita. Quem chama — compradores na web e nos aplicativos, e a Bilheteria na porta — manda todo pedido de reserva de assento para uma fachada. A fachada procura o evento numa tabela de roteamento e o manda ou para o coreto-core, o código antigo de reservas com seus travamentos de linha, para eventos ainda não movidos, ou para o novo serviço de reservas, que reserva assentos com prazo de expiração, para eventos já movidos.\"><defs><marker id=\"l07f-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"125\" width=\"150\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"151\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Quem chama</text><text x=\"95.0\" y=\"169\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper-dim)\">web e aplicativos</text><text x=\"95.0\" y=\"187\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper-dim)\">Bilheteria</text><rect x=\"230\" y=\"105\" width=\"180\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"320.0\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">Fachada</text><text x=\"320.0\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper)\">procura o evento</text><text x=\"320.0\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper)\">numa tabela de rotas</text><text x=\"320.0\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper)\">e o manda a um lado</text><rect x=\"480\" y=\"30\" width=\"220\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">coreto-core</text><text x=\"590.0\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper)\">código antigo de reservas</text><text x=\"590.0\" y=\"102\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper-dim)\">travamentos de linha</text><rect x=\"480\" y=\"200\" width=\"220\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Serviço de reservas</text><text x=\"590.0\" y=\"254\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper)\">código novo de reservas</text><text x=\"590.0\" y=\"272\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper-dim)\">reservas que expiram</text><path d=\"M172 165 L226 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l07f-ah)\"></path><path d=\"M412 140 L476 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l07f-ah)\"></path><path d=\"M412 190 L476 240\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#l07f-ah)\"></path><text x=\"436\" y=\"100\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ainda não movidos</text><text x=\"436\" y=\"244\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">movidos</text></svg>", "caption": "A forma do padrão estrangulador na Coreto. Todo pedido de reserva passa pela fachada, e mover um evento é mudar uma linha da tabela de roteamento — o que também faz de movê-lo de volta a mudança de uma linha."}
```

## Na Coreto

O time de Reservas, os quatro engenheiros que a aula 1 formou a partir do Checkout e de Pagamentos em
1º de março, assumiu o código das reservas de assento. O novo serviço de reservas guarda um assento
com um registro que expira sozinho, num armazenamento próprio, em vez de travar uma linha no banco do
`coreto-core` pelo tempo que o comprador levar para pagar. A fachada fica onde todo pedido de reserva
já entrava no monólito, e decide, evento por evento, qual código responde.

No fim do mês 1, o serviço novo levava 5% do tráfego de reservas. No fim do mês 6, levava 71%. A
migração inteira levou doze meses, e em nenhum dia desses doze a Coreto parou de vender ingressos,
congelou os outros times ou anunciou uma troca às casas de espetáculo.

## O que muda em relação a uma reescrita

| | reescrita | estrangulador |
|---|---|---|
| quando o valor chega | na virada, depois da construção inteira | com a primeira fatia movida |
| se o código novo estiver errado | errado para tudo, numa manhã | errado para uma fatia, roteada de volta |
| o sistema antigo enquanto isso | um alvo móvel que o novo persegue | encolhendo, uma fatia de cada vez |
| para onde vai o conhecimento do código antigo | redescoberto depois da troca | encontrado fatia por fatia, com os dois rodando |
| como termina | com uma troca, numa data | quando o código antigo é apagado |

**O alvo móvel da aula 6 deixa de ser um problema**, porque a parte sendo substituída não se move
mais: quando as reservas de um evento estão no serviço novo, as mudanças no funcionamento dessas
reservas são feitas lá. Os times continuam entregando, e o que entregam cai no lado que for dono
daquilo no momento.

## O que custa

O padrão é mais barato que uma reescrita e não é de graça. Durante a migração, a Coreto roda dois
sistemas de reservas em vez de um, mais a fachada entre eles. Alguns dados precisam ficar em sincronia
nos dois, o que é uma fonte de bugs por si só. E o padrão pede uma disciplina que uma reescrita nunca
pede: **o trabalho só termina quando o código antigo some**, e a essa altura a parte urgente já passou há
muito tempo.

É para esses custos que vão as duas próximas seções. Costuras e roteamento tratam de escolher as
fatias e movê-las com segurança; os últimos dez por cento tratam do fim, que é onde a maioria das
migrações desse tipo para sem alarde.
