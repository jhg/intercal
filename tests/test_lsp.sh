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
