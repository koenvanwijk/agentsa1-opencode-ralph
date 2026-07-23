def slugify(s):
    return s.strip().lower().replace(" ", "-")


def greeting(name):
    return f"Hello, {name}!"


if __name__ == "__main__":
    print(slugify("Hello World"))
    print(greeting("Koen"))
