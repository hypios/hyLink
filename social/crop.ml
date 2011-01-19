module type INTERFACE = sig

    val resize_width : Ocsigen_lib.file_info -> int -> string Lwt.t

  end

module IMPLEMENTATION = struct

(*
 * hyLink - fpgg
 *
 * crop.ml - croping uploaded images
 *
 * William Le Ferrand william@hypios.com
 *
 *)

open Printf
open Lwt

open Misc

let resize_width file size =
  let imgin = Eliom_sessions.get_tmp_filename file in
  let imgout, uri = Storage.fresh_copy file in
  Lwt_process.exec (Params.imagemagick, [| "convert"; imgin; "-resize"; sprintf "%d" size; imgout |])
  >>= fun _ -> return uri

let _ =
	debug' "shared/crop.ml loaded\n"

end

include (IMPLEMENTATION : INTERFACE)
  
