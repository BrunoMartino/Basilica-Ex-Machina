package audit

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

var skipDirs = map[string]bool{
	"node_modules": true, ".git": true, ".next": true, ".nuxt": true, ".output": true,
	".svelte-kit": true, ".astro": true, "dist": true, "build": true, "out": true,
	"coverage": true, "vendor": true, ".venv": true, "__pycache__": true, ".turbo": true,
	".cache": true, "storybook-static": true, ".vercel": true, "ios": true, "android": true,
}

var rootCandidates = []string{"src", "app", "pages", "components", "layouts", "lib", "islands", "features", "widgets"}

var (
	extJSX    = map[string]bool{".tsx": true, ".jsx": true}
	extSFC    = map[string]bool{".vue": true, ".svelte": true, ".astro": true}
	extStyle  = map[string]bool{".css": true, ".scss": true, ".sass": true, ".less": true}
	extScript = map[string]bool{".ts": true, ".js": true, ".mjs": true}
)

type checkDef struct {
	ID, Title, Severity string
	Exts                map[string]bool
	Pattern             *regexp.Regexp
	Unless              *regexp.Regexp
	Absence             bool
	ZeroMeans           string
	AbsentMeans         string
}

type Finding struct {
	Check, Severity, File string
	Line                  int
	Text                  string
}

type Result struct {
	Check, Title, Severity, Status, Meaning string
	Scanned                                 int
	Findings                                []Finding
}

func mergeExts(maps ...map[string]bool) map[string]bool {
	out := map[string]bool{}
	for _, m := range maps {
		for k, v := range m {
			out[k] = v
		}
	}
	return out
}

func checks() []checkDef {
	jsxSfc := mergeExts(extJSX, extSFC)
	styleSfc := mergeExts(extStyle, extSFC)
	allAnim := mergeExts(extStyle, extSFC, extJSX, extScript)
	return []checkDef{
		{ID: "conditional-render-no-exit", Title: "Conditional render with no exit animation", Severity: "important",
			Exts: jsxSfc, Pattern: regexp.MustCompile(`\{\s*\w[\w.?]*\s*&&\s*<|\?\s*<\w+[\s/>]`),
			Unless: regexp.MustCompile(`AnimatePresence|v-if|transition|\bexit\b|Transition`),
			ZeroMeans: "No unguarded conditional mounts found."},
		{ID: "hover-no-transition", Title: "Hover state with no transition", Severity: "important",
			Exts: styleSfc, Pattern: regexp.MustCompile(`:hover`),
			Unless: regexp.MustCompile(`transition|animation|@media\s*\(\s*hover`),
			ZeroMeans: "Every :hover sits next to a transition or animation."},
		{ID: "animated-layout-property", Title: "Animating a layout property", Severity: "critical",
			Exts: styleSfc, Pattern: regexp.MustCompile(`transition\s*:[^;]*\b(width|height|top|left|right|bottom|margin|padding)\b`),
			Unless: regexp.MustCompile(`transform|opacity`),
			ZeroMeans: "No transition targets a layout property."},
		{ID: "outline-none", Title: "Focus outline removed with no replacement", Severity: "critical",
			Exts: styleSfc, Pattern: regexp.MustCompile(`outline\s*:\s*(none|0)\b`),
			Unless: regexp.MustCompile(`focus-visible|box-shadow|outline-offset`),
			ZeroMeans: "No bare outline:none without replacement."},
		{ID: "clickable-non-button", Title: "Click handler on a non-interactive element", Severity: "critical",
			Exts: jsxSfc, Pattern: regexp.MustCompile(`<(div|span|li)\b[^>]*\bon(Click|click)\b`),
			Unless: regexp.MustCompile(`role\s*=|tabIndex|tabindex`),
			ZeroMeans: "Click handlers are on interactive elements."},
		{ID: "decorative-motion-not-hidden", Title: "Decorative animation not hidden from AT", Severity: "nice-to-have",
			Exts: jsxSfc, Pattern: regexp.MustCompile(`<(motion\.\w+|animated\.\w+|Lottie|Canvas|Player)\b`),
			Unless: regexp.MustCompile(`aria-hidden|aria-label|role\s*=|alt\s*=`),
			ZeroMeans: "Animated elements carry aria or role."},
		{ID: "will-change-broad", Title: "will-change left on permanently", Severity: "nice-to-have",
			Exts: styleSfc, Pattern: regexp.MustCompile(`will-change\s*:`),
			Unless: regexp.MustCompile(`will-change\s*:\s*auto`),
			ZeroMeans: "No permanent will-change."},
		{ID: "js-driven-animation", Title: "Animation driven by a timer", Severity: "important",
			Exts: mergeExts(extJSX, extScript, extSFC), Pattern: regexp.MustCompile(`\b(setTimeout|setInterval)\s*\(`),
			Unless: regexp.MustCompile(`debounce|throttle|fetch|poll|retry|timeout\s*[,)]|abort|toast|clearTimeout`),
			ZeroMeans: "No timer appears to drive visual state."},
		{ID: "inline-style-object", Title: "Inline style object on animated element", Severity: "nice-to-have",
			Exts: extJSX, Pattern: regexp.MustCompile(`style=\{\{`),
			Unless: regexp.MustCompile(`transform|opacity|transition|--`),
			ZeroMeans: "No rogue inline style objects."},
		{ID: "no-reduced-motion", Title: "prefers-reduced-motion never honoured", Severity: "critical",
			Exts: allAnim, Pattern: regexp.MustCompile(`prefers-reduced-motion`), Absence: true,
			AbsentMeans: "Nothing references prefers-reduced-motion.",
			ZeroMeans: "prefers-reduced-motion is referenced."},
		{ID: "no-1920-container", Title: "Missing max-width 1920px centered container", Severity: "important",
			Exts: mergeExts(extJSX, extSFC, extStyle), Pattern: regexp.MustCompile(`max-w-\[1920px\]|max-width:\s*1920px|maxWidth:\s*['"]?1920`),
			Absence: true, AbsentMeans: "No 1920px max-width container found (amaterasu rule).",
			ZeroMeans: "1920px container pattern found."},
	}
}

func discoverRoots(base string) ([]string, string) {
	var hits []string
	for _, d := range rootCandidates {
		p := filepath.Join(base, d)
		if st, err := os.Stat(p); err == nil && st.IsDir() {
			hits = append(hits, p)
		}
	}
	if len(hits) > 0 {
		names := make([]string, len(hits))
		for i, h := range hits {
			names[i] = filepath.Base(h)
		}
		return hits, "detected: " + strings.Join(names, ", ")
	}
	return []string{base}, "scanning whole tree"
}

func walk(roots []string, base string) []string {
	var files []string
	for _, root := range roots {
		_ = filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return nil
			}
			rel, _ := filepath.Rel(base, path)
			parts := strings.Split(rel, string(os.PathSeparator))
			for _, p := range parts {
				if skipDirs[p] {
					if info.IsDir() {
						return filepath.SkipDir
					}
					return nil
				}
			}
			if info.IsDir() {
				return nil
			}
			ext := filepath.Ext(path)
			if extJSX[ext] || extSFC[ext] || extStyle[ext] || extScript[ext] {
				files = append(files, path)
			}
			return nil
		})
	}
	return files
}

func runCheck(c checkDef, files []string, base string) Result {
	var relevant []string
	for _, f := range files {
		if c.Exts[filepath.Ext(f)] {
			relevant = append(relevant, f)
		}
	}
	res := Result{Check: c.ID, Title: c.Title, Severity: c.Severity, Status: "clean", Scanned: len(relevant), Meaning: c.ZeroMeans}
	if len(relevant) == 0 {
		res.Status = "not-applicable"
		res.Meaning = "No files of relevant type. Do not report as passing."
		return res
	}
	foundAny := false
	for _, f := range relevant {
		b, err := os.ReadFile(f)
		if err != nil {
			continue
		}
		lines := strings.Split(string(b), "\n")
		for n, line := range lines {
			if !c.Pattern.MatchString(line) {
				continue
			}
			foundAny = true
			if c.Absence {
				continue
			}
			if c.Unless != nil && c.Unless.MatchString(line) {
				continue
			}
			rel, _ := filepath.Rel(base, f)
			txt := strings.TrimSpace(line)
			if len(txt) > 200 {
				txt = txt[:200]
			}
			res.Findings = append(res.Findings, Finding{c.ID, c.Severity, rel, n + 1, txt})
		}
	}
	if c.Absence {
		if !foundAny {
			res.Status = "findings"
			res.Meaning = c.AbsentMeans
			res.Findings = append(res.Findings, Finding{c.ID, c.Severity, "(whole project)", 0, "pattern never appears"})
		}
		return res
	}
	if len(res.Findings) > 0 {
		res.Status = "findings"
		res.Meaning = fmt.Sprintf("%d occurrence(s) across %d file(s).", len(res.Findings), len(relevant))
	}
	return res
}

// Run audits root and returns markdown.
func Run(root string) string {
	if root == "" {
		root = "."
	}
	abs, err := filepath.Abs(root)
	if err != nil {
		return "Error: " + err.Error()
	}
	roots, how := discoverRoots(abs)
	files := walk(roots, abs)

	var b strings.Builder
	b.WriteString("# Amaterasu design audit\n\n")
	fmt.Fprintf(&b, "**Root:** `%s`\n**Roots:** %s\n**Files scanned:** %d\n\n", abs, how, len(files))

	var clean, findings, na int
	for _, c := range checks() {
		r := runCheck(c, files, abs)
		switch r.Status {
		case "clean":
			clean++
		case "findings":
			findings++
		default:
			na++
		}
		fmt.Fprintf(&b, "## [%s] %s\n", strings.ToUpper(r.Status), r.Title)
		fmt.Fprintf(&b, "- check: `%s` | severity: %s | scanned: %d\n", r.Check, r.Severity, r.Scanned)
		fmt.Fprintf(&b, "- meaning: %s\n", r.Meaning)
		for _, f := range r.Findings {
			fmt.Fprintf(&b, "  - `%s:%d` %s\n", f.File, f.Line, f.Text)
		}
		b.WriteString("\n")
	}
	fmt.Fprintf(&b, "---\n**Summary:** %d clean, %d findings, %d not-applicable\n", clean, findings, na)
	b.WriteString("Findings are evidence, not verdicts. Handoff profilers remain UNVERIFIED.\n")
	return b.String()
}
