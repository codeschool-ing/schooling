---
title: macOS: launchd e Itens de Início
version: 1
---

No Mac, o PID 1 é o **`launchd`**, o nome da aula 1 para o mesmo trabalho. Ele inicia serviços e
trabalhos agendados a partir de pequenos arquivos XML chamados **listas de propriedades**, `.plist`:

| pasta | o que mora ali |
|---|---|
| `/System/Library/LaunchDaemons` | os serviços de sistema da própria Apple; não mexa |
| `/Library/LaunchDaemons` | serviços de sistema que outros softwares instalaram |
| `/Library/LaunchAgents`, `~/Library/LaunchAgents` | trabalhos que rodam na sessão de uma pessoa |

```sh
launchctl list | head                         # what launchd is running for this user
sudo launchctl list | grep -v com.apple        # system services not from Apple
ls /Library/LaunchDaemons ~/Library/LaunchAgents
```

**Nada disso foi rodado para esta aula.** Uma plist pode dizer *mantenha isto rodando*, como um serviço,
ou *rode às 02:00* com um `StartCalendarInterval`, como um timer; o launchd faz os dois trabalhos. O cron
ainda funciona no Mac, e a Apple recomenda o launchd no lugar dele.

Os **Itens de Início**, em *Ajustes do Sistema > Geral*, são os *apps de inicialização* do Mac: o que abre
quando uma pessoa entra, e uma lista de itens em segundo plano que cada app acrescentou. Um software que
"sempre volta" depois de encerrado em geral é um desses.

## As mesmas três perguntas em todo lugar

Para qualquer máquina, seja qual for o sistema:

1. *O que roda em segundo plano*, e alguém precisa disso?
2. *O que inicia no boot ou no login*, e essa lista é curta?
3. *O que está agendado*, quando, em qual fuso, e foi **testado rodando agora**?
