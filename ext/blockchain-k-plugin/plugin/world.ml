open Msg_types

module type WorldState = sig
  val get_account : bytes -> account
  val get_storage_data : bytes -> bytes -> bytes
  val get_code : bytes -> bytes
  val get_blockhash : int -> bytes
end

let rev_string str =
  let buf = Buffer.create (String.length str) in
  for i = (String.length str - 1) downto 0 do
    Buffer.add_char buf str.[i]
  done;
  Buffer.contents buf

let is_negative ch = match ch with
| '\000'..'\127' -> false
| '\128'..'\255' -> true

let z_bits z =
  let rec aux z n =
    if z = Z.zero then n
    else aux (Z.shift_right z 8) (n+8)
  in aux z 0

exception Break of int

let be_int i =
  let le = Z.to_bits i in
  let be = rev_string le in
  let len = String.length be in
  try
    for i = 0 to len - 1 do
      if be.[i] <> '\000' then raise (Break i)
    done;
    ""
  with Break i -> String.sub be i (len - i)

let of_z z =
  if Z.equal z Z.zero then Bytes.of_string "\000" else
  let twos = if Z.gt z Z.zero then z else Z.extract z 0 (z_bits (Z.sub (Z.mul (Z.neg z) (Z.of_int 2)) Z.one)) in
  let big_endian = be_int twos in
  if Z.gt z Z.zero && is_negative big_endian.[0] then
    Bytes.of_string ("\000" ^ big_endian)
  else
    Bytes.of_string big_endian

let of_z_width width i =
  let be = be_int i in
  let unpadded_byte_width = String.length be in
  let padded = Bytes.make width '\000' in
  Bytes.blit_string be 0 padded (width - unpadded_byte_width) unpadded_byte_width;
  padded

let to_z_unsigned b =
  let little_endian = rev_string (Bytes.to_string b) in
  Z.of_bits little_endian

let to_z b =
  let unsigned = to_z_unsigned b in
  if Bytes.length b > 0 && is_negative (Bytes.get b 0) then
  Z.signed_extract unsigned 0 (Bytes.length b * 8)
  else unsigned

let zero = of_z Z.zero

module type MockBlockhash = sig
  val hashes : bytes array
end

module StringMap = Map.Make(String)

module InMemoryWorldState = struct

  type mock_account = {balance:bytes;nonce:bytes;code:bytes;storage:bytes StringMap.t}

  let accounts = ref StringMap.empty

  let add_account ~id ~nonce ~balance ~code storage =
    accounts := StringMap.add (Bytes.to_string id) {balance=balance;nonce=nonce;code=code;storage=storage} !accounts

  let hashes = ref []

  let add_blockhash hash =
    hashes := !hashes @ [hash]

  let get_account id =
    let id = Bytes.to_string id in
    try
      let acct = StringMap.find id !accounts  in
      {Msg_types.nonce=acct.nonce;Msg_types.balance=acct.balance;code_empty=Bytes.length acct.code = 0}
    with Not_found -> {Msg_types.nonce=Bytes.empty;Msg_types.balance=Bytes.empty;code_empty=true}

  let get_storage_data id offset =
    let id = Bytes.to_string id in
    let offset = Bytes.to_string offset in
    try (StringMap.find offset (StringMap.find id !accounts).storage) with Not_found -> zero

  let get_code id =
    let id = Bytes.to_string id in
    try (StringMap.find id !accounts).code with Not_found -> Bytes.empty

  let get_blockhash i = List.nth !hashes i

  let reset () = accounts := StringMap.empty; hashes := []
  let reset_state () = accounts := StringMap.empty
  let reset_blockhash () = hashes := [Bytes.make 32 '\000']
end

let in_chan_ref = ref None
let out_chan_ref = ref None

let input_framed in_chan decoder =
  let len = input_binary_int in_chan in
  let bytes = Bytes.create len in
  really_input in_chan bytes 0 len;
  decoder (Pbrt.Decoder.of_bytes bytes)
let output_framed out_chan encoder v =
  let enc = Pbrt.Encoder.create() in
  encoder v enc;
  let encoded = Pbrt.Encoder.to_bytes enc in
  output_binary_int out_chan (Bytes.length encoded);
  output_bytes out_chan encoded;
  flush out_chan

module NetworkWorldState = struct
  let send_query (q: Msg_types.vmquery) (decoder : Pbrt.Decoder.t -> 'a) : 'a =
    let (in_chan,out_chan) = match !in_chan_ref,!out_chan_ref with
    | Some c1, Some c2 -> c1, c2 
    | _ -> failwith "channels not set for network" in
    output_framed out_chan Msg_pb.encode_vmquery q;
    input_framed in_chan decoder

  let get_account (addr : bytes) : account =
    send_query (Get_account {address = addr})
               Msg_pb.decode_account
  let get_storage_data addr offset =
    (send_query (Get_storage_data {address = addr; offset=offset})
               Msg_pb.decode_storage_data).data
  let get_code addr =
    (send_query (Get_code {address = addr})
               Msg_pb.decode_code).code
  let get_blockhash i =
    (send_query (Get_blockhash {offset = Int32.of_int i})
               Msg_pb.decode_blockhash).hash
end

let _VERSION = String.trim ApiVersion._VERSION

let serve addr run_transaction : unit =
  let process_transactions in_chan out_chan : unit =
    in_chan_ref := Some in_chan;
    out_chan_ref := Some out_chan;
    let finish () = Unix.shutdown_connection in_chan;
                    close_in in_chan 
    in
    (try
      let hello = input_framed in_chan Msg_pb.decode_hello in
      if String.equal hello.version _VERSION then
      while true do
        let call_context = input_framed in_chan Msg_pb.decode_call_context in
        let call_result = run_transaction call_context in
        output_framed out_chan Msg_pb.encode_vmquery (Call_result call_result)
      done
      else ()
    with
      End_of_file -> ()
    | exn -> finish (); raise exn);
    finish ()
  in
  let print_addr = function
  | Unix.ADDR_UNIX str -> "file://" ^ str
  | Unix.ADDR_INET(inet,port) -> "tcp://" ^ (Unix.string_of_inet_addr inet) ^ ":" ^ (string_of_int port)
  in
  let timeout = ref 1 in
  while (
    try
      let open Unix in
      let sock = socket PF_INET SOCK_STREAM 0 in
      bind sock addr;
      let new_addr = getsockname sock in
      close sock;
      print_endline("Listening for requests at address " ^ (print_addr new_addr));
      establish_server process_transactions new_addr;
      false
    with Unix.Unix_error(Unix.EADDRINUSE, _, _) ->
      print_endline("Socket in use, retrying in " ^ (string_of_int !timeout) ^ "...");
      true
  ) do
    Unix.sleep !timeout;
    timeout := !timeout + 1
  done
  
let send addr ctx =
  let chans = Unix.open_connection addr in
  let hello = {version=_VERSION;config=Iele_config} in
    output_framed (snd chans) Msg_pb.encode_hello hello;
    output_framed (snd chans) Msg_pb.encode_call_context ctx;
    let result = ref None in
    while !result = None do
      let query = input_framed (fst chans) Msg_pb.decode_vmquery in
      match query with
      | Get_account { address=addr } ->
        let account = InMemoryWorldState.get_account addr in
        output_framed (snd chans) Msg_pb.encode_account account
      | Get_storage_data { address=addr; offset=off } ->
        let data = InMemoryWorldState.get_storage_data addr off in
        output_framed (snd chans) Msg_pb.encode_storage_data {data=data}
      | Get_code { address=addr } ->
        let code = InMemoryWorldState.get_code addr in
        output_framed (snd chans) Msg_pb.encode_code {code=code}
      | Get_blockhash { offset=off } ->
        let hash = InMemoryWorldState.get_blockhash (Int32.to_int off) in
        output_framed (snd chans) Msg_pb.encode_blockhash {hash=hash}
      | Call_result res ->
        result := Some res
    done;
    Unix.shutdown_connection (fst chans);
    close_in (fst chans);
    match !result with
    | Some res -> res
    | None -> failwith "unreachable"
