import pickle

luafile = []

luafile.append("RES_MAPS = {")

for i in range(1, 36):
    d = []
    mf = open("../res/maps/" + str(i) + ".map", "rb")
    d = pickle.load(mf)
    mf.close()
    l = "{\n"
    c = 1
    for v in d:
        l += str(v) + ", "
        c += 1
        if c > 26:
            l += "\n"
            c -= 26
    l = l[:-3]
    l += "}"
    if i < 35:
        l += ","
    luafile.append(l)

luafile.append("}")

with open("../maps.lua", 'w') as f:
    for line in luafile:
        f.write(line)
        f.write('\n')
