-file("src/popcorn_pb.erl", 1).

-module(popcorn_pb).

-export([encode_log_client/1, decode_log_client/1,
	 encode_log_message/1, decode_log_message/1]).

-export([has_extension/2, extension_size/1,
	 get_extension/2, set_extension/3]).

-export([decode_extensions/1]).

-export([encode/1, decode/2]).

-record(log_client,
	{account_token, type, version, os, os_version}).

-record(log_message,
	{version, node, node_role, node_version, severity,
	 message, module, function, line, pid, client}).

encode(Record) -> encode(element(1, Record), Record).

encode_log_client(Record)
    when is_record(Record, log_client) ->
    encode(log_client, Record).

encode_log_message(Record)
    when is_record(Record, log_message) ->
    encode(log_message, Record).

encode(log_message, Record) ->
    [iolist(log_message, Record)
     | encode_extensions(Record)];
encode(log_client, Record) ->
    [iolist(log_client, Record)
     | encode_extensions(Record)].

encode_extensions(_) -> [].

iolist(log_message, Record) ->
    [pack(1, optional,
	  with_default(Record#log_message.version, none), uint32,
	  []),
     pack(2, required,
	  with_default(Record#log_message.node, none), string,
	  []),
     pack(3, optional,
	  with_default(Record#log_message.node_role, none),
	  string, []),
     pack(4, optional,
	  with_default(Record#log_message.node_version, none),
	  string, []),
     pack(5, required,
	  with_default(Record#log_message.severity, none), int32,
	  []),
     pack(6, required,
	  with_default(Record#log_message.message, none), string,
	  []),
     pack(7, optional,
	  with_default(Record#log_message.module, none), string,
	  []),
     pack(8, optional,
	  with_default(Record#log_message.function, none), string,
	  []),
     pack(9, optional,
	  with_default(Record#log_message.line, none), string,
	  []),
     pack(10, optional,
	  with_default(Record#log_message.pid, none), string, []),
     pack(11, optional,
	  with_default(Record#log_message.client, none),
	  log_client, [])];
iolist(log_client, Record) ->
    [pack(1, optional,
	  with_default(Record#log_client.account_token, none),
	  string, []),
     pack(2, optional,
	  with_default(Record#log_client.type, none), string, []),
     pack(3, optional,
	  with_default(Record#log_client.version, none), string,
	  []),
     pack(4, optional,
	  with_default(Record#log_client.os, none), string, []),
     pack(5, optional,
	  with_default(Record#log_client.os_version, none),
	  string, [])].

with_default(Val, none) -> Val;
with_default(Default, Default) -> undefined;
with_default(Val, _) -> Val.

pack(_, optional, undefined, _, _) -> [];
pack(_, repeated, undefined, _, _) -> [];
pack(_, repeated_packed, undefined, _, _) -> [];
pack(_, repeated_packed, [], _, _) -> [];
pack(FNum, required, undefined, Type, _) ->
    exit({error,
	  {required_field_is_undefined, FNum, Type}});
pack(_, repeated, [], _, Acc) -> lists:reverse(Acc);
pack(FNum, repeated, [Head | Tail], Type, Acc) ->
    pack(FNum, repeated, Tail, Type,
	 [pack(FNum, optional, Head, Type, []) | Acc]);
pack(FNum, repeated_packed, Data, Type, _) ->
    protobuffs:encode_packed(FNum, Data, Type);
pack(FNum, _, Data, _, _) when is_tuple(Data) ->
    [RecName | _] = tuple_to_list(Data),
    protobuffs:encode(FNum, encode(RecName, Data), bytes);
pack(FNum, _, Data, Type, _)
    when Type =:= bool;
	 Type =:= int32;
	 Type =:= uint32;
	 Type =:= int64;
	 Type =:= uint64;
	 Type =:= sint32;
	 Type =:= sint64;
	 Type =:= fixed32;
	 Type =:= sfixed32;
	 Type =:= fixed64;
	 Type =:= sfixed64;
	 Type =:= string;
	 Type =:= bytes;
	 Type =:= float;
	 Type =:= double ->
    protobuffs:encode(FNum, Data, Type);
pack(FNum, _, Data, Type, _) when is_atom(Data) ->
    protobuffs:encode(FNum, enum_to_int(Type, Data), enum).

enum_to_int(pikachu, value) -> 1.

int_to_enum(_, Val) -> Val.

decode_log_client(Bytes) when is_binary(Bytes) ->
    decode(log_client, Bytes).

decode_log_message(Bytes) when is_binary(Bytes) ->
    decode(log_message, Bytes).

decode(enummsg_values, 1) -> value1;
decode(log_message, Bytes) when is_binary(Bytes) ->
    Types = [{11, client, log_client, [is_record]},
	     {10, pid, string, []}, {9, line, string, []},
	     {8, function, string, []}, {7, module, string, []},
	     {6, message, string, []}, {5, severity, int32, []},
	     {4, node_version, string, []},
	     {3, node_role, string, []}, {2, node, string, []},
	     {1, version, uint32, []}],
    Defaults = [],
    Decoded = decode(Bytes, Types, Defaults),
    to_record(log_message, Decoded);
decode(log_client, Bytes) when is_binary(Bytes) ->
    Types = [{5, os_version, string, []},
	     {4, os, string, []}, {3, version, string, []},
	     {2, type, string, []}, {1, account_token, string, []}],
    Defaults = [],
    Decoded = decode(Bytes, Types, Defaults),
    to_record(log_client, Decoded).

decode(<<>>, _, Acc) -> Acc;
decode(Bytes, Types, Acc) ->
    {ok, FNum} = protobuffs:next_field_num(Bytes),
    case lists:keyfind(FNum, 1, Types) of
      {FNum, Name, Type, Opts} ->
	  {Value1, Rest1} = case lists:member(is_record, Opts) of
			      true ->
				  {{FNum, V}, R} = protobuffs:decode(Bytes,
								     bytes),
				  RecVal = decode(Type, V),
				  {RecVal, R};
			      false ->
				  case lists:member(repeated_packed, Opts) of
				    true ->
					{{FNum, V}, R} =
					    protobuffs:decode_packed(Bytes,
								     Type),
					{V, R};
				    false ->
					{{FNum, V}, R} =
					    protobuffs:decode(Bytes, Type),
					{unpack_value(V, Type), R}
				  end
			    end,
	  case lists:member(repeated, Opts) of
	    true ->
		case lists:keytake(FNum, 1, Acc) of
		  {value, {FNum, Name, List}, Acc1} ->
		      decode(Rest1, Types,
			     [{FNum, Name,
			       lists:reverse([int_to_enum(Type, Value1)
					      | lists:reverse(List)])}
			      | Acc1]);
		  false ->
		      decode(Rest1, Types,
			     [{FNum, Name, [int_to_enum(Type, Value1)]} | Acc])
		end;
	    false ->
		decode(Rest1, Types,
		       [{FNum, Name, int_to_enum(Type, Value1)} | Acc])
	  end;
      false ->
	  case lists:keyfind('$extensions', 2, Acc) of
	    {_, _, Dict} ->
		{{FNum, _V}, R} = protobuffs:decode(Bytes, bytes),
		Diff = size(Bytes) - size(R),
		<<V:Diff/binary, _/binary>> = Bytes,
		NewDict = dict:store(FNum, V, Dict),
		NewAcc = lists:keyreplace('$extensions', 2, Acc,
					  {false, '$extensions', NewDict}),
		decode(R, Types, NewAcc);
	    _ ->
		{ok, Skipped} = protobuffs:skip_next_field(Bytes),
		decode(Skipped, Types, Acc)
	  end
    end.

unpack_value(Binary, string) when is_binary(Binary) ->
    binary_to_list(Binary);
unpack_value(Value, _) -> Value.

to_record(log_message, DecodedTuples) ->
    Record1 = lists:foldr(fun ({_FNum, Name, Val},
			       Record) ->
				  set_record_field(record_info(fields,
							       log_message),
						   Record, Name, Val)
			  end,
			  #log_message{}, DecodedTuples),
    Record1;
to_record(log_client, DecodedTuples) ->
    Record1 = lists:foldr(fun ({_FNum, Name, Val},
			       Record) ->
				  set_record_field(record_info(fields,
							       log_client),
						   Record, Name, Val)
			  end,
			  #log_client{}, DecodedTuples),
    Record1.

decode_extensions(Record) -> Record.

decode_extensions(_Types, [], Acc) ->
    dict:from_list(Acc);
decode_extensions(Types, [{Fnum, Bytes} | Tail], Acc) ->
    NewAcc = case lists:keyfind(Fnum, 1, Types) of
	       {Fnum, Name, Type, Opts} ->
		   {Value1, Rest1} = case lists:member(is_record, Opts) of
				       true ->
					   {{FNum, V}, R} =
					       protobuffs:decode(Bytes, bytes),
					   RecVal = decode(Type, V),
					   {RecVal, R};
				       false ->
					   case lists:member(repeated_packed,
							     Opts)
					       of
					     true ->
						 {{FNum, V}, R} =
						     protobuffs:decode_packed(Bytes,
									      Type),
						 {V, R};
					     false ->
						 {{FNum, V}, R} =
						     protobuffs:decode(Bytes,
								       Type),
						 {unpack_value(V, Type), R}
					   end
				     end,
		   case lists:member(repeated, Opts) of
		     true ->
			 case lists:keytake(FNum, 1, Acc) of
			   {value, {FNum, Name, List}, Acc1} ->
			       decode(Rest1, Types,
				      [{FNum, Name,
					lists:reverse([int_to_enum(Type, Value1)
						       | lists:reverse(List)])}
				       | Acc1]);
			   false ->
			       decode(Rest1, Types,
				      [{FNum, Name, [int_to_enum(Type, Value1)]}
				       | Acc])
			 end;
		     false ->
			 [{Fnum,
			   {optional, int_to_enum(Type, Value1), Type, Opts}}
			  | Acc]
		   end;
	       false -> [{Fnum, Bytes} | Acc]
	     end,
    decode_extensions(Types, Tail, NewAcc).

set_record_field(Fields, Record, '$extensions',
		 Value) ->
    Decodable = [],
    NewValue = decode_extensions(element(1, Record),
				 Decodable, dict:to_list(Value)),
    Index = list_index('$extensions', Fields),
    erlang:setelement(Index + 1, Record, NewValue);
set_record_field(Fields, Record, Field, Value) ->
    Index = list_index(Field, Fields),
    erlang:setelement(Index + 1, Record, Value).

list_index(Target, List) -> list_index(Target, List, 1).

list_index(Target, [Target | _], Index) -> Index;
list_index(Target, [_ | Tail], Index) ->
    list_index(Target, Tail, Index + 1);
list_index(_, [], _) -> -1.

extension_size(_) -> 0.

has_extension(_Record, _FieldName) -> false.

get_extension(_Record, _FieldName) -> undefined.

set_extension(Record, _, _) -> {error, Record}.

