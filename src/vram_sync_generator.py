f = open("mem/vram.mem", "w")
f.truncate(0)
for i in range(0, 307200):
    if (i == 320):
        f.write(f"1\n")
    else:
        f.write(f"0\n")
f.close()
