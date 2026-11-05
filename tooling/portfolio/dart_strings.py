"""Locate literal text segments, keeping Dart interpolation expressions intact."""
import re

CYRILLIC = re.compile('[А-Яа-яЁё]')


def segments(source):
    found = []
    n = len(source)

    def code(i, in_expression=False):
        depth = 1 if in_expression else 0
        while i < n:
            if source.startswith('//', i):
                end = source.find('\n', i)
                i = n if end < 0 else end + 1
            elif source.startswith('/*', i):
                level = 1
                i += 2
                while i < n and level:
                    if source.startswith('/*', i): level += 1; i += 2
                    elif source.startswith('*/', i): level -= 1; i += 2
                    else: i += 1
            elif source[i] in "'\"" or (source[i] in 'rR' and i+1<n and source[i+1] in "'\""):
                raw = source[i] in 'rR'
                if raw: i += 1
                i = string(i, raw)
            elif in_expression and source[i] == '{': depth += 1; i += 1
            elif in_expression and source[i] == '}':
                depth -= 1; i += 1
                if depth == 0: return i
            else: i += 1
        return i

    def string(i, raw):
        quote = source[i]
        delimiter = quote * (3 if source.startswith(quote*3,i) else 1)
        i += len(delimiter)
        start = i
        while i < n:
            if source.startswith(delimiter,i):
                if CYRILLIC.search(source[start:i]): found.append((start,i,source[start:i],raw))
                return i + len(delimiter)
            if not raw and source[i] == '\\': i += 2; continue
            if not raw and source.startswith('${',i):
                if CYRILLIC.search(source[start:i]): found.append((start,i,source[start:i],raw))
                i = code(i+2,True); start=i; continue
            if not raw and source[i]=='$' and i+1<n and re.match('[A-Za-z_]',source[i+1]):
                if CYRILLIC.search(source[start:i]): found.append((start,i,source[start:i],raw))
                i += 2
                while i<n and re.match('[A-Za-z0-9_]',source[i]): i+=1
                start=i;continue
            i += 1
        raise ValueError('Unterminated Dart string')
    code(0)
    return sorted(found)
