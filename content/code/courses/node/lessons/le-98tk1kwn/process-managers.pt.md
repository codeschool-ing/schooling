---
title: Mantendo um serviço rodando
version: 1
---

**Um `npm start` num terminal não é como um serviço roda num servidor.** O terminal fecha, a máquina
reinicia, o processo cai às três da manhã, e nada o inicia de novo. Um **gerenciador de processos** é o
programa cujo trabalho é esse: ele inicia o serviço no boot, o reinicia quando cai, dá a ele o ambiente,
manda `SIGTERM` para pará-lo, e guarda os logs.

| gerenciador de processos | onde você o encontra |
|---|---|
| **systemd** | todo servidor Linux comum; nada a instalar |
| a plataforma | uma plataforma de contêineres ou um serviço de hospedagem reinicia o que roda |
| **pm2** | um pacote do Node, popular em servidores sem nenhum dos dois |

## Rode o node, não o npm

Um detalhe primeiro, porque ele pode decidir se o desligamento gracioso chega a rodar. **Um gerenciador
de serviço para o que ele iniciou**, e o `npm start` inicia o npm, que inicia um shell, que inicia o
Node. O serviço links rodando com `npm start` no primeiro terminal, e no segundo:

```
ana@dev:~/server/links$ pgrep -a 'npm|node'
15469 npm start
15484 node --env-file-if-exists=.env server.js
ana@dev:~/server/links$ kill -TERM 15469
ana@dev:~/server/links$ sleep 1; pgrep -a 'npm|node'
15469 [npm start] <defunct>
15484 node --env-file-if-exists=.env server.js
ana@dev:~/server/links$ kill -TERM 15484
```

**O `SIGTERM` parou o npm e o Node nunca o ouviu.** O npm está `<defunct>`: ele terminou, e o pai dele
ainda não recolheu o código de saída. O Node continua rodando, sem ninguém para pará-lo, e com todo
pedido aberto que tinha ainda aberto; o último `kill` acima foi mandado ao Node à mão, e só então o
primeiro terminal imprimiu o desligamento gracioso. Num terminal o Ctrl-C chega até ele, porque o
terminal manda o sinal a todo processo do grupo. Se um gerenciador de serviço faz o mesmo depende do
gerenciador: o systemd, por padrão, sinaliza todo processo que o serviço iniciou, e o Docker sinaliza
só o primeiro, que aqui é o npm. **Um serviço roda o `node` direto**, com as mesmas opções que o script
`start` tem, e então a pergunta nem aparece.

## Uma unit do systemd

Um **arquivo de unit** descreve o serviço para o systemd. Este é o serviço links num servidor Linux, numa
pasta `/srv/links` que pertence a um usuário `links`:

```schooling-example
{"language": "ini", "file": "/etc/systemd/system/links.service", "parts": [
 {"code": "[Unit]\nDescription=links, the link shortener\nAfter=network.target", "note": "O que é o serviço, e que ele inicia depois que a rede subiu."},
 {"code": "[Service]\nUser=links\nWorkingDirectory=/srv/links\nEnvironment=NODE_ENV=production HOST=127.0.0.1 PORT=3000\nEnvironmentFile=/etc/links/secrets.env\nExecStart=/usr/bin/node server.js", "note": "**O ambiente, e o segredo à parte.** O `EnvironmentFile` é o arquivo protegido da aula 9: legível só pelo root, e o systemd o lê antes de o serviço iniciar. O `ExecStart` é o `node`, não o `npm`, pelo caminho completo: `/usr/bin/node` é onde o pacote de uma distribuição o põe, e um Node desempacotado do tarball como na aula 1 fica onde foi desempacotado."},
 {"code": "Restart=on-failure\nRestartSec=2\nKillSignal=SIGTERM\nTimeoutStopSec=15", "note": "**Reiniciar depois de uma queda**, dois segundos depois. Parar com `SIGTERM`, e esperar 15 segundos, mais que os dez do próprio serviço, antes do `SIGKILL`."},
 {"code": "[Install]\nWantedBy=multi-user.target", "note": "Iniciar no boot, depois de habilitado."}
]}
```

E os comandos que a carregam, a iniciam e leem o log dela:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now links
systemctl status links
journalctl -u links -f
```

**Esta unit não foi rodada para este curso.** É a forma padrão e cada linha está no próprio manual do
systemd, `man systemd.service`, mas a máquina de prática do curso não é um servidor iniciado pelo
systemd, e uma unit que nunca foi iniciada não é uma captura. O que ela acrescenta a tudo nesta aula
não é código novo: o serviço já lê o ambiente, recusa uma configuração ruim e para direito no
`SIGTERM`, que é tudo o que um gerenciador de processos precisa dele.

O **pm2** faz o mesmo a partir do npm, com `pm2 start server.js`, e acrescenta um modo cluster próprio.
Ele também não foi rodado aqui; numa máquina com systemd ele é um segundo gerenciador de processos, e
um basta.
