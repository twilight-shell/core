.pragma library

// A small TOML reader and writer for settings files: tables, dotted keys,
// strings, numbers, booleans, arrays and inline tables. Dates and arrays of
// tables are not supported. Writing changes one value in place, so the comments
// and layout of a file edited by hand survive.

function fail(text, pos, message) {
    const line = text.slice(0, pos).split("\n").length;
    throw new Error("line " + line + ": " + message);
}

const bareKey = /[A-Za-z0-9_-]/;

// ---- reading ----------------------------------------------------------

function parse(text) {
    text = text.replace(/\r\n?/g, "\n");
    const root = {};
    let table = root;
    let pos = 0;

    function peek() {
        return text[pos];
    }

    function skipSpace() {
        while (text[pos] === " " || text[pos] === "\t")
            pos++;
    }

    function skipComment() {
        if (text[pos] === "#")
            while (pos < text.length && text[pos] !== "\n")
                pos++;
    }

    function skipBlank() {
        for (;;) {
            skipSpace();
            skipComment();
            if (text[pos] === "\n")
                pos++;
            else
                return;
        }
    }

    function readString(quote) {
        const multi = text.startsWith(quote.repeat(3), pos);
        const open = multi ? quote.repeat(3) : quote;
        const start = pos;
        pos += open.length;
        // A newline right after the opening quotes of a multi-line string is dropped.
        if (multi && text[pos] === "\n")
            pos++;

        let out = "";
        for (;;) {
            if (pos >= text.length || (!multi && text[pos] === "\n"))
                fail(text, start, "unterminated string");
            if (text.startsWith(open, pos)) {
                // Up to two extra quotes may sit right before the closing ones.
                while (multi && text[pos + 3] === quote) {
                    out += quote;
                    pos++;
                }
                pos += open.length;
                return out;
            }
            const c = text[pos++];
            if (quote === "'" || c !== "\\") {
                out += c;
                continue;
            }

            const e = text[pos++];
            const simple = { b: "\b", t: "\t", n: "\n", f: "\f", r: "\r", '"': '"', "\\": "\\" };
            if (e in simple) {
                out += simple[e];
            } else if (e === "u" || e === "U") {
                const len = e === "u" ? 4 : 8;
                const hex = text.slice(pos, pos + len);
                if (!/^[0-9a-fA-F]+$/.test(hex) || hex.length !== len)
                    fail(text, pos, "bad unicode escape");
                out += String.fromCodePoint(parseInt(hex, 16));
                pos += len;
            } else if (multi && (e === "\n" || e === " " || e === "\t")) {
                // A backslash at the end of a line trims the whitespace after it.
                pos--;
                while (/\s/.test(text[pos] ?? "x"))
                    pos++;
            } else {
                fail(text, pos - 1, "bad escape \\" + e);
            }
        }
    }

    function readKeyPart() {
        if (peek() === '"' || peek() === "'")
            return readString(peek());
        const start = pos;
        while (bareKey.test(text[pos] ?? ""))
            pos++;
        if (pos === start)
            fail(text, pos, "expected a key");
        return text.slice(start, pos);
    }

    function readKey() {
        const parts = [];
        for (;;) {
            skipSpace();
            parts.push(readKeyPart());
            skipSpace();
            if (peek() !== ".")
                return parts;
            pos++;
        }
    }

    function readArray() {
        const out = [];
        pos++;
        for (;;) {
            skipBlank();
            if (peek() === "]") {
                pos++;
                return out;
            }
            out.push(readValue());
            skipBlank();
            if (peek() === ",")
                pos++;
            else if (peek() !== "]")
                fail(text, pos, "expected , or ] in array");
        }
    }

    function readInline() {
        const out = {};
        pos++;
        skipSpace();
        if (peek() === "}") {
            pos++;
            return out;
        }
        for (;;) {
            const key = readKey();
            skipSpace();
            if (peek() !== "=")
                fail(text, pos, "expected =");
            pos++;
            skipSpace();
            assign(out, key, readValue());
            skipSpace();
            if (peek() === ",")
                pos++;
            else if (peek() === "}") {
                pos++;
                return out;
            } else
                fail(text, pos, "expected , or } in inline table");
        }
    }

    function readValue() {
        const c = peek();
        if (c === '"' || c === "'")
            return readString(c);
        if (c === "[")
            return readArray();
        if (c === "{")
            return readInline();

        const start = pos;
        while (pos < text.length && !/[\s,\]}#]/.test(text[pos]))
            pos++;
        const raw = text.slice(start, pos);
        if (raw === "true")
            return true;
        if (raw === "false")
            return false;
        if (raw === "inf" || raw === "+inf")
            return Infinity;
        if (raw === "-inf")
            return -Infinity;
        if (raw === "nan" || raw === "+nan" || raw === "-nan")
            return NaN;

        const num = raw.replace(/_/g, "");
        if (/^[+-]?(0|[1-9]\d*)$/.test(num))
            return parseInt(num, 10);
        if (/^0x[0-9a-f]+$/i.test(num))
            return parseInt(num, 16);
        if (/^0o[0-7]+$/.test(num))
            return parseInt(num.slice(2), 8);
        if (/^0b[01]+$/.test(num))
            return parseInt(num.slice(2), 2);
        if (/^[+-]?(0|[1-9]\d*)(\.\d+)?([eE][+-]?\d+)?$/.test(num))
            return parseFloat(num);
        fail(text, start, "unexpected value '" + raw + "'");
    }

    // Walks down `path` from `base`, creating tables on the way.
    function descend(base, path) {
        let at = base;
        for (const part of path) {
            if (at[part] === undefined)
                at[part] = {};
            else if (typeof at[part] !== "object" || Array.isArray(at[part]))
                fail(text, pos, "'" + part + "' is not a table");
            at = at[part];
        }
        return at;
    }

    function assign(base, path, value) {
        const at = descend(base, path.slice(0, -1));
        const key = path[path.length - 1];
        if (key in at)
            fail(text, pos, "duplicate key '" + key + "'");
        at[key] = value;
    }

    function endOfLine() {
        skipSpace();
        skipComment();
        if (pos < text.length && text[pos] !== "\n")
            fail(text, pos, "unexpected '" + text[pos] + "'");
    }

    for (;;) {
        skipBlank();
        if (pos >= text.length)
            return root;

        if (peek() === "[") {
            if (text[pos + 1] === "[")
                fail(text, pos, "arrays of tables are not supported");
            pos++;
            const path = readKey();
            skipSpace();
            if (peek() !== "]")
                fail(text, pos, "expected ]");
            pos++;
            table = descend(root, path);
        } else {
            const key = readKey();
            skipSpace();
            if (peek() !== "=")
                fail(text, pos, "expected =");
            pos++;
            skipSpace();
            assign(table, key, readValue());
        }
        endOfLine();
    }
}

// ---- writing ----------------------------------------------------------

function formatKey(key) {
    return /^[A-Za-z0-9_-]+$/.test(key) ? key : formatString(key);
}

function formatString(s) {
    return '"' + s.replace(/[\\"\u0000-\u001f\u007f]/g, c => {
        const named = { "\\": "\\\\", '"': '\\"', "\n": "\\n", "\t": "\\t", "\r": "\\r", "\b": "\\b", "\f": "\\f" };
        return named[c] ?? "\\u" + c.charCodeAt(0).toString(16).padStart(4, "0");
    }) + '"';
}

function format(value) {
    if (typeof value === "string")
        return formatString(value);
    if (typeof value === "boolean")
        return value ? "true" : "false";
    if (typeof value === "number") {
        if (isNaN(value))
            return "nan";
        if (!isFinite(value))
            return value > 0 ? "inf" : "-inf";
        return String(value);
    }
    if (Array.isArray(value))
        return "[" + value.map(format).join(", ") + "]";
    if (value !== null && typeof value === "object")
        return "{ " + Object.keys(value).map(k => formatKey(k) + " = " + format(value[k])).join(", ") + " }";
    throw new Error("cannot write " + value);
}

// The text of a value on one line, split from a trailing comment: where the
// value ends in `line` starting at `from`, and how many lines it spans when an
// array runs on.
function valueEnd(lines, index, from) {
    let depth = 0;
    let quote = "";
    for (let i = index; i < lines.length; i++) {
        const line = lines[i];
        for (let j = i === index ? from : 0; j < line.length; j++) {
            const c = line[j];
            if (quote) {
                if (quote === '"' && c === "\\")
                    j++;
                else if (c === quote)
                    quote = "";
            } else if (c === '"' || c === "'") {
                quote = c;
            } else if (c === "[" || c === "{") {
                depth++;
            } else if (c === "]" || c === "}") {
                depth--;
            } else if (c === "#" && depth <= 0) {
                return { line: i, col: j };
            }
        }
        if (depth <= 0 && !quote)
            return { line: i, col: line.length };
    }
    return { line: lines.length - 1, col: lines[lines.length - 1].length };
}

// Tables are named by `[a.b]` headers; the key parsed back out of a line.
function headerOf(line) {
    const m = /^\s*\[([^\[\]]+)\]\s*(#.*)?$/.exec(line);
    return m ? m[1].split(".").map(p => p.trim().replace(/^["']|["']$/g, "")) : null;
}

function samePath(a, b) {
    return a.length === b.length && a.every((p, i) => p === b[i]);
}

// `text` with `path` (["table", "key"]) set to `value`. An existing line is
// changed in place, keeping its comment; otherwise the key is added to its
// table, which is created at the end of the file when it isn't there yet.
function set(text, path, value) {
    const eol = text.includes("\r\n") ? "\r\n" : "\n";
    const lines = text.replace(/\r\n/g, "\n").split("\n");
    const table = path.slice(0, -1);
    const key = path[path.length - 1];
    const rendered = formatKey(key) + " = " + format(value);

    // Find the table's body: from the line after its header (or the top for the
    // root table) up to the next header.
    let start = table.length === 0 ? 0 : -1;
    let end = lines.length;
    for (let i = 0; i < lines.length; i++) {
        const header = headerOf(lines[i]);
        if (!header)
            continue;
        if (start >= 0) {
            end = i;
            break;
        }
        if (table.length > 0 && samePath(header, table))
            start = i + 1;
    }
    if (table.length === 0 && start === 0) {
        // The root table ends at the first header of any kind.
        const first = lines.findIndex(l => headerOf(l));
        end = first < 0 ? lines.length : first;
    }

    if (start < 0) {
        while (lines.length > 0 && lines[lines.length - 1] === "")
            lines.pop();
        if (lines.length > 0)
            lines.push("");
        lines.push("[" + table.map(formatKey).join(".") + "]", rendered, "");
        return lines.join(eol);
    }

    const keyLine = new RegExp("^(\\s*)(" + key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "|\"" + key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "\")(\\s*=\\s*)");
    for (let i = start; i < end; i++) {
        const m = keyLine.exec(lines[i]);
        if (!m)
            continue;
        const valueStart = m[0].length;
        const stop = valueEnd(lines, i, valueStart);
        const tail = lines[stop.line].slice(stop.col);
        // Keep the gap before a trailing comment.
        const gap = /\s*$/.exec(lines[stop.line].slice(0, stop.col))[0];
        const head = lines[i].slice(0, valueStart);
        const comment = tail.startsWith("#") ? gap + tail : "";
        lines.splice(i, stop.line - i + 1, head + format(value) + comment);
        return lines.join(eol);
    }

    // New key: after the last non-blank line of the table's body.
    let at = end;
    while (at > start && lines[at - 1].trim() === "")
        at--;
    lines.splice(at, 0, rendered);
    return lines.join(eol);
}
