package com.vmware.acme.catalog;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.cache.annotation.Cacheable;

import static java.util.stream.StreamSupport.stream;

@Service
public class ProductService {

	private final ProductRepository productRepository;

	public ProductService(ProductRepository productRepository) {
		this.productRepository = productRepository;
	}

	@Cacheable(cacheNames= "products")
	public List<Product> getProducts() {
		return stream(productRepository.findAll().spliterator(), false)
				.collect(Collectors.toList());
	}

	@Cacheable(cacheNames= "product-items", key="#id")
	public Product getProduct(String id) {
		return productRepository.findById(id)
								.orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Unable to find product with id " + id));

	}

}
