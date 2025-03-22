import random

c_val = int(input("What's the current value for SPX? "))
entry = random.randint(c_val - 10, c_val + 10)
print("\U0001F414 says the entry will be " + str(entry))
exit = random.randint(c_val - 20, c_val + 20)
print("\U0001F414 says the exit will be " + str(exit))
pos = random.choice(["long", "short"])
print("\U0001F414 says we will be " + pos)
