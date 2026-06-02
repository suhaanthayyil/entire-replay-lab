.PHONY: verify build demo doctor check-patch smoke clean

verify:
	./scripts/verify-repo.sh

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

clean:
	./scripts/clean.sh
