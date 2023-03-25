
enum Event[r: Region, ef: Eff, a: Type](Region[r] -> Receiver[a, r] \ {ef, Impure})

def newEvent(rh: Region[r]): (Event[r, ef, a], Sender[a, r]) \ r = {
    let (tx, rx) = Channel.unbuffered(rh);
    let f = (_: Region[r]) -> checked_ecast(rx);
    let ev = Event.Event(f);

    (ev, tx)
}

def mapReceiver(rh: Region[r], f: a -> b \ ef, rx: Receiver[a, r]): Receiver[b, r] \ {ef, Impure} =
    let (tx, frx) = Channel.unbuffered(rh);

    println("Spawning mapped receiver");
    spawn (
        loop(_ ->
            let res = Channel.recv(rx);
            Channel.unsafeSend(f(res), tx)
        )
    ) @ rh;

    frx

def mapEvent(f: a -> b \ ef, ev: Event[r, ef, a]): Event[r, ef, b] = Event.Event(rh ->
    match ev {
        case Event.Event(e) => 
            let rx = e(rh);
            mapReceiver(rh, f, rx)
    }
)
