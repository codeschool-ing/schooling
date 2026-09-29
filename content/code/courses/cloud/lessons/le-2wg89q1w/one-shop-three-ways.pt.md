---
title: Uma loja, três jeitos, uma terça-feira
version: 1
---

Os modelos ficam mais fáceis de distinguir quando se vê o mesmo negócio funcionando em cada um. Pegue a
**Barro**, uma pequena loja virtual de cerâmica feita à mão: três pessoas, um catálogo de duzentas
peças, algumas dezenas de pedidos por dia. Ela poderia ser hospedada de três jeitos.

- Em IaaS, ela é uma máquina virtual rodando Ubuntu 24.04, com um servidor web, a aplicação Python da
  própria loja e um banco de dados PostgreSQL, tudo instalado por quem montou a máquina.
- Em PaaS, o mesmo código Python é enviado para uma plataforma, que o roda, e um banco PostgreSQL
  gerenciado fica ao lado.
- Em SaaS, não existe código. A Barro aluga um serviço de loja hospedada e o preenche com produtos, um
  tema, as configurações de pagamento e três contas de funcionário.

Para os clientes as três parecem iguais: uma página com vasos e um botão que leva o dinheiro deles. A
diferença só aparece quando alguma coisa precisa ser feita.

## Terça de manhã

Sai uma correção de segurança crítica para a biblioteca TLS que o sistema operacional traz, o código que
criptografa toda conexão HTTPS com a loja.

**Em IaaS, essa tarefa é da Barro, e só da Barro.** Ninguém do provedor vai entrar na máquina dela.
Alguém na Barro precisa saber que a correção existe e instalá-la: `sudo apt update` e `sudo apt upgrade`
no Ubuntu, não executados aqui, porque não existe máquina neste curso. Depois precisa reiniciar todo
programa que tinha a biblioteca antiga carregada, e conferir se a loja ainda responde. Se ninguém fizer isso, **nada
quebra**. A loja continua vendendo, as páginas continuam carregando, e toda conexão é criptografada por
uma biblioteca com uma falha publicada, pelo tempo que alguém levar para perceber. A primeira pessoa a
perceber pode não trabalhar na Barro.

**Em PaaS, a plataforma é dona do sistema operacional e das bibliotecas dele**, então aplicar a correção
é tarefa dela. Como ela chega à loja em funcionamento depende da plataforma: algumas aplicam por baixo
da aplicação que está rodando, outras incluem a biblioteca corrigida na imagem da aplicação na próxima
vez que a Barro publicar. Qual das duas a plataforma da Barro faz está escrito na documentação, e saber
disso antes da terça-feira é a parte da Barro. No segundo tipo, uma loja que ninguém mudou há um mês
está rodando a biblioteca do mês passado.

**Em SaaS, é invisível.** O provedor aplica os patches nos servidores dele, e a Barro pode ler sobre
isso numa página de status, ou nunca ficar sabendo.

## Terça à tarde

No mesmo dia sai uma correção para o framework web que o código Python da Barro importa. Esta fica na
fileira da aplicação, e o quadro muda. Em IaaS é tarefa da Barro. **Em PaaS continua sendo tarefa da
Barro**, porque a plataforma corrige o runtime e não os pacotes que o código lista: alguém atualiza a
versão, roda os testes e publica. Em SaaS não existe código da Barro, então é do provedor.

## Todos os outros dias

Mais duas tarefas completam o quadro, e são as que não se movem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Quatro tarefas que a loja tem numa terça-feira, e quem faz cada uma em IaaS, PaaS e SaaS. Uma correção de segurança do sistema operacional: em IaaS você atualiza, reinicia e confere; em PaaS a plataforma faz, em algumas só no seu próximo deploy; em SaaS o provedor faz. Uma correção de um pacote que o código da loja importa: você atualiza, testa e publica em IaaS e em PaaS; o provedor faz em SaaS. Uma pessoa da equipe sai: você remove o acesso dela nos três. Backups e uma cópia para levar embora: em IaaS você agenda e testa; em PaaS você liga e confere; em SaaS você exporta os pedidos. As tarefas suas estão destacadas.\"><defs><marker id=\"shop-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"269.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">IaaS</text><text x=\"449.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">PaaS</text><text x=\"629.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">SaaS</text><text x=\"20\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">correção de segurança</text><text x=\"20\" y=\"71.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">do sistema operacional</text><rect x=\"184\" y=\"40\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"194\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">você: atualiza, reinicia,</text><text x=\"194\" y=\"71.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confere se a loja responde</text><rect x=\"364\" y=\"40\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a plataforma; em algumas,</text><text x=\"374\" y=\"71.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no seu próximo deploy</text><rect x=\"544\" y=\"40\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"554\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o provedor</text><text x=\"20\" y=\"109.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">correção de um pacote</text><text x=\"20\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">que o código importa</text><rect x=\"184\" y=\"94\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"194\" y=\"109.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">você: atualiza, testa,</text><text x=\"194\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">publica</text><rect x=\"364\" y=\"94\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"109.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">você: atualiza, testa,</text><text x=\"374\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">publica</text><rect x=\"544\" y=\"94\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"554\" y=\"117.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o provedor</text><text x=\"20\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">uma pessoa da equipe</text><text x=\"20\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">sai</text><rect x=\"184\" y=\"148\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"194\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">você: remove as chaves</text><text x=\"194\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">e os logins dela</text><rect x=\"364\" y=\"148\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">você: remove os logins</text><text x=\"374\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">da plataforma e da loja</text><rect x=\"544\" y=\"148\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"554\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">você: remove o usuário</text><text x=\"554\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dela no painel da loja</text><text x=\"20\" y=\"217.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">backups, e uma cópia</text><text x=\"20\" y=\"233.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">para levar embora</text><rect x=\"184\" y=\"202\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"194\" y=\"217.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">você: agenda,</text><text x=\"194\" y=\"233.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">testa uma restauração</text><rect x=\"364\" y=\"202\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"217.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">você: liga,</text><text x=\"374\" y=\"233.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confere se rodam</text><rect x=\"544\" y=\"202\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"554\" y=\"217.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">você: exporta os</text><text x=\"554\" y=\"233.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedidos e os clientes</text></svg>", "caption": "A mesma loja na mesma terça-feira. A primeira tarefa atravessa a linha conforme o modelo muda; as duas últimas nunca. Uma loja em SaaS ainda tem uma pessoa da equipe cujo login alguém precisa remover.", "same": ["IaaS", "PaaS", "SaaS"]}
```

Quando uma das três pessoas sai, remover o acesso dela é tarefa da Barro em todo modelo: a chave SSH na
máquina, o login na plataforma, o usuário no painel da loja. E em todo modelo a Barro precisa de uma
cópia dos pedidos que possa levar embora. Em IaaS isso quer dizer agendar backups e testar uma
restauração; em PaaS, ligar os backups do banco gerenciado e conferir se eles rodam; em SaaS, saber onde
fica o botão de exportar e o que tem no arquivo que ele gera.

Leia as colunas de cima para baixo e a de SaaS tem menos tarefas marcadas como da Barro, que é o
argumento a favor dela. Leia as fileiras de lado a lado e as duas de baixo são da Barro em todo lugar,
que é o argumento contra acreditar que algum modelo deixa você sem nada para fazer.
