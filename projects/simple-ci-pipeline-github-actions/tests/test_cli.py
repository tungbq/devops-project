import pytest

from simple_ci_app.cli import main


def test_cli_add(capsys):
    exit_code = main(["add", "2", "3"])
    captured = capsys.readouterr()
    assert exit_code == 0
    assert captured.out.strip() == "5.0"


def test_cli_divide_by_zero(capsys):
    exit_code = main(["divide", "1", "0"])
    captured = capsys.readouterr()
    assert exit_code == 1
    assert "division by zero" in captured.err


def test_cli_invalid_operation():
    with pytest.raises(SystemExit):
        main(["power", "2", "3"])
