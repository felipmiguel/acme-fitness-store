package com.vmware.acme.catalog;

import com.azure.spring.data.cosmos.repository.ReactiveCosmosRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProductRepository extends ReactiveCosmosRepository<Product, String> {

}
