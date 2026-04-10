package com.example.demo;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class DemoApplication {

	@Value("${dbusername:NOT_FOUND}")
	private String dbUsername;

	@Value("${dbpassword:NOT_FOUND}")
	private String dbPassword;

	public static void main(String[] args) {
		SpringApplication.run(DemoApplication.class, args);
	}

	@GetMapping("/")
	public String hello() {
		return "Hello from Elastic Beanstalk! (Nginx Hash Optimized)";
	}

	@GetMapping("/config-check")
	public String checkConfig() {
		return String.format("AWS Secrets Status - Username: [%s], Password Loaded: [%b]", 
			dbUsername, (!"NOT_FOUND".equals(dbPassword)));
	}

}
