---
title: Escolhendo as células
version: 1
---

Duas escolhas vêm naturalmente e as duas são fracas. Uma é testar no que o testador tiver à mão, o
que testa os hábitos do testador. A outra é testar em tantas células quanto o tempo permitir, sem
ordem nenhuma, o que para onde o tempo acabar. **A cobertura é escolhida a partir de duas entradas:
quem de fato usa o produto, e onde ele tem mais chance de quebrar.** A primeira diz quais células
importam; a segunda diz com que profundidade testar cada uma.

## Quem usa

O teatro já tem um site, e as estatísticas dele dizem o que os visitantes usaram no mês passado:

| navegador e plataforma | parcela das visitas |
|---|---|
| Chrome em celulares Android | 46% |
| Safari em iPhones | 24% |
| Chrome no Windows | 13% |
| Edge no Windows | 7% |
| Safari em Macs | 4% |
| Firefox, em qualquer plataforma | 3% |
| todo o resto | 3% |

Sete visitas em dez vêm de um celular, o que transforma os 360 pixels do R8 de detalhe em caso
principal. E só a primeira linha já é 46%, então um defeito que só aparece no Chrome
de um celular Android atinge quase metade do público.

**Dados de público descrevem as pessoas para quem o site antigo funcionava.** Se o site antigo
estivesse quebrado no Firefox, os usuários do Firefox teriam parado de vir, e as estatísticas
mostrariam uma parcela pequena de Firefox como se fosse um fato sobre o público. Leia uma parcela
baixa como pergunta antes de lê-la como motivo para pular uma célula.

## Onde é provável quebrar

A segunda entrada é o risco, a mesma probabilidade e o mesmo impacto que ordenaram os riscos do
boxoffice na aula 1. Para compatibilidade, a probabilidade vem do que muda entre ambientes:

- layout, porque cada motor calcula larguras de um jeito ligeiramente diferente, e fontes que mudam
  de sistema para sistema deixam a mesma palavra mais larga ou mais estreita;
- controles de formulário, porque o menu de espetáculos, a caixa Student e os campos de texto são
  desenhados pelo sistema, não pela página;
- scripts, porque código rodando no navegador encontra as manias de cada motor.

O boxoffice manda HTML simples com um bloco curto de estilo e nenhum script, então o terceiro risco
não existe e os dois primeiros são pequenos. Isso é um achado real sobre o produto, e é por isso que
uma matriz modesta se defende aqui. Uma página de reserva construída sobre um grande framework de
scripts mereceria uma mais larga.

O impacto vem da tabela de público: uma falha no Chrome do Android custa quase metade dos clientes,
uma no Safari de um Mac custa quatro em cem.

## A escolha para o boxoffice 1.0

Juntas, as duas entradas dão a cada célula uma profundidade em vez de um sim ou não:

| célula | por quê | profundidade |
|---|---|---|
| Chrome num celular Android, 360 | 46% das visitas, um celular | passada completa |
| Safari num iPhone, 360 | 24%, o único motor de um iPhone | passada completa |
| Chrome no Windows, desktop | 13% | passada completa |
| Edge no Windows, desktop | 7%, o mesmo motor do Chrome | passada curta |
| Safari num Mac, desktop | 4%, WebKit em largura de desktop | passada curta |
| Firefox no Windows, desktop | 3%, a única célula Gecko | passada curta |
| Chrome, Firefox e Edge num iPhone | WebKit, já coberto pelo Safari no iPhone | não testado, e o plano diz isso |

Uma **passada completa** roda todos os casos. Uma **passada curta** roda a lista de fumaça da aula 8
e os casos dos riscos mais altos, e depois olha cada página naquele tamanho: tudo aparece, todo
controle pode ser alcançado e usado.
Três passadas completas e três curtas cabem no tempo em que catorze completas não caberiam, e todos
os motores e os dois tamanhos estão nelas.

Duas regras valem além deste exemplo. **Todo motor recebe pelo menos uma célula**, porque é entre
motores que estão as diferenças, por menor que seja a parcela de um motor. E os casos dos riscos mais
altos do plano, o preço e o layout no celular no caso do boxoffice, rodam em toda célula que for
testada; são os casos de risco baixo que ficam espalhados.

## O que o laboratório alcança

O laptop de Ana roda Ubuntu. Chrome, Firefox e Edge têm versões para Linux, então os motores das
três células de Windows estão na mesa dela, desenhando com as fontes do Ubuntu em vez das do
Windows, o que é parecido e não é igual. O Safari só roda nos sistemas da Apple, e nenhum dos dois
celulares é um laptop. Então três das seis células escolhidas precisam de algo que Ana não tem, e
a seção 05 desta aula trata de onde elas vêm. Seja qual for a resposta, ela vai para a linha de
ambiente do plano da aula 1, que dizia "Chrome, Firefox, Safari e Edge, versões atuais; um celular de
360 pixels de largura" e agora pode dizer quais, onde e com que profundidade.
