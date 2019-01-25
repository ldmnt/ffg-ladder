(* Very basic command line program to compute rank variations in the ffg ladder after a tournament *)

open Base

let player_name = ref "" and opponents = ref "" and n = ref 0
let usage_msg =
  "Usage: ffg_ladder \"player_name\" \"opponent_1[+|=|],opponent_2[+|=],...\"\n"
  ^ "where + stands for a win, = for a draw, and nothing for a loss\n"
  ^ "Example: ffg_ladder \"Dumont Louis\" \"Blanc Maurice+,Dupont Estelle,Fillet Chloé=,Marlet André+\""

let parse_args s =
  let () = match !n with
  | 0 -> player_name := s
  | 1 -> opponents := s
  | _ -> Caml.Arg.usage [] usage_msg in
  n := !n + 1

let () = Caml.Arg.parse [] parse_args usage_msg

(* Fetch ladder data *)
let ladder = Ladder.get () |> Ladder.parse
let results =
  String.split ~on:',' !opponents
  |> List.map ~f:begin fun s ->
    let len = String.length s in
    match s.[len - 1] with
    | '+' -> (String.sub s ~pos:0 ~len:(len - 1), Some true)
    | '=' -> (String.sub s ~pos:0 ~len:(len - 1), None)
    | _ -> (s, Some false)
  end

(* main *)
let ladder = Lwt_main.run ladder
let (initial_rank, new_rank, opponent_ranks, variations) = Variation.tournament_results !player_name results ladder

(* print output *)
let () = Stdio.printf "Initial rank for %s: %.0f\n" !player_name initial_rank
let data = Option.(List.zip opponent_ranks variations >>= List.zip results)
let rec print_output i data =
  match data with
  | [] -> ()
  | ((name, result), (opp_rank, var)) :: t ->
    let result_str = match result with
      | Some true -> "win"
      | Some false -> "loss"
      | None -> "draw" in
    Stdio.printf "Match %d -- opponent: %s (%.0f) -- %s -- variation: %.2f\n"
      i name opp_rank result_str var;
    print_output (i + 1) t
let () = match data with
  | Some l -> print_output 0 l
  | None -> assert false
let () = Stdio.printf "New rank: %.0f -- global variation: %.2f\n" new_rank Float.(new_rank - initial_rank)
