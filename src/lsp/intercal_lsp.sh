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
# in --diagnose mode and converting any ICL...I/W errors into LSP
# diagnostic JSON objects. Multiple errors and warnings are emitted.
publish_diagnostics() {
  local uri=$1
  local text="$2"
  local diagnostics_json="["
  local err
  err=$(print -r -- "$text" | zsh "$COMPILER" 2>&1 >/dev/null) || true
  local first=1
  local lineno
  while IFS= read -r lineno; do
    [[ -z "$lineno" ]] && continue
    if [[ "$lineno" =~ '(ICL[0-9]+[IW][[:space:]]+.*)' ]]; then
      local msg="${match[1]}"
      msg=${msg//\"/\\\"}
      msg=${msg//$'\n'/ }
      # Severity: 1 = Error, 2 = Warning. ICLnnnW -> Warning, ICLnnnI -> Error.
      local sev=1
      [[ "$msg" =~ 'ICL[0-9]+W' ]] && sev=2
      (( first )) || diagnostics_json+=","
      first=0
      diagnostics_json+='{"range":{"start":{"line":0,"character":0},"end":{"line":0,"character":1}},"severity":'"$sev"',"source":"intercalc","message":"'"$msg"'"}'
    fi
  done <<< "$err"
  diagnostics_json+="]"
  local body
  body='{"jsonrpc":"2.0","method":"textDocument/publishDiagnostics","params":{"uri":"'"$uri"'","diagnostics":'"$diagnostics_json"'}}'
  send_message "$body"
}

# Compute semantic tokens. The LSP spec defines a flat array of
# (deltaLine, deltaStart, length, tokenType, tokenModifiers) tuples.
# We classify into: keyword (DO/PLEASE/etc), variable (.N/:N/,N/;N),
# label ((N)), comment (DON'T/NOT lines).
#
# Token type IDs (matching legend below):
#   0 = keyword
#   1 = variable
#   2 = number
#   3 = label
#   4 = comment
SEMANTIC_TOKEN_TYPES='["keyword","variable","number","label","comment"]'

compute_semantic_tokens() {
  local text="$1"
  local out="["
  local first=1
  local prev_line=0 prev_start=0
  local lineno=0
  local line
  while IFS= read -r line; do
    lineno=$((lineno + 1))
    # Strip leading whitespace for processing but track positions
    local pos=0
    local len=${#line}
    while (( pos < len )); do
      local ch="${line[$((pos+1))]}"
      # Skip whitespace
      if [[ "$ch" == " " || "$ch" == $'\t' ]]; then
        pos=$((pos + 1))
        continue
      fi
      local start=$pos
      local tok_type=-1
      local tok_len=0
      # Keywords: DO, PLEASE, NEXT, RESUME, GIVE, UP, READ, OUT,
      # WRITE, IN, STASH, RETRIEVE, IGNORE, REMEMBER, ABSTAIN,
      # FROM, REINSTATE, COME, FORGET, NOT.
      if [[ "${line[$((pos+1)),$((pos+2))]}" == "DO" ]]; then
        tok_len=2; tok_type=0
      elif [[ "${line[$((pos+1)),$((pos+6))]}" == "PLEASE" ]]; then
        tok_len=6; tok_type=0
      elif [[ "${line[$((pos+1)),$((pos+4))]}" == "NEXT" ]]; then
        tok_len=4; tok_type=0
      elif [[ "${line[$((pos+1)),$((pos+6))]}" == "RESUME" ]]; then
        tok_len=6; tok_type=0
      elif [[ "${line[$((pos+1)),$((pos+4))]}" == "GIVE" ]]; then
        tok_len=4; tok_type=0
      elif [[ "${line[$((pos+1)),$((pos+5))]}" == "STASH" ]]; then
        tok_len=5; tok_type=0
      elif [[ "${line[$((pos+1)),$((pos+8))]}" == "RETRIEVE" ]]; then
        tok_len=8; tok_type=0
      elif [[ "${line[$((pos+1)),$((pos+6))]}" == "IGNORE" ]]; then
        tok_len=6; tok_type=0
      elif [[ "${line[$((pos+1)),$((pos+8))]}" == "REMEMBER" ]]; then
        tok_len=8; tok_type=0
      elif [[ "${line[$((pos+1))]}" == "." || "${line[$((pos+1))]}" == ":" || "${line[$((pos+1))]}" == "," || "${line[$((pos+1))]}" == ";" ]]; then
        # Variable .N or :N or ,N or ;N
        tok_len=1
        local p=$((pos + 1))
        while (( p < len )) && [[ "${line[$((p+1))]}" =~ [0-9] ]]; do
          tok_len=$((tok_len + 1))
          p=$((p + 1))
        done
        tok_type=1
      elif [[ "${line[$((pos+1))]}" == "#" ]]; then
        # Numeric literal #N
        tok_len=1
        local p=$((pos + 1))
        while (( p < len )) && [[ "${line[$((p+1))]}" =~ [0-9] ]]; do
          tok_len=$((tok_len + 1))
          p=$((p + 1))
        done
        tok_type=2
      elif [[ "${line[$((pos+1))]}" == "(" ]]; then
        # Label (N)
        tok_len=1
        local p=$((pos + 1))
        while (( p < len )) && [[ "${line[$((p+1))]}" != ")" ]]; do
          tok_len=$((tok_len + 1))
          p=$((p + 1))
        done
        if (( p < len )) && [[ "${line[$((p+1))]}" == ")" ]]; then
          tok_len=$((tok_len + 1))
        fi
        tok_type=3
      else
        pos=$((pos + 1))
        continue
      fi
      if (( tok_type >= 0 )); then
        local delta_line=$((lineno - 1 - prev_line))
        local delta_start
        if (( delta_line == 0 )); then
          delta_start=$((start - prev_start))
        else
          delta_start=$start
        fi
        (( first )) || out+=","
        first=0
        out+="${delta_line},${delta_start},${tok_len},${tok_type},0"
        prev_line=$((lineno - 1))
        prev_start=$start
        pos=$((pos + tok_len))
      fi
    done
  done <<< "$text"
  out+="]"
  REPLY="$out"
}

# Hover: extract the token under the cursor and return its kind.
compute_hover() {
  local text="$1"
  local line=$2
  local character=$3
  # Find the line at the given index
  local target_line=""
  local lineno=0
  while IFS= read -r l; do
    if (( lineno == line )); then
      target_line="$l"
      break
    fi
    lineno=$((lineno + 1))
  done <<< "$text"
  if [[ -z "$target_line" ]]; then
    REPLY=""
    return
  fi
  # Try to identify the token at character
  local cstart=$character
  while (( cstart > 0 )) && [[ "${target_line[$cstart]}" =~ [A-Za-z0-9._:,\;\#] ]]; do
    cstart=$((cstart - 1))
  done
  cstart=$((cstart + 1))
  local cend=$((character + 1))
  while (( cend <= ${#target_line} )) && [[ "${target_line[$cend]}" =~ [A-Za-z0-9] ]]; do
    cend=$((cend + 1))
  done
  local tok="${target_line[$cstart,$((cend-1))]}"
  local docs=""
  case "$tok" in
    DO) docs="INTERCAL imperative mood verb. Equivalent to PLEASE DO." ;;
    PLEASE) docs="INTERCAL polite verb. Statements with PLEASE count toward the politeness ratio (1/5 to 1/3 of total)." ;;
    NEXT) docs="Push current return point and transfer control to the labelled statement." ;;
    RESUME) docs="Pop N return points from the NEXT stack and continue execution at the last popped point." ;;
    FORGET) docs="Pop N return points from the NEXT stack without transferring control." ;;
    STASH) docs="Push the current value of the listed variables onto their per-variable stacks." ;;
    RETRIEVE) docs="Pop the most-recently STASH'd value of each listed variable. Triggers ICL436I if the stash is empty." ;;
    IGNORE) docs="Mark variables as read-only; subsequent assignments are silently discarded." ;;
    REMEMBER) docs="Reverse a previous IGNORE." ;;
    ABSTAIN) docs="Disable a labelled statement (or all statements of a gerund kind) until reinstated." ;;
    REINSTATE) docs="Re-enable a previously ABSTAINed statement (or gerund kind)." ;;
    GIVE) docs="GIVE UP terminates the program (clean exit)." ;;
    COME) docs="COME FROM (label) — after the labelled statement runs, control transfers here. Adopted in this compiler as a standard feature even though INTERCAL-72 omitted it." ;;
    READ) docs="READ OUT — write variables (Roman numerals for scalars, Turing Text Model for arrays)." ;;
    WRITE) docs="WRITE IN — read variables. Scalars expect spelled-out English digit names (ONE TWO THREE for 123)." ;;
    FROM) docs="Continuation of NEXT FROM (non-standard, this compiler's loop primitive: backward branch with no NEXT-stack push) or COME FROM. See docs/loop-extension.md." ;;
    *.[0-9]*|*:[0-9]*) docs="INTERCAL variable. Prefix . is 16-bit (spot), : is 32-bit (twospot), , is 16-bit array (tail), ; is 32-bit array (hybrid)." ;;
    *) docs="" ;;
  esac
  if [[ -n "$docs" ]]; then
    docs=${docs//\"/\\\"}
    REPLY='{"contents":{"kind":"markdown","value":"**'"$tok"'**: '"$docs"'"}}'
  else
    REPLY='null'
  fi
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
        local caps='{"textDocumentSync":1,"diagnosticProvider":{"interFileDependencies":false,"workspaceDiagnostics":false},"hoverProvider":true,"semanticTokensProvider":{"legend":{"tokenTypes":'"$SEMANTIC_TOKEN_TYPES"',"tokenModifiers":[]},"full":true},"completionProvider":{"triggerCharacters":[".",":",",",";","#","("]},"definitionProvider":true,"documentSymbolProvider":true}'
        local resp='{"jsonrpc":"2.0","id":'"$id"',"result":{"capabilities":'"$caps"',"serverInfo":{"name":"intercal-lsp","version":"0.4.0"}}}'
        send_message "$resp"
        log "-> initialize response"
        ;;
      textDocument/completion)
        local uri=""
        if get_field "$msg" "uri"; then uri="$REPLY"; fi
        local text="${doc_text[$uri]:-}"
        local items_json='['
        local first=1
        local kw
        # Keywords (CompletionItemKind = 14 for Keyword)
        for kw in DO PLEASE NEXT RESUME FORGET STASH RETRIEVE IGNORE REMEMBER ABSTAIN REINSTATE FROM "COME FROM" "READ OUT" "WRITE IN" "GIVE UP"; do
          (( first )) || items_json+=','
          first=0
          items_json+='{"label":"'"$kw"'","kind":14,"detail":"INTERCAL keyword"}'
        done
        # Variables present in the document
        local seen_vars=""
        local v=""
        for v in $(echo "$text" | grep -oE '\.[0-9]+|:[0-9]+|,[0-9]+|;[0-9]+' | sort -u); do
          (( first )) || items_json+=','
          first=0
          items_json+='{"label":"'"$v"'","kind":6,"detail":"INTERCAL variable used in this file"}'
        done
        # Labels in parens
        for v in $(echo "$text" | grep -oE '\([0-9]+\)' | sort -u); do
          (( first )) || items_json+=','
          first=0
          items_json+='{"label":"'"$v"'","kind":17,"detail":"INTERCAL label"}'
        done
        items_json+=']'
        local resp='{"jsonrpc":"2.0","id":'"$id"',"result":{"isIncomplete":false,"items":'"$items_json"'}}'
        send_message "$resp"
        ;;
      textDocument/definition)
        local uri="" line=0 character=0
        if get_field "$msg" "uri"; then uri="$REPLY"; fi
        if [[ "$msg" =~ '"line":[[:space:]]*([0-9]+)' ]]; then line="${match[1]}"; fi
        if [[ "$msg" =~ '"character":[[:space:]]*([0-9]+)' ]]; then character="${match[1]}"; fi
        local text="${doc_text[$uri]:-}"
        # Extract the label number under the cursor (in parens)
        local target_line=""
        local lineno=0
        while IFS= read -r l; do
          if (( lineno == line )); then target_line="$l"; break; fi
          lineno=$((lineno + 1))
        done <<< "$text"
        # Walk character forward/backward to find a (NN) pattern around the cursor.
        local lblnum=""
        if [[ "$target_line" =~ \(([0-9]+)\) ]]; then
          # Find any (N) on this line; if cursor near it, use it.
          lblnum="${match[1]}"
        fi
        local result='null'
        if [[ -n "$lblnum" ]]; then
          # Find the labelled statement: a line containing "(<lblnum>)"
          local def_line=-1
          local i=0
          while IFS= read -r l; do
            if [[ "$l" =~ \(${lblnum}\) ]] && [[ "$l" != *"NEXT"* ]] \
               && [[ "$l" != *"COME FROM"* ]] && [[ "$l" != *"ABSTAIN"* ]] \
               && [[ "$l" != *"REINSTATE"* ]] && [[ "$l" != *"FORGET"* ]] \
               && [[ "$l" != *"RESUME"* ]]; then
              def_line=$i
              break
            fi
            i=$((i + 1))
          done <<< "$text"
          if (( def_line >= 0 )); then
            result='{"uri":"'"$uri"'","range":{"start":{"line":'"$def_line"',"character":0},"end":{"line":'"$def_line"',"character":1}}}'
          fi
        fi
        local resp='{"jsonrpc":"2.0","id":'"$id"',"result":'"$result"'}'
        send_message "$resp"
        ;;
      textDocument/documentSymbol)
        # Return one DocumentSymbol per labelled statement so editors
        # can render an outline/structure view of the program.
        local uri=""
        if get_field "$msg" "uri"; then uri="$REPLY"; fi
        local text="${doc_text[$uri]:-}"
        local symbols_json='['
        local first=1
        local lineno=0
        local -a lines
        lines=("${(@f)text}")
        local l=""
        for l in "${lines[@]}"; do
          if [[ "$l" =~ '\(([0-9]+)\)[[:space:]]*(DO|PLEASE|PLSDO|DON'\''T)' ]]; then
            local lblnum="${match[1]}"
            local kind=12
            (( first )) || symbols_json+=','
            first=0
            local llen=${#l}
            symbols_json+='{"name":"('"$lblnum"')","kind":'"$kind"',"range":{"start":{"line":'"$lineno"',"character":0},"end":{"line":'"$lineno"',"character":'"$llen"'}},"selectionRange":{"start":{"line":'"$lineno"',"character":0},"end":{"line":'"$lineno"',"character":'"$llen"'}}}'
          fi
          lineno=$((lineno + 1))
        done
        symbols_json+=']'
        local resp='{"jsonrpc":"2.0","id":'"$id"',"result":'"$symbols_json"'}'
        send_message "$resp"
        ;;
      textDocument/semanticTokens/full)
        local uri=""
        if get_field "$msg" "uri"; then uri="$REPLY"; fi
        local text="${doc_text[$uri]:-}"
        compute_semantic_tokens "$text"
        local data="$REPLY"
        local resp='{"jsonrpc":"2.0","id":'"$id"',"result":{"data":'"$data"'}}'
        send_message "$resp"
        ;;
      textDocument/hover)
        local uri="" line=0 character=0
        if get_field "$msg" "uri"; then uri="$REPLY"; fi
        if [[ "$msg" =~ '"line":[[:space:]]*([0-9]+)' ]]; then
          line="${match[1]}"
        fi
        if [[ "$msg" =~ '"character":[[:space:]]*([0-9]+)' ]]; then
          character="${match[1]}"
        fi
        local text="${doc_text[$uri]:-}"
        compute_hover "$text" "$line" "$character"
        local result="${REPLY:-null}"
        local resp='{"jsonrpc":"2.0","id":'"$id"',"result":'"$result"'}'
        send_message "$resp"
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
          # Unescape \n \r \". $'\n' inside ${var//pat/repl} is NOT
          # expanded as a C-escape — it ends up as literal "$'\n'".
          # Hoist the newline / CR characters into local variables so
          # the substitution sees real bytes.
          local _NL=$'\n' _CR=$'\r'
          text="${text//\\n/$_NL}"
          text="${text//\\r/$_CR}"
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
          local _NL=$'\n' _CR=$'\r'
          text="${text//\\n/$_NL}"
          text="${text//\\r/$_CR}"
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
