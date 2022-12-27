let
    mkName =
        first:
        middle:
        last:
        let
            middleInitial = builtins.substring 0 1 middle;
        in {
            first = first;
            middle = middle;
            last = last;
            full = "${first} ${middleInitial}. ${last}";
            long = "${first} ${middle} ${last}";
            short = "${first} ${last}";
        };
    mkUser =
        username:
        {
            name = mkName "Travis" "Allen" "Everett";
            email = "travis.a.everett@gmail.com";
            handle = username;
        };
in {
    mkUser = mkUser;
}
