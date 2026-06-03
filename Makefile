.PHONY: verify validate doc-links release-docs reproducibility release-state build demo doctor check-patch smoke release-check clean

verify:
	./scripts/verify-repo.sh

validate:
	python3 ./scripts/validate-examples.py

doc-links:
	python3 ./scripts/validate-doc-links.py

release-docs:
	python3 ./scripts/validate-release-docs.py

reproducibility:
	./scripts/verify-reproducibility.sh

release-state:
	./scripts/verify-release-state.sh

build:
	./scripts/build-cli.sh

demo:
	./scripts/demo-commands.sh

doctor:
	./scripts/doctor.sh

check-patch:
	./scripts/check-patch.sh

smoke:
	./scripts/smoke.sh

release-check:
	./scripts/release-check.sh

clean:
	./scripts/clean.sh
