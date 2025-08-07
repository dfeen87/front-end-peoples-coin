import os
import re

LIB_DIR = 'lib/'

# Map method names to their expected named parameters (for replacement)
NAMED_PARAMS = {
    'fetchUserActions': ['userId', 'idToken'],
    'fetchUser': ['userId'],
    'getAuthenticatedUserProfile': ['idToken'],
    'getUserGoodwillActions': ['userId', 'idToken'],
    'listProposals': ['status', 'idToken'],
    'getProposalDetails': ['proposalId', 'idToken'],
    'createProposal': ['proposal', 'idToken'],
    'submitVote': ['vote', 'idToken'],
    'sendLoves': ['sendLovesData', 'idToken'],
}

# Regex to find method calls with positional arguments e.g. foo(x, y)
METHOD_CALL_RE = re.compile(r'(\w+)\s*\(\s*([^\)]*)\)')

# Fix .isEmpty on nullable string: replace "token.isEmpty" with "(token ?? '').isEmpty"
IS_EMPTY_RE = re.compile(r'(\w+)\.isEmpty')

# Fix double.tryParse on Object: find double.tryParse(something) where something is not string literal
DOUBLE_TRYPARSE_RE = re.compile(r'double\.tryParse\(\s*([^\)]+?)\s*\)')

def replace_positional_args(line):
    # Replace calls like fetchUserActions(userId, idToken) with fetchUserActions(userId: userId, idToken: idToken)
    # This will only handle methods in NAMED_PARAMS that appear in the line

    for method, params in NAMED_PARAMS.items():
        if f'{method}(' in line:
            # Find all calls to method and rewrite their positional args to named args
            def repl(m):
                if m.group(1) != method:
                    return m.group(0)
                args = m.group(2)
                # Split args by comma respecting nested parentheses (basic split)
                parts = []
                depth = 0
                current = ''
                for c in args:
                    if c == ',' and depth == 0:
                        parts.append(current.strip())
                        current = ''
                    else:
                        if c == '(':
                            depth += 1
                        elif c == ')':
                            depth -= 1
                        current += c
                if current.strip():
                    parts.append(current.strip())

                # If the count matches expected, rewrite
                if len(parts) == len(params):
                    named = [f'{pname}: {pval}' for pname, pval in zip(params, parts)]
                    return f'{method}({", ".join(named)})'
                else:
                    # If mismatch, return original
                    return m.group(0)

            line = re.sub(rf'{method}\s*\([^\)]*\)', repl, line)
    return line

def fix_is_empty(line):
    # Replace token.isEmpty with (token ?? '').isEmpty if token is nullable
    return IS_EMPTY_RE.sub(r'(\1 ?? \'\').isEmpty', line)

def fix_double_tryparse(line):
    # Replace double.tryParse(obj) with double.tryParse(obj.toString())
    def repl(m):
        inner = m.group(1).strip()
        # If inner is string literal, don't change
        if inner.startswith("'") or inner.startswith('"'):
            return m.group(0)
        # If inner already has .toString(), skip
        if '.toString()' in inner:
            return m.group(0)
        return f'double.tryParse({inner}.toString())'

    return DOUBLE_TRYPARSE_RE.sub(repl, line)

def fix_sendLoves_call(line):
    # Convert sendLoves(senderWalletId: ..., recipientWalletId: ..., amount: ..., idToken: ...)
    # to sendLoves(sendLovesData: {...}, idToken: ...)
    # This is heuristic and will only do if method call includes sendLoves and separate params matching expected keys

    if 'sendLoves(' not in line:
        return line

    # Extract args inside sendLoves(...)
    match = re.search(r'sendLoves\s*\((.*)\)', line)
    if not match:
        return line

    args_str = match.group(1)
    # split args by commas not inside {}
    parts = []
    depth = 0
    current = ''
    for c in args_str:
        if c == ',' and depth == 0:
            parts.append(current.strip())
            current = ''
        else:
            if c == '{':
                depth += 1
            elif c == '}':
                depth -= 1
            current += c
    if current.strip():
        parts.append(current.strip())

    # Collect recognized param values
    recognized = {}
    other_parts = []
    idToken_value = None

    # Keys expected for sendLovesData:
    keys = ['senderWalletId', 'recipientWalletId', 'amount', 'memo']

    for part in parts:
        if part.startswith('idToken:'):
            idToken_value = part[len('idToken:'):].strip()
        else:
            for key in keys:
                if part.startswith(f'{key}:'):
                    recognized[key] = part[len(key)+1:].strip()
                    break
            else:
                other_parts.append(part)

    # If we have at least senderWalletId, recipientWalletId and amount, rewrite
    if all(k in recognized for k in ['senderWalletId', 'recipientWalletId', 'amount']):
        # Compose sendLovesData map string
        map_items = [
            "'sender_wallet_id': " + recognized['senderWalletId'],
            "'recipient_wallet_id': " + recognized['recipientWalletId'],
            "'amount': " + recognized['amount'],
        ]
        if 'memo' in recognized:
            map_items.append("'memo': " + recognized['memo'])

        map_str = '{' + ', '.join(map_items) + '}'

        # Rebuild line with sendLovesData: map_str, plus idToken if present
        new_args = [f'sendLovesData: {map_str}']
        if idToken_value:
            new_args.append(f'idToken: {idToken_value}')

        # Rebuild line
        return re.sub(r'sendLoves\s*\(.*\)', f'sendLoves({", ".join(new_args)})', line)

    return line

def main():
    print("Scanning Dart files in lib/ and fixing common errors...")

    for root, dirs, files in os.walk(LIB_DIR):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    lines = f.readlines()

                changed = False
                new_lines = []
                for line in lines:
                    original = line
                    line = replace_positional_args(line)
                    line = fix_is_empty(line)
                    line = fix_double_tryparse(line)
                    line = fix_sendLoves_call(line)
                    if line != original:
                        changed = True
                    new_lines.append(line)

                if changed:
                    print(f'Updated {filepath}')
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.writelines(new_lines)

    print("Done. Please review your code and run your tests.")

if __name__ == '__main__':
    main()

