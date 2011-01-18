open Json_type
open Time
open Misc

type partial_period = {
  starting_date : date ;
  ending_date : date option ;
} with orm

let pretty_print_time time =
  (CalendarLib.Date.make time.time_y time.time_m time.time_d >>> pretty_print_date) ^
   (Printf.sprintf " %02dh%02d\n" time.time_h time.time_min)

let time_to_string = pretty_print_time

let extract_start_date period =
  CalendarLib.Printer.Date.sprint "%B %Y" (d2date period.starting_date)

let extract_end_date period =
  match period.ending_date with
      None -> "Present"
    | Some date -> CalendarLib.Printer.Date.sprint "%B %Y" (d2date date)

let extract_start_date_int period =
  Object [
          "year", Int period.starting_date.year ;
          "month", Int period.starting_date.month ;
          "day", Int period.starting_date.day ;
        ]

let extract_end_date_int period =
  match period.ending_date with
      None -> Object [
                      "year", Int 0;
                      "month", Int 0;
                      "day", Int 0;
                    ]
    | Some date -> Object [
      "year", Int date.year ;
      "month", Int date.month ;
      "day", Int date.day ;
    ]


let make_period ?(e_year=0) ?(e_month=0) ?(e_day=0) s_year s_month s_day =
  {
    starting_date = { year = s_year ; month = s_month ; day = s_day ; } ;
    ending_date = if e_year = 0 || e_month = 0 || e_day = 0
                    then None
                    else Some { year = e_year ; month = e_month ; day = e_day ; }
  }
