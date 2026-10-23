---
title: O Dependabot, configurado no repositório
version: 1
---

**O Dependabot é o bot de dependências do GitHub, e toda a configuração dele é um arquivo no
repositório, `.github/dependabot.yml`.** Ele tem dois trabalhos fáceis de confundir. As *security
updates* abrem um pull request quando o banco de avisos do GitHub cita uma versão que o seu
repositório usa, e são ligadas nas configurações do repositório. As *version updates* abrem pull
requests para toda versão mais nova, numa agenda, e são elas que o arquivo configura. Esta seção é
ensinada a partir da documentação do GitHub: o Dependabot roda nos servidores do GitHub contra um
repositório do GitHub, e **não foi executado** para este curso. O que foi executado é a checagem por
que todo arquivo de workflow do linkbox já passa, porque a configuração de um programa que abre pull
requests em seu nome merece a mesma revisão que um workflow.

### O arquivo da documentação

O menor arquivo que a documentação mostra pede atualizações semanais das dependências Python, e mais
nada:

@@FENCE 1@@

Escreva-o em `.github/dependabot.yml` por um momento e entregue-o ao zizmor, o verificador que a
aula 16 pôs no pipeline:

@@FENCE 2@@

O zizmor lê um arquivo do Dependabot além dos workflows, e tem uma auditoria exatamente para esse
arquivo: **`dependabot-cooldown`**. Sem um bloco `cooldown`, o Dependabot propõe uma versão no
instante em que ela é publicada, e o achado diz que o padrão implícito fica abaixo de sete dias. O
status de saída não é 0, então no pipeline este arquivo quebraria o estágio `workflows`. O motivo da
auditoria é o assunto da aula 12: vários dos incidentes situados lá foram versões maliciosas por
horas ou dias antes de alguém perceber e removê-las, e um bot sem período de espera leva uma versão
dessas para um pull request em menos de uma hora.

### O arquivo que o linkbox mantém

Salve-o como `.github/dependabot.yml`:

@@FENCE 3@@

Cada bloco é um **ecossistema** num diretório. Três deles cobrem o que o linkbox fixa: os requisitos
Python, as duas imagens base que a aula 15 nomeou por digest no `Dockerfile` e as actions que a
aula 16 fixou por commit no workflow. A documentação diz que o Dependabot atualiza um pin por digest
para o novo digest e um pin por commit para o novo commit, mantendo o comentário de versão ao lado,
que é a forma que a aula 16 pediu.

O resto de cada bloco decide com que frequência uma pessoa é interrompida:

- `schedule` põe toda atualização de versão na segunda de manhã, então as propostas da semana chegam
  juntas e não uma por hora.
- `cooldown` espera catorze dias depois de uma versão antes de propô-la, e trinta para uma versão
  major nova, o tipo que tem licença para quebrar coisas. A documentação diz que a espera vale só
  para atualizações de versão: uma atualização de segurança é proposta assim que o aviso é conhecido,
  e é a troca certa, porque aí o risco está em esperar.
- `groups` põe toda atualização minor e patch das dependências Python num pull request só, e toda
  atualização de action em outro. Uma versão major continua ganhando um pull request próprio, já que
  é a que alguém precisa ler o changelog.
- `open-pull-requests-limit` impede o Dependabot de abrir um quarto pull request enquanto três ainda
  estão abertos. Propostas que não cabem esperam a semana seguinte.

O zizmor não tem achado agora:

@@FENCE 4@@

Faça o commit e o push, e o pipeline roda o zizmor sobre ele no servidor de CI do mesmo jeito:

@@FENCE 5@@

### Uma coisa que a documentação não resolve para o linkbox

O suporte a pip do Dependabot lê arquivos de requisitos, e a documentação lista entre eles os
compilados pelo `pip-compile`: nesse caso ele edita o arquivo `.in` e compila o lock de novo, com os
hashes. O lock do linkbox foi compilado pelo `uv pip compile`, que escreve um cabeçalho próprio. Se
o Dependabot recompila esse arquivo ou o edita como uma lista simples de pins é algo que este curso
**não conseguiu conferir**, porque conferir exige um repositório no GitHub. Antes de confiar nisso,
abra um pull request do Dependabot num repositório de teste e olhe o diff do `requirements.txt`: toda
versão que ele muda deve vir com hashes novos. A seção sobre a correção numa branch, nesta aula,
mostra o que o pipeline faz com uma mudança que move uma versão e mantém os hashes antigos.
