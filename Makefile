.PHONY: verify build demo

verify:
	./scripts/verify-repo.sh

build:
	./scripts/build-cli.sh

demo:
	./scripts/demo-commands.sh
