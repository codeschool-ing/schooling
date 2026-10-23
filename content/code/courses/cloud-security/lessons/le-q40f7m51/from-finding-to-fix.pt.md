---
title: De um achado a uma correção, e de volta
version: 1
---

**Um achado é uma pergunta endereçada a uma pessoa: era isto que você queria? Há três respostas
honestas. Corrigir, aceitar com um motivo e uma data de fim, ou descobrir de quem é e perguntar.** Uma
quarta resposta é a comum e a errada: deixar na lista, onde ela ensina a todos que a lista é ruído.

## De quem é

Antes que qualquer coisa possa ser corrigida, alguém tem de ser quem corrige. O scanner diz *o quê*;
não sabe dizer *de quem*. Por isso a aula 17 e a aula 10 do curso `cloud` pedem etiquetas em todo
recurso: uma etiqueta `owner` transforma "a porta 22 está aberta no `sg-…`" numa mensagem com um nome.
A clínica é pequena o bastante para responder de memória. O caio criou o `booking-admin` para chegar
ao servidor de agendamento; o usuário da bia é da bia; os buckets são da clínica.

## Aceitando um, de propósito

O `clinic-web` é público porque é o site. A regra está certa em geral e errada aqui, então ele ganha
uma exceção. **Uma exceção carrega um motivo de que alguém pode discordar e uma data depois da qual
ela deixa de valer.** Sem a data ela é permanente, e daqui a um ano ninguém lembra por que o bucket do
site podia ser público, nem se as exportações de pacientes foram parar nele desde então.

```sh
cat > accepted.txt <<'EOF'
public-bucket clinic-web 2027-04-30 the public website: pages and logo only, reviewed by ana
EOF
```

## Corrigindo as outras três

Cada correção é uma chamada, do tamanho da falha, e cada uma vem da aula que a explicou:

```
ana@laptop:~/aws$ aws s3api put-bucket-encryption --bucket clinic-exports --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
ana@laptop:~/aws$ aws ec2 revoke-security-group-ingress --group-id "$sg" --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return
true
ana@laptop:~/aws$ aws iam enable-mfa-device --user-name bia --serial-number arn:aws:iam::123456789012:mfa/bia --authentication-code1 123456 --authentication-code2 654321
```

O `$sg` ainda guarda o id do grupo da seção anterior, no mesmo terminal. Na prática, a correção da
porta 22 é a que pede uma conversa: o caio ainda precisa chegar ao servidor de agendamento, e a aula 8
lhe dá um caminho que não é a internet inteira. A correção do MFA é da bia, no celular dela; aqui ela
faz as vezes da bia, com o moto aceitando os códigos como antes.

**Depois prove do jeito que as falhas foram achadas**, rodando o mesmo scanner:

```
ana@laptop:~/aws$ python3 scan.py; echo "exit $?"
accepted  public-bucket       clinic-web            until 2027-04-30: the public website: pages and logo only, reviewed by ana
0 open, 1 accepted
exit 0
```

Nada aberto, uma exceção com motivo e data, e código de saída `0`.

## Desvio: a mesma falha, na semana seguinte

Um relatório limpo descreve um momento. Uma semana depois, o caio está depurando de um café, abre o SSH
para o mundo "por cinco minutos" e esquece:

```
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id "$sg" --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return
true
ana@laptop:~/aws$ python3 scan.py; echo "exit $?"
accepted  public-bucket       clinic-web            until 2027-04-30: the public website: pages and logo only, reviewed by ana
OPEN      admin-port-open     sg-d877b106d3b8c910b  port 22 open to 0.0.0.0/0
1 open, 1 accepted
exit 1
```

**Isto é desvio**: a configuração se afastou do estado que foi conferido, pela mesma API que a
corrigiu. Nada o impede, porque o caio pode mudar o próprio security group, e é a varredura da manhã
seguinte que o pega. Uma varredura trimestral o pegaria em janeiro.

Duas coisas encolhem o desvio em vez de só pegá-lo. **Escrever a configuração como código**, para que
a correção viva num arquivo revisado e aplicado de novo, e uma mudança à mão seja desfeita pela próxima
aplicação — a aula 12. E **rodar a verificação antes da mudança**, não só depois: a aula 14 põe um
scanner no fluxo de publicação, onde um pull request que abre a porta 22 falha antes de chegar à
conta.
