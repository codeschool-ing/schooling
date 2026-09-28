---
title: Dois motores, uma linguagem
version: 1
---

O **Snort** foi escrito em 1998 e definiu como a detecção de intrusão em rede é feita de forma aberta:
uma linguagem de regras que descreve um pacote ou uma conversa, e um motor que confronta cada regra com o
tráfego. O **Suricata** chegou em 2010 e, de propósito, lia as mesmas regras. Essa linguagem comum é a
coisa mais útil a saber sobre qualquer um dos dois, porque é nas regras que está o trabalho, e uma regra
escrita para um é, na maior parte das vezes, uma regra para o outro.

| | Snort 2 | Snort 3 | Suricata |
|---|---|---|---|
| linguagem de regras | a original | a original, com pequenas mudanças | a original, mais palavras-chave próprias |
| processamento | uma thread por processo | multithread | multithread |
| configuração | `snort.conf` | Lua | YAML |
| saída mais usada | arquivos unified2, linhas de alerta | JSON e linhas de alerta | `eve.json`, um objeto JSON por evento |
| também registra | alertas | alertas, e dados de aplicação com complementos | alertas, fluxos, e HTTP, DNS, TLS e mais, por padrão |

**A última linha é a diferença prática** para quem defende e tem um motor para escolher. O Suricata grava
um registro de cada pedido HTTP, consulta DNS e handshake TLS que vê, tenha uma regra casado ou não, que a
aula 2 usou para nomear protocolos e que esta aula usa para achar algo para o qual nenhuma regra foi
escrita.

Este curso roda o Suricata, na versão que o Ubuntu 24.04 empacota. O Snort não está instalado no
laboratório e nenhum comando desta aula rodou nele; onde a sintaxe do Snort difere, o texto diz.

As regras em si vêm de dois lugares. **Conjuntos de regras publicados**, dos quais o gratuito Emerging
Threats Open é o mais conhecido, reúnem dezenas de milhares de assinaturas para malware, exploits e
violações de política conhecidos, mantidas por pessoas cujo trabalho é esse e atualizadas diariamente.
**Regras locais** descrevem o que só esta rede sabe: quais caminhos são privados, quais protocolos não
têm nada que fazer em qual segmento, qual login é sensível. Toda implantação precisa das duas, e esta
aula trata de escrever o segundo tipo.
