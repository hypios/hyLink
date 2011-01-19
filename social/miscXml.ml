
module type INTERFACE = sig

  end

module IMPLEMENTATION = struct

open Misc
open Lwt

(** Generate the <li> list, from an id list and a render function *)
let div_accumulator ?(div_class="") (render_fn : 'a -> 'a XHTML.M.elt list Lwt.t ) (id_list : 'a list) =
  Lwt_list.fold_left_s
    (
      fun acc id ->
        render_fn id >>= fun tmp_html ->
          <<
              <div class="$div_class$"> $list:tmp_html$ </div>
          >> :: acc >>> return
    ) [] id_list


let li_accumulator (render_fn : 'a -> 'a XHTML.M.elt Lwt.t ) (id_list : 'a list) =
  Lwt_list.fold_left_s
    (
      fun acc id ->
        render_fn id >>= fun tmp_html ->
          <<
              <li> $tmp_html$ </li>
          >> :: acc >>> return
    ) [] id_list

let javascript_truncate_utf8 text length =
  if (String.length text < length) then
    <:xmllist< <span> $str:text$ </span> >>
   else
   let subtext = (String.sub text 0 length) in
   let utf8 = convert_to_utf8 subtext in
    <:xmllist<
        <span> $str: utf8$ </span>
        <span style="display:none"> $str:text$ </span>
        <span> <a href="#" class="show_more_desc_unit"> ...  show more </a> </span>
    >>

end

(* data select creation *)

open XHTML.M
open Eliom_predefmod.Xhtml
open Lwt
open Misc

let generate_day_option d v =
  option ~a:([a_value (string_of_int ((d + 1)))] @ (if v = Some d then [a_selected `Selected] else [])) (pcdata (CalendarLib.Date.make 0 1 (d + 1) >>> CalendarLib.Printer.Date.sprint "%d"))

let generate_month_option m v =
  option ~a:([a_value (string_of_int ((m + 1)))] @ (if v = Some m then [a_selected `Selected] else [])) (pcdata (CalendarLib.Date.make 0 (m + 1) 1 >>> CalendarLib.Printer.Date.sprint "%m"))

let generate_year_option y v =
  option ~a:([a_value (string_of_int y)] @ (if v = Some y then [a_selected `Selected] else [])) (pcdata (string_of_int y))

let rec generate_day_list f acc top_limit v = function
    n when n < top_limit -> acc
  | n -> generate_day_list f (f n v :: acc) top_limit v (n - 1)

let rec generate_month_list f acc top_limit v = function
    n when n < top_limit -> acc
  | n -> generate_month_list f (f n v :: acc) top_limit v (n - 1)

let rec generate_year_list f acc top_limit v = function
    n when n > top_limit -> acc
  | n -> generate_year_list f (f n v :: acc) top_limit v (n + 1)

let create_day_select ?v day_str =
  select (option ~a:([a_value "0"]) (pcdata day_str))
    (generate_day_list generate_day_option [] 0 v 31)

let create_month_select ?v month_str =
  select (option ~a:([a_value "0"]) (pcdata month_str))
    (generate_month_list generate_month_option [] 0 v 11)

let create_year_select ?v ?(reverse=true) year_str begin_date end_date =
  let year_list = (generate_year_list generate_year_option [] end_date v begin_date) in
  select (option ~a:([a_value "0"]) (pcdata year_str)) (match reverse with true -> year_list | false -> List.rev year_list)

let make_select to_string ?value choices =
  let (h, q) =
    match choices with
      [] -> failwith "Invalid choice list"
    | h :: q -> (h, q)
  in
  let f_option v =
    let s = to_string v in
    option
      ~a: ((if value = Some v then [a_selected `Selected] else []) @[ a_value s])
      (pcdata s)
  in
  select (f_option h) (List.map f_option q)
;;

include (IMPLEMENTATION : INTERFACE)
  
