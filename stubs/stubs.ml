open Base
open Js_of_ocaml


let ladder : float Trie.t ref = ref Trie.empty

let load_ladder ladder_str =
  ladder := ladder_str
  |> Js.to_string
  |> Ladder.parse;
  Js.undefined

let complete_name name =
  Ladder.find !ladder (Js.to_string name) ~limit:10
  |> Array.of_list
  |> Array.map ~f:(fun (s, r) ->
      object%js
        val name = Js.string s
        val rank = Js.number_of_float r
      end)
  |> Js.array

let new_rank_matches initial_rank matches =
  let matches =
    matches
    |> Js.to_array
    |> Array.map ~f:(fun m -> (Js.float_of_number m##.opponentRank, Some (Js.to_bool m##.result)))
    |> Array.to_list in
  let (new_rank, variations) = Variation.new_rank_matches (Js.float_of_number initial_rank) matches in
  object%js
    val newRank = Js.number_of_float new_rank
    val variations = variations
                     |> Array.of_list
                     |> Array.map ~f:Js.number_of_float
                     |> Js.array
  end

let () =
  Js.export_all
    (object%js
      method loadLadder = load_ladder 
      method completeName = complete_name
      method newRankMatches = new_rank_matches
    end)
