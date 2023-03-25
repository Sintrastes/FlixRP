
def loop(f: Unit -> Unit \ e): Unit \ e =
    f();
    loop(f)

