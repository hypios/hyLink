
(*
 * hyLink - fpgg
 *
 * misc.ml - miscanellous utils for fpgg
 *
 * William Le Ferrand william@hypios.com
 *
 *)


open XHTML.M
(* open Eliom_duce.Xhtml *)

open Lwt
open Json_type

type flows = Xhtmltypes.div_content XHTML.M.elt list
(*
open Types
open Types_userinfo
*)

open Netconversion


(* General stuff *)

let (>>>) f g = g f

let debug' fmt =
  Printf.ksprintf (fun s -> print_string s; flush stdout ) fmt ;;


let pretty_print_number s =
  let revert s =
      let size = String.length s in
      let ns = String.create size in
      for i = 0 to (size - 1) do
        ns.[i] <- s.[size - i - 1]
      done ; ns in

    let size  = String.length s in
    let buffer = Buffer.create size in

    let p = ref size in

    while (!p > 0) do
      let c = ref 0 in
      while (!p > 0 && !c < 3) do
        decr p ;
        Buffer.add_char buffer s.[!p] ;
        incr c ;
      done ;
      if (!p > 0) then Buffer.add_char buffer ','
    done ;
    revert (Buffer.contents buffer) ;;

(* date and time *)

let timestamp () = Unix.time () >>> string_of_float

let pretty_print_date date = CalendarLib.Printer.Date.sprint "%A, %B %d, %Y" date

(* Lwt/Ocsigen stuff *)

let iteri_lwt f a =
  let l = Array.length a in
  let rec iterate = function
    | -1 -> return ()
    | n -> f n a.(n) >>= fun _ -> iterate (n-1) in
  iterate (l-1)

let warning fmt =
  Printf.ksprintf (fun s -> Ocsigen_messages.warning s) fmt ;;

let error fmt =
  Printf.ksprintf (fun s -> Ocsigen_messages.errlog s) fmt ;;

let array_fold_left_lwt f x a = (* : ('a -> 'b -> 'a Lwt.t) -> 'a -> 'b array -> 'a Lwt.t =  *)
  let rec fold_internal pos x =
    if pos = Array.length a then
      return x
    else
      ( f x a.(pos) >>= fold_internal (pos+1) ) in
  fold_internal 0 x


let iteri_lwt f a =
  let l = Array.length a in
  let rec iterate = function
    | -1 -> return ()
    | n -> f n a.(n) >>= fun _ -> iterate (n-1) in
  iterate (l-1)


let open_append_lwt file =
  Lwt_io.open_file
    ~flags: [Unix.O_APPEND ; Unix.O_WRONLY] ~mode: Lwt_io.output file

(* Mysql stuff *)

let rec extract_result f extractor result  =
       match Mysql.fetch result with
           None -> []
         | Some values -> f values :: extractor result

(* Celle là gère les erreurs d’extraction & est récursive terminale *)
let rec fold_result f result acc =
      match  Mysql.fetch result with
          None -> acc
        | Some values -> f values acc >>> fold_result f result

let rec fold_result_b f acc result =
      match  Mysql.fetch result with
          None -> return acc
        | Some values -> fold_result_b f (f values acc) result

let rec fold_result_lwt f result acc =
      match  Mysql.fetch result with
       None -> acc >>> return
      | Some values -> f values acc >>= fold_result_lwt f result

let rec fold_result_lwt_b f acc result =
      match  Mysql.fetch result with
       None -> acc >>> return
      | Some values -> f values acc >>= fold_result_lwt f result

let date2ml date =
  let year, month, day = Mysql.date2ml date in
  CalendarLib.Date.make year month day



(* Convenient modules *)

module Int =
struct
  type t = int
  let compare = Pervasives.compare
end

module ReverseString =
struct
  type t = string
  let compare a b = String.compare b a
end

module IntMap = Map.Make (Int)
module StringMap = Map.Make (ReverseString)

module InversedChar =
  struct
    include Char
    let compare a b = (Char.compare a b)
  end

module CharMap = Map.Make (InversedChar)

(* string stuff *)

let comma_split s =
  let rxp = Str.regexp "[ \t]*[,][ \t]*" in
  Str.split rxp s


(* If the string is too long, trim it and append "..." *)
let condense_string s l = match String.length s with
  | a when (a < l) -> s
  | _ -> ( (String.sub s 0 (l-3)) ^ "..." )

let convert_to_utf8 s =
  let op = String.make 1 (Char.chr 222) in
  let cl = String.make 1 (Char.chr 221) in
  let cd = String.make 1 (Char.chr 146) in
  let cp = String.make 1 (Char.chr 249) in
  let s = Str.global_replace
    (Str.regexp_string cp) "*"
      (Str.global_replace (Str.regexp_string cd) "'"
       (Str.global_replace (Str.regexp_string op) "'"
        (Str.global_replace (Str.regexp_string cl) "'" s)))
  in
  try
    verify `Enc_utf8 s ; s
  with e ->
    (* debug' "@@@ Pas de l'utf8: %s!\n" s ;  *)
    convert ~in_enc:`Enc_iso88591 ~out_enc:`Enc_utf8 s

let trim_beginning s =
  let len = String.length s in
  let i = ref 0 in
  let b = ref true in
  while !i < len && !b do
    match s.[!i] with
      ' ' -> incr i
    | _ -> b := false
  done;
  if !i >= len then
    ""
  else
    String.sub s !i (len - !i)
;;
let trim_end s =
  let len = String.length s in
  let i = ref (len - 1) in
  let b = ref true in
  while !i >= 0 && !b do
    match s.[!i] with
      ' ' -> decr i
    | _ -> b := false
  done;
  if !i < 0 then
    ""
  else
    String.sub s 0 (!i+1)
;;

let trim s = trim_end (trim_beginning s);;

(*c==v=[String.first_sentence]=1.0====*)
let first_sentence ?(limit=40) s =
  let rec get_before_dot s =
    try
      let len = String.length s in
      let n = String.index s '.' in
      if n + 1 >= len then
        (* the dot is the last character *)
        (true, s)
      else
        (
         match s.[n+1] with
           ' ' | '\n' | '\r' | '\t' ->
             (true, String.sub s 0 (n+1))
         | _ ->
             let (b, s2) = get_before_dot (String.sub s (n + 1) (len - n - 1)) in
             (b, (String.sub s 0 (n+1))^s2)
        )
    with
      Not_found -> (false, s)
  in
  let len = String.length s in
  let s_limited =
    if len > limit then
      String.sub s 0 limit
    else
      s
  in
  let (found, res) = get_before_dot s_limited in
  if found then
    res
  else
    if len > limit then
      if limit > 3 then
        (String.sub s_limited 0 (limit - 3) ^ "...")
      else
        s_limited
    else
      s
(*/c==v=[String.first_sentence]=1.0====*)

let opt_string ?(default="") = function
  None -> default
| Some s -> s
;;

(* Address parsing *)

let extract_address_simple address =
  let rxp = Str.regexp "\\([A-Z a-z]+\\)\\([0-9][0-9][0-9][0-9][0-9]\\)\\(.*\\)" in
  let _pos = Str.string_match rxp address 0 in
  let city = Str.matched_group 1 address in
  let zipcode = Str.matched_group 2 address in
  let extra = Str.matched_group 3 address in
  Printf.sprintf "%s %s %s " extra zipcode city

let extract_address_cedex address =
  let rxp = Str.regexp "\\([A-Z a-z ]+\\)\\([0-9][0-9][0-9][0-9][0-9][0-9][0-9]\\)\\(.*\\)" in
  let _pos = Str.string_match rxp address 0 in
  let city = Str.matched_group 1 address in
  let cedex = Str.matched_group 2 address in
  let extra = Str.matched_group 3 address in
  Printf.sprintf "%s %s %s" extra city cedex

(* list stuff *)

let merge_string_lists l1 l2 =
  let sl1 = List.sort String.compare l1 in
  let sl2 = List.sort String.compare l2 in
  List.merge String.compare sl1 sl2

let rec merge_list_without_duplicate l1 l2 =
  match l1 with
  | [] -> l2
  | h::q -> if List.mem h l2 then
              merge_list_without_duplicate q l2
            else
              merge_list_without_duplicate q (h::l2)

(* Remove all elements of l1 from l2 *)
let rec filter_list ?(pred=(=)) l1 l2 =
  let pred = fun e -> not (List.exists (pred e) l1) in
  List.filter pred l2

(* Extract from a list  *)
let rec extract_partial n l =
  match n,l with
      0, _ | _, [] -> []
    | n, t::q -> t:: (extract_partial (n-1) q)


(* useless functions ? *)

let fresh_id_project =
  let cnt = ref (int_of_float (Unix.gettimeofday ())) in (****/!\****)
  let mtx = Lwt_mutex.create () in
  (fun () -> Lwt_mutex.lock mtx >>= fun () -> incr cnt ; let v = !cnt in Lwt_mutex.unlock mtx ; return v)





  
