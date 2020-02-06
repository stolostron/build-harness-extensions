# Run SonarCloud analysis for Go
.PHONY: sonar/go
sonar/go:
	go test -coverprofile=coverage.out ./...
	go test -json ./... > report.json
	sonar-scanner --debug
