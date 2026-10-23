---
title: Mapeamento e limpeza, e quem assina
version: 1
---

O mapeamento é onde as decisões de uma migração ficam escritas. É tentador tratá-lo como o código
que move os dados, e deixar as decisões morarem nesse código. **O mapeamento é primeiro um documento
e só depois código**: uma linha por campo do destino, dizendo de onde vem o valor, o que acontece com
ele no caminho e quem concordou. O código implementa o documento, e quando os dois discordam é o
documento que vai para a discussão.

## A especificação de mapeamento

Uma especificação de mapeamento é uma tabela. Cada linha dá nome a um campo do destino, ao campo ou
campos de origem de onde ele vem, à regra que transforma um no outro e ao dono que assinou a regra.
Parte da especificação do cadastro de fazendas do Coleta é assim:

| campo de destino | origem no Coleta | regra | dono |
|---|---|---|---|
| `farm_id` | nenhuma | identificador novo, gerado pelo novo sistema | Joana |
| `legacy_code` | código da fazenda | copiado sem mudança, guardado enquanto alguém consultar o Coleta | Sebastião |
| `tax_id` | CPF ou CNPJ | copiado; recusado se os dígitos verificadores falharem | financeiro |
| `municipality` | município, texto livre | traduzido para o código do IBGE pela tabela de municípios | Sebastião |
| `vendor` | número do fornecedor no SAP | copiado; recusado se o SAP tiver bloqueado esse fornecedor | financeiro |
| `bank_account` | conta bancária | **não migrado**: o cadastro de fornecedores do SAP é a única fonte | financeiro |
| `litres` (histórico) | litros × 100, um inteiro | dividido por 100, guardado com duas casas decimais | Sebastião |
| `collected_on` (histórico) | data, oito dígitos, dia primeiro | lida como dia, mês, ano; recusada se não for uma data real | Sebastião |
| resultados de laboratório (histórico) | gordura, proteína, contagem de células, contagem bacteriana | copiados; unidades conferidas contra a tabela de Cláudia | Cláudia |

Três coisas nessa tabela merecem atenção.

**Guarde a chave antiga.** O `legacy_code` custa uma coluna e responde toda pergunta do tipo "que
fazenda do Coleta era esta?" nos meses em que as pessoas ainda consultam o Coleta. Sem ele, o único
caminho de um registro novo para um antigo é comparar nomes, que é a junção por texto que a camada
anticorrupção da aula 13 existe para evitar.

**Um campo pode ser mapeado para nada.** A conta bancária do Coleta parece dado e é um fóssil. O
perfil mostrou que ela não batia com o SAP em 412 fazendas, e é no SAP que o financeiro mantém os
dados bancários. Migrá-la criaria uma terceira cópia e, mais cedo ou mais tarde, um pagamento para a
errada.

**Unidade é uma regra como qualquer outra.** O Coleta guarda os litros em centésimos num inteiro,
porque em 1996 era assim que se guardavam decimais exatos. O novo sistema guarda um decimal. Os dois
estão certos; uma carga que copia o inteiro direto fica errada por um fator de cem e entra
perfeitamente.

## Tabelas de tradução e fusões

Onde a origem tem texto livre ou códigos antigos, a regra é uma consulta. **Uma tabela de tradução
leva cada valor que o perfil achou ao valor que o destino espera**, e é um arquivo que o dono
consegue ler e assinar:

| grafia no Coleta | fazendas | município do IBGE |
|---|---|---|
| `SANTOS DUMONT` | 61 | Santos Dumont |
| `STOS DUMONT` | 9 | Santos Dumont |
| `S. DUMONT` | 4 | Santos Dumont |
| `SANTOS DUMOND` | 1 | Santos Dumont |

A tabela tem 97 linhas, uma por grafia, e a carga recusa qualquer grafia que não esteja nela. Essa
recusa importa: **uma tabela de tradução com uma linha padrão transforma a grafia errada de amanhã
numa fazenda na cidade errada**, em silêncio.

As 7 fazendas duplicadas são uma tradução de chaves, não de valores. Uma tabela de fusões diz, para
cada par, qual código sobrevive e qual desaparece; o histórico de coletas da duplicada passa para a
sobrevivente. Sebastião escreveu a tabela à mão, porque só ele sabia que código cada fazenda de fato
usava, e assinou cada uma das 7 linhas.

## Valores padrão, e o que não migrar

Um campo do destino que a origem não consegue preencher pede uma decisão, e a mais fácil é um valor
padrão. **Um valor padrão é um valor em que alguém depois vai acreditar.** Se uma fazenda sem rota
tivesse recebido a rota 1 para satisfazer um campo obrigatório, o novo planejador de rotas mandaria
um caminhão até ela. Onde a origem não tem nada, os valores honestos são um vazio que o destino
aceite, ou uma recusa que devolva a linha ao dono.

O mesmo vale para linhas. Nem tudo do sistema antigo pertence ao novo:

- **o histórico fora do período** vai para o arquivo: as 182 fazendas sem coleta em seis anos, e
  cerca de 10,5 milhões de coletas antigas;
- **os órfãos** vão para o arquivo com uma nota, já que nada no novo sistema pode se referir a eles;
- **campos com um dono melhor em outro lugar**, como a conta bancária, não vão para lugar nenhum.

Cada exclusão é uma regra na especificação. A reconciliação, mais adiante nesta aula, precisa
prestar contas de cada linha da origem, e uma linha deixada de fora de propósito precisa de uma
regra para a qual apontar.

## Onde limpar

O perfil achou dados sujos; o mapeamento tem de dizer onde eles ficam limpos. Há três lugares, e eles
não são equivalentes.

| onde | o que significa | bom para | o preço |
|---|---|---|---|
| na origem | o dono corrige o sistema antigo antes da mudança | fatos errados: um CPF inválido, um número de fornecedor vencido | as telas do sistema antigo e o tempo do dono |
| no caminho | a transformação corrige o valor durante a passagem | forma e código: grafias, unidades, layouts, fusões | o sistema antigo continua sujo; a regra roda em toda carga |
| depois da carga | o dono corrige o sistema novo | o que for achado tarde, por quem usa | o sistema novo começa sujo, na frente dos usuários |

O primeiro instinto de Joana foi fazer tudo no caminho. Na fintech de onde ela veio, uma correção de
dados era um script na migração, e a origem era um banco que ninguém mais leria. Sebastião apontou a
diferença. **O Coleta continua rodando meses depois de o cadastro de fazendas mudar de sistema**,
porque o estrangulamento da aula 13 move uma capacidade de cada vez, e toda noite ele ainda escreve
o arquivo que o SAP carrega. Um CPF inválido corrigido só no caminho continua inválido no Coleta, em
todo arquivo que ele escreve, até o dia em que for desligado. Um fato errado é corrigido onde ele
mora.

Então a Serra Alta dividiu o trabalho por tipo. **Fatos errados são corrigidos na origem pelo dono:**
o financeiro consertou os 9 CPFs e os 4 fornecedores bloqueados nas telas do próprio Coleta.
**Formas erradas são traduzidas no caminho:** os municípios, as unidades, as datas e as 7 fusões,
todos por tabelas que fazem parte da especificação. Nada foi planejado para depois da carga, o que
não é o mesmo que nada acontecer ali; a última seção desta aula trata do que aconteceu.

## O pipeline e os rejeitos

Juntando tudo, a migração são três passos, com um arquivo de rejeitos em cada um dos dois últimos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l14-pipeline\" aria-label=\"O pipeline da migração, da esquerda para a direita: o Coleta, copiado no congelamento; extração; transformação; carga; o novo sistema de fazendas. Acima da transformação, a especificação de mapeamento, assinada pelos donos dos dados, alimenta as regras: tabelas de tradução, a tabela de fusões e as unidades. Debaixo da extração, as linhas fora do período vão para o arquivo. Debaixo da transformação e da carga, um arquivo de rejeitos guarda cada linha recusada com o motivo. Os dois arquivos de rejeitos vão para os donos, o financeiro, Sebastião e Cláudia, que corrigem os fatos errados no próprio Coleta, numa seta tracejada de volta ao Coleta, e a execução seguinte já leva a correção.\"><defs><marker id=\"l14-pipeline-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-pipeline-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l14-pipeline-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"14.0\" y=\"105.0\" width=\"112.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"123.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Coleta</text><text x=\"70.0\" y=\"136.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cópia no congelamento</text><rect x=\"156.0\" y=\"105.0\" width=\"112.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"212.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">extração</text><rect x=\"306.0\" y=\"105.0\" width=\"112.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"362.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">transformação</text><rect x=\"456.0\" y=\"105.0\" width=\"112.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"512.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">carga</text><rect x=\"600.0\" y=\"105.0\" width=\"112.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"656.0\" y=\"123.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">novo sistema</text><text x=\"656.0\" y=\"136.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">de fazendas</text><path d=\"M126.0 130.0 L154.0 130.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-pipeline-es-ah-phosphor)\"></path><path d=\"M268.0 130.0 L304.0 130.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-pipeline-es-ah-phosphor)\"></path><path d=\"M418.0 130.0 L454.0 130.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-pipeline-es-ah-phosphor)\"></path><path d=\"M568.0 130.0 L598.0 130.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-pipeline-es-ah-phosphor)\"></path><rect x=\"237.0\" y=\"17.0\" width=\"250.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"362.0\" y=\"33.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">especificação de mapeamento</text><text x=\"362.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">assinada pelos donos dos dados</text><path d=\"M362.0 63.0 L362.0 103.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-es-ah-paper-dim)\"></path><text x=\"372.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">regras, tabelas, fusões</text><path d=\"M212.0 155.0 L212.0 193.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-es-ah-paper-dim)\"></path><rect x=\"146.0\" y=\"194.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"212.0\" y=\"209.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivo</text><text x=\"212.0\" y=\"222.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fora do período</text><path d=\"M362.0 155.0 L362.0 193.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-es-ah-amber)\"></path><rect x=\"296.0\" y=\"194.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"362.0\" y=\"209.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivo de rejeitos</text><text x=\"362.0\" y=\"222.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">linha + motivo</text><path d=\"M512.0 155.0 L512.0 193.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-es-ah-amber)\"></path><rect x=\"446.0\" y=\"194.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"512.0\" y=\"209.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivo de rejeitos</text><text x=\"512.0\" y=\"222.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">linha + motivo</text><path d=\"M362.0 238.0 L362.0 270.0 L420.0 270.0 L420.0 280.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-es-ah-amber)\"></path><path d=\"M512.0 238.0 L512.0 270.0 L454.0 270.0 L454.0 280.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-es-ah-amber)\"></path><rect x=\"312.0\" y=\"282.0\" width=\"250.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"437.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">donos: financeiro, Sebastião, Cláudia</text><path d=\"M312.0 300.0 L70.0 300.0 L70.0 157.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l14-pipeline-es-ah-paper-dim)\"></path><text x=\"186.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fatos errados corrigidos na origem</text></svg>", "caption": "O pipeline e para onde vão os rejeitos. Uma linha rejeitada é trabalho para quem é dono da regra que ela quebrou, e um fato errado é corrigido no Coleta, então cada execução seguinte parte de dados mais limpos.", "same": ["Coleta"]}
```

**Um arquivo de rejeitos é uma fila de trabalho, não um log.** Cada linha rejeitada leva o motivo e
vai para a pessoa dona da regra que ela quebrou: um CPF inválido para o financeiro, uma grafia
desconhecida para Sebastião, um resultado de laboratório na unidade errada para Cláudia. Uma linha
rejeitada sem dono continua rejeitada, e uma fazenda sem cadastro no novo sistema é uma fazenda que
não recebe.

## Quem assina

**Os dados pertencem ao negócio, não ao time de migração.** O time consegue escrever uma regra; só o
dono consegue dizer que é a regra certa. Na Serra Alta a especificação tem três assinaturas. Cláudia
assina tudo o que é de qualidade, porque os resultados de laboratório decidem quanto uma fazenda
recebe pelo leite. O financeiro assina os documentos, o vínculo com o fornecedor e tudo o que termina
num pagamento. Sebastião assina o que cada campo do Coleta significa, porque é a única pessoa que
sabe.

Uma assinatura vale para uma versão da especificação, e cada ensaio roda uma versão com nome. Quando
um ensaio mostra que uma regra estava errada, a regra muda no documento, o dono assina de novo e o
ensaio seguinte roda a versão nova. Esse ciclo é o assunto da próxima seção.
