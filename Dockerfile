# Use the official Flutter image as the base image
FROM dart:stable AS build

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="$PATH:/usr/local/flutter/bin"
RUN flutter channel stable
RUN flutter upgrade
RUN flutter doctor

# Set the working directory in the container
WORKDIR /app

# Copy the entire project to the container
COPY . .

# Get Flutter dependencies
RUN flutter pub get

# Build the web app
RUN flutter build web

# Use Nginx to serve the web app
FROM nginx:alpine

# Copy the built web app to Nginx's serve directory
COPY --from=0 /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
