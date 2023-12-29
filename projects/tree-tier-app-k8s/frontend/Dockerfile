# Build React app
FROM node:latest as build

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install
# # Add environment variables during the build process
ARG REACT_APP_API_URL
ENV REACT_APP_API_URL=${REACT_APP_API_URL}

COPY . .
RUN npm run build

# Serve React app using Nginx
FROM nginx:latest

COPY --from=build /usr/src/app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
