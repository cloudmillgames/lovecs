import pickle

luafile = []

luafile.append("RES_MAPS = {")

skip = [1, 2, 13, 14, 25, 26]

for i in range(1, 36):
    d = []
    mf = open("../res/maps/" + str(i) + ".map", "rb")
    d = pickle.load(mf)
    mf.close()
    l = "{\n"
    c = 1
    lc = 0
    for v in d:
        l += str(v) + ", "
        lc+=1
        if not c in skip:
            l += str(v) + ", "
            lc+=1
        c += 1
        if c > 26:
            #if i == 1:
                #print("LINE LEN = " + str(lc))
            lc = 0
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
