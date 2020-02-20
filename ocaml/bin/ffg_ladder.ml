(* Very basic command line program to compute rank variations in the ffg ladder after a tournament *)

open Base
open Cohttp_lwt_unix

let (>>=) = Lwt.(>>=)
let (>|=) = Lwt.(>|=)

let player_name = ref "" and opponents = ref "" and n = ref 0
let usage_msg =
  "Usage: ffg_ladder \"player_name\" \"opponent_1[+|],opponent_2[+|],...\"\n"
  ^ "where + stands for a win, and nothing for a loss.\n"
  ^ "You may replace a name by a prefix, which will be searched in the ladder."
  ^ "Example: ffg_ladder \"Dumont\" \"Blanc Mau+,Dupont Estelle,Fill,Marlet+\""

let () = if Array.length (Sys.get_argv ()) - 1 <> 2 then (Caml.Arg.usage [] usage_msg; Caml.exit 0)

let parse_args s =
  let () = match !n with
  | 0 -> player_name := s
  | 1 -> opponents := s
  | _ -> assert false in
  n := !n + 1

let () = Caml.Arg.parse [] parse_args usage_msg

(* to decode the ladder text file, which is latin-1 encoded. *)
let latin1_to_utf8 str =
  let rec loop dec buf = match Uutf.decode dec with
    | `Uchar u -> Uutf.Buffer.add_utf_8 buf u; loop dec buf
    | `End -> Buffer.contents buf
    | `Malformed _ -> Uutf.Buffer.add_utf_8 buf Uutf.u_rep; loop dec buf
    | `Await -> assert false in
  loop (Uutf.decoder ~encoding:`ISO_8859_1 (`String str)) (Buffer.create 512)

(* fetch ladder data *)
let ladder =
  Client.get (Uri.of_string "http://ffg.jeudego.org/echelle/echtxt/ech_ffg_V3.txt") >>= fun (_, body) ->
  Cohttp_lwt.Body.to_string body
  >|= latin1_to_utf8
  >|= Ladder.parse
        
let results =
  String.split ~on:',' !opponents
  |> List.map ~f:begin fun s ->
    let len = String.length s in
    match s.[len - 1] with
    | '+' -> (String.sub s ~pos:0 ~len:(len - 1), Some true)
    | '=' -> (String.sub s ~pos:0 ~len:(len - 1), None)
    | _ -> (s, Some false)
  end

(* Select players that have several matches in the ladder. *)
let ladder = Lwt_main.run ladder

let select_player name =
  let (name, _) =
    match Ladder.find ladder name ~limit:20 with
    | [] -> raise (Failure ("Player not found: " ^ name))
    | [e] -> e
    | l ->
      let options = List.mapi l ~f:(fun i (name, rank) ->
          Printf.sprintf "%d. %s (%.0f)" i name rank) in
      let index =
        Stdio.printf "\nSelect player corresponding to name \"%s\":\n" name;
        List.iter options ~f:Stdio.print_endline;
        Caml.read_int () in
      match List.nth l index with
      | None -> raise (Failure ("Player not found: " ^ name))
      | Some e -> e in
  name

let () = player_name := select_player !player_name
let results = results |> List.map ~f:begin fun (name, result) -> (select_player name, result) end
                
(* Run simulation. *)
let (initial_rank, new_rank, opponent_ranks, variations) = Variation.tournament_results !player_name results ladder

(* print output *)
let () = Stdio.printf "\nInitial rank for %s: %.0f\n" !player_name initial_rank
let data = List.zip_exn opponent_ranks variations |> List.zip_exn results
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
let () = print_output 0 data
let () = Stdio.printf "New rank: %.0f -- global variation: %.2f\n" new_rank Float.(new_rank - initial_rank)
