# Flutter é compilado pelo GitHub Actions antes desta imagem ser construída.
# Este Dockerfile só empacota o output já gerado em um nginx mínimo.
FROM nginx:alpine
COPY build/web /usr/share/nginx/html

# Pré-comprime no build: o nginx serve o .gz via gzip_static sem gastar CPU
# por requisição (a VM tem 1/8 de OCPU).
RUN find /usr/share/nginx/html -type f \
      \( -name '*.js' -o -name '*.wasm' -o -name '*.mjs' -o -name '*.json' \
         -o -name '*.html' -o -name '*.css' -o -name '*.svg' -o -name '*.otf' -o -name '*.ttf' \) \
      -exec sh -c 'gzip -9 -c "$1" > "$1.gz"' _ {} \;

COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
