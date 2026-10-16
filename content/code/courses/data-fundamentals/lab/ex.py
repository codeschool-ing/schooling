"""The builders lab/exercises/*.py write questions with. See exgen.py."""


def C(en, pt, why_en, why_pt, ok=False):
    return {'en': en, 'pt': pt, 'why_en': why_en, 'why_pt': why_pt, 'ok': ok}


def _p(x):
    return x if isinstance(x, tuple) else (x, x)


def Q(id, section, diff, prompt, hint, *choices, kind='quiz'):
    return {'id': id, 'section': section, 'type': kind, 'difficulty': diff,
            'prompt': _p(prompt), 'hint': _p(hint), 'choices': list(choices)}


def MC(id, section, diff, prompt, hint, *choices):
    return Q(id, section, diff, prompt, hint, *choices, kind='multiple-choice')


def N(id, section, diff, prompt, hint, value, tolerance, unit):
    return {'id': id, 'section': section, 'type': 'numeric', 'difficulty': diff,
            'prompt': _p(prompt), 'hint': _p(hint), 'value': value, 'tolerance': tolerance,
            'unit': _p(unit)}


def Z(id, section, diff, prompt, hint, accept_en, accept_pt, ignore_case=True):
    return {'id': id, 'section': section, 'type': 'cloze', 'difficulty': diff,
            'prompt': _p(prompt), 'hint': _p(hint), 'accept': (accept_en, accept_pt),
            'ignore_case': ignore_case}


def O(id, section, diff, prompt, hint, items, trap):
    return {'id': id, 'section': section, 'type': 'ordering', 'difficulty': diff,
            'prompt': _p(prompt), 'hint': _p(hint), 'items': [_p(i) for i in items],
            'trap': _p(trap)}


def M(id, section, diff, prompt, hint, pairs):
    return {'id': id, 'section': section, 'type': 'matching', 'difficulty': diff,
            'prompt': _p(prompt), 'hint': _p(hint),
            'pairs': [(_p(l), _p(r)) for l, r in pairs]}
