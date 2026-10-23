---
title: O que a plataforma pergunta
version: 1
---

Quando o boxoffice roda em outro lugar que não o seu terminal, outra coisa decide quando iniciá-lo, quando
mandar requisições para ele, quando reiniciá-lo e quando pará-lo: o Docker, o Kubernetes, uma plataforma de
nuvem, o systemd. Essa coisa não lê o log como você lê. **Ela faz perguntas ao processo, por HTTP, e age
conforme as respostas**, e as respostas precisam ser projetadas com o mesmo cuidado de qualquer outro
endpoint, porque uma resposta errada vira ação automática.

São duas perguntas, e confundi-las é o erro clássico:

| pergunta | a palavra da plataforma | o que um "não" a faz fazer | o que deve decidir a resposta |
|---|---|---|---|
| **Este processo funciona, afinal?** | liveness | matá-lo e iniciar outro | só o próprio processo: ele ainda consegue responder? |
| **Este processo deve receber requisições agora?** | readiness, a prontidão | parar de mandar tráfego a ele, e esperar | se o que ele precisa agora está lá: o banco, um cache aquecido, não estar desligando |

**Uma verificação de liveness que testa o banco é uma armadilha.** Quando o banco cai, todas as cópias do
boxoffice falham na liveness no mesmo instante, e a plataforma reinicia todas. Elas voltam, o banco continua
fora, e são reiniciadas de novo, num laço que soma carga a um sistema que já está em apuros e não conserta
nada: um boxoffice reiniciado não alcança um banco fora do ar melhor que o anterior. A liveness deve falhar
só pelo que um reinício cura, um deadlock ou um processo que parou de responder, e o teste honesto mais
barato disso é responder, simplesmente.

A prontidão é o lugar das dependências. Um processo cujo banco sumiu deve parar de receber requisições que
não consegue atender, para o balanceador mandá-las a uma cópia que consiga, ou a lugar nenhum; e deve voltar
a recebê-las sozinho quando o banco retornar. **A prontidão também é como um processo sai com elegância**: a
seção 06 faz o boxoffice dizer "não pronto" no instante em que começa a desligar.

Uma terceira verificação, a de startup, existe no Kubernetes para processos que levam minutos para subir,
para a liveness não os matar no meio disso. O boxoffice sobe em milissegundos e não precisa de uma.

## Uma porta só delas

Verificações de saúde e métricas são para a maquinaria em volta do serviço, não para os clientes dele. O
boxoffice as serve num terceiro listener, `-ops`, `localhost:9100` por padrão: mais uma linha na
configuração da aula 14. **Essa porta nunca é publicada na internet**: as métricas descrevem o interior do
serviço em detalhe, e a plataforma alcança a porta de dentro da rede.

A aula 13 deixou mais uma coisa a vigiar, e a seção 03 esbarra nela.
