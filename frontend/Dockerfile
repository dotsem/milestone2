# kleine image voor nginx
FROM nginx:1.25-alpine

COPY index.html /usr/share/nginx/html/index.html

# hiermee krijgen we ook onze foto te zien
COPY assets /usr/share/nginx/html/assets

COPY nginx.conf /etc/nginx/conf.d/default.conf

# default HTTP poort
EXPOSE 80

