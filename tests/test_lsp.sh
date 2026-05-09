#!/bin/zsh
# Verify the minimal LSP server responds to initialize.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
LSP="${ROOT_DIR}/src/lsp/intercal_lsp.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

# Construct an initialize request
INIT_BODY='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":12345,"rootUri":null,"capabilities":{}}}'
INIT_LEN=${#INIT_BODY}

EXIT_BODY='{"jsonrpc":"2.0","method":"exit"}'
EXIT_LEN=${#EXIT_BODY}

# Send initialize then exit
RESP=$(printf 'Content-Length: %d\r\n\r\n%sContent-Length: %d\r\n\r\n%s' \
  "$INIT_LEN" "$INIT_BODY" "$EXIT_LEN" "$EXIT_BODY" | zsh "$LSP" 2>/dev/null)

# Test 1: response contains capabilities
if [[ "$RESP" == *"capabilities"* ]]; then
  echo "PASS initialize returns capabilities"
  PASS=$((PASS + 1))
else
  echo "FAIL initialize response"
  echo "  got: $RESP" | head -c 200
  FAIL=$((FAIL + 1))
fi

# Test 2: response includes serverInfo
if [[ "$RESP" == *"serverInfo"* ]]; then
  echo "PASS server info present"
  PASS=$((PASS + 1))
else
  echo "FAIL server info missing"
  FAIL=$((FAIL + 1))
fi

# Test 3a: server advertises hover and semantic tokens
if [[ "$RESP" == *"hoverProvider"* ]] && [[ "$RESP" == *"semanticTokensProvider"* ]]; then
  echo "PASS hover + semantic tokens advertised"
  PASS=$((PASS + 1))
else
  echo "FAIL hover/semantic tokens not advertised"
  FAIL=$((FAIL + 1))
fi

# Test 3b: semanticTokens/full request returns a data array
SEMTOK_BODY='{"jsonrpc":"2.0","id":2,"method":"textDocument/semanticTokens/full","params":{"textDocument":{"uri":"file:///tmp/x.i"}}}'
DIDOPEN_BODY='{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":"file:///tmp/x.i","languageId":"intercal","version":1,"text":"DO .1 <- #5"}}}'
RESP_TOK=$(printf 'Content-Length: %d\r\n\r\n%sContent-Length: %d\r\n\r\n%sContent-Length: %d\r\n\r\n%sContent-Length: %d\r\n\r\n%s' \
  ${#INIT_BODY} "$INIT_BODY" \
  ${#DIDOPEN_BODY} "$DIDOPEN_BODY" \
  ${#SEMTOK_BODY} "$SEMTOK_BODY" \
  ${#EXIT_BODY} "$EXIT_BODY" | zsh "$LSP" 2>/dev/null)
if [[ "$RESP_TOK" == *"\"data\":["* ]]; then
  echo "PASS semanticTokens returns data"
  PASS=$((PASS + 1))
else
  echo "FAIL semanticTokens missing data"
  FAIL=$((FAIL + 1))
fi

# Test extra: completion provider advertised
if [[ "$RESP" == *"completionProvider"* ]]; then
  echo "PASS completion advertised"
  PASS=$((PASS + 1))
else
  echo "FAIL completion not advertised"
  FAIL=$((FAIL + 1))
fi

# Test extra: definition provider advertised
if [[ "$RESP" == *"definitionProvider"* ]]; then
  echo "PASS definition advertised"
  PASS=$((PASS + 1))
else
  echo "FAIL definition not advertised"
  FAIL=$((FAIL + 1))
fi

# Test extra: completion request returns items including DO and PLEASE
COMPL_BODY='{"jsonrpc":"2.0","id":3,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/x.i"},"position":{"line":0,"character":0}}}'
DIDOPEN_BODY2='{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":"file:///tmp/x.i","languageId":"intercal","version":1,"text":"DO .1 <- #5\nPLEASE GIVE UP"}}}'
RESP_COMPL=$(printf 'Content-Length: %d\r\n\r\n%sContent-Length: %d\r\n\r\n%sContent-Length: %d\r\n\r\n%sContent-Length: %d\r\n\r\n%s' \
  ${#INIT_BODY} "$INIT_BODY" \
  ${#DIDOPEN_BODY2} "$DIDOPEN_BODY2" \
  ${#COMPL_BODY} "$COMPL_BODY" \
  ${#EXIT_BODY} "$EXIT_BODY" | zsh "$LSP" 2>/dev/null)
if [[ "$RESP_COMPL" == *"\"DO\""* ]] && [[ "$RESP_COMPL" == *"\"PLEASE\""* ]]; then
  echo "PASS completion includes DO + PLEASE"
  PASS=$((PASS + 1))
else
  echo "FAIL completion missing DO/PLEASE"
  FAIL=$((FAIL + 1))
fi

# Test extra: documentSymbol provider advertised
if [[ "$RESP" == *"documentSymbolProvider"* ]]; then
  echo "PASS documentSymbol advertised"
  PASS=$((PASS + 1))
else
  echo "FAIL documentSymbol not advertised"
  FAIL=$((FAIL + 1))
fi

# Test extra: documentSymbol returns labelled statements
DOCSYM_BODY='{"jsonrpc":"2.0","id":4,"method":"textDocument/documentSymbol","params":{"textDocument":{"uri":"file:///tmp/sym.i"}}}'
DIDOPEN_BODY3='{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":"file:///tmp/sym.i","languageId":"intercal","version":1,"text":"DO .1 <- #5\n(10) DO READ OUT .1\n(20) DO GIVE UP"}}}'
RESP_SYM=$(printf 'Content-Length: %d\r\n\r\n%sContent-Length: %d\r\n\r\n%sContent-Length: %d\r\n\r\n%sContent-Length: %d\r\n\r\n%s' \
  ${#INIT_BODY} "$INIT_BODY" \
  ${#DIDOPEN_BODY3} "$DIDOPEN_BODY3" \
  ${#DOCSYM_BODY} "$DOCSYM_BODY" \
  ${#EXIT_BODY} "$EXIT_BODY" | zsh "$LSP" 2>/dev/null)
if [[ "$RESP_SYM" == *'"name":"(10)"'* ]] && [[ "$RESP_SYM" == *'"name":"(20)"'* ]]; then
  echo "PASS documentSymbol returns labelled stmts (10) and (20)"
  PASS=$((PASS + 1))
else
  echo "FAIL documentSymbol missing labels"
  FAIL=$((FAIL + 1))
fi

# Test 3: response uses Content-Length framing
if [[ "$RESP" == "Content-Length:"* ]]; then
  echo "PASS Content-Length framing"
  PASS=$((PASS + 1))
else
  echo "FAIL framing"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
