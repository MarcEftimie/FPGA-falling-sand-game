import random
f = open("mem/vram.mem", "w")
f.truncate(0)
for i in range(0, 256000):
    if (i == 320):
        f.write(f"01\n")
    else:
        f.write("00\n")
f.close()

f = open("mem/zeros.mem", "w")
f.truncate(0)
for i in range(0, 256000):
    f.write("00\n")
f.close()
