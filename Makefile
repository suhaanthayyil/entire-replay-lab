.PHONY: verify metadata validate doc-links markdown-fences portability release-docs reproducibility patch-manifest command-surface report-fixtures release-state build demo doctor check-patch smoke release-check clean

verify:
	./scripts/verify-repo.sh

metadata:
	python3 ./scripts/validate-project-metadata.py

validate:
	python3 ./scripts/validate-examples.py

doc-links:
	python3 ./scripts/validate-doc-links.py

markdown-fences:
	python3 ./scripts/validate-markdown-fences.py

portability:
	python3 ./scripts/validate-portability.py

release-docs:
	python3 ./scripts/validate-release-docs.py

reproducibility:
	./scripts/verify-reproducibility.sh

patch-manifest:
	./scripts/verify-patch-manifest.sh

command-surface:
	./scripts/check-command-surface.sh

report-fixtures:
	./scripts/check-report-fixtures.sh

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
