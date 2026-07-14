FROM jekyll/jekyll:4 AS builder
WORKDIR /srv/jekyll
COPY . .
RUN bundle install && jekyll build

FROM nginx:alpine
COPY --from=builder /srv/jekyll/_site /usr/share/nginx/html
