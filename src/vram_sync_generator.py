import random
f = open("mem/vram.mem", "w")
f.truncate(0)
for i in range(0, 256000):
    if (i == 320):
        f.write(f"11\n")
    else:
        f.write("00\n")
f.close()
