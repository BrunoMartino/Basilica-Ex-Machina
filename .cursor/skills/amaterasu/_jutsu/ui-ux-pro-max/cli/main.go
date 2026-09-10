package main

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/michelangelo/amaterasu-ui/internal/audit"
	"github.com/michelangelo/amaterasu-ui/internal/search"
)

func usage() {
	fmt.Fprintf(os.Stderr, `amaterasu-ui — design intelligence CLI

Usage:
  amaterasu-ui search <query> [-domain NAME] [-stack NAME] [-max N] [-full]
  amaterasu-ui design-system <query>
  amaterasu-ui audit [root]

Flags may appear before or after the query.

Env:
  AMATERASU_UI_DATA  override path to CSV data dir

`)
}

// takeFlags extracts known flags from anywhere in args; returns remaining as query parts.
func takeFlags(args []string) (domain, stack string, max int, full bool, rest []string) {
	max = 3
	for i := 0; i < len(args); i++ {
		a := args[i]
		switch {
		case a == "-domain" || a == "--domain":
			if i+1 < len(args) {
				i++
				domain = args[i]
			}
		case strings.HasPrefix(a, "-domain="):
			domain = strings.TrimPrefix(a, "-domain=")
		case strings.HasPrefix(a, "--domain="):
			domain = strings.TrimPrefix(a, "--domain=")
		case a == "-stack" || a == "--stack":
			if i+1 < len(args) {
				i++
				stack = args[i]
			}
		case strings.HasPrefix(a, "-stack="):
			stack = strings.TrimPrefix(a, "-stack=")
		case strings.HasPrefix(a, "--stack="):
			stack = strings.TrimPrefix(a, "--stack=")
		case a == "-max" || a == "--max" || a == "-max-results":
			if i+1 < len(args) {
				i++
				if n, err := strconv.Atoi(args[i]); err == nil {
					max = n
				}
			}
		case a == "-full" || a == "--full":
			full = true
		case a == "-f" || a == "--f" || a == "-format" || a == "--format":
			if i+1 < len(args) {
				i++ // ignore format value; markdown only
			}
		case a == "--design-system":
			// allow search --design-system as alias routed by caller
			rest = append(rest, a)
		default:
			rest = append(rest, a)
		}
	}
	return
}

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}
	cmd := os.Args[1]
	args := os.Args[2:]
	if cmd == "--" && len(args) > 0 {
		cmd = args[0]
		args = args[1:]
	}

	switch cmd {
	case "search":
		domain, stack, max, full, rest := takeFlags(args)
		// Support: search --design-system <query>
		ds := false
		var qparts []string
		for _, r := range rest {
			if r == "--design-system" {
				ds = true
				continue
			}
			qparts = append(qparts, r)
		}
		query := strings.Join(qparts, " ")
		if query == "" {
			fmt.Fprintln(os.Stderr, "search requires a query")
			os.Exit(2)
		}
		if ds {
			fmt.Print(search.DesignSystem(query))
			return
		}
		var res search.Result
		if stack != "" {
			res = search.StackSearch(query, stack, max)
		} else {
			res = search.DomainSearch(query, domain, max)
		}
		fmt.Print(search.FormatMarkdown(res, full))

	case "design-system":
		_, _, _, _, rest := takeFlags(args)
		query := strings.Join(rest, " ")
		if query == "" {
			fmt.Fprintln(os.Stderr, "design-system requires a query")
			os.Exit(2)
		}
		fmt.Print(search.DesignSystem(query))

	case "audit":
		root := "."
		if len(args) > 0 && !strings.HasPrefix(args[0], "-") {
			root = args[0]
		}
		fmt.Print(audit.Run(root))

	case "-h", "--help", "help":
		usage()
	default:
		fmt.Fprintf(os.Stderr, "unknown command %q\n", cmd)
		usage()
		os.Exit(2)
	}
}
