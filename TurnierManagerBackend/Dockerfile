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

FROM eclipse-temurin:25-jre-ubi10-minimal@sha256:d1276c798b69fb8dc33b4c6a6974d7ed4e842b2ffe130478f88b05e27f74fb0c

ENV TZ=Europe/Berlin

# Set the working directory
WORKDIR /app
RUN mkdir /app/uploaded

# Copy the jar file from the build stage
COPY --from=build /app/target/turniermanager-0.0.1-SNAPSHOT.jar app.jar

# Expose port 8080
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
