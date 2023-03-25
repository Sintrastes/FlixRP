
enum Behavior[r: Region, ef: Eff, a: Type](Unit -> a \ {r, ef})

// An example of creating a behavior from a reference.
def newBehavior(x: Ref[a, r]): Behavior[r, ef, a] = Behavior.Behavior(_ ->
    checked_ecast(deref x)
)

def mapBehavior(
    f: a -> b \ ef, 
    bx: Behavior[r, ef, a]
): Behavior[r, ef, b] = match bx {
    case Behavior.Behavior(x) => Behavior.Behavior(_ ->
        f(x())   
    )
}

/*
instance IxFunctor[Behavior[r]] {
    pub def ixMap(
        f: a -> b \ ef, 
        bx: Behavior[r, ef, a]
    ): Behavior[r, ef, b] with Sendable[a], Sendable[b] = match bx {
        case Behavior.Behavior(x) => Behavior.Behavior(_ ->
            f(x())   
        )
    }
}
*/
