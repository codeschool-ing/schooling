---
title: Cinco perguntas que alguém precisa saber responder
version: 1
---

A imagem comum de um administrador de banco de dados é alguém que escreve SQL esperto. Isso é
trabalho de desenvolvedor, e um bom trabalho. **O administrador responde pelo servidor em que o SQL
roda**, e o trabalho é mais fácil de descrever como cinco perguntas sobre esse servidor que alguém
sempre precisa saber responder, a qualquer hora, com evidência.

**Ele está no ar?** Não "estava no ar quando olhei pela última vez", mas se os clientes conseguem
conectar agora, e se alguém saberia em minutos caso não conseguissem. Um servidor que ficou uma hora
fora do ar sem ninguém perceber tem dois problemas, e o segundo é pior.

**Os dados estão seguros?** Escritos no disco quando a aplicação foi avisada de que estavam,
legíveis depois de uma queda de energia, e não corrompidos por um ajuste que alguém relaxou para um
benchmark ficar bonito. As lições 7 e 8 tratam do que "escrito" quer dizer.

**Ele pode ser restaurado?** Um backup que ninguém restaurou é uma esperança, e a pergunta só se
responde tendo feito, recentemente, e cronometrado. Este curso deixa os backups para
`db-reliability`, que dedica a primeira lição exatamente a essa frase; mas toda lição daqui muda o
que um backup precisa conter, e a lição 4 mostra quais são os arquivos.

**Quem pode fazer o quê?** Todo papel, todo grant, toda senha e toda regra de rede que decide quem
alcança quais linhas. A conta da aplicação deve poder fazer o que a aplicação faz e nada mais. As
lições 11 a 13 são essa pergunta.

**Ainda vai caber?** Disco, memória, conexões, o tamanho da maior tabela daqui a seis meses. A maioria
das indisponibilidades que não são falha de hardware é um limite que alguém podia ter visto chegar:
um disco que encheu, um limite de conexões alcançado no primeiro dia movimentado, uma tabela que
cresceu além da sua manutenção.

## E mais uma coisa que não é pergunta

Embaixo das cinco está a **mudança**. O servidor recebe upgrades, a configuração é ajustada, o
esquema evolui enquanto a aplicação continua rodando, e cada uma dessas é um momento em que um
sistema que funciona pode parar de funcionar. Boa parte do trabalho é tornar a mudança tediosa:
ensaiada, reversível, anotada. As lições 20, 22 e 23 tratam disso, e a lição 24 de anotar o que você
fez quando não foi nada tedioso.
