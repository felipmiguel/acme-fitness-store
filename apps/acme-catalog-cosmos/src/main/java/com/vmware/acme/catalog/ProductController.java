package com.vmware.acme.catalog;

import io.micrometer.core.annotation.Timed;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.stream.Collectors;

@Timed("store.products")
@RestController
public class ProductController {

	private final ProductService productService;

	public ProductController(ProductService productService) {
		this.productService = productService;
	}

	@GetMapping("/products")
	public Mono<GetProductsResponse> getProducts() {
		return Mono.just(new GetProductsResponse(productService.getProducts().map(ProductResponse::new).collect(Collectors.toList()).block()));
	}

	@GetMapping("/products/{id}")
	public Mono<GetProductResponse> getProduct(@PathVariable String id) {
		return productService.getProduct(id).map(p -> new GetProductResponse(new ProductResponse(p), HttpStatus.OK.value()));
	}
}
