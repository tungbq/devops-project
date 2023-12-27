# Use the official Nginx image as the base image
FROM nginx

# Copy your Nginx configuration file to the container
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy your static website files to the Nginx default HTML directory
COPY . /usr/share/nginx/html
