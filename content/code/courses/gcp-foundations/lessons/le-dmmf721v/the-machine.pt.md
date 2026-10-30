---
title: A máquina atrás do terminal
version: 1
---

**O Cloud Shell é uma pequena máquina Linux que o Google inicia para você quando você abre um terminal no
console**, com gcloud, Terraform, kubectl, Docker e as linguagens comuns já instalados, e com as suas próprias
credenciais já nela. Não custa nada e não precisa de nada instalado. É o jeito mais rápido de rodar um comando
contra uma conta real, de qualquer navegador, e a lição 1 disse por que ele não é o laboratório deste curso:
ele exige uma conta do Google, e este curso foi escrito para ninguém precisar de uma.

Que tipo de máquina ele é decide quase tudo para o que ele serve:

| ele é | então |
|---|---|
| **uma máquina virtual num projeto do Google**, não seu | ele não está na sua rede VPC, e alcança os seus endereços privados tão pouco quanto a internet |
| **iniciado para você, e parado quando ocioso** | o que roda nele para junto; ele não é um servidor |
| **conectado como você** | todo comando age com os seus papéis, e isso é a conveniência e o risco |
| **alcançado pelo navegador** | nada nele pode ser alcançado da internet, exceto pelo web preview da terceira seção |

**Nada nesta lição rodou no Cloud Shell**, pelo motivo acima. O que rodou foi o lado do gcloud, no laptop, e a
resposta do Google a ele. Os fatos sobre a máquina são da documentação do Google, que não estava acessível de
onde este curso foi escrito em 30 de outubro de 2026, então a lição não dá nenhum número que possa ter mudado
desde então: a página de limites do Cloud Shell na documentação é onde estão as horas e os tamanhos atuais.

## O lado do gcloud

O gcloud alcança o Cloud Shell a partir de um laptop, e esse é o único jeito de usá-lo sem navegador:

```
ana@laptop:~/gcp$ gcloud cloud-shell --help | sed -n "/^COMMANDS/,/^NOTES/p" | grep -E "^     [a-z]"
     get-mount-command
     scp
     ssh
```

O `ssh` abre uma sessão nele, o `scp` copia arquivos para dentro e para fora, e o `get-mount-command` imprime a
linha que monta o diretório home dele no laptop por SSH. Peça o comando SSH que ele rodaria, sem rodá-lo. Este
pedido chega ao Google, então a saída é filtrada para as linhas que não são aleatórias:

```
ana@laptop:~/gcp$ gcloud cloud-shell ssh --dry-run 2>&1 | grep -E "^(Automatic|WARNING|ERROR|Your)"
Automatic authentication with GCP CLI tools in Cloud Shell is disabled. To enable, please rerun command with `--authorize-session` flag.
WARNING: The private SSH key file for gcloud does not exist.
WARNING: The public SSH key file for gcloud does not exist.
WARNING: You do not have an SSH key for gcloud.
WARNING: SSH keygen will be executed to generate a key.
Your identification has been saved in /home/ana/.ssh/google_compute_engine
Your public key has been saved in /home/ana/.ssh/google_compute_engine.pub
ERROR: (gcloud.cloud-shell.ssh) UNAUTHENTICATED: Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project. This command is authenticated with an access token from /home/ana/gcp/placeholder-token specified by the [auth/access_token_file] property.
```

Três coisas aconteceram em ordem. O gcloud disse que **não entregaria as suas credenciais à sessão** a menos que
se pedisse com `--authorize-session`, e esse é o padrão certo: uma sessão que herda as suas credenciais é mais
um lugar onde elas estão. Ele **fez uma chave SSH** para si, `~/.ssh/google_compute_engine`, que ele reusa para
toda máquina a que se conectar daqui em diante. E ele pediu à API do Cloud Shell para iniciar a máquina, que
recusou o token de mentira como todo serviço do Google neste curso.
