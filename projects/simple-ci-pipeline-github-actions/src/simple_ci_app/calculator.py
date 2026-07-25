"""Pure calculator functions used to give the CI pipeline something real to build and test."""


def add(x: float, y: float) -> float:
    """Return x + y."""
    return x + y


def subtract(x: float, y: float) -> float:
    """Return x - y."""
    return x - y


def multiply(x: float, y: float) -> float:
    """Return x * y."""
    return x * y


def divide(x: float, y: float) -> float:
    """Return x / y. Raises ZeroDivisionError when y is 0."""
    if y == 0:
        raise ZeroDivisionError("division by zero is not allowed")
    return x / y
