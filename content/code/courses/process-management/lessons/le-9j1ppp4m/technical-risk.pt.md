---
title: Risco técnico e o arquiteto
version: 1
---

A maior parte desta aula vale para qualquer projeto. Os riscos que um arquiteto está mais bem posicionado para encontrar e reduzir são técnicos, e merecem tratamento próprio, porque se comportam de forma diferente dos riscos de prazo: costumam ser **binários** — o projeto funciona ou não — e são descobertos tarde, a menos que alguém vá procurá-los.

## Arquitetura guiada por risco

*Just Enough Software Architecture*, de George Fairbanks (2010), propõe uma regra simples para quanto esforço de projeto um sistema merece: **faça tanta arquitetura quanto os riscos pedirem, e não mais**. Uma ferramenta interna pequena com tecnologia conhecida precisa de pouca; um sistema de pagamento lidando com dinheiro alheio em trinta clínicas precisa de muita. A quantidade é definida nomeando os riscos — *a agenda de consultas pode não aguentar duas recepcionistas marcando o mesmo horário ao mesmo tempo* — e escolhendo trabalho de projeto que reduza cada um.

Essa regra amarra ideias de aulas anteriores. A espiral de Boehm na aula 1 ordenava o trabalho por risco. A elaboração do RUP na aula 7 provava as decisões mais arriscadas em código rodando antes da construção. O spike do XP na aula 4 comprava conhecimento com uma investigação curta e de tempo limitado. As três são respostas a risco: **mitigação aprendendo cedo**.

## Tipos de risco técnico que vale nomear

- **Novidade**: uma tecnologia, um framework ou um serviço de nuvem que o time nunca usou em produção.
- **Integração**: um sistema fora do controle do time — um provedor de pagamento, um serviço de governo, um banco legado — cujo comportamento só está documentado em parte.
- **Atributos de qualidade perto do limite**: um tempo de resposta, uma meta de disponibilidade ou um volume de dados perto do que o projeto consegue entregar.
- **Irreversibilidade**: decisões caras de mudar depois, que a aula 2 listou — o armazenamento de dados, as fronteiras entre serviços, a identidade.
- **Conhecimento concentrado**: uma parte do sistema que uma só pessoa entende, que é como o risco B foi parar no registro do time Agenda.

## Reduzindo-os

As respostas habituais são baratas perto dos riscos:

- **Um spike ou um protótipo** responde a uma pergunta sobre novidade ou integração em dias.
- **Um esqueleto andante** — a versão de ponta a ponta mais fina do sistema, implantada — prova que as partes se conectam, do jeito que a elaboração do RUP fazia.
- **Um teste de carga contra um cenário realista** transforma um risco de atributo de qualidade numa medição.
- **Uma revisão de arquitetura**, como o ATAM do SEI, torna explícitos os trade-offs e os pontos de sensibilidade de um projeto, com as partes interessadas presentes.
- **Par e documentação** reduzem o conhecimento concentrado.

## Traduzindo para o registro

Riscos técnicos vão para o mesmo registro que os outros, escritos de modo que um patrocinador sem formação técnica consiga pesá-los: causa, evento e efeito em termos de tempo, dinheiro ou serviço. "O ORM pode gerar consultas N+1" não quer dizer nada para um patrocinador; "a tela de agendamento pode levar mais de dois segundos com a carga de segunda de manhã, violando o nível de serviço, a menos que gastemos dois dias num teste de carga e numa correção na Sprint 1" é uma decisão que alguém consegue tomar. O curso `architect-communication` dedica a essa tradução uma aula própria, a quarta dele.
