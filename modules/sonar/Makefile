SONAR_GO_TEST_ARGS ?= ./...


.PHONY: sonar/go
## Run SonarCloud analysis for Go on Travis CI. This will not be run during local development.
sonar/go: go/gosec-install
	go test -coverprofile=coverage.out -json ${SONAR_GO_TEST_ARGS} > report.json
	gosec -fmt sonarqube -out gosec.json -no-fail ./...
	unset SONARQUBE_SCANNER_PARAMS
	sonar-scanner --debug


.PHONY: sonar/go/openshiftci
## Run SonarCloud analysis for Go on OpenShift CI. This will not be run during local development.
sonar/go/openshift-ci:
	test -r /etc/sonarcloud/token
	export SONAR_TOKEN="$(shell cat /etc/sonarcloud/token)"
	go test -coverprofile=coverage.out -json ${SONAR_GO_TEST_ARGS} > report.json
	gosec -fmt sonarqube -out gosec.json -no-fail ./...
	sonar-scanner --debug


# This expects that your code uses Jest to execute tests.
# Add this field to your jest.config.js file to generate the report:
#     testResultProcessor: 'jest-sonar-reporter',
# It must be run before make component/test/unit.
.PHONY: sonar/js/jest-init
## Install npm module to make Sonar test reports in Jest on Travis. This will not be run during local development.
sonar/js/jest-init:
	npm install -D jest-sonar-reporter


# Test reports and code coverage must be generated before running the scanner.
# It must be run after make component/test/unit.
.PHONY: sonar/js
## Runs the SonarCloud analysis for JavaScript on Travis. This will not be run during local development.
sonar/js:
	unset SONARQUBE_SCANNER_PARAMS
	sonar-scanner --debug
