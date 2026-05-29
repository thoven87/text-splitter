/// Per-language separator patterns used by `RecursiveCharacterTextSplitter.forLanguage(_:)`.
/// All patterns are regex strings (used with `isSeparatorRegex: true`).
extension Language {
    public var separators: [String] {
        switch self {
        case .c, .cpp:
            return [
                "\nclass ", "\nvoid ", "\nint ", "\nfloat ", "\ndouble ",
                "\nif ", "\nfor ", "\nwhile ", "\nswitch ", "\ncase ",
                "\n\n", "\n", " ", "",
            ]
        case .go:
            return [
                "\nfunc ", "\nvar ", "\nconst ", "\ntype ",
                "\nif ", "\nfor ", "\nswitch ", "\ncase ",
                "\n\n", "\n", " ", "",
            ]
        case .java:
            return [
                "\nclass ",
                "\npublic ", "\nprotected ", "\nprivate ", "\nstatic ",
                "\nif ", "\nfor ", "\nwhile ", "\nswitch ", "\ncase ",
                "\n\n", "\n", " ", "",
            ]
        case .kotlin:
            return [
                "\nclass ",
                "\npublic ", "\nprotected ", "\nprivate ", "\ninternal ",
                "\ncompanion ", "\nfun ", "\nval ", "\nvar ",
                "\nif ", "\nfor ", "\nwhile ", "\nwhen ", "\nelse ",
                "\n\n", "\n", " ", "",
            ]
        case .js:
            return [
                "\nfunction ", "\nconst ", "\nlet ", "\nvar ", "\nclass ",
                "\nif ", "\nfor ", "\nwhile ", "\nswitch ", "\ncase ", "\ndefault ",
                "\n\n", "\n", " ", "",
            ]
        case .ts:
            return [
                "\nenum ", "\ninterface ", "\nnamespace ", "\ntype ",
                "\nclass ", "\nfunction ", "\nconst ", "\nlet ", "\nvar ",
                "\nif ", "\nfor ", "\nwhile ", "\nswitch ", "\ncase ", "\ndefault ",
                "\n\n", "\n", " ", "",
            ]
        case .php:
            return [
                "\nfunction ", "\nclass ",
                "\nif ", "\nforeach ", "\nwhile ", "\ndo ", "\nswitch ", "\ncase ",
                "\n\n", "\n", " ", "",
            ]
        case .proto:
            return [
                "\nmessage ", "\nservice ", "\nenum ", "\noption ",
                "\nimport ", "\nsyntax ",
                "\n\n", "\n", " ", "",
            ]
        case .python:
            return ["\nclass ", "\ndef ", "\n\tdef ", "\n\n", "\n", " ", ""]
        case .r:
            return [
                "\nfunction ",
                "\nsetClass\\(", "\nsetMethod\\(", "\nsetGeneric\\(",
                "\nif ", "\nelse ", "\nfor ", "\nwhile ", "\nrepeat ",
                "\nlibrary\\(", "\nrequire\\(",
                "\n\n", "\n", " ", "",
            ]
        case .rst:
            return [
                "\n=+\n", "\n-+\n", "\n\\*+\n",
                "\n\n.. *\n\n",
                "\n\n", "\n", " ", "",
            ]
        case .ruby:
            return [
                "\ndef ", "\nclass ",
                "\nif ", "\nunless ", "\nwhile ", "\nfor ",
                "\ndo ", "\nbegin ", "\nrescue ",
                "\n\n", "\n", " ", "",
            ]
        case .rust:
            return [
                "\nfn ", "\nconst ", "\nlet ",
                "\nif ", "\nwhile ", "\nfor ", "\nloop ", "\nmatch ",
                "\n\n", "\n", " ", "",
            ]
        case .scala:
            return [
                "\nclass ", "\nobject ",
                "\ndef ", "\nval ", "\nvar ",
                "\nif ", "\nfor ", "\nwhile ", "\nmatch ", "\ncase ",
                "\n\n", "\n", " ", "",
            ]
        case .swift:
            return [
                "\nfunc ", "\nclass ", "\nstruct ", "\nenum ",
                "\nif ", "\nfor ", "\nwhile ", "\ndo ", "\nswitch ", "\ncase ",
                "\n\n", "\n", " ", "",
            ]
        case .markdown:
            return [
                "\n#{1,6} ",
                "```\n",
                "\n\\*\\*\\*+\n", "\n---+\n", "\n___+\n",
                "\n\n", "\n", " ", "",
            ]
        case .latex:
            return [
                "\n\\\\chapter\\{", "\n\\\\section\\{",
                "\n\\\\subsection\\{", "\n\\\\subsubsection\\{",
                "\n\\\\begin\\{enumerate\\}", "\n\\\\begin\\{itemize\\}",
                "\n\\\\begin\\{description\\}", "\n\\\\begin\\{list\\}",
                "\n\\\\begin\\{quote\\}", "\n\\\\begin\\{quotation\\}",
                "\n\\\\begin\\{verse\\}", "\n\\\\begin\\{verbatim\\}",
                "\n\\\\begin\\{align\\}",
                "\\$\\$", "\\$",
                " ", "",
            ]
        case .html:
            return [
                "<body", "<div", "<p", "<br", "<li",
                "<h1", "<h2", "<h3", "<h4", "<h5", "<h6",
                "<span", "<table", "<tr", "<td", "<th",
                "<ul", "<ol", "<header", "<footer", "<nav",
                "<head", "<style", "<script", "<meta", "<title",
                "",
            ]
        case .sol:
            return [
                "\npragma ", "\nusing ",
                "\ncontract ", "\ninterface ", "\nlibrary ",
                "\nconstructor ", "\ntype ", "\nfunction ",
                "\nevent ", "\nmodifier ", "\nerror ", "\nstruct ", "\nenum ",
                "\nif ", "\nfor ", "\nwhile ", "\ndo while ", "\nassembly ",
                "\n\n", "\n", " ", "",
            ]
        case .csharp:
            return [
                "\ninterface ", "\nenum ", "\ndelegate ", "\nevent ",
                "\nclass ", "\nabstract ",
                "\npublic ", "\nprotected ", "\nprivate ", "\nstatic ", "\nreturn ",
                "\nif ", "\ncontinue ", "\nfor ", "\nforeach ",
                "\nwhile ", "\nswitch ", "\nbreak ", "\ncase ", "\nelse ",
                "\ntry ", "\nthrow ", "\nfinally ", "\ncatch ",
                "\n\n", "\n", " ", "",
            ]
        case .cobol:
            return [
                "\nIDENTIFICATION DIVISION.", "\nENVIRONMENT DIVISION.",
                "\nDATA DIVISION.", "\nPROCEDURE DIVISION.",
                "\nWORKING-STORAGE SECTION.", "\nLINKAGE SECTION.",
                "\nFILE SECTION.", "\nINPUT-OUTPUT SECTION.",
                "\nOPEN ", "\nCLOSE ", "\nREAD ", "\nWRITE ",
                "\nIF ", "\nELSE ", "\nMOVE ", "\nPERFORM ",
                "\nUNTIL ", "\nVARYING ", "\nACCEPT ", "\nDISPLAY ",
                "\nSTOP RUN.",
                "\n", " ", "",
            ]
        case .lua:
            return [
                "\nlocal ", "\nfunction ",
                "\nif ", "\nfor ", "\nwhile ", "\nrepeat ",
                "\n\n", "\n", " ", "",
            ]
        case .perl:
            return ["\nsub ", "\nif ", "\nfor ", "\nwhile ", "\n\n", "\n", " ", ""]
        case .haskell:
            return [
                "\nmain :: ", "\nmain = ",
                "\nlet ", "\nin ", "\ndo ", "\nwhere ",
                "\n:: ", "\n= ",
                "\ndata ", "\nnewtype ", "\ntype ",
                "\nmodule ", "\nimport ", "\nqualified ", "\nimport qualified ",
                "\nclass ", "\ninstance ",
                "\ncase ",
                "\n| ", "\n= \\{", "\n, ",
                "\n\n", "\n", " ", "",
            ]
        case .elixir:
            return [
                "\ndef ", "\ndefp ", "\ndefmodule ",
                "\ndefprotocol ", "\ndefmacro ", "\ndefmacrop ",
                "\nif ", "\nunless ", "\ncase ", "\ncond ",
                "\nwith ", "\nfor ", "\ndo ",
                "\n\n", "\n", " ", "",
            ]
        case .powershell:
            return [
                "\nfunction ", "\nparam ",
                "\nif ", "\nforeach ", "\nfor ", "\nwhile ", "\nswitch ",
                "\nclass ",
                "\ntry ", "\ncatch ", "\nfinally ",
                "\n\n", "\n", " ", "",
            ]
        case .visualBasic6:
            let vis = "(?:Public|Private|Friend|Global|Static)\\s+"
            return [
                "\n(?!End\\s)\(vis)?Sub\\s+",
                "\n(?!End\\s)\(vis)?Function\\s+",
                "\n(?!End\\s)\(vis)?Property\\s+(?:Get|Let|Set)\\s+",
                "\n(?!End\\s)\(vis)?Type\\s+",
                "\n(?!End\\s)\(vis)?Enum\\s+",
                "\n(?!End\\s)If\\s+",
                "\nElseIf\\s+",
                "\nElse\\s+",
                "\nSelect\\s+Case\\s+",
                "\nCase\\s+",
                "\nFor\\s+",
                "\nDo\\s+",
                "\nWhile\\s+",
                "\nWith\\s+",
                "\n\n", "\n", " ", "",
            ]
        }
    }
}
