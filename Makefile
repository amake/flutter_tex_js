# Remember to update flutterTexJsSupportedEnvironments when upgrading
katex_version := v0.13.13
katex_url := https://github.com/KaTeX/KaTeX/releases/download/$(katex_version)/katex.tar.gz
katex_ios := ios/Assets/katex
katex_android := android/src/main/assets/katex

.PHONY: assets
assets: ## Download vendor assets
assets: $(katex_ios) $(katex_android)

$(katex_ios):
	cd $(@D); curl -L $(katex_url) | tar xz --include '*/katex.min.*' --include '*.woff2'
# Fonts must be in root of bundle in order to be found by WebView
	sed -i '' -e 's|fonts/||g' $(@)/katex.min.css

$(katex_android):
	cd $(@D); curl -L $(katex_url) | tar xz --include '*/katex.min.*' --include '*.woff2'

.PHONY: clobber
clobber: ## Delete all vendor files
clobber:
	rm -rf $(katex_ios) $(katex_android)

.PHONY: help
help: ## Show this help text
	$(info usage: make [target])
	$(info )
	$(info Available targets:)
	@awk -F ':.*?## *' '/^[^\t].+?:.*?##/ \
         {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
