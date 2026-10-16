---
title: Por que a documentação apodrece, e o que a mantém verdadeira
version: 1
---

**A documentação se deteriora porque o sistema muda e a página não, e uma página desatualizada faz
mais estrago do que uma que falta, porque nela se acredita.** O que mantém a documentação verdadeira não
é esforço, é arranjo: menos páginas, cada uma com dono e data, atualizadas pelas mudanças que as tornam
erradas e apagadas quando ninguém vai mantê-las.

A conclusão tentadora diante de uma wiki cheia de páginas velhas é que o time precisa de mais
disciplina, e vem um mutirão de documentação. Ele produz algumas centenas de páginas corretas no dia em
que termina, e a mesma deterioração começa na manhã seguinte, porque nada no arranjo mudou.

## A página desatualizada em que se acredita

Em setembro, pediram a Ícaro um relatório de repasses por transportadora. Ele achou a página da wiki
"Arquitetura de Payments", que era clara, bem desenhada e dizia que o job de repasses lê o status das
entregas na tabela `deliveries` do monólito. Ele escreveu as consultas contra essa tabela.

A página era verdadeira quando foi escrita, em março de 2023. Em 2024 Tracking foi para um serviço
próprio, com banco de dados próprio, e a tabela `deliveries` parou de receber entregas novas da maioria
das transportadoras. **O relatório de Ícaro mostrou várias transportadoras grandes sem entrega
nenhuma**, e ele passou seis dias úteis procurando o bug nas consultas até Bruno, ao revisar o
relatório, reconhecer a tabela.

Nada disso foi culpa de Ícaro, e essa é a lição. Se a página não existisse, ele teria perguntado a
Bruno na primeira manhã, e a resposta teria levado cinco minutos. **Um documento que falta produz uma
pergunta; um documento errado produz confiança.** A página não deixou de ajudá-lo; ela o mandou
ativamente para o lado errado, com um diagrama de cara oficial e nada nele dizendo que tinha três anos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Uma grade dois por dois. Colunas: correta, desatualizada. Linhas: confiável, posta em dúvida. Correta e confiável é para isso que serve documentação, mantida certa pelo dono. Desatualizada e confiável está destacada como o prejuízo, os seis dias de Ícaro, alcançado sem ninguém agir. Correta e posta em dúvida é desperdício: está certa, mas todos perguntam mesmo assim. Desatualizada e posta em dúvida é inofensiva se marcada com data, aviso ou arquivo. Uma seta tracejada com o rótulo tempo leva a página de correta para desatualizada; as setas que saem do canto do prejuízo dizem atualizar, de volta para correta, e marcar ou apagar, para baixo, até posta em dúvida.\"><defs><marker id=\"l8quad-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"280\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">correta</text><text x=\"590\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">desatualizada</text><text x=\"140\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">confiável</text><text x=\"140\" y=\"280\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">posta em dúvida</text><rect x=\"150\" y=\"50\" width=\"260\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">para isso serve documentação</text><text x=\"280.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">mantida certa pelo dono</text><rect x=\"470\" y=\"50\" width=\"240\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"590.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">o prejuízo: os seis dias de Ícaro</text><text x=\"590.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">alcançado sem ninguém agir</text><rect x=\"150\" y=\"230\" width=\"260\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"271.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">desperdício: está certa,</text><text x=\"280.0\" y=\"289.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">mas todos perguntam mesmo assim</text><rect x=\"470\" y=\"230\" width=\"240\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"271.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">inofensiva, se marcada:</text><text x=\"590.0\" y=\"289.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">data, aviso ou arquivo</text><path d=\"M412 132 L466 132\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" marker-end=\"url(#l8quad-ah)\"></path><text x=\"440\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text><path d=\"M468 82 L414 82\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l8quad-ah)\"></path><text x=\"440\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">atualizar</text><path d=\"M590 172 L590 226\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l8quad-ah)\"></path><text x=\"580\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">marcar ou apagar</text></svg>", "caption": "Uma página tem duas propriedades: se está correta e se os leitores confiam nela. O tempo leva uma página confiável para o canto caro sem ninguém tocar nela; as saídas são atualizá-la ou marcá-la para que ninguém confie nela por engano."}
```

O canto que custa é o de cima à direita: errado e confiável. Uma página entra nele sem ninguém fazer
nada, só porque o sistema muda em volta dela. As saídas são as duas setas: torná-la verdadeira de novo,
ou impedir que se confie nela por engano — uma data, um aviso ou a remoção.

## Por que a documentação apodrece

Cinco causas explicam a maior parte, e cada uma tem uma correção que é de arranjo, não de força de
vontade.

- **Foi escrita uma vez, como entregável.** Um projeto termina com "escrever a documentação", as páginas
  são escritas na última semana e ninguém fica responsável por elas depois que o projeto fecha.
- **Mora longe da mudança.** A wiki da seção anterior: nada no dia de um desenvolvedor passa por ela.
- **Ninguém é dono.** "O time" ou "todo mundo" é dono da página, o que quer dizer que, quando ela está
  errada, não é trabalho de ninguém perceber.
- **É detalhada demais.** Uma página que lista cada endpoint de Payments fica errada a cada endpoint
  novo. Uma página que diz que Payments é dono dos repasses e Tracking é dono dos comprovantes muda
  mais ou menos uma vez por ano. **Escreva no nível que muda devagar, e gere o resto** — uma referência
  de API a partir do arquivo OpenAPI, um diagrama de nível de código a partir do código.
- **Não tem data.** Quem lê não distingue uma página de 2023 de uma escrita na semana passada, então
  confia nas duas por igual.

## O que a mantém viva

As regras de Renata para a Carreto cabem numa ficha, e cada uma responde a uma das causas acima.

**Toda página tem dono e data.** O dono é um time com uma pessoa nomeada, escrito no topo. A data é a
da última vez em que a página foi conferida contra o sistema, não só editada, e a página diz de quanto
em quanto tempo deve ser conferida: seis meses para um diagrama de contêineres, um ano para um README.
Um pequeno job no pipeline lista toda página com a data vencida e põe um aviso na cópia publicada. O
aviso não deixa a página certa; impede que se confie nela por engano.

**Mudanças disparam atualizações.** O modelo de pull request da seção anterior é um gatilho. O fórum
de arquitetura, que a aula 10 descreve, percorre o diagrama de contêineres uma vez por trimestre e
pergunta a cada time se a parte dele ainda é verdade. A integração de pessoas novas é o terceiro: cada
engenheiro novo corrige as páginas que o enganaram no primeiro mês, enquanto ainda se lembra de quais
foram. O primeiro pull request de Ícaro depois do relatório reescreveu a página de Payments, com data e
dono, o que transformou seis dias perdidos na correção.

**O que pode ser conferido é conferido.** Um diagrama que afirma que Payments não chama Matching é uma
afirmação que um programa consegue testar contra o código, e a aula 9 mostra o programa. Uma afirmação
sustentada por um teste não consegue ficar velha em silêncio.

**Menos páginas.** Cada página é uma promessa de manter algo verdadeiro, e as promessas são pagas com o
tempo de alguém. A página mais barata de manter é a que nunca foi escrita porque o código ou uma
referência gerada já respondia à pergunta.

## Registros e descrições

Dois tipos de documento se parecem e precisam ser tratados de maneiras opostas.

**Um registro é verdadeiro numa data, e nunca é atualizado.** Um ADR, um postmortem, a ata da reunião
em que se combinou o prazo da safra. O valor dele é dizer o que se sabia e se decidiu naquele momento.
Quando a decisão muda, um registro novo substitui o antigo, como a aula 5 descreveu para os ADRs; editar
o antigo para bater com hoje destruiria exatamente o que o fazia valer a pena.

**Uma descrição afirma ser verdadeira agora, e precisa continuar assim.** O diagrama de contêineres, um
README, um runbook, a página de requisitos da aula 7. Uma descrição que não é mantida não é um registro
histórico; está simplesmente errada.

**O erro é tratar um como o outro.** Reescrever um ADR para bater com o sistema de hoje apaga por que o
sistema foi construído como foi. Deixar uma descrição intocada por três anos, como se fosse registro,
produziu os seis dias de Ícaro. A Carreto marca cada documento com o tipo no topo, para que quem lê
saiba se "março de 2023" quer dizer "isto é história" ou "isto pode estar desatualizado".

## Apagar

**Apagar uma página é manutenção.** Uma página errada sem dono disposto a corrigi-la deve sair, ou ser
arquivada com um aviso que aponte para o que a substituiu. A maioria dos times nunca apaga nada, porque
apagar parece perder informação, quando a informação se perdeu no dia em que a página deixou de ser
verdade.

Renata fez uma varredura da wiki de 640 páginas. As 230 páginas editadas nos últimos dois anos ficaram.
Cada time percorreu as outras 410 que tocavam a sua área e escolheu uma de duas coisas para cada uma:
corrigi-la e dar a ela dono e data, ou arquivá-la. Antes, toda página que fosse na verdade o registro
de uma decisão foi copiada para o repositório. Corrigiram 90 e arquivaram 320. Metade da wiki, em
número de páginas, saiu num mês, e ninguém pediu de volta uma página arquivada até agora. **Uma wiki de
320 páginas verdadeiras é muito mais útil do que uma de 640 em que o leitor não consegue saber quais
são.**

A aula 11 de `architecture-modeling` vai mais fundo em onde a documentação viva deve ficar e quanto
tempo ela vive.
