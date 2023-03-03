package com.vmware.acme.catalog;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import static java.util.stream.StreamSupport.stream;

@Service
public class ProductService {

    private final ProductRepository productRepository;

    public ProductService(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    public Flux<Product> getProducts() {
        return productRepository.findAll();
    }

    public Mono<Product> getProduct(String id) {
        return productRepository.findById(id);
    }

}
