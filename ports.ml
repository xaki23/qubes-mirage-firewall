module Set = Set.Make(struct
  type t = int
  let compare a b = compare a b
end)

include Set

(* TODO put retries in here *)
let rec pick_free_port ~add_list ~consult_list =
  let p = 1024 + Random.int (0xffff - 1024) in
  if mem p !add_list || mem p !consult_list
  then pick_free_port ~add_list ~consult_list
  else
    begin
      add_list := add p !add_list;
      p
    end
