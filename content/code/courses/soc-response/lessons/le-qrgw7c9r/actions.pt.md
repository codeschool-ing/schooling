---
title: Ações que são feitas
version: 1
---

Uma revisão produz **ações**, e uma ação que não é acompanhada é um desejo. Cada uma precisa de quatro coisas:

| ação | dono | prazo | feita quando |
|---|---|---|---|
| um padrão de instalação para servidores, com SSH só por chave e o `keyaudit.sh` agendado | diego | 30 out | um servidor novo instalado por ele passa no `sshd -T` e na auditoria sem mudanças |
| alertas críticos acionam quem está de sobreaviso, a qualquer hora | ana | 16 out | um alerta de teste às 03:00 chega a um celular, e o acionamento fica no registro do alerta |
| a saída para a internet de todo servidor declarada na fonte do firewall, com negação por padrão | diego | 13 nov | a configuração do firewall não tem regra que deixe algum servidor alcançar qualquer lugar |
| limitar a taxa de tentativas de SSH no `fw` | diego | 23 out | 20 tentativas num minuto de um endereço são descartadas, primeiro no laboratório |
| a regra Sigma para a saída do `files`, e uma para logins com chaves fora do inventário | ana | 23 out | cada regra dispara num evento de teste e aparece no SIEM |
| a escala de sobreaviso, e quanto ela paga | sócia-diretora | 16 out | a escala está publicada e a primeira semana está coberta |

Olhe a última coluna. **"Feita quando" é uma verificação que alguém consegue rodar**, não uma descrição de
esforço. "Melhorar o monitoramento" não tem como ser feito; "um alerta de teste às 03:00 chega a um celular"
acontece ou não acontece.

Dois hábitos mantêm a lista honesta. As ações vão para o **mesmo controle das outras tarefas**, não para o
documento da revisão, onde ninguém olha de novo. E alguém, normalmente a líder do incidente, **confere a lista
nos prazos** e relata o que atrasou: uma revisão cujas ações vencem em silêncio foi só uma reunião, que é o
aviso da figura no começo desta aula.

Nem todo fator ganha uma ação, e isso é permitido. A revisão pode decidir que um risco é aceito, por um
motivo, escrito. O que não é permitido é um fator sobre o qual ninguém decidiu nada.
