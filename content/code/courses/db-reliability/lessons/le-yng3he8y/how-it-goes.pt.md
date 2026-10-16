---
title: Como um ataque chega primeiro aos backups
version: 1
---

O ransomware costuma ser imaginado como um único momento: os arquivos são criptografados e aparece um
bilhete. Para quem depois tem que recuperar, a parte importante aconteceu antes desse momento, muitas
vezes semanas antes, e é dessa parte que esta lição trata.

Vistos do lado de quem defende, os relatos desses ataques seguem a mesma ordem, vez após vez:

1. **Uma entrada.** Uma senha roubada, um notebook pego por phishing, um servidor exposto na internet,
   um serviço sem patch. Nada a ver com o banco ainda.
2. **Tempo lá dentro.** O intruso olha em volta, em silêncio, por dias ou semanas, e dá um jeito de
   manter o acesso: uma conta a mais, uma chave adicionada em algum lugar, uma tarefa agendada. Os
   relatos chamam isso de **dwell time**, e ele é longo porque o objetivo é o silêncio.
3. **Os backups.** Antes de qualquer coisa visível, o intruso encontra e destrói o que deixaria a
   vítima se recuperar sem pagar: snapshots apagados, repositórios de backup esvaziados, retenção
   encurtada, rotinas de backup desativadas. A pergunta da lição 9, que credenciais conseguem apagar
   as cópias, se decide aqui.
4. **O dano.** Arquivos criptografados, ou bancos sobrescritos, no maior número de máquinas possível
   ao mesmo tempo, normalmente à noite ou num feriado.
5. **A exigência.** Pague pela chave. Muitas vezes também: pague para que uma cópia dos dados, tirada
   durante o dwell time, não seja publicada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Uma linha do tempo de um ataque: a entrada, semanas lá dentro em que uma conta a mais é criada, os backups apagados e depois o dano. Um ponto de restauração logo antes do dano traz os dados de volta, e a conta junto. Um ponto antes da entrada é limpo e perde mais.\"><defs><marker id=\"l10a-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"l10a-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><defs><marker id=\"l10a-wi\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M20 80 L70 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M150 80 L170 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 80 L430 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M550 80 L570 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M650 80 L700 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10a-wi)\"></path><rect x=\"70\" y=\"64\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">entrada</text><rect x=\"170\" y=\"64\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"290\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">semanas lá dentro: uma conta a mais</text><rect x=\"430\" y=\"64\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"490\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">backups apagados</text><rect x=\"570\" y=\"64\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">dano</text><path d=\"M560 130 L560 100\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10a-pa)\"></path><text x=\"560\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">restaurar aqui: dados de volta, a conta também</text><path d=\"M45 170 L45 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10a-ph)\"></path><text x=\"30\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">restaurar aqui: limpo, perde-se mais</text></svg>", "caption": "Por que o ponto limpo é anterior ao dano. Uma restauração ao momento antes do dano traz de volta o que o intruso deixou nas semanas lá dentro; só um ponto antes da entrada é limpo, e ele perde tudo desde então."}
```

Duas coisas decorrem disso para um administrador de banco de dados, e o resto da lição se apoia nelas.

**Os backups são um alvo, não um espectador.** Tudo o que a lição 9 construiu (uma cópia em outro
lugar, atrás de outra credencial, imutável até uma data) existe por causa do passo 3. Um backup que as
credenciais do intruso alcançam é apagado antes que alguém saiba que existe um intruso.

**O dano não é onde o ataque começou.** Uma restauração ao momento antes da criptografia traz de volta
os dados e, junto com eles, tudo o que o intruso arranjou nas semanas anteriores: a conta a mais, a
configuração alterada. O ponto limpo é mais antigo do que parece, e a segunda metade desta lição
descobre isso no shop.

E uma coisa que backups não resolvem de jeito nenhum: **dados que foram copiados para fora** durante o
dwell time estão fora do seu controle, seja qual for a restauração. Isso é assunto de criptografia em
repouso, de controle de acesso e das pessoas que cuidam da divulgação, não deste curso, e é citado
aqui para que ninguém confunda uma boa restauração com o fim do incidente.
