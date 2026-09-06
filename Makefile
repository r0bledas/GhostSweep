.PHONY: all build test clean run cli install

all: build

build:
	@./scripts/build_app.sh

test:
	@swift test

run: build
	@open GhostSweep.app

cli:
	@swift build -c release --product ghostsweep
	@echo "CLI binary built at .build/release/ghostsweep"

install: build
	@echo "Installing CLI to /usr/local/bin/ghostsweep..."
	@sudo cp .build/release/ghostsweep /usr/local/bin/
	@echo "Installing GhostSweep.app to /Applications/..."
	@rm -rf /Applications/GhostSweep.app
	@cp -R GhostSweep.app /Applications/
	@echo "Installation complete!"

clean:
	@rm -rf .build GhostSweep.app
