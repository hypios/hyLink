open Lwt
open XHTML.M
open Eliom_predefmod.Xhtml

let split_list l =
  let rec iter (l,r) n = function
    [] -> (l, r) (** beware, lists are returned in reverse order *)
  | h ::q ->
      if n mod 2 = 0 then
        iter (h::l, r) (n+1) q
      else
        iter (l, h::r) (n+1) q
  in
  iter ([],[]) 0 l
;;

let two_columns_list ~id ~cl ~cl_left ~cl_right f list =
  let (list_left, list_right) = split_list list in
  let side = Lwt_list.fold_left_s
    (fun acc x -> (f x) >>= fun x -> Lwt.return (x @ acc))
      []
  in
   side list_left
    >>= fun left ->
    side list_right
    >>= fun right ->
    Lwt.return
    (div ~a:[a_id id; a_class [cl]]
     [
       div ~a: [a_class [cl_left]] left ;
       div ~a: [a_class [cl_right]] right ;
     ]
    )
  ;;

  
