(*
 * Partially taken from hyLink - fpgg
 *
 * types.ml - miscanellous types
 *
 * William Le Ferrand william@myrilion.com
 *
 *)

open Misc

type date = { year : int ; month : int ; day : int ; } with orm

type time = { time_y: int ; time_m: int; time_d: int; time_h: int; time_min: int; time_s: int; } with orm


let string_of_time t =
  Printf.sprintf "%04d-%02d-%02d %02d:%02d:%02d"
    t.time_y t.time_m t.time_d
    t.time_h t.time_min t.time_s
;;

let now () =
  let tm = Unix.localtime (Unix.time ()) in
  {
    time_y = (tm.Unix.tm_year + 1900);
    time_m = tm.Unix.tm_mon ;
    time_d = tm.Unix.tm_mday ;
    time_h = tm.Unix.tm_hour ;
    time_min = tm.Unix.tm_min ;
    time_s = tm.Unix.tm_sec ;
  }

let time_of_date d =
  let tm = {
    Unix.tm_sec = 0 ;
    Unix.tm_min = 0 ;
    Unix.tm_hour = 0 ;
    Unix.tm_mday = d.day ;
    Unix.tm_mon = d.month ;
    Unix.tm_year = d.year ;
    Unix.tm_wday = 0 ;
    Unix.tm_yday = 0 ;
    Unix.tm_isdst = true ;
  } in
  Unix.mktime tm >>> fun (time, _) -> string_of_float time

let d2date d =
  CalendarLib.Date.make d.year d.month d.day

let date2d date =
 {
   year = CalendarLib.Date.year date ;
   month = CalendarLib.Date.int_of_month (CalendarLib.Date.month date) ;
   day = CalendarLib.Date.day_of_month date ;
 }

let today () =
  date2d (CalendarLib.Date.today ())

let current_year () =
  CalendarLib.Date.year (CalendarLib.Date.today ())

let date_equal d1 d2 =
  d1.year = d2.year && d1.month = d2.month && d1.day = d2.day

let date_to_string d =
  Printf.sprintf "%d-%d-%d" d.year d.month d.day

let date_to_string_fr d =
  Printf.sprintf "%d/%d/%d" d.day d.month d.year