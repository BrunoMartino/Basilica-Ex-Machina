package data

import (
	"os"
	"path/filepath"
	"runtime"
)

const relDataFromCWD = ".claude/skills/amaterasu/_jutsu/ui-ux-pro-max/data"

// Dir resolves the CSV data directory.
func Dir() string {
	if v := os.Getenv("AMATERASU_UI_DATA"); v != "" {
		return v
	}
	if cwd, err := os.Getwd(); err == nil {
		p := filepath.Join(cwd, relDataFromCWD)
		if info, err := os.Stat(p); err == nil && info.IsDir() {
			return p
		}
		// go -C .../cli run . → cwd is the cli package
		p = filepath.Join(cwd, "..", "data")
		if info, err := os.Stat(p); err == nil && info.IsDir() {
			return p
		}
	}
	if _, file, _, ok := runtime.Caller(0); ok {
		p := filepath.Join(filepath.Dir(file), "..", "..", "..", "data")
		if info, err := os.Stat(p); err == nil && info.IsDir() {
			return p
		}
	}
	exe, err := os.Executable()
	if err == nil {
		p := filepath.Join(filepath.Dir(exe), "data")
		if info, err := os.Stat(p); err == nil && info.IsDir() {
			return p
		}
	}
	return filepath.Join("..", "data")
}
