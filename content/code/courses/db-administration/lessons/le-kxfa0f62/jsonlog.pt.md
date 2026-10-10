---
title: jsonlog, para uma máquina ler
version: 1
---

Uma pessoa lê o log em texto com `grep`. Um programa que recolhe logs de muitos servidores — um
coletor alimentando um mecanismo de busca, o serviço de log de um provedor de nuvem — quer
**campos**, e interpretar um prefixo com uma expressão regular quebra no dia em que alguém
acrescenta `%a` a ele. O PostgreSQL 15 trouxe o **`jsonlog`**: um objeto JSON por linha, com cada
campo nomeado.

Ele precisa do logging collector, porque só o logger do próprio servidor consegue escrever um
formato que não seja texto puro, então isto é um restart:

@@1@@

@@2@@

@@3@@

O `pg_current_logfile()` tem resposta agora, porque o servidor abriu o arquivo ele mesmo. É um
caminho relativo ao diretório de dados. E o arquivo que o Ubuntu montou parou de crescer:

@@4@@

**As duas últimas linhas em `/var/log/postgresql` dizem para onde o log foi.** É a armadilha de que
a primeira seção avisou, vista do outro lado: quem conhece só o padrão do Ubuntu abre esse arquivo,
vê um desligamento limpo e uma partida, e conclui que nada aconteceu desde então.

@@5@@

O `sh -c` está ali porque o diretório pertence a `postgres`: o `*` precisa ser expandido por um
shell que consiga lê-lo. O `jq .` imprime a linha indentada. Cada parte do prefixo é um campo
próprio — `user`, `dbname`, `pid`, `application_name` — e há alguns que prefixo nenhum tinha: o
`state_code` é o SQLSTATE, `22012` para divisão por zero, que um programa consegue casar sem ler
inglês, e o `backend_type` diz que tipo de processo escreveu a linha. O arquivo `.log` pequeno ao
lado do JSON é o arquivo em texto puro do collector, que ele mantém para qualquer coisa escrita na
saída de erro que não passou pelo log do próprio PostgreSQL.

Os arquivos agora são nomeados pelo `log_filename`, por padrão a data e a hora em que o arquivo foi
aberto, e **girados pelo servidor**, por `log_rotation_age` (um dia) e `log_rotation_size` (10 MB).
O logrotate não participa mais, e nada apaga os arquivos antigos a menos que
`log_truncate_on_rotation` e um `log_filename` que se repete estejam montados para sobrescrevê-los,
ou que algo fora do servidor limpe o diretório. É uma segunda coisa a arranjar antes de ligar isto
de verdade.

## Devolvendo tudo

O curso segue com o log do Ubuntu, então cada parâmetro que esta lição mudou é restaurado, o restart
tira o collector de novo, e o `postgresql.auto.conf` volta às suas duas linhas de comentário:

@@6@@

@@7@@
