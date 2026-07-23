def dedup(xs):
    # BUG: using a set loses the original first-seen order.
    return list(set(xs))


if __name__ == "__main__":
    print(dedup([3, 1, 3, 2, 1, 2]))
