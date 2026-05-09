#!/bin/zsh
# Minimal Language Server Protocol implementation for INTERCAL.
#
# Spec: https://microsoft.github.io/language-server-protocol/
#
# This is an educational stub: handles initialize, initialized,
# textDocument/didOpen, textDocument/didChange, textDocument/didClose,
# and emits diagnostics by invoking intercalc.sh --diagnose on the
# document text.
#
# Communication: JSON-RPC 2.0 over stdio with Content-Length headers.
#
# Note [LSPStub]
#   Real LSPs (rust-analyzer, gopls, ZLS) implement dozens of methods
#   plus incremental parsing, semantic tokens, hover, completion,
#   go-to-definition. This server implements only the diagnostic
#   essentials. The point is to demonstrate the LSP shape, not to be
#   a daily-driver IDE backend.

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/../.."
COMPILER="${ROOT_DIR}/src/bootstrap/intercalc.sh"
LOG=${INTERCAL_LSP_LOG:-/tmp/intercal_lsp.log}

log() {
  print -r -- "[$(date +%H:%M:%S)] $*" >>"$LOG"
}

# Read a JSON-RPC message: Content-Length: N\r\n\r\n{json}.
read_message() {
  local line len=0
  while IFS= read -r line; do
    line="${line%$'\r'}"
    if [[ -z "$line" ]]; then
      break
    fi
    if [[ "$line" =~ '^Content-Length:[[:space:]]*([0-9]+)' ]]; then
      len="${match[1]}"
    fi
  done
  if (( len > 0 )); then
    REPLY=$(dd bs=1 count=$len 2>/dev/null)
  else
    REPLY=""
  fi
}

send_message() {
  local body="$1"
  local len=${#body}
  print -nr -- "Content-Length: ${len}\r\n\r\n${body}"
}

# Extract a string field via primitive grep. The simplification is
# fine for our tiny input space (only well-formed JSON from clients).
get_field() {
  local json="$1"
  local key="$2"
  if [[ "$json" =~ "\"$key\":[[:space:]]*\"([^\"]+)\"" ]]; then
    REPLY="${match[1]}"
    return 0
  fi
  return 1
}

get_int_field() {
  local json="$1"
  local key="$2"
  if [[ "$json" =~ "\"$key\":[[:space:]]*([0-9]+)" ]]; then
    REPLY="${match[1]}"
    return 0
  fi
  return 1
}

# Emit a diagnostics array for a given URI by invoking the compiler
# in --diagnose mode and converting any ICL...I errors into LSP
# diagnostic JSON objects.
publish_diagnostics() {
  local uri=$1
  local text="$2"
  local diagnostics_json="["
  # Simple heuristic: try to compile; on failure capture stderr.
  local err
  err=$(print -r -- "$text" | zsh "$COMPILER" 2>&1 >/dev/null) || true
  if [[ "$err" =~ '(ICL[0-9]+[IW][[:space:]]+[^\n]+)' ]]; then
    local msg="${match[1]}"
    msg=${msg//\"/\\\"}
    diagnostics_json+='{"range":{"start":{"line":0,"character":0},"end":{"line":0,"character":1}},"severity":1,"message":"'"$msg"'"}'
  fi
  diagnostics_json+="]"
  local body
  body='{"jsonrpc":"2.0","method":"textDocument/publishDiagnostics","params":{"uri":"'"$uri"'","diagnostics":'"$diagnostics_json"'}}'
  send_message "$body"
}

main() {
  log "INTERCAL LSP started; pid=$$"
  local -A doc_text
  while true; do
    read_message
    [[ -z "$REPLY" ]] && break
    local msg="$REPLY"
    log "<- $msg"

    local method=""
    if get_field "$msg" "method"; then
      method="$REPLY"
    fi
    local id=""
    if get_int_field "$msg" "id"; then
      id="$REPLY"
    fi

    case "$method" in
      initialize)
        local resp='{"jsonrpc":"2.0","id":'"$id"',"result":{"capabilities":{"textDocumentSync":1,"diagnosticProvider":{"interFileDependencies":false,"workspaceDiagnostics":false}},"serverInfo":{"name":"intercal-lsp","version":"0.1.0"}}}'
        send_message "$resp"
        log "-> initialize response"
        ;;
      initialized)
        log "-> initialized notification (no response)"
        ;;
      textDocument/didOpen)
        local uri=""
        if get_field "$msg" "uri"; then uri="$REPLY"; fi
        # Extract document text (may contain escaped chars; we keep simple)
        local text=""
        if [[ "$msg" =~ '"text":[[:space:]]*"([^"]*)"' ]]; then
          text="${match[1]}"
          # Unescape \n \r \"
          text="${text//\\n/$'\n'}"
          text="${text//\\r/$'\r'}"
          text="${text//\\\"/\"}"
        fi
        doc_text[$uri]="$text"
        publish_diagnostics "$uri" "$text"
        ;;
      textDocument/didChange)
        local uri=""
        if get_field "$msg" "uri"; then uri="$REPLY"; fi
        local text=""
        if [[ "$msg" =~ '"text":[[:space:]]*"([^"]*)"' ]]; then
          text="${match[1]}"
          text="${text//\\n/$'\n'}"
          text="${text//\\r/$'\r'}"
          text="${text//\\\"/\"}"
        fi
        doc_text[$uri]="$text"
        publish_diagnostics "$uri" "$text"
        ;;
      textDocument/didClose)
        local uri=""
        if get_field "$msg" "uri"; then uri="$REPLY"; fi
        unset "doc_text[$uri]"
        ;;
      shutdown)
        local resp='{"jsonrpc":"2.0","id":'"$id"',"result":null}'
        send_message "$resp"
        ;;
      exit)
        exit 0
        ;;
      *)
        log "unhandled method: $method"
        if [[ -n "$id" ]]; then
          local resp='{"jsonrpc":"2.0","id":'"$id"',"error":{"code":-32601,"message":"Method not found: '"$method"'"}}'
          send_message "$resp"
        fi
        ;;
    esac
  done
}

main
