let player_name = "Tu Linh Vu"
let matches =
  [("Ougier Guillaume", Some true);
   ("Frangi Manuel", Some true);
   ("Minieri Davide", Some true);
   ("Naegele Thibaud", Some true);
   ("Neirynck Lucas", Some false)]
let ladder = Ladder.get () |> Ladder.parse |> Lwt_main.run

let (initial_rank, new_rank) = Variation.tournament_results player_name matches ladder
let () = print_float initial_rank; print_newline (); print_float new_rank; print_newline ()
