---
title: Ajuste fino, para a prevenção continuar ligada
version: 1
---

**Toda configuração de HIPS troca um ataque que passa por um colega bloqueado.** Os números do
`jail.local` são essa troca por escrito, e cada um a move:

| opção | mais baixo | mais alto |
|---|---|---|
| `maxretry` | bane antes, e pega o colega que erra a digitação duas vezes | deixa um chutador tentar mais antes do banimento |
| `findtime` | esquece as falhas antes, então um chutador lento espalhado por horas nunca chega à contagem | lembra por mais tempo, e soma enganos sem relação entre si |
| `bantime` | o chutador volta antes | um colega trancado do lado de fora espera mais |

Não existe valor certo, só motivo certo. No `web`, o SSH aceita chaves e nenhuma senha depois que o
endurecimento da aula 1 está aplicado, então chutar não leva a nada, e o trabalho do fail2ban é manter o
log legível e as conexões baratas; banimentos curtos bastam. Num servidor que ainda aceita senhas
vindas da internet, os banimentos ficam mais longos e os reincidentes ganham mais tempo ainda, o que a
jail `recidive` do fail2ban faz vigiando o próprio log atrás de endereços banidos repetidas vezes.

## Nunca bana quem conserta as coisas

**`ignoreip` lista os endereços que o fail2ban nunca vai banir**, e deve estar em toda configuração de
jail que chegue à produção. Na rede da Jatobá ela teria o `admin`, e o servidor de salto que a aula 15
constrói, para que uma chave digitada errada na própria máquina dos administradores nunca os tranque
fora do servidor que estão tentando consertar:

```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 192.168.60.30 192.168.60.40
```

O custo é que um invasor no `admin` também nunca é banido, o que é mais um motivo para a aula 15
tratar as máquinas dos administradores como as mais protegidas do escritório.

## Vigiando a própria proteção

Três conferências mantêm um HIPS honesto, e cada uma pega uma falha que se parece com silêncio:

- **A ação tem efeito?** Depois de qualquer mudança numa jail, provoque um banimento de propósito, de
  uma máquina de teste, e confirme que o endereço é recusado, como esta aula fez a partir do `desk`. As
  mensagens de erro de uma ação que falhou vão para o `fail2ban.log`, e ninguém lê esse log sem motivo.
- **A jail está lendo o log certo?** Uma jail cujo log mudou de lugar, ou cujo serviço agora registra
  no journal, não conta nada e não bane ninguém, para sempre. Um `fail2ban-client status` mostrando um
  total de zero falhas por meses num servidor alcançável pela internet não é boa notícia.
- **O banco de integridade ainda é o aprovado?** Um banco remontado depois de uma mudança sem
  explicação aprovou essa mudança. Remontar é uma decisão, e o registro de mudanças deve dizer quem a
  tomou e por quê.
