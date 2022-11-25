FROM golang
RUN mkdir -p /var/www/html

WORKDIR /usr/src/app

COPY . .

EXPOSE 80

CMD ["go", "run", "./server/server.go"]