using System.Net.Http.Json;
using Azure.Monitor.OpenTelemetry.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddHttpClient();

// Only wires up Azure Monitor when a connection string is actually
// configured — lets this run locally (dotnet run, docker compose) with no
// Azure subscription at all, exactly like a real app shouldn't crash just
// because observability isn't configured for a dev environment.
var appInsightsConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
if (!string.IsNullOrWhiteSpace(appInsightsConnectionString))
{
    builder.Services.AddOpenTelemetry().UseAzureMonitor();
}

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// No UseHttpsRedirection(): TLS terminates at APIM/Container Apps ingress
// in the real deployment target — redirecting inside the container itself
// would just break the container-to-container call below.

app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "dotnet-orders-api" }));

var orders = new List<OrderRecord>();
var random = new Random();

app.MapGet("/api/orders", () => Results.Ok(orders));

app.MapPost("/api/orders", async (OrderRequest req, IHttpClientFactory httpClientFactory, ILogger<Program> logger) =>
{
    // Same "config, not code" pattern as the microservices-orchestration
    // project's ConfigMap-injected URLs — here it's an env var set by the
    // Container Apps Terraform (see ../../terraform/container-apps.tf)
    // instead of a K8s ConfigMap, same idea.
    var inventoryUrl = Environment.GetEnvironmentVariable("INVENTORY_URL") ?? "http://localhost:8081";
    var client = httpClientFactory.CreateClient();

    HttpResponseMessage reserveResponse;
    try
    {
        reserveResponse = await client.PostAsJsonAsync(
            $"{inventoryUrl}/api/inventory/reserve",
            new { item = req.Item, quantity = req.Quantity });
    }
    catch (HttpRequestException ex)
    {
        logger.LogError(ex, "java-inventory-api unreachable at {InventoryUrl}", inventoryUrl);
        return Results.Problem(detail: $"inventory service unreachable: {ex.Message}", statusCode: 502);
    }

    if (!reserveResponse.IsSuccessStatusCode)
    {
        var body = await reserveResponse.Content.ReadAsStringAsync();
        logger.LogWarning("Inventory reservation failed with {StatusCode}: {Body}", reserveResponse.StatusCode, body);
        return Results.Problem(detail: body, statusCode: (int)reserveResponse.StatusCode);
    }

    // ~15% simulated failure rate on the order itself (after stock is
    // already reserved) — gives the SLO/error-rate dashboard real,
    // non-zero data to show instead of a flat 100% success line. This is
    // a demo-data generator, not a bug — see README "What this project
    // deliberately leaves out".
    if (random.NextDouble() < 0.15)
    {
        logger.LogError("Simulated order processing failure for item {Item}", req.Item);
        return Results.Problem(detail: "simulated order processing failure", statusCode: 500);
    }

    var order = new OrderRecord(Guid.NewGuid().ToString(), req.Item, req.Quantity, DateTimeOffset.UtcNow);
    orders.Add(order);
    logger.LogInformation("Order {OrderId} confirmed for {Quantity}x {Item}", order.Id, req.Quantity, req.Item);
    return Results.Created($"/api/orders/{order.Id}", order);
});

app.Run();

record OrderRequest(string Item, int Quantity);
record OrderRecord(string Id, string Item, int Quantity, DateTimeOffset CreatedAt);
