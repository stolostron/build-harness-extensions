## Extensions to `build-harness`

This repo is structured just like `build-harness`, and is pulled in via:

```BUILD_HARNESS_EXTENSIONS_PATH```

In order to use the MVP build harness and extensions, add the following to your `Makefile`:

```
# GITHUB_USER containing '@' char must be escaped with '%40'
GITHUB_USER := $(shell echo $(GITHUB_USER) | sed 's/@/%40/g')
GITHUB_TOKEN ?=

-include $(shell curl -so .build-harness-bootstrap -H "Authorization: token $(GITHUB_TOKEN)" -H "Accept: application/vnd.github.v3.raw" "https://raw.github.com/open-cluster-management/build-harness-extensions/master/templates/Makefile.build-harness-bootstrap"; echo .build-harness-bootstrap)
```
