open Base

type color = Black | White
type match_result = color option

let parameters rank =
  let rec process = function
    | [] -> failwith "Variance and dilatation parameters are empty."
    | [(_, con, a)] -> (con, a)
    | (level, con, a) :: t -> if Float.(level <= rank) then (con, a) else process t in
  process (List.rev Parameters_.parameters)
    
let match_variation w_rank b_rank handicap result =
  let open Float in
  let w_frank = w_rank in
  let b_frank = if handicap = 0. then b_rank else b_rank +. 100. *. (handicap -. 0.5) in
  let rank_diff = abs (b_frank -. w_frank) in
  let variation strong weak strong_won = 
    let epsilon = Parameters_.epsilon in
    let (con_weak, a_weak) = parameters weak in
    let (con_strong, _) = parameters strong in
    let p_weak = 1. /. (exp (rank_diff /. a_weak) +. 1.) -. epsilon /. 2. in
    let p_strong = 1. -. epsilon -. p_weak in
    match strong_won with
    | None -> (con_strong *. (0.5 -. p_strong), con_weak *. (0.5 -. p_weak))
    | Some true -> (con_strong *. (1. -. p_strong), con_weak *. (0. -. p_weak))
    | Some false -> (con_strong *. (0. -. p_strong), con_weak *. (1. -. p_weak)) in
  let (strong, weak) = if b_frank > w_frank then (b_frank, w_frank) else (w_frank, b_frank) in
  let strong_won = match result with
    | None -> None
    | Some Black -> Some (b_frank > w_frank)
    | Some White -> Some (w_frank > b_frank) in
  let (var_strong, var_weak) = variation strong weak strong_won in
  if b_frank > w_frank then (var_weak, var_strong) else (var_strong, var_weak)
                                                        
let new_ranks_match w_rank b_rank handicap result =
  let (varw, varb) = match_variation w_rank b_rank handicap result in
  (w_rank +. varw, b_rank +. varb)
  
let rec new_rank_matches initial_rank = function
  | [] -> initial_rank
  | (opponent_rank, result) :: t ->
     let result = match result with
       | None -> None
       | Some bool -> if bool then Some White else Some Black in
     let (rank, _) = new_ranks_match initial_rank opponent_rank 0. result in
     new_rank_matches rank t
                                            
let tournament_results player_name results ladder =
  let get_rank name = match Map.find ladder name with
    | Some (rank : float) -> rank
    | None -> raise (Failure ("Couldn't find rank of: " ^ name)) in
  let initial_rank = get_rank player_name in
  let new_rank =
    results
    |> List.map ~f:(fun (name, result) -> (get_rank name, result))
    |> new_rank_matches initial_rank in
  (initial_rank, new_rank)
  
