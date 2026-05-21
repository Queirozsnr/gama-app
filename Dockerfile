# Flutter é compilado pelo GitHub Actions antes desta imagem ser construída.
# Este Dockerfile só empacota o output já gerado em um nginx mínimo.
FROM nginx:alpine
COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
