module type INTERFACE = sig

(** This function expose a file for public use *)
    val link : Ocsigen_lib.file_info -> string

(** Create a fresh filename *)
    val fresh_copy : Ocsigen_lib.file_info -> string * string

(** This function prepares a file to be exposed through a retrieve_file *)
    val link_private : Ocsigen_lib.file_info -> string * string


  end

module IMPLEMENTATION =  struct

(*
 * hyLink - fpgg
 *
 * storage.ml - converters to amazon S3 uris, basically
 *
 * William Le Ferrand william@myrilion.com
 *
 *)

open XHTML.M
(*open Eliom_duce.Xhtml *)



open Eliom_services
open Eliom_parameters
open Eliom_sessions
open Eliom_predefmod
open Misc
open Lwt

(** This function expose a file for public use *)
let link file =
  let filename = Eliom_sessions.get_original_filename file in
  let basename = Ocsigen_lib.basename filename in
  let upload_date = Unix.time () >>> int_of_float in
  let uri = Printf.sprintf "/upload/%d_%s" upload_date basename in
  let newname = Params.public_dir ^ uri in
  Unix.link (Eliom_sessions.get_tmp_filename file) newname;
  uri

(** Create a fresh filename *)
let fresh_copy file =
  let filename = Eliom_sessions.get_original_filename file in
  let basename = Ocsigen_lib.basename filename in
  let timestamp = Unix.time () >>> int_of_float in
  let i = Random.int 2000 in

  let uri = Printf.sprintf "/upload/%d_%d_%s" timestamp i basename in
  let newname = Params.public_dir ^ uri in
  (newname, uri)

(** This function prepares a file to be exposed through a retrieve_file *)
let link_private file =
  let filename = Eliom_sessions.get_original_filename file in
  let tmp_filename = Eliom_sessions.get_tmp_filename file in
  let uid = Ocsigen_lib.basename tmp_filename in
  let oid = Ocsigen_lib.basename filename in
  let newname = Printf.sprintf "%s/%s" Params.private_dir uid in
  Unix.link tmp_filename newname;
  (oid, uid)



end

include (IMPLEMENTATION : INTERFACE)
  