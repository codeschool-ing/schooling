---
title: A verificação no código
version: 1
---

A seção anterior observou o portal de fora. Aqui está a parte do programa dele que produziu aquelas
respostas, o trecho que trata todo endereço que começa com `/payslips/`. Ele é curto, e cada pedaço é
uma das ideias desta aula. Você não precisa saber Python para acompanhar: leia a nota ao lado de cada
pedaço.

```schooling-example
{"language": "python", "file": "portal.py", "parts": [{"code": "if path.startswith('/payslips/'):\n    owner = path[len('/payslips/'):]", "note": "O endereço diz de quem é o holerite pedido. Esse nome é o dono do recurso, e a regra abaixo precisa dele."}, {"code": "    me = self.who()\n    if me is None:\n        return self.ask_to_sign_in()", "note": "Autenticação. O who() confere o usuário e a senha contra o hash guardado e não devolve nada se falharem; nada quer dizer 401, faça login primeiro."}, {"code": "    name, groups = me\n    # Authorisation: may THIS person see THAT payslip?\n    if name != owner and 'hr' not in groups:\n        return self.reply(403, 'not yours to read\\n')", "note": "Autorização, usando o que a autenticação provou. Você lê um holerite se ele é seu ou se você está em hr. Qualquer outro recebe 403."}, {"code": "    if owner not in users():\n        return self.reply(404, 'no such payslip\\n')", "note": "A existência só é conferida depois da permissão, então uma recusa nunca diz se o holerite existe."}, {"code": "    return self.reply(200, 'payslip for %s, September 2026\\n' % owner)", "note": "Só agora, com a identidade provada e a permissão concedida, o holerite é servido."}]}
```

Três coisas neste código valem mais que o tamanho delas.

**A ordem é o projeto.** A autenticação vem primeiro, porque a regra abaixo dela usa `name` e
`groups`, que só existem depois que o `who()` provou quem está pedindo. A permissão vem antes da
existência, e é por isso que a ana ouviu 403 para carla e nunca soube se carla está na folha.

**A regra é sobre o pedido, não sobre a página.** Nada aqui diz "esta página é da equipe". Diz "este
holerite pode ser lido pelo dono ou por `hr`", e isso é conferido contra o nome específico deste pedido
específico. Um programa que só conferisse "tem alguém logado?" passaria no primeiro teste e serviria o
holerite do bruno à ana, que é exatamente a falha que a próxima seção descreve.

**A verificação fica no servidor.** Uma página poderia esconder o link para o holerite dos outros, e
isso seria bom projeto, mas não seria um controle: a ana poderia digitar o endereço ela mesma, como o
`curl` fez. **Esconder um botão não é autorização.** A única verificação que conta roda na máquina que
guarda os dados, onde quem pede não consegue mudá-la.

As aulas 12 e 13 de `secure-code` vão além para quem escreve software: como organizar essas
verificações numa aplicação inteira para que nenhuma página fique sem uma.
