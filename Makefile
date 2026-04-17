IMAGE = git.yhu.me/yang/immich-ml-router
VENV  = .venv
PY    = $(VENV)/bin/python
PIP   = $(VENV)/bin/pip
PYTEST = $(VENV)/bin/pytest

.PHONY: test test-unit test-integration build push venv

venv: $(VENV)/bin/activate

$(VENV)/bin/activate: requirements-dev.txt
	python3 -m venv $(VENV)
	$(PIP) install -q -r requirements-dev.txt
	touch $(VENV)/bin/activate

test: test-unit test-integration

test-unit: venv
	$(PYTEST) tests/test_router.py -v

test-integration:
	docker compose -f docker-compose.test.yml up -d --build
	bash tests/integration_test.sh
	docker compose -f docker-compose.test.yml down

build:
	docker build -t $(IMAGE):latest .

push: build
	docker push $(IMAGE):latest
