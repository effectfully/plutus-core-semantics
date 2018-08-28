open Constants
open Constants.K

let do_hash_str: string -> Cryptokit.hash -> Constants.K.kitem list =
  fun str h ->
    let bytes = Cryptokit.hash_string h str in
    let buf = Buffer.create ((String.length bytes) * 2) in
    String.iter (fun c -> Buffer.add_string buf (Printf.sprintf "%02x" (int_of_char c))) bytes;
    [String (Buffer.contents buf)]

let do_hash_bytes: bytes -> Cryptokit.hash -> Constants.K.kitem list =
  fun bytes h ->
    h#add_substring bytes 0 (Bytes.length bytes);
    [Bytes (Bytes.of_string h#result)]

let do_hook: Cryptokit.hash -> string
	      -> kitem list -> klabel -> sort -> kitem list -> (string -> k -> Z.t -> k) -> kitem list =
  fun h failMsg c lbl sort config ff -> match c with
    [String str]  ->  do_hash_str str h
  | [Bytes bytes] ->  do_hash_bytes bytes h
  | _ -> failwith failMsg

let hook_sha2_256  = do_hook (Cryptokit.Hash.sha2 256)      "sha2_256"
let hook_keccak256 = do_hook (Cryptokit.Hash.keccak 256)    "keccak256"
let hook_ripemd160 = do_hook (Cryptokit.Hash.ripemd160 ())  "ripemd160"
