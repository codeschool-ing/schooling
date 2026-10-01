---
title: Acesso remoto, um túnel por pessoa
version: 1
---

O acesso remoto põe o túnel no próprio dispositivo da pessoa. Na aula 4, o laptop da Ana foi um par
WireGuard de `hq` com uma chave própria, e depois um cliente OpenVPN com um certificado próprio. **A
outra ponta é um concentrador ao qual muita gente se conecta, e cada conexão é uma pessoa, não uma
rede.** Quase tudo o que difere do site a site decorre disso.

**A identidade tem de ser de uma pessoa.** O arquivo de status da aula 4 escreveu `ana` ao lado do
endereço dela, e é essa palavra que torna o log útil e permite cortar uma pessoa e mais ninguém. Uma
chave ou uma senha compartilhada por uma equipe inteira faria toda linha desse arquivo dizer a mesma
coisa, e sair da empresa não mudaria nada.

Uma senha sozinha não basta numa porta virada para a internet. Um gateway de VPN é um dos serviços mais
atacados que uma empresa mantém, porque um login bem-sucedido põe o atacante dentro da rede. Por isso o
acesso remoto pede um segundo fator, MFA: um código de um aplicativo, uma notificação no celular ou uma
chave física, geralmente conferido pelo provedor de identidade da empresa e não pela própria VPN. O
OpenVPN faz isso com um plugin ou script que confere nome, senha e código além do certificado; clientes
comerciais mandam a pessoa para a página de login do provedor de identidade. **Nada disso rodou no
laboratório**, cujo OpenVPN aceitou um certificado e mais nada.

**O dispositivo importa tanto quanto a pessoa.** Um laptop roubado leva junto a chave WireGuard ou o
certificado, então a chave tem de ficar num disco criptografado, e um dispositivo perdido tem de ser
revogado no mesmo dia. Alguns gateways vão além e conferem o dispositivo antes de deixá-lo entrar: disco
criptografado, sistema atualizado, software da empresa rodando.

O resto decorre de o dispositivo estar em outro lugar. O endpoint muda entre a casa, um hotel e um
celular, e quase sempre está atrás do NAT de alguém, que é para o que servem o roaming e o
`PersistentKeepalive` da aula 4. O endereço dele dentro do túnel vem de um pool, `10.8.0.2` na aula 4,
e não de nada que a pessoa escolheu.

| | site a site | acesso remoto |
|---|---|---|
| as duas pontas | dois roteadores | um dispositivo e um concentrador |
| quem é autenticado | um local | uma pessoa, e de preferência o dispositivo |
| quem sabe que ele existe | ninguém nas duas LANs | a pessoa, que o inicia |
| quando está de pé | sempre | enquanto a pessoa trabalha |
| o endereço da outra ponta | fixo | qualquer lugar, geralmente atrás de NAT |
| quantos túneis | um por par de escritórios | um por pessoa |
| neste laboratório | `hq` até `branch` | `remote` até `hq` |
