---
title: Artifactory e Nexus
version: 1
---

**Um registry OCI guarda artefatos OCI. Uma empresa guarda mais do que isso**: jars do Maven, pacotes
npm e PyPI, módulos Go, pacotes Debian, charts do Helm, tarballs simples. Um **gerenciador de
repositórios** é um servidor que fala todos esses formatos, e os dois que a maioria das empresas roda
são o JFrog Artifactory e o Sonatype Nexus Repository. Os dois têm uma edição gratuita e uma paga.

Eles organizam os repositórios do mesmo jeito, com palavras diferentes:

| o que faz | o Nexus chama de | o Artifactory chama de |
|---|---|---|
| guarda o que os seus builds publicam | hosted | local |
| busca de uma fonte pública no primeiro uso, e depois serve a cópia dele | proxy | remote |
| um endereço na frente de vários dos anteriores | group | virtual |

**O proxy é a parte que muda como uma empresa trabalha.** Todo build busca o `busybox`, o `requests` ou
o `lodash` pelo servidor da própria empresa, que guarda uma cópia. Os builds deixam de depender dos
limites do Docker Hub ou de um registry público estar no ar; um pacote que some na origem, ou é trocado
por uma versão maliciosa, não some nem muda dentro da empresa; e há um lugar para ver todo artefato de
terceiros que a empresa usa. A máquina de gravação deste curso é uma instância pequena da mesma ideia:
o cluster dela baixa tudo por um registry que guarda cópias.

**O group é o que torna isso prático.** Quem desenvolve e os builds apontam para um endereço, digamos
`https://repo.example.com/npm/`, e o group responde a partir do repositório hosted para os pacotes da
própria empresa e do proxy para os dos outros.

Em volta disso, os dois acrescentam o que uma organização precisa e um registry simples não tem:
usuários e permissões por repositório, **políticas de escrita única** que recusam sobrescrever uma
versão publicada, regras de retenção, e um log de auditoria de quem publicou o quê. O Nexus chama a
política de escrita única de *deployment policy: disable redeploy*; o Artifactory a chama de
*immutable*, ou simplesmente recusa sobrescrever releases por padrão.

## Por que este curso não roda um

Os dois rodam como container, e o Nexus foi experimentado na máquina de gravação: ele precisa de cerca
de 2 GiB de memória e de um minuto para subir, e a edição gratuita pede a quem instala que aceite a
licença dela pela API antes de guardar qualquer coisa. **Essa aceitação é sua para dar, não de um
curso**, então a parte prática desta aula fica no registry OCI, que é tudo o que um arranjo GitOps
precisa de um gerenciador de repositórios: um lugar onde imagens e charts são publicados uma vez e
baixados pelo digest. Se a sua empresa roda Artifactory ou Nexus, o endereço do registry nos seus
manifestos é o deles, e todo o resto desta aula é igual.
