import QtQuick
import "../Twilight/Core/util/Toml.js" as Toml

// Tests for the TOML reader and writer. Needs only Qt's qml tool:
//     QT_QPA_PLATFORM=offscreen qml tests/toml.qml
// Exits with a non-zero code when a check fails.
Item {
    Component.onCompleted: {
        try {
            run();
        } catch (e) {
            console.log("FAIL exception:", e);
            Qt.exit(1);
        }
    }

    function run() {
        let pass = 0, fails = 0;
        const eq = (name, got, want) => {
            const g = JSON.stringify(got), w = JSON.stringify(want);
            if (g === w) pass++; else { fails++; console.log("FAIL", name, "\n  got ", g, "\n  want", w); }
        };
        const throws = (name, fn, part) => {
            try { fn(); fails++; console.log("FAIL", name, "did not throw"); }
            catch (e) { if (String(e.message).includes(part)) pass++; else { fails++; console.log("FAIL", name, "wrong error:", e.message); } }
        };

        // reading
        eq("basic", Toml.parse('a = 1\nb = "x"\nc = true\nd = 1.5\n'), {a:1,b:"x",c:true,d:1.5});
        eq("comments", Toml.parse('# top\na = 1 # side\n\n  # indented\nb = "has # hash"\n'), {a:1,b:"has # hash"});
        eq("tables", Toml.parse('x = 1\n[bar]\nh = 36\n[bar.island]\nlift = 5\n[other]\nk = "v"'), {x:1,bar:{h:36,island:{lift:5}},other:{k:"v"}});
        eq("dotted", Toml.parse('a.b.c = 1\na.b.d = 2\n'), {a:{b:{c:1,d:2}}});
        eq("arrays", Toml.parse('t = ["ghostty", "-e"]\nn = [1, 2,\n 3, # c\n]\nm = [[1],[2,3]]\ne = []'), {t:["ghostty","-e"],n:[1,2,3],m:[[1],[2,3]],e:[]});
        eq("inline", Toml.parse('p = { x = 1, y = "a" }\nq = {}'), {p:{x:1,y:"a"},q:{}});
        eq("escapes", Toml.parse('a = "q\\"\\n\\t\\\\ \\u00e9"\nb = \'C:\\path\\n\''), {a:'q"\n\t\\ é', b:'C:\\path\\n'});
        eq("multiline", Toml.parse('a = """\nl1\nl2"""\nb = \'\'\'raw\\n\'\'\''), {a:"l1\nl2", b:"raw\\n"});
        eq("numbers", Toml.parse('a = 1_000\nb = -5\nc = 0xff\nd = 1e3\ne = +2\nf = inf'), {a:1000,b:-5,c:255,d:1000,e:2,f:null});
        eq("quoted keys", Toml.parse('"a b" = 1\n[ "x.y" ]\nk = 2'), {"a b":1,"x.y":{k:2}});
        eq("crlf", Toml.parse('a = 1\r\n[t]\r\nb = 2\r\n'), {a:1,t:{b:2}});
        eq("empty", Toml.parse(''), {});
        throws("dup", () => Toml.parse('a = 1\na = 2'), "duplicate");
        throws("no value", () => Toml.parse('a ='), "unexpected value");
        throws("bad str", () => Toml.parse('a = "x'), "unterminated");
        throws("junk", () => Toml.parse('a = 1 2'), "unexpected");
        throws("line no", () => Toml.parse('a = 1\nb = 2\nc = ?'), "line 3");
        throws("aot", () => Toml.parse('[[x]]'), "not supported");

        // lookup
        eq("lookup", Toml.lookup({a:{b:1}}, ["a", "b"]), 1);
        eq("lookup missing", Toml.lookup({a:{b:1}}, ["a", "c"]), undefined);
        eq("lookup through a value", Toml.lookup({a:1}, ["a", "b"]), undefined);
        eq("lookup false", Toml.lookup({a:false}, ["a"]), false);

        // template
        eq("template", Toml.template('# why\na = 1\n\n[t]\nb = [1,\n 2]\n'),
           '# Every setting with its default value. Change what you like.\n\n# why\na = 1\n\n[t]\nb = [1,\n 2]\n');
        eq("template parses to the defaults", Toml.parse(Toml.template('a = 1\n[t]\nb = 2')), {a:1,t:{b:2}});
        eq("template then set", Toml.parse(Toml.set(Toml.template('a = 1\n[t]\nb = 2'), ["t", "b"], 5)), {a:1,t:{b:5}});

        // writing
        const doc = '# my config\nterminal = "xterm"  # which one\nsize = 3\n\n[bar]\nheight = 36 # px\n\n[popouts]\nfoo = 1\n';
        eq("set existing keeps comment", Toml.set(doc, ["terminal"], "ghostty"), doc.replace('"xterm"', '"ghostty"'));
        eq("set table key", Toml.set(doc, ["bar", "height"], 40), doc.replace("36 #", "40 #"));
        eq("add root key", Toml.set(doc, ["new"], true), doc.replace('size = 3\n', 'size = 3\nnew = true\n'));
        eq("add table key", Toml.set(doc, ["bar", "gap"], 8), doc.replace('height = 36 # px\n', 'height = 36 # px\ngap = 8\n'));
        eq("add table", Toml.set(doc, ["fresh", "x"], [1, "a"]), doc + '\n[fresh]\nx = [1, "a"]\n');
        eq("empty doc", Toml.set('', ["a", "b"], 1), '[a]\nb = 1\n');
        eq("empty doc root", Toml.set('', ["a"], 1), 'a = 1\n');
        eq("multiline array replaced", Toml.set('t = [\n  1,\n  2,\n] # keep\nz = 1\n', ["t"], [9]), 't = [9] # keep\nz = 1\n');
        eq("string needing escape", Toml.set('a = 1', ["a"], 'q"\n'), 'a = "q\\"\\n"');
        eq("hash in string untouched", Toml.set('a = "x # y" # c\n', ["a"], "z"), 'a = "z" # c\n');
        eq("roundtrip", Toml.parse(Toml.set(Toml.set(doc, ["bar", "height"], 41), ["terminal"], 'a "b" \\ c')).bar.height, 41);
        eq("roundtrip str", Toml.parse(Toml.set(doc, ["terminal"], 'a "b" \\ c é')).terminal, 'a "b" \\ c é');
        eq("same key other table", Toml.set('x = 1\n[t]\nx = 2\n', ["t", "x"], 5), 'x = 1\n[t]\nx = 5\n');
        eq("crlf kept", Toml.set('a = 1\r\nb = 2\r\n', ["a"], 7), 'a = 7\r\nb = 2\r\n');

        console.log("TOML TESTS:", pass, "passed,", fails, "failed");
        Qt.exit(fails === 0 ? 0 : 1);
    }
}
