let initial_rank = 271. and matches = [(118., Some true); (142., Some true); (50., Some true); (257., Some true); (461., Some false)]
let () = print_float (initial_rank +. Variation.approx_variation initial_rank matches); print_newline ()

let _ = read_line ()
    
let () = Ladder.(get () |> print |> print_newline)
