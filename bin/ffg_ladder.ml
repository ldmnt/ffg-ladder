let player_name = "Tu Linh Vu"
let matches =
  [("Ougier Guillaume", Some true);
   ("Kunne Stéphan", Some true);
   ("Minieri Davide", Some true);
   ("Naegele Thibaud", Some true);
   ("Neirynck Lucas", Some false)]
let ladder = Ladder.get () |> Ladder.parse |> Lwt_main.run

let (initial_rank, new_rank, opponent_ranks, variations) = Variation.tournament_results player_name matches ladder
let () =
  print_float initial_rank; print_newline ();
  print_float new_rank; print_newline ();
  List.iter (fun x -> print_float x; print_char ' ') opponent_ranks; print_newline ();
  List.iter (fun x -> print_float x; print_char ' ') variations; print_newline ();
  
