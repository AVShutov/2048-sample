FROM nginx:1.22.1-alpine

LABEL maintainer="ashutau"

COPY 2048 /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
