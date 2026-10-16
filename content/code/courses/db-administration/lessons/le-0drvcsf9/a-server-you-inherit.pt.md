---
title: O primeiro dia com um servidor que você não montou
version: 1
---

A maioria dos administradores conhece a maioria dos seus servidores já rodando. Outra pessoa
instalou, outra pessoa configurou, e quem sabia o porquê muitas vezes já não está por perto. **O
primeiro dia é um inventário**, e a lista é a mesma seja qual for o motor: responda cada pergunta,
anote a resposta com a data, e só então mude alguma coisa.

| pergunta | por que importa | onde o curso responde |
|---|---|---|
| Qual versão, exatamente, e ela ainda tem suporte? | uma versão fora do fim de vida não recebe correções de segurança | a lição 3 lê a string de versão; a lição 20 trata de seguir adiante |
| Onde estão os arquivos de dados, a configuração e o log? | todo o resto parte daqui, e num servidor de pacote são três lugares diferentes | lições 4 e 5 |
| Quais ajustes diferem do padrão, e alguém sabe por quê? | um ajuste que ninguém explica é uma correção que ninguém anotou ou um erro que ninguém viu | lições 5, 6 e 23 |
| Quem pode conectar, de onde, e como quem? | o furo mais comum é uma conta com mais direitos que o seu trabalho, e uma senha que todo mundo sabe | lições 5, 11, 12 e 13 |
| Qual o tamanho, a que velocidade cresce, e quanto espaço sobra? | a data em que o disco enche é um fato que dá para calcular hoje | lições 4 e 9 |
| A manutenção está dando conta? | uma tabela contra a qual o autovacuum perde há meses é uma indisponibilidade lenta | lições 14 a 17 |
| O que o log diz? | um servidor costuma reclamar por semanas antes de falhar | lição 19 |
| Quando o último backup foi restaurado, e quanto tempo levou? | a única pergunta de backup com resposta útil | lições 1 e 7 de `db-reliability` |

Nenhuma delas exige mudar o servidor, e é de propósito. **No primeiro dia nada é consertado**, por
mais errado que pareça, porque um ajuste que parece errado pode estar segurando algo que você ainda
não achou. O inventário vem primeiro; a lista do que mudar sai do inventário, em ordem de risco.

## Anotando

As respostas vão para um lugar onde a próxima pessoa vai achá-las: uma página na documentação da
equipe, um arquivo num repositório, um ticket. Um inventário útil tem data, diz como cada resposta
foi obtida (o comando, não só o resultado), e diz o que ainda não se sabe. Essa última parte é a que
mais importa. "Nenhuma restauração de backup registrada" é uma constatação; deixar a linha de fora
deixa o próximo leitor supor que alguém verificou.

A lição 24 trata do outro documento que um administrador mantém — o runbook —, e o inventário é onde
ele começa: não dá para anotar como recuperar um servidor cujo formato você nunca anotou.
