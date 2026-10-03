FROM nginxinc/nginx-unprivileged:alpine


USER root
RUN apk upgrade --no-cache
USER 101


COPY index.html /usr/share/nginx/html/index.html

EXPOSE 8080
