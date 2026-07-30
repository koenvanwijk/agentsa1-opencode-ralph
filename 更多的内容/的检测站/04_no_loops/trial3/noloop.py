def total(xs):
    if xs == []:
        return 0
    return xs[0] + total(xs[1:])
