open Lwt
open Cohttp_lwt_unix

let get () =
  Client.get (Uri.of_string "http://ffg.jeudego.org/echelle/echtxt/ech_ffg_V3.txt") >>= fun (_, body) ->
  Cohttp_lwt.Body.to_string body

let print ladder =
  let ladder = Lwt_main.run ladder in
  print_endline ladder
