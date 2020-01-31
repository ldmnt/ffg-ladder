(* Functions to compute the rank variations after a match or a tournament
   based on the algorithm used by the ffg ladder:
   http://ffg.jeudego.org/echelle/echelle_algo.php
   
   The main entry point is the function `tournament_results` and the heavy
   work is done in `match_variation` *)

open Base

type color = Black | White
type match_result = color option


let match_variation w_rank b_rank handicap result =
  (* The variation is computed based on virtual ranks (depending on handicap). *)
  let open Float in
  let w_frank = w_rank in
  let b_frank = if handicap = 0. then b_rank else b_rank + 100. * (handicap - 0.5) in
  let rank_diff = abs (b_frank - w_frank) in
  let variation strong weak strong_won = 
    let epsilon = Parameters_.epsilon in
    let (con_weak, a_weak) = Parameters_.get weak in
    let (con_strong, _) = Parameters_.get strong in
    let p_weak = 1. / (exp (rank_diff / a_weak) + 1.) - epsilon / 2. in
    let p_strong = 1. - epsilon - p_weak in
    match strong_won with
    | None -> (con_strong * (0.5 - p_strong), con_weak * (0.5 - p_weak))
    | Some true -> (con_strong * (1. - p_strong), con_weak * (0. - p_weak))
    | Some false -> (con_strong * (0. - p_strong), con_weak * (1. - p_weak)) in
  let (strong, weak) = if b_frank > w_frank then (b_frank, w_frank) else (w_frank, b_frank) in
  let strong_won = match result with
    | None -> None
    | Some Black -> Some (b_frank > w_frank)
    | Some White -> Some (w_frank > b_frank) in
  let (var_strong, var_weak) = variation strong weak strong_won in
  let (varw, varb) = if b_frank > w_frank then (var_weak, var_strong) else (var_strong, var_weak) in
  
  (* adjust variations by taking into account the handicap factor, unless the rank is less than -2000 *)
  let factor rank = if rank < -2000. then 1. else (1. - handicap / 10.) in
  let fact_w = factor w_rank and fact_b = factor b_rank in
  let varw = fact_w * varw in
  let varb = fact_b * varb in
  
  (* if white lost in a handicap game, variation is reduced even further *)
  let white_lost = match result with | Some Black -> true | _ -> false in
  let varw = if handicap > 0. && white_lost then fact_w * varw else varw in
  (varw, varb)

                                                        
let new_ranks_one_match w_rank b_rank handicap result =
  let (varw, varb) = match_variation w_rank b_rank handicap result in
  (w_rank +. varw, b_rank +. varb)


(* Computes the variations and rank update after a series of matches. Restricted for now (because I was lazy) 
   to only even games (therefore color does not matter and results are encoded as bool options). *)
let new_rank_matches initial_rank results =
  let rec loop initial_rank variations = function
    | [] -> (initial_rank, List.rev variations)
    | (opponent_rank, result) :: t ->
       let result = match result with
         | None -> None
         | Some bool -> if bool then Some White else Some Black in
       let (rank, _) = new_ranks_one_match initial_rank opponent_rank 0. result in
       let var = rank -. initial_rank in
       loop rank (var :: variations) t in
  loop initial_rank [] results


let tournament_results player_name results ladder =
  let get_rank name = match Trie.find ladder name with
    | Some rank -> rank
    | None -> raise (Failure ("Couldn't find rank of: " ^ name)) in
  let (names, results) = List.unzip results in
  let opponent_ranks = List.map ~f:get_rank names and initial_rank = get_rank player_name in
  let (new_rank, variations) = new_rank_matches initial_rank (List.zip_exn opponent_ranks results) in
  (initial_rank, new_rank, opponent_ranks, variations)
