.PHONY: sonar/go
## Run SonarCloud analysis for Go. This will generally be run as part of a Travis build, not during local development.
sonar/go: go/gosec-install
	go test -coverprofile=coverage.out -json ./... > report.json
	gosec --quiet -fmt sonarqube -out gosec.json -no-fail ./...
	sonar-scanner --debug
