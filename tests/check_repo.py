#!/usr/bin/env python3
"""Static checks for the HVLisp AutoLISP project (fork of AutoLISP Civil Tools Community)."""
from pathlib import Path
import csv
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
LENH = ROOT / "lenh"
PREFIX = "HV"
# Only this file in lenh/ may call the network (WScript.Shell, PowerShell, http).
NETWORK_ALLOWED = {"hv-update.lsp"}
MODULES = [
    "act-core.lsp",
    "act-coord.lsp",
    "act-export.lsp",
    "act-import.lsp",
    "act-elev.lsp",
    "act-chainage.lsp",
    "act-interp.lsp",
    "act-profile.lsp",
]
NETWORK = [r"https?://", r"startapp", r"wscript\.shell", r"powershell", r"curl", r"wget"]
SECRETS = [r"api[_-]?key", r"password", r"secret", r"token"]
FORBIDDEN = NETWORK + SECRETS
PUBLIC_COMMANDS = {"CTCOORD", "CTEXPORT", "CTIMPORT", "CTELEV", "CTCHAINAGE", "CTINTERP", "CTPROFILE"}
# Calls that change the drawing: a lenh/ file using them must use Undo marks and *error*.
EDIT_CALLS = [r"\(entmakex?\s", r"\(entmod\s", r"\(entdel\s", r"\(command\s", r"\(vl-cmdf\s", r"\(vla-(?:add|delete|put-)"]
VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")


def code_without_comments(text):
    output = []
    for line in text.splitlines():
        clean = []
        in_string = False
        escaped = False
        for char in line:
            if char == '"' and not escaped:
                in_string = not in_string
            if char == ";" and not in_string:
                break
            clean.append(char)
            escaped = char == "\\" and not escaped
            if char != "\\":
                escaped = False
        output.append("".join(clean))
    return "\n".join(output)


def check_parentheses(path, text, failures):
    depth = 0
    in_string = False
    escaped = False
    for char in code_without_comments(text):
        if char == '"' and not escaped:
            in_string = not in_string
        elif not in_string and char == "(":
            depth += 1
        elif not in_string and char == ")":
            depth -= 1
            if depth < 0:
                failures.append(f"{path}: closing parenthesis without opening parenthesis")
                return
        escaped = char == "\\" and not escaped
        if char != "\\":
            escaped = False
    if depth != 0 or in_string:
        failures.append(f"{path}: unbalanced parentheses or string")


def check_patterns(path, text, patterns, failures):
    code = code_without_comments(text)
    for pattern in patterns:
        if re.search(pattern, code, flags=re.IGNORECASE):
            failures.append(f"{path}: forbidden runtime pattern {pattern}")


def find_commands(text):
    return [name.upper() for name in re.findall(r"\(defun\s+C:([^\s(/]+)", code_without_comments(text), flags=re.IGNORECASE)]


def is_ascii(text):
    return all(ord(char) < 128 for char in text)


def main():
    failures = []

    version_file = ROOT / "VERSION"
    version = version_file.read_text(encoding="utf-8").strip() if version_file.exists() else ""
    if not VERSION_RE.match(version):
        failures.append(f"VERSION must look like X.Y.Z, found {version!r}")

    # src/: original modules, same rules as upstream.
    src_commands = []
    for path in sorted(SRC.glob("*.lsp")):
        text = path.read_text(encoding="utf-8")
        check_parentheses(path, text, failures)
        check_patterns(path, text, FORBIDDEN, failures)
        src_commands.extend(find_commands(text))
    if set(src_commands) != PUBLIC_COMMANDS:
        failures.append("src/ commands must be exactly: " + ", ".join(sorted(PUBLIC_COMMANDS)))

    # lenh/: user commands.
    lenh_commands = []
    lenh_files = sorted(LENH.glob("*.lsp")) if LENH.is_dir() else []
    if not lenh_files:
        failures.append("lenh/ must contain at least one .lsp file")
    for path in lenh_files:
        text = path.read_text(encoding="utf-8")
        check_parentheses(path, text, failures)
        if not is_ascii(text):
            failures.append(f"{path}: must be ASCII only (tieng Viet khong dau)")
        if not text.lstrip().startswith(";"):
            failures.append(f"{path}: must start with a header comment (ten lenh, muc dich, cach dung)")
        patterns = SECRETS if path.name in NETWORK_ALLOWED else FORBIDDEN
        check_patterns(path, text, patterns, failures)
        names = find_commands(text)
        for name in names:
            if not name.startswith(PREFIX):
                failures.append(f"{path}: command C:{name} must start with prefix {PREFIX}")
        code = code_without_comments(text)
        if any(re.search(pattern, code, flags=re.IGNORECASE) for pattern in EDIT_CALLS):
            for contract in ["ACT:undo-start", "ACT:undo-end", "*error*"]:
                if contract not in code:
                    failures.append(f"{path}: edits the drawing but is missing {contract}")
        lenh_commands.extend(names)

    commands = src_commands + lenh_commands
    duplicates = sorted({name for name in commands if commands.count(name) > 1})
    if duplicates:
        failures.append("duplicate public commands: " + ", ".join(duplicates))
    for required in (f"{PREFIX}UPDATE", f"{PREFIX}HELP"):
        if required not in lenh_commands:
            failures.append(f"lenh/ missing command {required}")

    # Command list shown by HVHELP.
    listing = LENH / "danh-sach.txt"
    if listing.exists():
        listing_text = listing.read_text(encoding="utf-8")
        if not is_ascii(listing_text):
            failures.append(f"{listing}: must be ASCII only")
        listed = {line.split(" - ")[0].strip().upper() for line in listing_text.splitlines() if " - " in line}
        for name in sorted(set(commands) - listed):
            failures.append(f"{listing}: missing line 'TENLENH - mo ta' for {name}")
        for name in sorted(listed - set(commands)):
            failures.append(f"{listing}: lists unknown command {name}")
    else:
        failures.append("lenh/danh-sach.txt is missing")

    # Loader.
    loader = (SRC / "act-load.lsp").read_text(encoding="utf-8")
    for module in MODULES:
        if f'"{module}"' not in loader:
            failures.append(f"loader missing module: {module}")
    if re.search(r'ACT:version\s+"\d', loader):
        failures.append("loader must read ACT:version from VERSION, not hard-code it")
    for contract in ['"\\\\VERSION"', "vl-directory-files", "vl-catch-all-apply", "\\\\lenh"]:
        if contract not in loader:
            failures.append(f"loader missing: {contract}")

    core = (SRC / "act-core.lsp").read_text(encoding="utf-8")
    for contract in ["trans", "vla-StartUndoMark", "vla-EndUndoMark", "vlax-curve-getDistAtPoint"]:
        if contract not in core:
            failures.append(f"core missing safety contract: {contract}")
    for command in PUBLIC_COMMANDS:
        matches = [path.read_text(encoding="utf-8") for path in SRC.glob("*.lsp") if f"(defun C:{command} " in path.read_text(encoding="utf-8")]
        if len(matches) == 1 and ("ACT:undo-start" not in matches[0] or "ACT:undo-end" not in matches[0]):
            failures.append(f"{command}: missing command-level Undo contract")

    # Updater script.
    updater = ROOT / "update.ps1"
    if not updater.exists():
        failures.append("update.ps1 is missing")
    else:
        updater_bytes = updater.read_bytes()
        if any(byte > 127 for byte in updater_bytes):
            failures.append("update.ps1 must be ASCII only")
        updater_text = updater_bytes.decode("ascii", errors="replace")
        for contract in ["$Repo", "$Dest", "Tls12", "archive/refs/heads/main.zip", "exit 0", "exit 1"]:
            if contract not in updater_text:
                failures.append(f"update.ps1 missing: {contract}")

    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    if f"## {version} " not in changelog:
        failures.append(f"CHANGELOG.md has no section for version {version}")

    fixture = ROOT / "examples" / "import-points.csv"
    with fixture.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    valid_rows = 0
    for row in rows:
        try:
            tuple(float(row[key]) for key in ("x", "y", "z"))
            valid_rows += 1
        except (TypeError, ValueError):
            pass
    if len(rows) != 5 or valid_rows != 3:
        failures.append("import fixture must contain exactly 3 valid and 2 invalid rows")

    if failures:
        print("FAIL")
        print("\n".join(failures))
        return 1
    print(f"PASS v{version}: source safety, lenh/ rules, manifest, parentheses, and command uniqueness")
    return 0


if __name__ == "__main__":
    sys.exit(main())
