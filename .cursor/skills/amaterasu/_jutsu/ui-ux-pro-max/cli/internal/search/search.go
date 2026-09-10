package search

import (
	"encoding/csv"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/michelangelo/amaterasu-ui/internal/bm25"
	"github.com/michelangelo/amaterasu-ui/internal/config"
	"github.com/michelangelo/amaterasu-ui/internal/data"
)

const truncateAt = 300

// Result is a domain or stack search result.
type Result struct {
	Domain         string
	Stack          string
	Query          string
	File           string
	AutoDetected   bool
	RunnerUpDomain string
	Count          int
	Rows           []map[string]string
	Suggestions    []string
	Error          string
}

func loadCSV(path string) ([]map[string]string, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	r := csv.NewReader(f)
	r.LazyQuotes = true
	r.FieldsPerRecord = -1
	records, err := r.ReadAll()
	if err != nil {
		return nil, err
	}
	if len(records) < 1 {
		return nil, nil
	}
	headers := records[0]
	var rows []map[string]string
	for _, rec := range records[1:] {
		m := map[string]string{}
		for i, h := range headers {
			if i < len(rec) {
				m[h] = rec[i]
			}
		}
		rows = append(rows, m)
	}
	return rows, nil
}

func searchFile(path string, searchCols, outputCols []string, query string, maxResults int) (Result, *bm25.Index) {
	rows, err := loadCSV(path)
	if err != nil {
		return Result{Error: err.Error(), File: filepath.Base(path), Query: query}, nil
	}
	docs := make([]string, len(rows))
	for i, row := range rows {
		parts := make([]string, 0, len(searchCols))
		for _, c := range searchCols {
			parts = append(parts, row[c])
		}
		docs[i] = strings.Join(parts, " ")
	}
	idx := bm25.Fit(docs)
	ranked := idx.Score(query)
	var out []map[string]string
	for _, sd := range ranked {
		if sd.Score <= 0 || len(out) >= maxResults {
			continue
		}
		row := rows[sd.Index]
		m := map[string]string{}
		for _, c := range outputCols {
			if v, ok := row[c]; ok {
				m[c] = v
			}
		}
		out = append(out, m)
	}
	return Result{File: filepath.Base(path), Query: query, Count: len(out), Rows: out}, idx
}

// DomainSearch runs BM25 over a named domain (or auto-detects).
func DomainSearch(query, domain string, maxResults int) Result {
	dataDir := data.Dir()
	if domain != "" {
		cfg, ok := config.Domains[domain]
		if !ok {
			return Result{Error: fmt.Sprintf("unknown domain %q", domain), Query: query}
		}
		res, idx := searchFile(filepath.Join(dataDir, cfg.File), cfg.SearchCols, cfg.OutputCols, query, maxResults)
		res.Domain = domain
		if res.Count == 0 && idx != nil {
			res.Suggestions = bm25.SuggestTerms(idx, query, 6)
		}
		return res
	}

	// Auto: score each domain's best hit; pick winner.
	type cand struct {
		domain string
		score  float64
		res    Result
	}
	var best, second cand
	for name, cfg := range config.Domains {
		path := filepath.Join(dataDir, cfg.File)
		rows, err := loadCSV(path)
		if err != nil || len(rows) == 0 {
			continue
		}
		docs := make([]string, len(rows))
		for i, row := range rows {
			parts := make([]string, 0, len(cfg.SearchCols))
			for _, c := range cfg.SearchCols {
				parts = append(parts, row[c])
			}
			docs[i] = strings.Join(parts, " ")
		}
		idx := bm25.Fit(docs)
		ranked := idx.Score(query)
		top := 0.0
		if len(ranked) > 0 {
			top = ranked[0].Score
		}
		res, _ := searchFile(path, cfg.SearchCols, cfg.OutputCols, query, maxResults)
		res.Domain = name
		res.AutoDetected = true
		c := cand{domain: name, score: top, res: res}
		if c.score > best.score {
			second = best
			best = c
		} else if c.score > second.score {
			second = c
		}
	}
	best.res.RunnerUpDomain = second.domain
	if best.res.Count == 0 {
		_, idx := searchFile(filepath.Join(dataDir, config.Domains[best.domain].File),
			config.Domains[best.domain].SearchCols, config.Domains[best.domain].OutputCols, query, maxResults)
		if idx != nil {
			best.res.Suggestions = bm25.SuggestTerms(idx, query, 6)
		}
	}
	return best.res
}

// StackSearch searches a stack CSV.
func StackSearch(query, stack string, maxResults int) Result {
	file, ok := config.Stacks[stack]
	if !ok {
		return Result{Error: fmt.Sprintf("unknown stack %q", stack), Query: query}
	}
	res, idx := searchFile(filepath.Join(data.Dir(), file), config.StackSearchCols, config.StackOutputCols, query, maxResults)
	res.Stack = stack
	if res.Count == 0 && idx != nil {
		res.Suggestions = bm25.SuggestTerms(idx, query, 6)
	}
	return res
}

// FormatMarkdown renders a Result.
func FormatMarkdown(res Result, full bool) string {
	if res.Error != "" {
		return "Error: " + res.Error
	}
	var b strings.Builder
	if res.Stack != "" {
		b.WriteString("## UI Pro Max Stack Guidelines\n")
		fmt.Fprintf(&b, "**Stack:** %s | **Query:** %s\n", res.Stack, res.Query)
	} else {
		b.WriteString("## UI Pro Max Search Results\n")
		dom := res.Domain
		if res.AutoDetected {
			dom += " (auto-detected"
			if res.RunnerUpDomain != "" {
				dom += ", runner-up: " + res.RunnerUpDomain
			}
			dom += ")"
		}
		fmt.Fprintf(&b, "**Domain:** %s | **Query:** %s\n", dom, res.Query)
	}
	fmt.Fprintf(&b, "**Source:** %s | **Found:** %d results\n\n", res.File, res.Count)

	if res.Count == 0 {
		b.WriteString("No matches. Retry with broader keywords before falling back.\n")
		if len(res.Suggestions) > 0 {
			fmt.Fprintf(&b, "**Closest known terms:** %s\n", strings.Join(res.Suggestions, ", "))
		}
		return b.String()
	}

	for i, row := range res.Rows {
		fmt.Fprintf(&b, "### Result %d\n", i+1)
		for k, v := range row {
			vs := v
			if !full && !config.UntruncatedCols[k] && len(vs) > truncateAt {
				vs = vs[:truncateAt] + "…"
			}
			fmt.Fprintf(&b, "- **%s:** %s\n", k, vs)
		}
		b.WriteString("\n")
	}
	return b.String()
}

// DesignSystem synthesizes a short proposal from style/color/typography/product searches.
func DesignSystem(query string) string {
	style := DomainSearch(query, "style", 1)
	color := DomainSearch(query, "color", 1)
	typo := DomainSearch(query, "typography", 1)
	product := DomainSearch(query, "product", 1)

	var b strings.Builder
	b.WriteString("# Design System Proposal (amaterasu)\n\n")
	fmt.Fprintf(&b, "**Query:** %s\n\n", query)
	b.WriteString("> Proposal only — validated visual thesis wins on conflict.\n")
	b.WriteString("> Fonts: self-host woff2 by default (see web-styling); CDN only if user asks.\n")
	b.WriteString("> Layout: framework breakpoints + `max-width: 1920px` centered.\n\n")

	b.WriteString("## Product\n")
	if product.Count > 0 {
		for k, v := range product.Rows[0] {
			fmt.Fprintf(&b, "- **%s:** %s\n", k, v)
		}
	} else {
		b.WriteString("_No product match._\n")
	}

	b.WriteString("\n## Style\n")
	if style.Count > 0 {
		for k, v := range style.Rows[0] {
			if k == "Implementation Checklist" || k == "Design System Variables" || k == "Style Category" ||
				k == "Primary Colors" || k == "Effects & Animation" || k == "Best For" || k == "Type" {
				fmt.Fprintf(&b, "- **%s:** %s\n", k, v)
			}
		}
	} else {
		b.WriteString("_No style match._\n")
	}

	b.WriteString("\n## Color palette\n")
	if color.Count > 0 {
		for _, key := range []string{"Product Type", "Primary", "On Primary", "Secondary", "On Secondary", "Accent", "On Accent", "Background", "Foreground", "Destructive", "Notes"} {
			if v := color.Rows[0][key]; v != "" {
				fmt.Fprintf(&b, "- **%s:** %s\n", key, v)
			}
		}
		b.WriteString("\nMap also to tertiary / success / danger / warning via design brief if missing.\n")
	} else {
		b.WriteString("_No color match._\n")
	}

	b.WriteString("\n## Typography\n")
	if typo.Count > 0 {
		for _, key := range []string{"Font Pairing Name", "Heading Font", "Body Font", "Mood/Style Keywords", "Best For", "Google Fonts URL", "Tailwind Config", "Notes"} {
			if v := typo.Rows[0][key]; v != "" {
				fmt.Fprintf(&b, "- **%s:** %s\n", key, v)
			}
		}
	} else {
		b.WriteString("_No typography match._\n")
	}

	b.WriteString("\n## Tokens to emit\n")
	b.WriteString("- Colors → Tailwind `@theme` or Bootstrap `$theme-colors`\n")
	b.WriteString("- Fonts → download woff2 + `@font-face`\n")
	b.WriteString("- Spacing / radii / motion → MASTER.md\n")
	b.WriteString("- Container → `max-width: 1920px; margin-inline: auto`\n")
	return b.String()
}
