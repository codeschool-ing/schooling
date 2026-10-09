---
title: Recuperação, em passos
version: 1
---

A **recuperação** é devolver os sistemas ao serviço normal, e confirmar que eles estão funcionando normalmente.
A segunda metade é a que leva tempo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"A recuperação em cinco passos, cada um com uma porta antes do próximo: restaurar de uma fonte confiável; verificar que o conserto está lá e o buraco fechado; voltar ao serviço, um sistema por vez; vigiar mais de perto, por um período definido; encerrar, quando os critérios escritos no começo forem cumpridos.\"><rect x=\"10\" y=\"50\" width=\"124\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"72.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">restaurar</text><text x=\"72.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fonte confiável</text><path d=\"M134 82 L154 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M154 82 L146.0 78.0 L146.0 86.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"154\" y=\"50\" width=\"124\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"216.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">verificar</text><text x=\"216.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">conserto, buraco fechado</text><path d=\"M278 82 L298 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M298 82 L290.0 78.0 L290.0 86.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"298\" y=\"50\" width=\"124\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">voltar</text><text x=\"360.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um sistema por vez</text><path d=\"M422 82 L442 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M442 82 L434.0 78.0 L434.0 86.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"442\" y=\"50\" width=\"124\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"504.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">vigiar</text><text x=\"504.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por prazo definido</text><path d=\"M566 82 L586 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M586 82 L578.0 78.0 L578.0 86.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"586\" y=\"50\" width=\"124\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"648.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">encerrar</text><text x=\"648.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">critérios cumpridos</text></svg>", "caption": "Cada passo tem uma porta: o próximo começa quando este foi conferido, não quando terminou."}
```

Cada passo tem uma **porta**: o próximo começa quando este foi conferido, não quando foi feito. Para o `gw`,
depois da reconstrução, a porta antes de devolvê-lo ao serviço são três perguntas com evidência: o buraco está
fechado, a entrada legítima ainda funciona, e tudo está sendo registrado?

```
root@soc:~# ip netns exec outside ssh -o BatchMode=yes -o PreferredAuthentications=password -o StrictHostKeyChecking=accept-new ana@198.51.100.22 true
ana@198.51.100.22: Permission denied (publickey).
root@soc:~# ip netns exec outside runuser -u ana -- ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ana@198.51.100.22 hostname
gw
root@soc:~# tail -n 4 /var/log/soclab/gw-auth.log
2026-10-07T20:48:18-0300 gw sshd: Connection closed by authenticating user ana 203.0.113.66 port 55460 [preauth]
2026-10-07T20:48:18-0300 gw sshd: Accepted publickey for ana from 203.0.113.66 port 55466 ssh2: ED25519 SHA256:QJsKkPtqEBuAn+lfcyMGgnotN3pJ16nFW1AbcdPz8bo
2026-10-07T20:48:18-0300 gw sshd: Received disconnect from 203.0.113.66 port 55466:11: disconnected by user
2026-10-07T20:48:18-0300 gw sshd: Disconnected from user ana 203.0.113.66 port 55466
```

O primeiro comando pede só senha e é recusado: `Permission denied (publickey)`, o servidor oferecendo chaves e
nada mais. O segundo entra com a chave da ana e roda `hostname`: `gw`. O log tem os dois: uma conexão encerrada
antes da autenticação, e uma chave aceita, com a impressão digital, a mesma que o inventário guarda. **Essa
impressão digital no log é onde a auditoria e o monitoramento se encontram**: um login com uma chave que não
está no inventário é o tipo de regra da aula 4, esperando para ser escrita.

**Volte um sistema por vez.** O `gw` primeiro, vigiado por um dia; depois a conta do bruno, com a chave nova;
depois as exceções da regra de saída revistas com o dono do servidor de arquivos. Se algo der errado, fica
claro qual passo causou.

**O fim da recuperação é escrito no começo.** Para a quinta, o registro do incidente diz que a recuperação está
completa quando: o `gw` foi reconstruído e passa nas três verificações; toda chave dos dois hosts está no
inventário; as senhas estão desligadas no `gw`; a regra de saída está na fonte do firewall; e duas semanas de
revisão diária de logins não acharam nada. Sem critérios assim, um incidente nunca é encerrado, ou é encerrado
no dia em que todo mundo cansou dele, que não é a mesma coisa.

Então o incidente vai para a sua última fase, a que deixa o próximo mais barato: a aula 15.
