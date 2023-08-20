"""
Merge std string name output with the file given as argument
"""
import sys

def read_file(fpath):
    with open(fpath) as handle:
        names = {}
        lines = []
        for line in handle:
            line = line.strip()
            if not line or line.startswith("#") or line.startswith("--"):
                lines.append(line)
            else:
                i = line.find('=')
                if i < 0:
                    names[line] = len(lines)
                    lines.append(line)
                else:
                    names[line[:i].strip()] = len(lines)
                    lines.append(line)

    return names, lines

def read_stdin():
    for line in sys.stdin:
        yield line.strip()

def run():
    if len(sys.argv) != 2:
        print("Expected a file path argument with available string translations")
        sys.exit(1)

    names, lines = read_file(sys.argv[1])
    print(f"{len(names)} names in {len(lines)} lines")

    ignored = ["",
        "make -C /newhome/alberth/dev/corsix-th/corsix_level-editor4 run",
        "make[1]: Entering directory '/newhome/alberth/dev/corsix-th/corsix_level-editor4'",
        "./build/CorsixTH/run-corsixth-dev.sh",
        "---------------------------------------------------------------",
        "Welcome to CorsixTH v0.67-beta1!",
        "This window will display useful information if an error occurs.",
        "make[1]: Leaving directory '/newhome/alberth/dev/corsix-th/corsix_level-editor4'",
    ]
    for line in read_stdin():
        if line in ignored:
            continue

        if line not in names:
            print(line)
            names[line] = len(lines)
            lines.append(line)
    print("DONE")

if __name__ == "__main__":
    run()

