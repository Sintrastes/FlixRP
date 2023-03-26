
def main(): Unit \ { IO } = region r {
    let dy = Dynamic.sequence(r, 
        Nel.Nel(0, 1 :: 2 :: 3 :: 4 :: 5 :: Nil), 
        Time/Duration.fromSeconds(1)
    );

    let dy2 = dy |> 
        mapDynamic(x -> x + 2);

    let dy3 = dy |>
        mapDynamic(_ -> y -> y + 3);

    let dy4 = IxApplicative.ixAp(dy3, dy2);

    printToConsole(r, dy4)
}