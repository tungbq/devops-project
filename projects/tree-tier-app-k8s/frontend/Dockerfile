# Use a base image suitable for your frontend (e.g., Node.js)
FROM node:lts

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json to the container
COPY ./src/package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the source code to the container
COPY ./src .

# Specify any necessary build commands here
# For example, if it's a React app, you might have a build command like:
# RUN npm run build

# Expose the port your frontend app runs on (if needed)
EXPOSE 80

# Command to start your frontend application
CMD ["npm", "start"]
