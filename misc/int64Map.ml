include Map.Make (Int64)

let int64map_partial_fold l f map acc =
  let _, res = fold
    (fun k v (remaining,acc) ->
       match remaining with
         0 -> (0, acc)
       | n -> match f k v acc with
             new_acc, false -> remaining, new_acc
           | new_acc, true -> remaining - 1, new_acc
    )
      map (l, acc)
  in
  res

let int64map_paginated_fold ~from ~size f map init =
  let _, _, res = fold
    (fun k v (to_forget, to_display, acc ) ->
       match to_forget with
         0 ->
           (match to_display with
              0 -> (0, 0, acc)
            | n -> match f k v acc with
                  new_acc, true -> (0, (n-1), new_acc)
                | new_acc, false -> (0, n, new_acc))
       | n -> (n-1, to_display, acc)
    ) map (from, size, init)
  in
  res
