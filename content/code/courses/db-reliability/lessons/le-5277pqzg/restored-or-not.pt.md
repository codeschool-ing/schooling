---
title: Um backup é só uma afirmação até ser restaurado
version: 1
---

Pergunte a uma equipe se o banco dela tem backup e a resposta é quase sempre sim. Pergunte em que
esse sim se apoia e a resposta é uma rotina: algo roda toda noite e relata sucesso. **Isso é uma
afirmação sobre a rotina, não sobre os dados.** Diz que um programa começou, fez alguma coisa e
terminou sem reclamar. Se os bytes que ele deixou para trás podem voltar a ser um banco funcionando
é outra pergunta, e o único jeito de respondê-la é fazendo.

## A corrente, e onde ela se rompe

Entre as linhas de um banco em produção e essas mesmas linhas rodando de novo depois de um desastre
existe uma corrente, e cada elo pode falhar sem avisar:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma corrente de seis caixas: o banco em produção, a rotina de backup, a cópia, onde ela fica, a restauração e a verificação. Embaixo de cada uma das cinco primeiras, uma falha que deixa a rotina relatando sucesso. Um colchete sobre as duas primeiras diz o que uma rotina verde prova; um colchete sobre as seis diz o que uma restauração prova.\"><defs><marker id=\"l1c-wi\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"12\" y=\"86\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"64\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o banco em produção</text><path d=\"M116 108 L128 108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1c-wi)\"></path><text x=\"64\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">copia o banco</text><text x=\"64\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">errado</text><rect x=\"130\" y=\"86\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"182\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a rotina de backup</text><path d=\"M234 108 L246 108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1c-wi)\"></path><text x=\"182\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">um pipe esconde</text><text x=\"182\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o erro</text><rect x=\"248\" y=\"86\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"300\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a cópia</text><path d=\"M352 108 L364 108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1c-wi)\"></path><text x=\"300\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">papéis e chaves</text><text x=\"300\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ficam de fora</text><rect x=\"366\" y=\"86\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"418\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">onde ela fica</text><path d=\"M470 108 L482 108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1c-wi)\"></path><text x=\"418\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">mesmo disco, mesma</text><text x=\"418\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">credencial</text><rect x=\"484\" y=\"86\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"536\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a restauração</text><path d=\"M588 108 L600 108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1c-wi)\"></path><text x=\"536\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">leva dois dias</text><text x=\"536\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">quando o prazo</text><text x=\"536\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">era de duas horas</text><rect x=\"602\" y=\"86\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"654\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a verificação</text><text x=\"654\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o único elo que</text><text x=\"654\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">testa os outros</text><path d=\"M12 70 L12 62 L234 62 L234 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"123\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que uma rotina verde prova</text><path d=\"M12 206 L12 214 L706 214 L706 206\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"359\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o que uma restauração prova</text></svg>", "caption": "A corrente que vai das linhas em produção a linhas que respondem de novo. Uma rotina que termina sem erro diz algo sobre os dois primeiros elos; só uma restauração verificada diz algo sobre os seis."}
```

Cada elo tem uma falha que deixa a rotina verde:

- **A cópia guarda a coisa errada.** A rotina faz dump de um banco que a aplicação deixou de
  usar no ano passado, ou de um schema em cada três, ou gera um arquivo de vinte bytes porque o programa que
  recebia o pipe deu certo e o que importava não. Uma seção mais adiante nesta lição faz exatamente isso, de
  propósito.
- **A cópia está certa e incompleta.** Um dump lógico de um banco deixa de fora os papéis donos das
  tabelas e as senhas com que eles se conectam. A lição 2 restaura um dump assim num servidor limpo
  e vê a restauração falhar nisso.
- **A cópia não pode ser lida de volta.** Foi criptografada com uma chave que ninguém guardou, ou
  comprimida por uma ferramenta que a máquina da restauração não tem, ou gravada por uma versão que
  as ferramentas de restauração recusam.
- **A cópia sumiu.** Ficava no mesmo disco, na mesma conta ou com as mesmas credenciais da coisa que
  protegia, e foi junto com ela. As lições 9 e 10 tratam de onde uma cópia mora e de quem pode
  apagá-la.
- **A cópia volta devagar demais para servir.** Dois dias para restaurar um banco que o negócio
  precisa de volta em duas horas é um backup que funciona e uma recuperação que falhou. A lição 8
  transforma isso num número com que alguém concorda antes do incidente.

Nenhuma dessas aparece no código de saída de uma rotina, e todas aparecem numa restauração.

## Já aconteceu com gente que sabia de tudo isso

Em 31 de janeiro de 2017 um engenheiro do GitLab, trabalhando até tarde num problema de replicação,
apagou o diretório de dados do servidor de banco de produção em vez do da réplica. A empresa
publicou o incidente inteiro enquanto ele acontecia. Dos cinco mecanismos que ela tinha para
recuperar os dados, **nenhum funcionou como deveria**: o `pg_dump` noturno vinha falhando em
silêncio porque sua versão não batia com a do servidor, e os e-mails que relatavam a falha estavam
sendo rejeitados; outras cópias nunca tinham sido configuradas para aquele servidor. O que salvou a
empresa foi um snapshot tirado à mão umas seis horas antes, por um motivo sem relação, e essas seis
horas de dados se perderam.

Ninguém ali era descuidado com backup no sentido de não ter nenhum. Eram cinco. O que faltava era
**uma restauração que alguém tivesse rodado recentemente e visto dar certo**, e é a única coisa que
teria encontrado cada uma daquelas falhas antes da noite em que elas importaram.

## O que este curso faz a respeito

O curso é montado nessa ordem. As lições 2 a 5 fazem cópias, lógicas e físicas, e o arquivamento
contínuo que deixa a cópia atualizada até os últimos segundos. As lições 6 e 7 restauram essas
cópias, para um ponto no tempo e depois como um ensaio com cronômetro. As lições 8 a 10 decidem
quanta perda e quanto tempo fora do ar são aceitáveis, e onde as cópias precisam morar para
sobreviver às pessoas e aos programas que poderiam querer que elas sumissem.

As lições 11 a 21 são a outra metade: um segundo servidor que já está restaurado, mantido em dia
pela replicação, e o mecanismo que decide quando ele assume. As lições 22 a 24 são o que acontece no
dia, ensaiado antes e escrito para não depender de quem está acordado.

O tempo todo, **você quebra coisas de propósito**, porque o curso é sobre o que acontece quando um
banco morre, e o jeito de aprender isso é matar um que é seu. A próxima seção monta a máquina em
que você vai fazer isso.
