
/** Utility to perform an action in a loop. */
def loop(f: Unit -> Unit \ e): Unit \ e =
    f();
    loop(f)

class IxFunctor[f: Eff -> Type -> Type] {
    pub def ixMap(f: a -> b \ ef, bx: f[ef, a]): f[ef, b] with Sendable[a], Sendable[b]
}

class IxApplicative[f: Eff -> Type -> Type] {
    pub def ixAp(
        cf: f[ef, a -> b \ ef],
        cx: f[ef, a]
    ): f[ef, b] with Sendable[a], Sendable[b]
}

