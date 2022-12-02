export DOCKER=docker
export DOCKERFILE=Dockerfile
export PWD=$(shell pwd)
export PROJECT_NAME=ffmpeg_trim
export IMAGE_NAME=$(PROJECT_NAME)-image
export CONTAINER_NAME=$(PROJECT_NAME)-container

docker-build:
	$(DOCKER) build -t $(IMAGE_NAME) -f $(DOCKERFILE) .

docker-run:
	$(DOCKER) run -it -v $(PWD):/work --name $(CONTAINER_NAME) $(IMAGE_NAME)

trim:
	$(DOCKER) run -it --rm -v $(PWD):/work --name $(CONTAINER_NAME) $(IMAGE_NAME) bash /work/trim.sh ${RECIPE_ID}/trim.txt

clean: clean-container clean-image

clean-container:
	$(DOCKER) rm -f $(CONTAINER_NAME)

clean-image:
	$(DOCKER) rmi -f $(IMAGE_NAME)
