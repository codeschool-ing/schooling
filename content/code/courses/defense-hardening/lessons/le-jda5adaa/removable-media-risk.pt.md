---
title: A outra porta de toda estação
version: 1
---

**Uma tomada USB é uma porta de rede que pula a rede.** Tudo o que a primeira metade desta aula
filtrou viaja pela rede, passando pelo switch da aula 4 e pelo firewall da seção anterior. Um pendrive
ligado numa estação chega direto à máquina, e três riscos diferentes entram pela mesma tomada.

**Dados saem andando.** Um pendrive guarda mais registros de clientes do que alguém conseguiria mandar
por e-mail, e copiá-los não deixa rastro na rede. Para um escritório de contabilidade que guarda
documentos fiscais e números de identidade de todos os clientes, este é o que termina numa
comunicação à autoridade de proteção de dados. A aula 9 trata do lado dos dados; esta aula trata da
tomada.

**Malware entra andando.** Um arquivo num pendrive passa por fora do filtro de e-mail e do proxy web.
É assim que malware chega a redes que nem estão ligadas à internet, e é por isso que os arquivos em
mídia removível são a primeira coisa que a proteção de endpoint examina, assunto da aula 7.

**O dispositivo mente sobre o que é.** Um dispositivo USB anuncia a própria classe. Algo com cara de
pendrive pode se anunciar como teclado, e um teclado tem a confiança de digitar: o sistema
operacional aceita as teclas dele como se fossem da pessoa na mesa. As defesas contra este não podem
depender do sistema de arquivos, porque não há arquivo; precisam decidir que dispositivos podem se
conectar.

## O que os controles decidem

| controle | o que decide | barra |
|---|---|---|
| nenhum driver para armazenamento USB | pendrives e discos nem são montados | dados saindo, arquivos entrando; não um dispositivo fingindo ser teclado |
| uma lista de dispositivos permitidos | só dispositivos cuja identidade está numa lista podem se conectar | dispositivos desconhecidos de todas as classes, se a lista for exata |
| armazenamento só de leitura | pendrives podem ser lidos, não gravados | dados saindo; não malware entrando |
| exame na inserção | arquivos são conferidos antes de serem abertos | malware conhecido entrando; nada mais |

Como no perfil Nível 2 da aula 2, a configuração mais forte custa uma função. A mesa da recepção não
recebe nada em pendrive. Quem recebe os documentos de um cliente num pendrive precisa de um caminho
para eles, e a resposta é uma decisão sobre a máquina dessa pessoa, anotada, não uma exceção que
ninguém registra.

A próxima seção monta os dois primeiros no Linux e cita os equivalentes no Windows. O laboratório não
consegue ligar um dispositivo, e essa seção diz exatamente onde para.
