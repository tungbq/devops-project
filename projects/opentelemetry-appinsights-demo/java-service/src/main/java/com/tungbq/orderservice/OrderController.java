package com.tungbq.orderservice;

import io.opentelemetry.api.trace.Span;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;

import java.util.Map;

@RestController
public class OrderController {

    private final RestClient restClient;

    public OrderController(@Value("${inventory.service.url}") String inventoryServiceUrl) {
        this.restClient = RestClient.create(inventoryServiceUrl);
    }

    // The whole point of this endpoint: it calls a second service (the
    // .NET inventory service) over plain HTTP. The Application Insights
    // agent auto-instruments this outbound call and propagates the
    // OpenTelemetry trace context header (W3C traceparent), so the two
    // services show up as one connected trace, not two unrelated ones.
    // Each service reports its own view of the current trace ID so the
    // demo script can assert they match — proof of propagation, not just
    // a claim about it.
    @GetMapping("/api/order/{sku}")
    public Map<String, Object> placeOrder(@PathVariable String sku) {
        Map<?, ?> inventory = restClient.get()
                .uri("/api/inventory/{sku}", sku)
                .retrieve()
                .body(Map.class);
        return Map.of(
                "sku", sku,
                "service", "java-order-service",
                "traceId", Span.current().getSpanContext().getTraceId(),
                "inventory", inventory);
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "ok", "service", "java-order-service");
    }
}
