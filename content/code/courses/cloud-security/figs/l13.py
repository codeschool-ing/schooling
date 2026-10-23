"""Lesson 13: the four edges of one function."""
from figures import Fig, T, figure


@figure('l13-edges', 13)
def edges():
    f = Fig('l13-edges', 720, 340, T(
        'The four edges of one Lambda function, each written in a different place. Above it, who may '
        'become it: the trust policy of its execution role, which should name only the Lambda service. '
        'On its left, who may call it: its resource-based policy and the authentication type of its '
        'function URL. On its right, what it may do: the policies of its execution role, which any '
        'code inside the function inherits. Below it, what it carries: its code, its dependencies '
        'and its environment variables, all frozen into the deployed package and its configuration.',
        'As quatro bordas de uma função Lambda, cada uma escrita num lugar diferente. Acima dela, quem '
        'pode se tornar ela: a política de confiança do seu papel de execução, que deve nomear só o '
        'serviço Lambda. À esquerda, quem pode chamá-la: a política baseada em recurso dela e o tipo '
        'de autenticação da URL de função. À direita, o que ela pode fazer: as políticas do papel de '
        'execução, que todo código dentro da função herda. Abaixo, o que ela carrega: o código, as '
        'dependências e as variáveis de ambiente, todos congelados no pacote publicado e na '
        'configuração dela.'))
    cx, cy = 360, 170
    f.rect(cx - 90, cy - 40, 180, 80, stroke='--phosphor', fill='--scan', width=1.6)
    f.text(cx, cy - 8, 'daily-export', size=12, mono=True)
    f.text(cx, cy + 14, T('the function', 'a função'), size=10, fill='--paper-dim', italic=True)
    boxes = [
        (cx - 130, 14, 260, 54, T('who may become it', 'quem pode se tornar ela'),
         T('the role\'s trust policy', 'a política de confiança do papel')),
        (16, cy - 34, 200, 68, T('who may call it', 'quem pode chamá-la'),
         T('resource policy, function URL', 'política de recurso, URL de função')),
        (504, cy - 34, 200, 68, T('what it may do', 'o que ela pode fazer'),
         T('the execution role\'s policies', 'as políticas do papel de execução')),
        (cx - 150, 272, 300, 54, T('what it carries', 'o que ela carrega'),
         T('code, dependencies, environment', 'código, dependências, ambiente')),
    ]
    for x, y, w, h, head, sub in boxes:
        f.rect(x, y, w, h, stroke='--amber', fill='--panel', width=1.3)
        f.text(x + w / 2, y + h / 2 - 9, head, size=11, weight='600')
        f.text(x + w / 2, y + h / 2 + 11, sub, size=9.5, fill='--paper-dim')
    f.arrow([(cx, 70), (cx, cy - 42)], stroke='--paper-dim')
    f.arrow([(218, cy), (cx - 92, cy)], stroke='--paper-dim')
    f.arrow([(cx + 92, cy), (502, cy)], stroke='--paper-dim')
    f.line(cx, cy + 42, cx, 270, stroke='--paper-dim', dash='4 3')
    return f, T('Four documents decide what one function is. A review that reads only the code has read '
                'one of them.',
                'Quatro documentos decidem o que é uma função. Uma revisão que lê só o código leu um deles.')
