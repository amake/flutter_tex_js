katex_version := v0.11.1
katex_url := https://github.com/KaTeX/KaTeX/releases/download/$(katex_version)/katex.tar.gz
katex_ios := ios/Assets/katex
katex_android := android/src/main/assets/katex

.PHONY: assets
assets: $(katex_ios) $(katex_android)

$(katex_ios):
	cd $(@D); curl -L $(katex_url) | tar xz --include '*/katex.min.*' --include '*.woff2'
# Fonts must be in root of bundle in order to be found by WebView
	sed -i '' -e 's|fonts/||g' $(@)/katex.min.css

$(katex_android):
	cd $(@D); curl -L $(katex_url) | tar xz --include '*/katex.min.*' --include '*.woff2'
