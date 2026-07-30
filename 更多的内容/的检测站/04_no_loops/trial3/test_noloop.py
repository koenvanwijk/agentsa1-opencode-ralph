from noloop import total

# Test 1: Empty list
assert total([]) == 0, "Empty list should return 0"

# Test 2: Single element
assert total([5]) == 5, "Single element should return itself"

# Test 3: Multiple positive numbers
assert total([1, 2, 3, 4]) == 10, "Sum of 1,2,3,4 should be 10"

# Test 4: Negative numbers
assert total([-1, -2, -3]) == -6, "Sum of -1,-2,-3 should be -6"

# Test 5: Mixed positive/negative
assert total([10, -5, 3]) == 8, "Sum of 10,-5,3 should be 8"

# Test 6: Floats
assert total([1.5, 2.5]) == 4.0, "Sum of 1.5,2.5 should be 4.0"

print("All tests passed!")
