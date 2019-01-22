open Base
open Lwt
open Cohttp_lwt_unix

let get () =
  Client.get (Uri.of_string "http://ffg.jeudego.org/echelle/echtxt/ech_ffg_V3.txt") >>= fun (_, body) ->
  Cohttp_lwt.Body.to_string body

let print ladder =
  let ladder = Lwt_main.run ladder in
  Stdio.print_endline ladder

(* helper function that extracts a tuple (last name + first name, rank) from one line of the ladder file *)
let parse_line line =
  let max = String.length line in
  let rec loop left_idx right_idx out =
    if right_idx >= max then
      let word = String.sub line ~pos:left_idx ~len:(right_idx - left_idx) in
      word :: out
    else
      match line.[right_idx] with
      | ' ' ->
        if right_idx = left_idx then
          loop (right_idx + 1) (right_idx + 1) out
        else
          let word = String.sub line ~pos:left_idx ~len:(right_idx - left_idx) in
          loop (right_idx + 1) (right_idx + 1) (word :: out)
      | _ -> loop left_idx (right_idx + 1) out in
  let words =
    List.rev (loop 0 0 [])
    |> List.map ~f:
      begin String.map ~f:
          begin function
            | '_' -> ' '
            | c -> c
          end
      end
    |> Array.of_list in
    (words.(0) ^ " " ^ words.(1), Float.of_string words.(2))

let parse ladder =
  ladder >|= fun ladder ->
  ladder
  |> String.split_lines
  |> List.tl
  |> begin function
    | None -> assert false
    | Some l -> l end
  |> List.map ~f:parse_line
  |> Map.of_alist_reduce (module String.Caseless) ~f:(fun x _ -> x)
    
