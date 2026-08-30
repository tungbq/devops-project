# Multi-stage build: Maven+JDK image compiles, JRE-only image ships.
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src

COPY pom.xml .
RUN mvn -q -B dependency:go-offline

COPY src ./src
RUN mvn -q -B package -DskipTests

# Azure Monitor's Java auto-instrumentation is agent-based, not a library
# dependency (the opposite of the .NET side's SDK approach — a genuinely
# different, both-valid pattern per ecosystem, see README). Downloaded here
# in the build stage (which already has curl via the Maven base image) and
# copied into the runtime stage below, so the final image doesn't need curl
# at all. The release asset name is versioned
# (applicationinsights-agent-X.Y.Z.jar), so a plain `ADD <url>` can't target
# it without hardcoding a version that goes stale — resolve the actual
# latest asset via the GitHub API instead.
RUN curl -fsSL "https://api.github.com/repos/microsoft/ApplicationInsights-Java/releases/latest" \
    | grep -o '"browser_download_url": *"[^"]*applicationinsights-agent-[^"]*\.jar"' \
    | grep -o 'https://[^"]*' \
    | xargs curl -fsSL -o /src/applicationinsights-agent.jar

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /src/target/*.jar app.jar
COPY --from=build /src/applicationinsights-agent.jar applicationinsights-agent.jar

EXPOSE 8081
# Without APPLICATIONINSIGHTS_CONNECTION_STRING set, the agent just logs a
# warning and stays inert — same "no crash without Azure" behavior as
# dotnet-orders-api, just achieved a different way.
ENTRYPOINT ["java", "-javaagent:/app/applicationinsights-agent.jar", "-jar", "app.jar"]
