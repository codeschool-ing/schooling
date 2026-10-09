---
title: Fechando o buraco
version: 1
---

Remover a chave desfaz o que o invasor fez. Não impede o próximo, porque a entrada continua aberta: o `gw`
aceita senhas da internet, e uma senha pode ser adivinhada. O `sshd -T` imprime as configurações que o servidor
usaria de fato, depois de ler todos os arquivos, que é a resposta honesta para "o que este servidor permite?":

```
root@soc:~# sshd -T | grep -E '^(password|pubkey)authentication'
pubkeyauthentication yes
passwordauthentication yes
root@soc:~# echo 'PasswordAuthentication no' > /etc/ssh/sshd_config.d/50-keys-only.conf
root@soc:~# sshd -T | grep -E '^(password|pubkey)authentication'
pubkeyauthentication yes
passwordauthentication no
```

Antes: `passwordauthentication yes`. Uma linha num arquivo próprio em `sshd_config.d/`, e depois: `no`. Chaves
continuam funcionando, então ninguém que tem uma perde o acesso. Um arquivo próprio, em vez de uma edição no
meio do `sshd_config`, é mais fácil de achar, de revisar e de colocar no padrão de instalação, que é onde ele
precisa terminar.

Use a configuração como verificação, não como crença: o `sshd -T` lê a configuração do jeito que o servidor vai
ler no próximo início, então um erro de digitação aparece aqui, antes de reiniciar, e não como um servidor que
recusa todo mundo.

**A ordem importa.** Todo usuário precisa ter uma chave, registrada no inventário, *antes* de as senhas serem
desligadas, senão o conserto tranca a equipe junto com o invasor. Na quinta, isso significou que o bruno
recebeu a chave nova pessoalmente primeiro, como diz o registro de decisões da aula 13, e a configuração mudou
depois.

Fechar o buraco é o passo que transforma um incidente numa melhoria, e é também o mais pulado: a chave sumiu, o
servidor funciona, todo mundo está cansado. A aula 15 é onde passos pulados como este são encontrados.
