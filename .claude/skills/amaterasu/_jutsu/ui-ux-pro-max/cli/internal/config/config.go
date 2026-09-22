package config

// Domain describes a CSV domain search.
type Domain struct {
	File       string
	SearchCols []string
	OutputCols []string
}

// Domains mirrors Python CSV_CONFIG.
var Domains = map[string]Domain{
	"style": {
		File:       "styles.csv",
		SearchCols: []string{"Style Category", "Keywords", "Best For", "Type", "AI Prompt Keywords"},
		OutputCols: []string{"Style Category", "Type", "Keywords", "Primary Colors", "Effects & Animation", "Best For", "Light Mode ✓", "Dark Mode ✓", "Performance", "Accessibility", "Framework Compatibility", "Complexity", "AI Prompt Keywords", "CSS/Technical Keywords", "Implementation Checklist", "Design System Variables"},
	},
	"color": {
		File:       "colors.csv",
		SearchCols: []string{"Product Type", "Notes"},
		OutputCols: []string{"Product Type", "Primary", "On Primary", "Secondary", "On Secondary", "Accent", "On Accent", "Background", "Foreground", "Card", "Card Foreground", "Muted", "Muted Foreground", "Border", "Destructive", "On Destructive", "Ring", "Notes"},
	},
	"chart": {
		File:       "charts.csv",
		SearchCols: []string{"Data Type", "Keywords", "Best Chart Type", "When to Use", "When NOT to Use", "Accessibility Notes"},
		OutputCols: []string{"Data Type", "Keywords", "Best Chart Type", "Secondary Options", "When to Use", "When NOT to Use", "Data Volume Threshold", "Color Guidance", "Accessibility Grade", "Accessibility Notes", "A11y Fallback", "Library Recommendation", "Interactive Level"},
	},
	"landing": {
		File:       "landing.csv",
		SearchCols: []string{"Pattern Name", "Keywords", "Conversion Optimization", "Section Order"},
		OutputCols: []string{"Pattern Name", "Keywords", "Section Order", "Primary CTA Placement", "Color Strategy", "Conversion Optimization"},
	},
	"product": {
		File:       "products.csv",
		SearchCols: []string{"Product Type", "Keywords", "Primary Style Recommendation", "Key Considerations"},
		OutputCols: []string{"Product Type", "Keywords", "Primary Style Recommendation", "Secondary Styles", "Landing Page Pattern", "Dashboard Style (if applicable)", "Color Palette Focus"},
	},
	"ux": {
		File:       "ux-guidelines.csv",
		SearchCols: []string{"Category", "Issue", "Description", "Platform"},
		OutputCols: []string{"Category", "Issue", "Platform", "Description", "Do", "Don't", "Code Example Good", "Code Example Bad", "Severity"},
	},
	"typography": {
		File:       "typography.csv",
		SearchCols: []string{"Font Pairing Name", "Category", "Mood/Style Keywords", "Best For", "Heading Font", "Body Font"},
		OutputCols: []string{"Font Pairing Name", "Category", "Heading Font", "Body Font", "Mood/Style Keywords", "Best For", "Google Fonts URL", "CSS Import", "Tailwind Config", "Notes"},
	},
	"icons": {
		File:       "icons.csv",
		SearchCols: []string{"Category", "Icon Name", "Keywords", "Best For"},
		OutputCols: []string{"Category", "Icon Name", "Keywords", "Library", "Import Code", "Usage", "Best For", "Style"},
	},
	"gsap": {
		File:       "motion.csv",
		SearchCols: []string{"Category", "Intensity Tier", "Keywords", "Trigger"},
		OutputCols: []string{"Category", "Intensity Tier", "Trigger", "Duration", "Easing", "GSAP Snippet", "Framework Notes", "Do", "Don't", "Performance Notes"},
	},
	"react": {
		File:       "react-performance.csv",
		SearchCols: []string{"Category", "Issue", "Keywords", "Description"},
		OutputCols: []string{"Category", "Issue", "Platform", "Description", "Do", "Don't", "Code Example Good", "Code Example Bad", "Severity"},
	},
	"web": {
		File:       "app-interface.csv",
		SearchCols: []string{"Category", "Issue", "Keywords", "Description"},
		OutputCols: []string{"Category", "Issue", "Platform", "Description", "Do", "Don't", "Code Example Good", "Code Example Bad", "Severity"},
	},
	"google-fonts": {
		File:       "google-fonts.csv",
		SearchCols: []string{"Family", "Category", "Stroke", "Classifications", "Keywords", "Subsets", "Designers"},
		OutputCols: []string{"Family", "Category", "Stroke", "Classifications", "Styles", "Variable Axes", "Subsets", "Designers", "Popularity Rank", "Google Fonts URL"},
	},
}

// Stacks maps stack name → CSV under data/stacks/.
var Stacks = map[string]string{
	"react": "stacks/react.csv", "nextjs": "stacks/nextjs.csv", "vue": "stacks/vue.csv",
	"svelte": "stacks/svelte.csv", "astro": "stacks/astro.csv", "swiftui": "stacks/swiftui.csv",
	"react-native": "stacks/react-native.csv", "flutter": "stacks/flutter.csv",
	"nuxtjs": "stacks/nuxtjs.csv", "nuxt-ui": "stacks/nuxt-ui.csv",
	"html-tailwind": "stacks/html-tailwind.csv", "shadcn": "stacks/shadcn.csv",
	"jetpack-compose": "stacks/jetpack-compose.csv", "threejs": "stacks/threejs.csv",
	"angular": "stacks/angular.csv", "laravel": "stacks/laravel.csv",
	"javafx": "stacks/javafx.csv", "wpf": "stacks/wpf.csv", "winui": "stacks/winui.csv",
	"avalonia": "stacks/avalonia.csv", "uno": "stacks/uno.csv", "uwp": "stacks/uwp.csv",
}

var StackSearchCols = []string{"Category", "Guideline", "Description", "Do", "Don't"}
var StackOutputCols = []string{"Category", "Guideline", "Description", "Do", "Don't", "Code Good", "Code Bad", "Severity", "Docs URL"}

var UntruncatedCols = map[string]bool{
	"Code Example Good": true, "Code Example Bad": true, "Code Good": true, "Code Bad": true,
	"Implementation Checklist": true, "Design System Variables": true, "CSS Import": true,
	"Tailwind Config": true, "GSAP Snippet": true,
}
