import datetime

from ci.gate import BREAK, PASS, WARN, judge

DAY = datetime.date(2026, 10, 14)
FIXED = {"id": "PYSEC-1", "fix_versions": ["1.1"]}
UNFIXED = {"id": "PYSEC-2", "fix_versions": []}


def verdict(vulns, exceptions=""):
    audit = {"dependencies": [{"name": "pkg", "version": "1.0", "vulns": vulns}]}
    return judge(audit, exceptions, DAY)[0]


def test_a_fix_nobody_applied_breaks_the_build():
    assert verdict([FIXED]) == BREAK


def test_an_advisory_with_no_fix_warns():
    assert verdict([UNFIXED]) == WARN


def test_an_exception_holds_until_its_date():
    assert verdict([FIXED], "PYSEC-1 2026-12-31 the vendor's fix is due in November") == PASS


def test_an_exception_close_to_its_date_warns():
    assert verdict([FIXED], "PYSEC-1 2026-10-16 the vendor's fix is due in November") == WARN


def test_an_expired_exception_breaks_the_build_again():
    assert verdict([FIXED], "PYSEC-1 2026-10-13 the vendor's fix is due in November") == BREAK
