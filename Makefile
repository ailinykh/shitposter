run:
	python shitposter

lint:
	flake8

build: lint
	echo "docker-compose.yml" >> .dockerignore
	docker build . -t ailinykh/shitposter
	sed -i '' '/^docker-compose.yml$$/d' .dockerignore

push:
	docker push ailinykh/shitposter

check:
	docker run --rm --env-file .env -it --mount type=bind,src=`pwd`/data,dst=/home/app/data ailinykh/shitposter
