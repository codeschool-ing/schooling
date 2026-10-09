---
title: Quatro tipos, por quem os lê
version: 1
---

Uma crença comum é que inteligência de ameaças é uma lista de endereços maliciosos. Isso é um dos quatro
tipos dela, e o menos durável. **Inteligência de ameaças é conhecimento sobre ameaças, organizado para que
alguém tome uma decisão com ele**, e os quatro tipos diferem em quem toma a decisão:

| tipo | o que diz | quem lê | quanto tempo continua verdade |
|---|---|---|---|
| **estratégica** | quais ameaças importam para um setor e por quê: ransomware contra escritórios de contabilidade cresceu no ano passado | a diretoria, o gestor de segurança | anos |
| **operacional** | uma campanha específica: quem, contra quem, quando, com que objetivo | o líder do SOC, quem responde a incidentes | semanas a meses |
| **tática** | como o adversário trabalha: as técnicas dele, num vocabulário comum (aula 9) | analistas, quem escreve regras | meses a anos |
| **técnica** | os próprios indicadores: endereços, domínios, hashes de arquivo | o SIEM, o firewall | horas a semanas |

A linha de baixo é a que as máquinas consomem e a que envelhece mais depressa: um endereço usado para
adivinhar senhas nesta semana é a conexão de casa de alguém no mês que vem. As linhas de cima envelhecem
devagar e precisam de uma pessoa para aplicá-las. Um SOC que só consome a linha de baixo automatizou a parte
da inteligência que menos importa.

Inteligência também é algo que você **produz**. O incidente de quinta, descrito com endereços, horários e
técnicas, é inteligência operacional e técnica sobre um evento que ninguém mais viu por dentro.
