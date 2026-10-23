---
title: As mesmas ideias no Windows e em produtos
version: 1
---

**Nada nesta seção foi executado para este curso.** Não há máquina Windows no laboratório; o que vem a
seguir foi tirado da documentação da Microsoft e dos próprios fabricantes.

## Bloqueio de conta, o fail2ban do Windows

O Windows conta logins que falharam por **conta**, e não por endereço. O *limite de bloqueio de
conta*, definido pela Política de Grupo em *Políticas de Conta, Política de Bloqueio de Conta*, trava
uma conta depois de um número de senhas erradas, por um tempo definido. A linha de base de segurança
da Microsoft sugere dez. A diferença importa: contar por conta protege uma conta de um chutador em
qualquer lugar, e deixa qualquer um que saiba um nome trancar o dono dele de propósito, e é por isso
que o limite não é baixo. O fail2ban conta por endereço e nunca trava conta nenhuma.

## Regras de redução da superfície de ataque

As regras de **redução da superfície de ataque** do Microsoft Defender são um HIPS feito de
comportamentos de que o trabalho comum quase nunca precisa, e cada uma pode ficar em *auditoria* ou em *bloqueio*.
Alguns exemplos: aplicativos do Office iniciando processos filhos, scripts lançando executáveis baixados,
processos lendo credenciais da memória do processo de autenticação do sistema. A orientação da própria
Microsoft é a que esta aula dá: **rode cada regra em modo de auditoria primeiro**, leia o que ela teria
bloqueado e passe para bloqueio só onde nada legítimo aparecer.

## Acesso controlado a pastas

O **acesso controlado a pastas** protege pastas escolhidas, como Documentos, de serem alteradas por
qualquer programa fora de uma lista permitida. Mira o ransomware, que cifra todo arquivo que alcança,
e é um pequeno controle de acesso obrigatório: a pergunta não é que conta está gravando, e sim que
programa.

## Integridade de arquivos e HIPS em produtos

Produtos comerciais de EDR, assunto da aula 8, trazem a maior parte desta aula num agente só:
monitoramento de integridade de caminhos escolhidos, regras que bloqueiam comportamentos e um console
central onde os alertas de todas as máquinas são lidos. O Wazuh, de código aberto, monitora a
integridade de arquivos e roda respostas ativas, o nome que ele dá a ações automáticas como bloquear um
endereço, no mesmo espírito do fail2ban. O OSSEC, de onde o Wazuh nasceu, fazia as duas coisas antes de
qualquer um deles se chamar EDR.

A engenharia por baixo é a que esta aula rodou à mão: um log ou um evento, uma contagem ou uma
comparação, um limite e uma ação que alguém conferiu que funciona de fato.
