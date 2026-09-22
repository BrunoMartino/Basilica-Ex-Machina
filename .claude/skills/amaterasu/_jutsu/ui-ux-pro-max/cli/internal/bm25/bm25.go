package bm25

import (
	"math"
	"regexp"
	"strings"
)

const (
	k1 = 1.5
	b  = 0.75
)

var (
	punctRe = regexp.MustCompile(`[^\w\s]`)
)

var stopwords = map[string]bool{
	"to": true, "in": true, "on": true, "at": true, "is": true, "of": true,
	"by": true, "or": true, "an": true, "if": true, "no": true, "so": true,
	"do": true, "be": true, "we": true, "it": true, "as": true, "the": true,
	"and": true, "for": true, "are": true, "was": true,
}

var synonyms = map[string]string{
	"e-commerce": "ecommerce", "dark-mode": "dark", "darkmode": "dark",
	"light-mode": "light", "lightmode": "light", "a11y": "accessibility",
	"nav": "navigation", "sign-up": "signup", "log-in": "login",
	"colour": "color", "colours": "colors", "customisation": "customization",
	"organisation": "organization", "behaviour": "behavior", "ux/ui": "ux ui",
}

// Index holds a BM25 index over tokenized documents.
type Index struct {
	corpus     [][]string
	docLengths []int
	avgDL      float64
	idf        map[string]float64
	termFreqs  []map[string]int
	N          int
}

func normalize(text string) string {
	for variant, canonical := range synonyms {
		text = strings.ReplaceAll(text, variant, canonical)
	}
	return text
}

// Tokenize lowercases, normalizes synonyms, splits, and filters stopwords.
func Tokenize(text string) []string {
	text = normalize(strings.ToLower(text))
	text = punctRe.ReplaceAllString(text, " ")
	var out []string
	for _, w := range strings.Fields(text) {
		if len(w) >= 2 && !stopwords[w] {
			out = append(out, w)
		}
	}
	return out
}

// Fit builds the index from raw document strings.
func Fit(documents []string) *Index {
	idx := &Index{N: len(documents)}
	if idx.N == 0 {
		idx.idf = map[string]float64{}
		return idx
	}

	idx.corpus = make([][]string, idx.N)
	idx.docLengths = make([]int, idx.N)
	idx.termFreqs = make([]map[string]int, idx.N)
	docFreq := map[string]int{}

	var totalLen int
	for i, doc := range documents {
		tokens := Tokenize(doc)
		idx.corpus[i] = tokens
		idx.docLengths[i] = len(tokens)
		totalLen += len(tokens)

		tf := map[string]int{}
		for _, w := range tokens {
			tf[w]++
		}
		idx.termFreqs[i] = tf
		for w := range tf {
			docFreq[w]++
		}
	}
	idx.avgDL = float64(totalLen) / float64(idx.N)

	idx.idf = make(map[string]float64, len(docFreq))
	for w, freq := range docFreq {
		idx.idf[w] = math.Log((float64(idx.N-freq)+0.5)/(float64(freq)+0.5) + 1)
	}
	return idx
}

// Score ranks all documents against the query (descending score).
func (idx *Index) Score(query string) []ScoredDoc {
	if idx.N == 0 {
		return nil
	}
	queryTokens := Tokenize(query)
	scores := make([]ScoredDoc, idx.N)

	for i := 0; i < idx.N; i++ {
		var score float64
		docLen := float64(idx.docLengths[i])
		tf := idx.termFreqs[i]

		for _, token := range queryTokens {
			idf, ok := idx.idf[token]
			if !ok {
				continue
			}
			tfVal := float64(tf[token])
			num := tfVal * (k1 + 1)
			den := tfVal + k1*(1-b+b*docLen/idx.avgDL)
			score += idf * num / den
		}
		scores[i] = ScoredDoc{Index: i, Score: score}
	}

	// sort descending
	for i := 0; i < len(scores); i++ {
		for j := i + 1; j < len(scores); j++ {
			if scores[j].Score > scores[i].Score {
				scores[i], scores[j] = scores[j], scores[i]
			}
		}
	}
	return scores
}

// Vocabulary returns all indexed terms.
func (idx *Index) Vocabulary() []string {
	out := make([]string, 0, len(idx.idf))
	for w := range idx.idf {
		out = append(out, w)
	}
	return out
}

// ScoredDoc is a document index with its BM25 score.
type ScoredDoc struct {
	Index int
	Score float64
}

// SuggestTerms returns nearest vocabulary terms for zero-hit queries.
func SuggestTerms(idx *Index, query string, limit int) []string {
	if idx == nil || limit <= 0 {
		return nil
	}
	queryTokens := Tokenize(query)
	if len(queryTokens) == 0 {
		return nil
	}

	seen := map[string]bool{}
	var ordered []string
	for _, term := range idx.Vocabulary() {
		for _, qt := range queryTokens {
			prefix := qt
			if len(prefix) > 3 {
				prefix = prefix[:3]
			}
			termPrefix := term
			if len(termPrefix) > 3 {
				termPrefix = termPrefix[:3]
			}
			if strings.HasPrefix(term, prefix) || strings.HasPrefix(qt, termPrefix) {
				if !seen[term] {
					seen[term] = true
					ordered = append(ordered, term)
				}
				break
			}
		}
		if len(ordered) >= limit {
			break
		}
	}
	return ordered
}
