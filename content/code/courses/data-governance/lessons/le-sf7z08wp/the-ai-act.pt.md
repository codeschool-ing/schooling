---
title: O AI Act europeu em uma página
version: 1
---

O **Regulamento da Inteligência Artificial** — o AI Act —, Regulamento (UE) 2024/1689, entrou em vigor
em **1º de agosto de 2024**. Não é uma lei de proteção de dados: o GDPR continua valendo para
qualquer dado pessoal que um sistema de IA toque. É uma **lei de segurança de produto para sistemas
de IA**, que os separa pelo risco do uso que se faz deles e põe obrigações em quem os constrói e em
quem os usa.

## Com quem ele está falando

- o **fornecedor** (*provider*) desenvolve um sistema de IA, ou o manda desenvolver, e o coloca no
  mercado ou em serviço com o próprio nome;
- o **responsável pela implantação** (*deployer*) usa um sistema de IA sob sua autoridade numa
  atividade profissional.

A Ipê é **fornecedora** dos modelos que ela mesma constrói e **responsável pela implantação** dos que
compra. O AI Act alcança fornecedores e responsáveis estabelecidos na União, e os de fora dela
**quando o resultado do sistema é usado na União** (art. 2º). É assim que a empresa de Lisboa o traz
para dentro: um sistema usado lá, ou cujo resultado é usado lá, está sob o AI Act, seja quem for que o
escreveu.

## Quatro níveis de risco

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l8-ai-tiers\" aria-label=\"Os quatro níveis de risco do AI Act europeu, de cima para baixo: práticas proibidas, sistemas de alto risco, sistemas com obrigações de transparência, e risco mínimo. Cada sistema da Ipê fica num nível: a triagem de currículos é de alto risco, o chatbot de suporte tem obrigações de transparência, e o score de fraude e o recomendador são de risco mínimo.\"><rect x=\"80.0\" y=\"20.0\" width=\"320.0\" height=\"45.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">proibido</text><text x=\"240.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">art. 5 · não pode ser usado</text><text x=\"600.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada na Ipê</text><rect x=\"62.0\" y=\"75.0\" width=\"356.0\" height=\"45.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">alto risco</text><text x=\"240.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Anexo III · a maior parte da lei</text><path d=\"M420.0 97.0 L500.0 97.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"500.0\" y=\"81.0\" width=\"200.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cv-screen</text><rect x=\"44.0\" y=\"130.0\" width=\"392.0\" height=\"45.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">transparência</text><text x=\"240.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">art. 50 · dizer que é uma IA</text><path d=\"M438.0 152.0 L500.0 152.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"500.0\" y=\"136.0\" width=\"200.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">support-bot</text><rect x=\"26.0\" y=\"185.0\" width=\"428.0\" height=\"45.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">mínimo</text><text x=\"240.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem deveres específicos</text><path d=\"M456.0 207.0 L500.0 207.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"500.0\" y=\"191.0\" width=\"200.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fraud-score · recommender</text></svg>", "caption": "A classe decorre do uso do sistema, e não de como ele é construído."}
```

- **Práticas proibidas** (art. 5º): manipulação que explora vulnerabilidades, pontuação social,
  previsão de crimes só a partir de perfilamento, raspagem não direcionada de rostos para montar
  bases de reconhecimento, reconhecimento de emoções no trabalho e na educação, categorização
  biométrica que infere traços sensíveis, e identificação biométrica remota em tempo real em espaços
  públicos para fins de polícia, com exceções estreitas.
- **Sistemas de alto risco** (art. 6º): componentes de segurança de produtos já regulados (Anexo I),
  e os usos listados no **Anexo III** — biometria, infraestrutura crítica, educação, **emprego**,
  acesso a serviços essenciais incluindo **score de crédito**, polícia, migração, justiça e eleições.
  Esses carregam a maior parte da lei: gestão de risco, governança de dados, documentação técnica,
  registro de eventos, transparência para quem implanta, supervisão humana, exatidão e robustez,
  registro numa base pública.
- **Obrigações de transparência** (art. 50): as pessoas devem ser informadas de que estão interagindo
  com um sistema de IA; áudio, imagem, vídeo e texto sintéticos devem ser marcados como tais de forma
  legível por máquina; deep fakes devem ser revelados.
- **Risco mínimo**: todo o resto, que a lei deixa em paz, fora o letramento em IA.

Os modelos de propósito geral — os grandes modelos de linguagem sobre os quais os outros são
construídos — têm capítulo próprio (Capítulo V), com obrigações para os seus fornecedores que valem
desde 2 de agosto de 2025.

## O artigo de governança de dados

Para um time de dados, o **artigo 10** é onde o AI Act encontra este curso. Os dados de treino,
validação e teste de um sistema de alto risco devem estar sujeitos a práticas de governança de
dados. O artigo lista o que elas cobrem: as escolhas de projeto, o processo de coleta e a **origem**
dos dados, a finalidade para a qual o dado pessoal foi coletado originalmente, a preparação
(rotulagem, limpeza, enriquecimento), as premissas, uma avaliação de se os dados são **suficientes e
representativos**, um exame de **possíveis vieses**, e as lacunas encontradas. Essa lista é a aula 6
e a aula 9 escritas como obrigação legal, para um tipo de sistema.

## Multas

Até **35 milhões de euros ou 7%** do faturamento anual mundial para uma prática proibida; até **15
milhões ou 3%** para a maioria das outras obrigações; até **7,5 milhões ou 1%** por fornecer
informação errada às autoridades (art. 99). Para pequenas e médias empresas, o menor dos dois.
