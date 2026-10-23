from pathlib import Path
import re

source = Path('tool/apply_mvp_update.py').read_text(encoding='utf-8')
start = source.index("write('lib/core/resume_parser.dart'")
namespace = {}
exec(source[:start], namespace)

def replace(path, old, new):
    p = Path(path)
    text = p.read_text(encoding='utf-8')
    if old in text:
        p.write_text(text.replace(old, new), encoding='utf-8')
        return
    # Dart indentation has no meaning; tolerate the existing two-space style.
    pattern = r'\n[ \t]*'.join(re.escape(line.lstrip(' \t')) for line in old.split('\n'))
    changed, count = re.subn(pattern, lambda m: new, text)
    if count:
        p.write_text(changed, encoding='utf-8')
        return
    if new in text:
        return
    # Also allow the idempotent replacement in different leading indentation.
    new_pattern = r'\n[ \t]*'.join(re.escape(line.lstrip(' \t')) for line in new.split('\n'))
    if re.search(new_pattern, text):
        return
    raise RuntimeError(f'Migration anchor missing: {path}: {old[:80]}')

namespace['replace'] = replace
exec(source[start:], namespace)
