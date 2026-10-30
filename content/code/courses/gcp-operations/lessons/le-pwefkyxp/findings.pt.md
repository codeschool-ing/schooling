---
title: O que é um achado, e de onde os achados vêm
version: 1
---

**O Security Command Center junta achados sobre os recursos de uma organização numa lista só: um achado é um
problema, num recurso, de uma fonte, com uma severidade e um estado.** É o lugar onde a varredura de
vulnerabilidades da lição 2, um bucket mal configurado e uma mudança suspeita de permissões terminam lado a lado,
para que alguém decida o que fazer primeiro. **Nada nesta lição chega ao Security Command Center**, que não tem
emulador e funciona no nível de uma organização. Ela é ensinada pela documentação do Google; a prática é a triagem,
sobre uma lista de achados que o curso escreve, na próxima seção.

## De onde vêm os achados

| fonte | o que acha | classe de achado |
|---|---|---|
| Security Health Analytics | configurações erradas: um bucket público, um firewall aberto ao mundo, uma chave nunca girada | `MISCONFIGURATION` |
| varredura de vulnerabilidades | vulnerabilidades conhecidas em imagens e nos pacotes de máquinas (a varredura da lição 2, entre outras) | `VULNERABILITY` |
| Event Threat Detection | atividade suspeita lida dos logs: uma concessão de permissão incomum, acesso de um endereço malicioso conhecido | `THREAT` |
| Container Threat Detection | comportamento suspeito dentro de contêineres do GKE em execução | `THREAT` |

O primeiro tipo é sobre o que está configurado, o segundo sobre o que está instalado, o terceiro e o quarto sobre o
que está acontecendo. Uma configuração errada é uma porta deixada aberta; um achado de ameaça diz que alguém pode ter
passado por uma.

## Os campos que importam para a triagem

- **`severity`**: `CRITICAL`, `HIGH`, `MEDIUM` ou `LOW`, definida pela fonte a partir de quão explorável e danoso o
  problema é em geral. Ela não sabe se o recurso importa para você.
- **`state`**: `ACTIVE` enquanto o problema está lá, `INACTIVE` quando a fonte o vê corrigido. Um achado de
  configuração fica inativo sozinho quando a configuração é corrigida; ninguém o fecha à mão.
- **`mute`**: `MUTED` esconde um achado das visões padrão sem corrigir nada. Silenciar é para um achado que alguém
  julgou aceitável (uma sandbox que ninguém usa para nada real), e **uma regra de silenciamento é uma decisão que
  precisa ser escrita com o motivo**, porque esconde todo achado futuro que casar com ela.
- **`resourceName`**: o nome completo daquilo de que o achado trata, que é como um achado se liga a um dono (os
  rótulos da lição 23 respondem "de quem é isto?").

## Níveis

O Security Command Center tem um nível **Standard**, sem cobrança, com uma parte das verificações do Security Health
Analytics, e níveis **Premium** e **Enterprise** que acrescentam o resto dos detectores, a detecção de ameaças, a
simulação de caminhos de ataque e relatórios de conformidade. A página de preços do Google, lida em 30 de outubro de
2026, diz que só os níveis Premium e Enterprise são cobrados, por assinatura ou por uso; os números dependem do gasto
total da organização no Google Cloud e não são citados aqui.
