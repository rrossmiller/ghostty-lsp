import json
import re

struct_re = re.compile(r"pub const Doc = struct {.*};")

doc_str = r"pub const doc_str = \\"


def fill_doc(doc: dict[str, str], to_doc: list[str], desc: str):
    for d in to_doc:
        doc[d] = desc


if __name__ == "__main__":
    with open("docs.md") as f:
        lines = f.read().splitlines()

    docs = [
        l.replace("#", "").replace("`", "").strip() for l in lines if l.startswith("##")
    ]
    docs = dict.fromkeys(docs, "")

    # find description sections
    doc_start = None
    to_doc = []
    for i, l in enumerate(lines):
        # parse key
        if l.startswith("##"):
            # if there are empty docs, fill them in with above section
            if doc_start is not None:
                desc = "\n".join(x for x in lines[doc_start:i])
                fill_doc(docs, to_doc, desc)

                to_doc.clear()
                doc_start = None

            k = l.replace("#", "").replace("`", "").strip()
            docs[k] = ""
            to_doc.append(k)
        elif doc_start is None:
            doc_start = i

    # remove leading and trailing \n
    for k, v in docs.items():
        docs[k] = v.strip("\n")

    doc_str += json.dumps(docs)
    with open("../src/docs/doc_text.zig", "w") as f:
        f.write(doc_str)
        f.write("\n;")
