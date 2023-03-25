
/** Prints the values of a dynamic to the console as they update. */
def printToConsole(rh: Region[r], values: Dynamic[r, ef, a]): Unit \ {Impure, ef} with ToString[a] = {
    let reader = dynReader(rh, values);

    spawn (
       loop(_ ->
            let dynValue = Channel.recv(reader);
            println(dynValue)
        )
    ) @ rh
}
