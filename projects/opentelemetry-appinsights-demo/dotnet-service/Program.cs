using Azure.Monitor.OpenTelemetry.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

// Azure Monitor OpenTelemetry Distro — Microsoft's own distribution of the
// standard OpenTelemetry .NET SDK, bundled with ASP.NET Core/HttpClient
// auto-instrumentation and the Azure Monitor exporter. Reads
// APPLICATIONINSIGHTS_CONNECTION_STRING from the environment by default.
builder.Services.AddOpenTelemetry().UseAzureMonitor();

var app = builder.Build();

// A tiny in-memory "inventory" — the whole point of this service is being a
// second hop in a distributed trace, not the business logic.
var inventory = new Dictionary<string, int>
{
    ["widget"] = 42,
    ["gadget"] = 7,
    ["gizmo"] = 0,
};

app.MapGet("/api/inventory/{sku}", (string sku) =>
{
    // Activity.Current is .NET's built-in distributed-tracing primitive —
    // the Azure Monitor OpenTelemetry Distro's ASP.NET Core instrumentation
    // populates it automatically per-request, including the trace ID
    // extracted from the incoming W3C traceparent header sent by whichever
    // service called us. Reporting it lets the demo script prove this
    // service saw the SAME trace as the caller, not just "a" trace.
    var traceId = System.Diagnostics.Activity.Current?.TraceId.ToString() ?? "";

    if (!inventory.TryGetValue(sku, out var quantity))
    {
        return Results.NotFound(new { sku, error = "unknown sku", traceId });
    }
    return Results.Ok(new { sku, quantity, service = "dotnet-inventory-service", traceId });
});

app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "dotnet-inventory-service" }));

app.Run();
