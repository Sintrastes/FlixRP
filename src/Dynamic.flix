
enum Dynamic[r: Region, ef: Eff, a: Type](
    Event[r, ef, a], 
    Behavior[r, ef, a]
)

namespace Dynamic {
    /** Create a new Dynamic together with a sender that can be used to mutable update its values. */
    pub def createMutable(rh: Region[r], initialValue: a): (Dynamic[r, ef, a], Sender[a, r]) \ r = {
        let (ev, tx) = newEvent(rh);

        let xRef = ref initialValue @ rh;
        let bx = newBehavior(xRef);

        let d = Dynamic.Dynamic(ev, bx);

        (d, tx)
    }

    /** 
      * Create a Dynamic that emits the non-empty list of values, pausing for a specified duration
      *  in-between. 
      */
    pub def sequence(rh: Region[r], items: Nel[a], delay: Time/Duration): Dynamic[r, ef, a] \ {Impure, r} = match items {
        case Nel.Nel(initial, rest) =>
            let (dy, tx) = Dynamic.createMutable(rh, initial);

            spawn ({
                foreach(item <- initial :: rest) {
                    let _ = Channel.unsafeSend(item, tx);
                    Thread.sleep(delay)
                }
            }) @ rh;

            dy
    }

    pub def hold(rh: Region[r], value: a, event: Event[r, ef, a]): Dynamic[r, ef, a] = ???

    pub def fold(reducer: a -> b -> b, events: Event[r, ef, a], initial: b): Dynamic[r, ef, b] = ???

    pub def scan(): Dynamic[r, ef, a] = ???
}


// Functor instance for dynamic.
instance IxFunctor[Dynamic[r]] {
    pub def ixMap(
        f: a -> b \ ef, 
        dx: Dynamic[r, ef, a]
    ): Dynamic[r, ef, b] with Sendable[a], Sendable[b] = match dx {
        case Dynamic.Dynamic(Event.Event(ex), bx) => 
            let fbx = bx |> mapBehavior(f);
            let fex = Event.Event(r -> ex(r) |> mapReceiver(r, f));
            Dynamic.Dynamic(fex, fbx)
    }
}

instance IxApplicative[Dynamic[r]] {
    pub def ixAp(
        f: Dynamic[r, ef, a -> b \ ef], 
        x: Dynamic[r, ef, a]
    ): Dynamic[r, ef, b] with Sendable[a], Sendable[b] = match (f, x) {
        case (
            Dynamic.Dynamic(Event.Event(fe), Behavior.Behavior(fb)), 
            Dynamic.Dynamic(Event.Event(xe), Behavior.Behavior(xb))
        ) =>
            let fxb = _ -> fb()(xb());
            
            // Whenever either fe or xe fire,
            //  update fxe with the latest from fxb.
            let fxe = Event.Event(r ->
                let (tfx, rfx) = Channel.unbuffered(r);

                let fr = fe(r);
                let xr = xe(r);

                spawn (
                    loop(_ -> 
                        let fCurrent = Channel.recv(fr);
                        let xCurrent = xb();

                        Channel.send(fCurrent(xCurrent), tfx)
                    )
                ) @ r;

                spawn (
                    loop(_ -> 
                        let xCurrent = Channel.recv(xr);
                        let fCurrent = fb();

                        Channel.send(fCurrent(xCurrent), tfx)
                    )
                ) @ r;

                rfx
            );

            Dynamic.Dynamic(fxe, Behavior.Behavior(fxb))
    }
}

def mapDynamic(f: a -> b \ ef, dy: Dynamic[r, ef, a]): Dynamic[r, ef, b] = match dy {
    case Dynamic.Dynamic(ev, bh) => Dynamic.Dynamic(mapEvent(f, ev), mapBehavior(f, bh))
}

def dynReader(rh: Region[r], dy: Dynamic[r, ef, a]): Receiver[a, r] \ {Impure, r, ef} = match dy {
    case Dynamic.Dynamic(Event.Event(ev), _) =>
        ev(rh)
}
