"""
Merge all strings given at the input of the form

  x.y[1].y = "<some text>"

into a nested table.
"""
import sys
import re

line_pat = re.compile("\\s*([^ =]+)\\s*=\\s*(\".*\")\\s*,?\\s*")

iden_pat = re.compile("[a-zA-Z_][A-Za-z0-9_]*")
child_iden_pat = re.compile("\\.[a-zA-Z_][A-Za-z0-9_]*")
numeric_index_pat = re.compile("\\[[0-9]+\\]")

def parse_string_name(text, linenum):
    parts = []
    i = 0
    while i < len(text):
        #print(f"Trying to match name part:")
        #print(text + "<<")
        #print((" " * i) + "^")

        if i == 0:
            # Root name expected.
            m = iden_pat.match(text, i)
            if not m:
                #print(f"String name {text} failed to parse at line {linenum}")
                return None
            #print(f"Found {m.group()}")
            parts.append(m.group())
            i = m.end()
            continue

        # Child field expected
        m = child_iden_pat.match(text, i)
        if m:
            stored_text = m.group()[1:]
        else:
            m = numeric_index_pat.match(text, i)
            if not m:
                #print(f"String name {text} failed to parse at line {linenum}")
                return None
            stored_text = m.group()

        #print(f"Found {m.group()}")
        parts.append(stored_text)
        i = m.end()

    return parts


def read_input(fpath, handle, lines):
    with open(fpath, "r") as handle:
        for i, line in enumerate(handle):
            line.strip()
            if line == "" or line.startswith("#") or line.startswith("--"):
                continue # Empty line or comment.
            if "=" in line:
                m = line_pat.fullmatch(line)
                if not m:
                    print(f"Line {i+1} of file \"{fpath}\" is not correct, skipping it.")
                    continue
                parts = parse_string_name(m.group(1), i+1)
                if parts is None:
                    print(f"String name of line {i+1} of file \"{fpath}\" is not correct, skipping it.")
                else:
                    lines.append((parts, m.group(2)))
            else:
                # Just the string name?
                line = line.strip()
                if line:
                    parts = parse_string_name(line, i+1)
                    if parts is None:
                        print(f"String name of line {i+1} of file \"{fpath}\" is not correct, skipping it.")
                    else:
                        lines.append((parts, "\"\""))

def read_lines():
    lines = []
    if len(sys.argv) > 1:
        if "-h" in sys.argv[1:] or "=-help" in sys.argv[1:]:
            print("Usage: Either give file paths to read or supply it at stdin.")
            sys.exit(0)

        for fpath in sys.argv[1:]:
            with open(fpath, "r") as handle:
                read_input(fpath, handle, lines)
    else:
        read_input("<stdin>", sys.stdin, lines)

    return lines

def build_table(lines):
    root = {}
    for parts, text in lines:
        #print(f"parts: {parts}, text={text}")
        num_parts = len(parts)
        current = root
        for i, part in enumerate(parts):
            if i == num_parts - 1:
                child_table = None
                next_value = ("text", text)
            else:
                child_table = {}
                next_value = ("table", child_table)

            exist_child = current.get(part)
            if exist_child is None:
                current[part] = next_value
                current = child_table
            else:
                assert exist_child[0] == "table"
                current = exist_child[1]

    return root

def print_tree(parent, value, indent, last_node):
    def key_func(x):
        #print(x)
        if x[0].startswith("["):
            return (len(x[0]), x[0])
        else:
            return (0, x[0])

    kind, content = value
    if kind == 'text':
        if not last_node:
            print(f"{indent}{parent} = {content},")
        else:
            print(f"{indent}{parent} = {content}")
        return

    assert kind == 'table'
    print(f"{indent}{parent} = {{")
    last_item = len(content) - 1
    for i, (k, v) in enumerate(sorted(content.items(), key=key_func)):
        print_tree(k, v, indent + "  ", i == last_item)
    if not last_node:
        print(f"{indent}}},")
    else:
        print(f"{indent}}}")

if __name__ == "__main__":
    lines = read_lines()

    #print(lines[:10])
    table = build_table(lines)
    #print(table)
    print_tree("level_editor", table['level_editor'], "", True)
