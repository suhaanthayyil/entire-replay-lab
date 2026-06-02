.PHONY: verify build demo check-patch clean

verify:
	./scripts/verify-repo.sh

build:
	./scripts/build-cli.sh

demo:
	./scripts/demo-commands.sh

check-patch:
	./scripts/check-patch.sh

clean:
	./scripts/clean.sh
