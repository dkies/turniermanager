# Use an official Maven image to build the application
FROM maven:3.9-eclipse-temurin-21-alpine AS build

# Set the working directory
WORKDIR /app

# Copy the pom.xml and download dependencies
COPY pom.xml ./
RUN mvn dependency:go-offline -B

# Copy the rest of the application files
COPY src ./src

# Package the application
RUN mvn package -DskipTests

# Use an OpenJDK image to run the application
FROM openjdk:21-jdk-slim

# Set the working directory
WORKDIR /app
RUN mkdir /app/uploaded

# Copy the jar file from the build stage
COPY --from=build /app/target/turniermanager-0.0.1-SNAPSHOT.jar app.jar

# Expose port 8080
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
