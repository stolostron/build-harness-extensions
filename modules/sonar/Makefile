.PHONY: sonar/go
## Run SonarCloud analysis for Go. This will generally be run as part of a Travis build, not during local development.
sonar/go:
	go test -coverprofile=coverage.out -json ./... > report.json
	sonar-scanner --debug
