---
title: Categorias e resultados
version: 1
---

Abaixo das seis funções, o CSF divide o terreno mais duas vezes. Na versão 2.0 são **22 categorias** e
**106 subcategorias**, e cada uma é escrita como um **resultado**: um estado de coisas a alcançar, e não
uma instrução sobre como alcançá-lo.

Alguns exemplos, com os identificadores:

| identificador | categoria | um resultado que ela contém, em resumo |
|---|---|---|
| **GV.RM** | estratégia de gestão de riscos | o apetite e a tolerância a risco são definidos e comunicados |
| **ID.AM** | gestão de ativos | inventários de hardware, software, serviços e dados são mantidos |
| **PR.AA** | gestão de identidade, autenticação e controle de acesso | o acesso é limitado a usuários autorizados, com menor privilégio |
| **PR.DS** | segurança de dados | backups são criados, protegidos, mantidos e testados |
| **DE.CM** | monitoramento contínuo | redes, usuários e sistemas são monitorados para achar eventos adversos |
| **RS.MA** | gestão de incidentes | incidentes são triados, priorizados e escalados |
| **RC.RP** | execução do plano de recuperação | a restauração é feita para garantir a disponibilidade operacional |

O identificador é montado com as duas letras da função e as da categoria: `PR.AA` é Proteger, gestão de
identidade e controle de acesso. As subcategorias acrescentam um número, como `PR.DS-11` para o resultado
de backup da tabela.

### Resultados, não instruções

A diferença importa. "Backups são criados, protegidos, mantidos e testados" não diz noturno, não diz qual
ferramenta, não diz 3-2-1. A aula 12 é um jeito de cumprir isso; um serviço de nuvem com snapshots
imutáveis é outro. É por isso que o CSF serve igualmente a uma loja de nove pessoas e a um banco: cada um
decide **como**, e o framework só nomeia **o quê**.

Para o como, o CSF aponta para outros lugares. O NIST publica **referências informativas** que mapeiam
cada subcategoria para controles específicos de outros documentos, incluindo o Anexo A da ISO 27001, os
CIS Controls (aula 16) e o catálogo de controles do próprio NIST, o SP 800-53. E o CSF 2.0 acrescenta
**exemplos de implementação**: ilustrações curtas e concretas de como cumprir cada resultado poderia ser.

### Usando as categorias

As categorias transformam as seis funções em algo contra o que a organização consegue se avaliar. Para
cada subcategoria: cumprimos esse resultado totalmente, em parte ou de jeito nenhum? As respostas,
escritas, são a matéria-prima dos perfis da próxima seção. Também são um lugar natural para pendurar
evidência no sentido da aula 13: ao lado de `PR.DS-11`, o registro dos testes de restauração.
