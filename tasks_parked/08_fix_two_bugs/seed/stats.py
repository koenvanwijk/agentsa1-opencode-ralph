def mean(xs):
    # BUG: divides by the wrong count
    return sum(xs) / (len(xs) + 1)


def var(xs):
    # BUG: uses 0 instead of the mean as the center
    m = 0
    return sum((x - m) ** 2 for x in xs) / len(xs)


if __name__ == "__main__":
    print(mean([1, 2, 3, 4]), var([1, 2, 3, 4]))
