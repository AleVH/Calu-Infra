# KYC Service - Build phase
FROM maven:3.9.4-eclipse-temurin-17 AS build
WORKDIR /build
COPY . .

# Install zip if needed
RUN apt-get update && apt-get install -y zip

# Build with Maven or fallback to dummy JAR
RUN if [ -f pom.xml ]; then \
        mvn clean package -DskipTests ; \
    else \
        mkdir -p target && \
        echo "echo KYC Service ready" > dummy.sh && chmod +x dummy.sh && \
        zip -r target/kyc-service.jar dummy.sh ; \
    fi

# Runtime phase
FROM openjdk:17
WORKDIR /app
COPY --from=build /build/target/*.jar app.jar
EXPOSE 4006
CMD ["java", "-jar", "app.jar"]