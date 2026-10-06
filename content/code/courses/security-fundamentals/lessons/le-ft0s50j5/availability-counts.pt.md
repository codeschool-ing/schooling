---
title: Disponibilidade também é segurança
version: 1
---

Um erro comum é tratar uma loja que para de funcionar como problema de operação, e uma loja cujos
dados vazam como problema de segurança. **Para a tríade, os dois são falhas de segurança.** O
negócio perde de qualquer jeito, e o mesmo atacante que consegue roubar dados muitas vezes
consegue, em vez disso, parar um sistema, que é exatamente o que um ransomware faz.

No laboratório, disponibilidade é fácil de ver, porque é a única propriedade cuja perda aparece
de fora:

```
ana@laptop:~$ curl -s http://www.example.com/
shop.example.com: open
root@www:~# kill $(cat /srv/portal/portal.pid)
ana@laptop:~$ curl -s http://www.example.com/; echo "exit $?"
exit 7
root@www:~# portal-restart
portal restarted
ana@laptop:~$ curl -s http://www.example.com/
shop.example.com: open
```

O primeiro pedido recebe a página inicial da loja. Depois o administrador, no prompt `root@www`
do servidor, para o programa que a serve. O mesmo pedido agora não recebe nada: o `curl` não
mostra página nenhuma, e `exit 7` é o jeito dele de dizer que nem conseguiu conectar. O
`portal-restart` traz o programa de volta e a página volta.

Nada foi lido e nada foi mudado. **Confidencialidade e integridade estão intactas, e a loja
continua perdendo cada venda até alguém perceber.** Aqui a causa foi um comando de propósito; na
vida real o mesmo sintoma vem de vários lugares:

| causa | exemplo | o que defende a disponibilidade |
|---|---|---|
| falha | um disco morre, a fonte de um servidor queima | redundância: um segundo disco, um segundo servidor |
| erro | uma atualização com defeito, uma tabela apagada | teste, controle de mudanças, backups |
| ataque | uma enxurrada de tráfego, um ransomware | filtragem, capacidade, backups offline |
| dependência | o provedor de pagamento caiu | conhecer as dependências e ter um plano |

Disponibilidade também é onde segurança e negócio mais discutem. Todo controle tem algum custo em
disponibilidade: uma regra de firewall pode bloquear um cliente legítimo, um patch pede
reinicialização, o MFA tranca fora quem perdeu o celular. Um controle que protege a
confidencialidade deixando o sistema inutilizável não o deixou seguro. Ele mudou o dano de um
vértice do triângulo para outro.

**Disponibilidade se mede, não se sente.** "A loja ficou no ar 99,9% do mês" é um número que
permite uns 43 minutos fora do ar num mês de 30 dias. A aula 12 volta a isso com backups, onde as
perguntas passam a ser quanto dado a loja pode perder e quanto tempo pode ficar parada.
