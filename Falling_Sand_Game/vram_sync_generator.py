f = open("vram.mem", "w")
f.truncate(0)
for i in range(0, 307200):
    if (i < 307200/2):
        f.write(f"1\n")
    else:
        f.write(f"0\n")
f.close()
