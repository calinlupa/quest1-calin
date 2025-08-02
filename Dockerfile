# Use an official Node.js runtime as a parent image
FROM node:18-alpine

# Set the working directory in the container
WORKDIR /usr/src/app

#ENV TwelveFactor=quest001001222\
# Set environment variables for the application
ENV SECRET_WORD="your_secret_word" 

# Copy package.json and package-lock.json (if available)
COPY package.json ./

# Install app dependencies
RUN npm install

# Copy the rest of the application's source code from your host to your image filesystem.
COPY . .

# Make your app's port available to the outside world
EXPOSE 3000

# Define the command to run your app
CMD [ "npm", "start" ]
