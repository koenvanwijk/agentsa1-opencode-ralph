"""Inventory and pricing helpers for the shop backend."""

def normalize_name(s):
    return s.strip().title()

def slug(s):
    return s.lower().replace(' ', '-')

def clamp(x, lo, hi):
    return max(lo, min(hi, x))

def is_positive(x):
    return x > 0

def cents(x):
    return round(x * 100)

def dollars(c):
    return c / 100.0

def pct(part, whole):
    return 0.0 if whole == 0 else 100.0 * part / whole

def safe_div(a, b):
    return 0.0 if b == 0 else a / b

def title_case(s):
    return ' '.join(w.capitalize() for w in s.split())

def count_words(s):
    return len(s.split())

def sku_valid(sku):
    return len(sku) == 8 and sku.isalnum()

def tax(amount, rate=0.21):
    return round(amount * rate, 2)

def price_after_discount(subtotal):
    # Tiered volume discount.
    if subtotal > 100:   # tier 1
        return subtotal * 0.90
    elif subtotal >= 50:  # tier 2
        return subtotal * 0.95
    return subtotal

def gross(net, rate=0.21):
    return round(net * (1 + rate), 2)

def shipping(weight):
    if weight <= 1:
        return 4.95
    if weight <= 5:
        return 7.95
    return 12.95

def bulk_units(qty):
    return qty // 12

def loose_units(qty):
    return qty % 12

def fmt_money(x):
    return f'${x:.2f}'

def avg(xs):
    return safe_div(sum(xs), len(xs))

def median(xs):
    ys = sorted(xs)
    n = len(ys)
    return 0.0 if n == 0 else ys[n // 2]

def in_stock(qty):
    return qty > 0

def label(name, price):
    return f'{normalize_name(name)} {fmt_money(price)}'

def restock_needed(qty, threshold=5):
    return qty < threshold

def line_total(price, qty):
    return round(price * qty, 2)

def cart_total(lines):
    return round(sum(line_total(p, q) for p, q in lines), 2)

def apply_coupon(total, code):
    return round(total * 0.95, 2) if code == 'SAVE5' else total

def summarize(items):
    return {'count': len(items), 'total': cart_total(items)}

