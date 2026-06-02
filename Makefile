.PHONY: verify validate build demo doctor check-patch smoke release-check clean

verify:
	./scripts/verify-repo.sh

validate:
	python3 ./scripts/validate-examples.py

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
