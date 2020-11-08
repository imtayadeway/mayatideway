#!make

encrypt:
	bin/encrypt

build: encrypt
	bundle exec jekyll build

deploy: build
	rsync --verbose --recursive --compress --checksum --delete _site/ root@198.74.55.56:/usr/share/nginx/html/mayatideway

clean:
	bundle exec jekyll clean
