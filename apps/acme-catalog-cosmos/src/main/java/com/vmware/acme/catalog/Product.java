package com.vmware.acme.catalog;

import com.azure.spring.data.cosmos.core.mapping.Container;
import com.azure.spring.data.cosmos.core.mapping.PartitionKey;
import org.springframework.data.annotation.Id;

import java.util.List;

@Container(containerName="products")
public class Product {

    @PartitionKey
    @Id
    private String id;

    private String imageUrl1;
    private String imageUrl2;
    private String imageUrl3;
    private String name;
    private String shortDescription;
    private String description;
    private Double price;
    private List<String> tags;

    public static Product fromProductRequestToProduct(ProductResponse productResponse) {

        Product product = new Product();
        product.setPrice(productResponse.getPrice());
        product.setDescription(productResponse.getDescription());
        product.setName(productResponse.getName());
        product.setImageUrl1(productResponse.getImageUrl1());
        product.setImageUrl2(productResponse.getImageUrl2());
        product.setImageUrl3(productResponse.getImageUrl3());
        product.setShortDescription(productResponse.getShortDescription());
        product.setTags(productResponse.getTags());
        return product;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getImageUrl1() {
        return imageUrl1;
    }

    public void setImageUrl1(String imageUrl1) {
        this.imageUrl1 = imageUrl1;
    }

    public String getImageUrl2() {
        return imageUrl2;
    }

    public void setImageUrl2(String imageUrl2) {
        this.imageUrl2 = imageUrl2;
    }

    public String getImageUrl3() {
        return imageUrl3;
    }

    public void setImageUrl3(String imageUrl3) {
        this.imageUrl3 = imageUrl3;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getShortDescription() {
        return shortDescription;
    }

    public void setShortDescription(String shortDescription) {
        this.shortDescription = shortDescription;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Double getPrice() {
        return price;
    }

    public void setPrice(Double price) {
        this.price = price;
    }

    public List<String> getTags() {
        return tags;
    }

    public void setTags(List<String> tags) {
        this.tags = tags;
    }
}
