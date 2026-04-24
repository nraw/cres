select(.type == "user")
| select(.message.content | type == "string")
| select((.message.content | startswith("<command-name>")) | not)
| select((.message.content | startswith("<local-command-stdout>")) | not)
| select(.sessionId != null and .sessionId != ""
         and .cwd != null and .cwd != ""
         and .timestamp != null and .timestamp != "")
| [
    .timestamp[0:16],
    .sessionId,
    .cwd,
    (.message.content | gsub("[\n\r\t]+"; " ") | .[0:300]),
    (.message.content | @base64)
  ]
| @tsv
