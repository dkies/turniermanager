FROM nginx:alpine-slim

RUN apk upgrade --no-cache && \
    apk add --no-cache apache2-utils && \
    mkdir -p /usr/share/nginx/html/data && \
    chown nginx:nginx /usr/share/nginx/html/data

# Nginx-Konfiguration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Website-Dateien
COPY index.html /usr/share/nginx/html/index.html
COPY manifest.json /usr/share/nginx/html/manifest.json
COPY sw.js /usr/share/nginx/html/sw.js
COPY css/ /usr/share/nginx/html/css/
COPY js/ /usr/share/nginx/html/js/
COPY assets/ /usr/share/nginx/html/assets/

# Beispieldaten
COPY data/ /usr/share/nginx/html/data/
RUN chown -R nginx:nginx /usr/share/nginx/html/data

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
