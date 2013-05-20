-ifndef(LOG_MESSAGE_PB_H).
-define(LOG_MESSAGE_PB_H, true).
-record(log_message, {
    version,
    node = erlang:error({required, node}),
    node_role,
    node_version,
    severity = erlang:error({required, severity}),
    message = erlang:error({required, message}),
    module,
    function,
    line,
    pid,
    client
}).
-endif.

-ifndef(LOG_CLIENT_PB_H).
-define(LOG_CLIENT_PB_H, true).
-record(log_client, {
    account_token,
    type,
    version,
    os,
    os_version
}).
-endif.

