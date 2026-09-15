# Project: OpenTelemetry via Application Insights — Java and .NET

This project demonstrates OpenTelemetry auto-instrumentation concepts using Microsoft's real Application Insights agents — the Java agent and the Azure Monitor OpenTelemetry Distro for .NET — across two services written in different languages, and proves the core payoff of OpenTelemetry: **distributed tracing works across language and runtime boundaries with zero manual trace-linking code.**

## Overview

### Introduction

- Tech stack: `java` (Spring Boot), `dotnet` (ASP.NET Core), `opentelemetry`, `application insights`, `docker`
- Both Microsoft agents are built on the standard OpenTelemetry SDK under the hood — this project is about seeing that concretely, not re-teaching OpenTelemetry from scratch
- Runs entirely locally via Docker — **no Azure subscription required** to run and verify the demo (see "Why this works without Azure" below); point it at a real connection string only when you want to see the data land in the actual Azure portal

### Prerequisite

- You have `docker` installed on your machine
- Basic knowledge of distributed tracing concepts (spans, trace ID, context propagation)

### The two services

| Service | Language | Instrumentation | Port |
|---|---|---|---|
| `java-service` (order-service) | Java 21 / Spring Boot | `-javaagent:applicationinsights-agent.jar` | 8080 |
| `dotnet-service` (inventory-service) | .NET 8 / ASP.NET Core | `Azure.Monitor.OpenTelemetry.AspNetCore` (`UseAzureMonitor()`) | 5080 |

Calling the Java service's `GET /api/order/{sku}` makes it call the .NET service's `GET /api/inventory/{sku}` over plain HTTP — no OpenTelemetry-aware code in either handler. Both agents auto-instrument the HTTP client and server calls and propagate the [W3C `traceparent` header](https://www.w3.org/TR/trace-context/) automatically.

### Why this works without a real Azure resource

Both agents need a connection string to know where to *export* telemetry — but a connection string only has to be **well-formed**, not **real**, for the agent to attach and instrument normally:

- **Java agent + no connection string at all, or a malformed one** → the agent can fail to start (confirmed while building this project).
- **Java agent + a syntactically valid but fake connection string** → the agent attaches, instruments the app fully, and the app runs and serves real traffic. Only the final export call to Azure fails, with a clean, logged `400 Invalid instrumentation key` — proof the agent captured and tried to send real telemetry, not proof it's broken.
- **.NET distro + no connection string** → throws `InvalidOperationException` at startup, the app never runs (confirmed while building this project — see `dotnet-service`'s `Program.cs` comment).
- **.NET distro + a syntactically valid but fake connection string** → same story as Java: the app runs and serves real traffic normally.

`demo_project.sh` uses a placeholder-but-well-formed connection string by default for exactly this reason. Export it yourself to run against a real resource:

```bash
APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=<your-real-key>;IngestionEndpoint=https://<region>.in.applicationinsights.azure.com/" ./demo_project.sh
```

## 1-Build and run both services

- `docker build -t otel-demo-java ./java-service` — multi-stage build; the Application Insights Java agent jar is downloaded during the image build and baked in
- `docker build -t otel-demo-dotnet ./dotnet-service` — multi-stage build with the Azure Monitor OpenTelemetry Distro NuGet package
- Run both on a shared Docker network so the Java service can reach the .NET service by container name

## 2-Confirm both agents actually attached

- Java: `docker logs otel-demo-java | grep "Application Insights Java Agent"` — a clear startup banner
- .NET: there's no equivalent banner — the *absence of a startup crash* is the signal, given point 6 below shows what a missing/invalid connection string actually does

## 3-Make the cross-service call and read the trace IDs back

- `curl http://localhost:8080/api/order/gadget`
- Both services put their own view of the current OpenTelemetry trace ID (via `Span.current()` in Java, `Activity.Current` in .NET — reading the *auto-instrumented* trace, no manual span creation) into their JSON response
- The two trace IDs in the response are identical — the .NET service, entirely without being told anything about the Java service, correctly reconstructed that it's part of the same trace, because the Java agent's outbound HTTP instrumentation attached a `traceparent` header and the .NET distro's inbound instrumentation read it

## 4-Confirm trace IDs are real, not fixed

- Two unrelated, independent requests get two different trace IDs — the matching IDs in step 3 are a genuine correlation, not an artifact of a hardcoded value

## 5-Bonus

All of the above, scripted end-to-end (build → run → confirm both agents attached → cross-service call → assert matching trace IDs → assert distinct trace IDs across unrelated requests → confirm a real export attempt was made), is in [demo_project.sh](./demo_project.sh).

## Related link

- https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-enable?tabs=java
- https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-enable?tabs=aspnetcore
- https://learn.microsoft.com/dotnet/core/diagnostics/observability-applicationinsights
- https://github.com/microsoft/ApplicationInsights-Java
- https://www.w3.org/TR/trace-context/
