---
title: Protegendo o BGP: filtros, assinaturas e vigilância
version: 1
---

**O BGP acredita no que lhe dizem.** Nada no protocolo em si verifica se o AS que anuncia um prefixo tem
algum direito a ele. Um erro, ou um anúncio falso e deliberado do bloco de outro, viaja até onde os vizinhos
não o filtram, e o casamento pelo prefixo mais longo da aula 14 faz um anúncio falso mais específico vencer
o verdadeiro onde quer que seja aceito. As defesas são camadas, cada uma acrescentada pelas redes que se
importam, e esta seção as descreve como um operador de rede as aplica e verifica. **Nada disto foi executado
no laboratório**: não há validador nele, e endereços de documentação não têm registros reais contra os
quais validar.

## Filtros construídos a partir de registros

O filtro do lado do provedor, da seção anterior, tem de vir de algum lugar. Na prática ele é construído a
partir de **Internet Routing Registries** (IRR), bancos de dados onde as redes publicam *route objects*
dizendo que AS origina que prefixo. Um provedor gera os filtros dos clientes a partir desses objetos, então
um cliente que anuncia algo que nunca registrou é recusado no primeiro salto. A fraqueza é que um registro
vale o que vale quem o escreveu, e registros antigos raramente são limpos.

## RPKI e validação de origem de rota

O **RPKI** (*Resource Public Key Infrastructure*) amarra blocos de endereços a certificados criptográficos
emitidos pela mesma cadeia que distribui os endereços: do registro regional até o titular. O titular
assina uma **ROA** (*Route Origin Authorisation*): *o AS 64500 pode originar 203.0.113.0/24, até um tamanho
máximo de /24*. Um software chamado validador coleta e confere cada ROA, e os roteadores o consultam sobre
cada rota que recebem. Isso é a **validação de origem de rota** (*route origin validation*), e ela dá a cada
rota um de três estados:

| estado | significado |
|---|---|
| **válida** (*valid*) | uma ROA cobre o prefixo, o AS de origem bate, e o tamanho está dentro do máximo |
| **inválida** (*invalid*) | uma ROA cobre o prefixo, mas o AS de origem ou o tamanho não batem |
| **não encontrada** (*not found*) | nenhuma ROA cobre o prefixo |

A política que a maioria das redes que validam aplica é simples: **descartar as inválidas, aceitar o
resto**. Todo `show ip bgp` desta aula imprimiu `RPKI validation codes: V valid, I invalid, N Not found` na
legenda e nenhum código ao lado de nenhuma rota, porque o FRR conhece os estados e este laboratório não lhe
dá validador para consultar.

Dois limites valem saber. A validação de origem confere só o **último AS do caminho**, então um anúncio que
falsifica a origem certa passa por ela; o trabalho para validar o resto do caminho continua. E uma ROA com
tamanho máximo maior que o que o titular de fato anuncia deixa espaço para um mais específico de aparência
válida, então **o tamanho máximo de uma ROA deve bater com o que é de fato anunciado**.

## Protegendo a sessão e vigiando o resultado

- **A própria sessão** se protege com autenticação TCP entre os dois roteadores, e com uma verificação de
  TTL que recusa pacotes BGP que não vieram de um vizinho diretamente conectado.
- **`maximum-prefix`**, como na seção anterior, limita o estrago de um vizinho que de repente manda muito
  mais que o normal.
- **Vigilância de fora**: coletores de rotas públicos e *looking glasses* mostram como outras redes veem
  seus prefixos, e serviços de alerta avisam quando seu bloco aparece com uma origem que não é a sua. Uma
  rede que nunca olha de fora fica sabendo de um problema pelos clientes.

O **MANRS** (*Mutually Agreed Norms for Routing Security*) reúne isso numa lista curta com que as redes se
comprometem: filtrar o que anunciam e aceitam, impedir endereços de origem falsificados, manter os contatos
em dia para que outros as encontrem durante um incidente, e publicar suas intenções de roteamento num IRR e
no RPKI para que outros possam filtrá-las. Para a empresa deste laboratório, isso quer dizer três
verificações: uma ROA para 203.0.113.0/24 com origem 64500 e tamanho máximo /24, um filtro de saída como o
`TO-PROVIDER`, e provedores que filtram o que aceitam dela.
