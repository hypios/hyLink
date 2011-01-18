(*
 * hyLink - cdj
 *
 * register.ml - extra registering functions
 *
 * Fabrice Le Fessant Fabrice.Le_fessant@inria.fr
 *
 *)

 open Lwt
 open Json_type

 open Eliom_services

 open Profile

 open Misc

 (* no cache trick *)

 open Http_headers

 let (<<<) h (n, v) = replace n v h

 (* Cache-Control: no-cache, *)
 let no_cache = dyn_headers <<< (name "Cache-Control", "no-cache")

 (* preapply Service.Frontend.home (Some 1, None) *)
 let anonymous_default_page = ref None
 (*  preapply Service.Frontend.profile_about (profile.user_id, ()) *)
 let profile_default_page = ref None

 let set_anonymous_default_page s =
   anonymous_default_page := Some s
 let set_profile_default_page f =
   profile_default_page := Some f

 let anonymous_default_page () =
   match !anonymous_default_page with
     None ->
       Printf.fprintf stderr "module Shared.Register: you must specify anonymous_default_page first\n%!";
       exit 2
   | Some f -> f

 let profile_default_page () =
   match !profile_default_page with
     None ->
       Printf.fprintf stderr "module Shared.Register: you must specify profile_default_page first\n%!";
       exit 2
   | Some f -> f

 let append profile = function
   | Object (l) -> Object ( ("is_admin", Bool (is_admin profile)) :: l)
   | _ as o -> o

let register_json service profiled_handler =
  let anonymous_default_page = anonymous_default_page () in
  let safe_handler sp gp pp =
   catch
     (fun () ->
       Tables.get_profile sp
       >>= function
       | Some profile -> (profiled_handler sp profile gp pp >>= fun json -> Json_io.string_of_json ~compact:false (append profile json) >>> Eliom_predefmod.HtmlText.send ~sp)
        | None ->
Eliom_predefmod.Redirection.send ~headers:no_cache ~sp  (anonymous_default_page None) )
     (fun exn -> Object ([ "status", Int 0; "error_message", String (Printexc.to_string exn)]) >>> Json_io.string_of_json ~compact:false >>> Eliom_predefmod.HtmlText.send ~sp )


in
  Eliom_predefmod.Any.register service safe_handler


let register_safe ?(anonymous=None) ?(restrict=true) (service) profiled_handler =
  let anonymous_default_page = anonymous_default_page () in
  let safe_handler sp gp pp =
   Tables.get_profile sp
     >>= function
	 | Some profile -> profiled_handler sp profile gp pp
	 | None -> match anonymous with
	     | None ->
	       let uri = Eliom_predefmod.Xhtml.make_uri ~absolute:true ~service:(Obj.magic (preapply service gp)) ~sp () in
	       let uri = XHTML.M.string_of_uri uri  in
	       Eliom_predefmod.Redirection.send ~headers:no_cache ~sp (anonymous_default_page (Some uri))
	     | Some anonymous_handler -> anonymous_handler sp gp pp
  in Eliom_predefmod.Any.register service safe_handler

let register_admin ?(anonymous=None) service profiled_handler =
  let profile_default_page = profile_default_page () in
  let anonymous_default_page = anonymous_default_page () in
  let safe_handler sp gp pp =
    Tables.get_profile sp
      >>= function
	| None ->
	  ( match anonymous with
	     | None -> Eliom_predefmod.Redirection.send ~headers:no_cache ~sp (anonymous_default_page None)
             | Some anonymous_handler -> anonymous_handler sp gp pp )
	| Some profile ->
	  match is_admin profile with
	    | true -> profiled_handler sp profile gp pp
        | _ ->
            Eliom_predefmod.Redirection.send ~headers:no_cache ~sp
(* (preapply Service.Frontend.wiki_view "forbidden") *)
            (profile_default_page profile)
            in
  Eliom_predefmod.Any.register service safe_handler

let register_unsafe service unsafe_handler =
  Eliom_predefmod.Any.register service unsafe_handler

let register_json_admin service profiled_handler =
  let safe_handler sp gp pp =
    Tables.get_profile sp
      >>= function
	| None -> return ""
	| Some profile ->
	  match is_admin profile with
	    | true -> profiled_handler sp profile gp pp
			       >>= fun json -> Json_io.string_of_json ~compact:false json >>> return
	    | _ -> return "" in
  Eliom_predefmod.HtmlText.register service safe_handler

