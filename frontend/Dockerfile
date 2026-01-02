# ---------- BUILD STAGE ----------
FROM node:18-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# ---------- PRODUCTION STAGE ----------
FROM nginx:stable-alpine
COPY --from=build /app/build /usr/share/nginx/html

# Replace default NGINX config with custom one (optional but recommended)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
