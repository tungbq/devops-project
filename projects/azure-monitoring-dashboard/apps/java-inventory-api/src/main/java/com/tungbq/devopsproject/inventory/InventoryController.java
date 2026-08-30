package com.tungbq.devopsproject.inventory;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class InventoryController {

    private static final Logger log = LoggerFactory.getLogger(InventoryController.class);

    // In-memory stock — a demo sink, not a real inventory system. Same
    // pattern as the microservices-orchestration project's
    // inventory-service.py, for narrative consistency across the repo.
    private final Map<String, Integer> stock = new ConcurrentHashMap<>(Map.of(
            "widget", 50,
            "gadget", 20));

    public record ReserveRequest(String item, int quantity) {
    }

    @PostMapping("/api/inventory/reserve")
    public ResponseEntity<?> reserve(@RequestBody ReserveRequest req) {
        Integer available = stock.get(req.item());
        if (available == null) {
            log.warn("Reservation attempted for unknown item {}", req.item());
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "unknown item '" + req.item() + "'"));
        }
        if (available < req.quantity()) {
            log.warn("Insufficient stock for {}: have {}, requested {}", req.item(), available, req.quantity());
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "insufficient stock for '" + req.item() + "'"));
        }

        int remaining = available - req.quantity();
        stock.put(req.item(), remaining);
        log.info("Reserved {}x {} ({} remaining)", req.quantity(), req.item(), remaining);
        return ResponseEntity.ok(Map.of(
                "service", "java-inventory-api",
                "item", req.item(),
                "reserved", req.quantity(),
                "remaining", remaining));
    }
}
