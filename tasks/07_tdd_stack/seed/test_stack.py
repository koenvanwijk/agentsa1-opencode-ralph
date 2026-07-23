from stack import Stack


def test_stack_behaviour():
    s = Stack()
    assert s.is_empty() is True
    s.push(1)
    s.push(2)
    s.push(3)
    assert len(s) == 3
    assert s.peek() == 3
    assert s.is_empty() is False
    assert s.pop() == 3
    assert s.pop() == 2
    assert len(s) == 1
    assert s.pop() == 1
    assert s.is_empty() is True
