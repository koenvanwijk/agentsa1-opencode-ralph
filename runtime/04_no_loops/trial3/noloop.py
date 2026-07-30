def total(xs):
    if not xs:
        return 0
    return xs[0] + total(xs[1:])


if __name__ == "__main__":
    # Test cases
    assert total([]) == 0
    assert total([1, 2, 3]) == 6
    assert total([5]) == 5
    assert total([-1, 1, -2, 2]) == 0
    assert total([1.5, 2.5]) == 4.0
    print("All tests passed!")
