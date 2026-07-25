"""Argparse-based CLI entry point for simple_ci_app."""

import argparse
import sys
from typing import Optional, Sequence

from .calculator import add, divide, multiply, subtract

OPERATIONS = {
    "add": add,
    "subtract": subtract,
    "multiply": multiply,
    "divide": divide,
}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="simple-ci-app", description="Tiny calculator CLI")
    parser.add_argument("operation", choices=sorted(OPERATIONS))
    parser.add_argument("x", type=float)
    parser.add_argument("y", type=float)
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = build_parser().parse_args(argv)
    operation = OPERATIONS[args.operation]
    try:
        result = operation(args.x, args.y)
    except ZeroDivisionError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
