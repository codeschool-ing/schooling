---
title: Cadeia de custódia
version: 1
---

Um hash mostra que um arquivo não mudou desde que o hash foi calculado. Ele não diz **quem** calculou,
quem ficou com o arquivo depois, ou se o arquivo e o hash foram substituídos juntos no caminho. É isso que
a **cadeia de custódia** registra: uma lista sem lacunas, da coleta ao relatório final ou a um tribunal, de
todos que tiveram a evidência e do que fizeram com ela.

No Brasil isso tem uma forma legal precisa. O Código de Processo Penal, desde a Lei 13.964/2019, define a
cadeia de custódia nos artigos 158-A a 158-F, etapa por etapa, do reconhecimento de um vestígio até o
descarte. Logs coletados por uma empresa podem acabar num inquérito policial ou num processo cível, e uma
lacuna na história deles os enfraquece. A referência internacional para lidar com evidência digital é a
**ISO/IEC 27037**, e a aula 16 aplica a mesma disciplina a imagens de disco.

Um registro de custódia para um arquivo de log precisa destes campos, preenchidos na coleta e estendidos
a cada transferência:

| campo | para o arquivo desta aula |
|---|---|
| item | `gw.log-20261007`, o log de SSH do `gw` como recebido no `soc` |
| hash e algoritmo | SHA-256, o valor impresso quando ele foi selado |
| coletado por | o nome e a função do analista |
| quando | data e hora, com o fuso |
| de onde | `soc:/var/log/remote/`, e como chegou lá (rsyslog por TCP a partir do `gw`) |
| como | o comando usado para copiá-lo, e a versão da ferramenta |
| onde fica guardado | o local e quem pode abri-lo |
| cada transferência | de quem, para quem, quando, por quê, e as duas assinaturas |

Três hábitos mantêm a cadeia intacta na prática. **Trabalhe em cópias**, nunca no arquivo coletado, e
confira o hash de cada cópia contra o registro antes de usá-la. **Registre as transferências na hora em que
acontecem**, não no fim da semana, de memória. E **guarde o registro onde a evidência não está**: um
registro de custódia salvo dentro da pasta que ele descreve fica exposto a tudo a que essa pasta está.

Nada disso muda o que o log diz. Decide se alguém mais é obrigado a acreditar nele.
