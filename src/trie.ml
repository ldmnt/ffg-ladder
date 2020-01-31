open Base

type 'a t = Node of 'a option * (Char.t, 'a t, Char.comparator_witness) Map.t

let project = String.lowercase

let empty = Node (None, Map.empty (module Char))

let find tree key =
  let rec find tree key =
    match (tree, key) with
    | Node (value, _), [] -> value
    | Node (_, children), hd :: tl ->
      match Map.find children hd with
      | None -> None
      | Some tree -> find tree tl in
  key |> project |> String.to_list |> find tree

let add tree key value =
  let rec aux tree key =
    match (tree, key) with
    | Node (_, children), [] -> Node (Some value, children)
    | Node (v, children), hd :: tl ->
      let new_child = match Map.find children hd with
        | None -> empty
        | Some tree -> tree in
      let new_child = aux new_child tl in
      Node (v, Map.set children ~key:hd ~data:new_child) in
  key |> project |> String.to_list |> aux tree

let iter tree ~f =
  let rec aux (Node (value, children)) key =
    begin
      match value with
      | None -> ()
      | Some v ->
        let key = key |> List.rev |> String.of_char_list in
        f key v
    end;
    Map.iteri children
      ~f:(fun ~key:c ~data:tree -> aux tree (c :: key)) in
  aux tree []

let to_alist tree =
  let rec aux (Node (value, children)) key acc =
    let acc = match value with
      | None -> acc
      | Some v ->
        let key = key |> List.rev |> String.of_char_list in
        (key, v) :: acc in
    Map.fold children ~init:acc
      ~f:(fun ~key:k ~data:v a -> aux v (k :: key) a) in
  List.rev (aux tree [] [])

let take tree n = List.take (to_alist tree) n

let find_prefix tree p ~limit =
  let rec aux tree p = match (tree, p) with
    | tree, [] -> take tree limit
    | (Node (_, children), hd :: tl) ->
      match Map.find children hd with
      | None -> []
      | Some child -> aux child tl in
  let p_list = p |> project |> String.to_list in
  aux tree p_list
  |> List.map ~f:(fun (k, v) -> (p ^ k, v))

let of_alist lst =
  List.fold lst ~init:empty
    ~f:(fun t (k, v) -> add t k v)



