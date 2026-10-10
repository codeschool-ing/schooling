"""Lesson 14: Agenda's hiring funnel."""
from figures import Fig, T, figure


@figure('l14-funnel', 14)
def funnel():
    f = Fig('l14-funnel', 720, 310, T(
        'A funnel of six stages for Caju’s mid-level hire, each bar narrower than the one above. '
        'Applications: 240. CV screen: 60. Recruiter call: 30. Technical interview: 15. Final '
        'interviews: 6. Offers: 2. At the bottom, one accepted offer. The narrowest step relative '
        'to its width is the final interviews, where 6 became 2.',
        'Um funil de seis etapas para a contratação de pleno da Caju, cada barra mais estreita que a '
        'de cima. Candidaturas: 240. Triagem de currículos: 60. Conversa com recrutamento: 30. '
        'Entrevista técnica: 15. Entrevistas finais: 6. Propostas: 2. No fim, uma proposta aceita. '
        'O passo mais estreito em relação à largura é o das entrevistas finais, em que 6 viraram 2.'))
    stages = [(T('applications', 'candidaturas'), 240), (T('CV screen', 'triagem'), 60),
              (T('recruiter call', 'conversa com recrutamento'), 30),
              (T('technical interview', 'entrevista técnica'), 15),
              (T('final interviews', 'entrevistas finais'), 6), (T('offers', 'propostas'), 2)]
    cx, maxw, top, h = 330, 420, 20, 36
    import math
    for i, (name, n) in enumerate(stages):
        w = 40 + (maxw - 40) * math.sqrt(n / 240)
        y = top + i * (h + 6)
        col = '--phosphor' if i < 4 else '--amber'
        f.rect(cx - w / 2, y, w, h, stroke=col, fill='--panel', width=1.4, rx=3)
        f.text(cx, y + h / 2, str(n), size=13, weight='600', mono=True)
        f.text(cx + maxw / 2 + 20, y + h / 2, name, size=11.5, anchor='start')
    y = top + 6 * (h + 6)
    f.circle(cx, y + 12, 10, fill='--phosphor')
    f.text(cx, y + 12, '1', size=11, weight='600', fill='--ink')
    f.text(cx + maxw / 2 + 20, y + 12, T('accepted', 'aceita'), size=11.5, anchor='start',
           weight='600')
    f.text(20, top + 2 * (h + 6), T('width scaled by', 'largura proporcional'), size=10,
           anchor='start', fill='--paper-dim', italic=True)
    f.text(20, top + 2 * (h + 6) + 14, T('the square root', 'à raiz quadrada'), size=10,
           anchor='start', fill='--paper-dim', italic=True)
    return f, T('One hire from 240 applications. Caju’s numbers for a fictional role, so the arithmetic has something to work on.',
                'Uma contratação a partir de 240 candidaturas. Números da Caju para uma vaga fictícia, para a conta ter com o que trabalhar.')
